"""Productions EE RÉELLES : extraction anonymisée (prod, LECTURE SEULE) puis import rédigé.

- ``extract`` lance EXACTEMENT la commande validée par le propriétaire :
  ssh … "LC_ALL=C.UTF-8 sudo -u postgres env PGOPTIONS='-c default_transaction_read_only=on'
  psql -X -A -t -v ON_ERROR_STOP=1 -v salt=<SEL> -d sejourfr_db_v2 -f -" < export_ee_real_v1.sql
  Uniquement des SELECT, aucun fichier écrit sur le VPS, sortie brute dans data/raw/ (gitignoré).
- ``import_raw`` rédige les données personnelles LOCALEMENT avant tout stockage, n'écrit que
  le texte rédigé (plus un compteur par type), isole les strates, tire le sous-ensemble
  « repeat », écrit un audit local et SUPPRIME le brut après import réussi.
"""
from __future__ import annotations

import json
import secrets
import subprocess
from collections import Counter, defaultdict
from pathlib import Path

from . import config, store
from .length import count_words
from .redact import redact, residues

SALT_FILE = config.DATA_DIR / ".salt"
RAW_DIR = config.DATA_DIR / "raw"
AUDIT_DIR = config.DATA_DIR / "audit"
EXPORT_SQL = config.SQL_DIR / "export_ee_real_v1.sql"
PROD_HOST = "root@82.223.165.43"
PROD_DB = "sejourfr_db_v2"
CLASSIC = ("A1", "A2", "B1", "B2")
ISOLATED = ("A1_NON_ATTEINT", "NON_EVALUABLE", "PLAFOND")
REPEAT_PER_CLASSIC_CELL = 2
REPEAT_PER_ISOLATED_STRATUM = 1


def salt() -> str:
    """Sel local (secrets.token_hex(32)), créé une fois, jamais affiché ni versionné."""
    config.DATA_DIR.mkdir(parents=True, exist_ok=True)
    if not SALT_FILE.exists():
        SALT_FILE.write_text(secrets.token_hex(32), encoding="utf-8")
        SALT_FILE.chmod(0o600)
    value = SALT_FILE.read_text(encoding="utf-8").strip()
    if len(value) != 64:
        raise SystemExit("sel local invalide")
    return value


def extract() -> Path:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    out = RAW_DIR / f"export_ee_real_v1-{store.now_iso().replace(':', '').replace('+0000', 'Z')}.jsonl"
    remote = ("LC_ALL=C.UTF-8 sudo -u postgres env PGOPTIONS='-c default_transaction_read_only=on' "
              f"psql -X -A -t -v ON_ERROR_STOP=1 -v salt={salt()} -d {PROD_DB} -f -")
    with open(EXPORT_SQL, "rb") as sql_in, open(out, "wb") as raw_out:
        res = subprocess.run(["ssh", "-o", "BatchMode=yes", PROD_HOST, remote],
                             stdin=sql_in, stdout=raw_out, stderr=subprocess.PIPE, timeout=300)
    if res.returncode != 0:
        out.unlink(missing_ok=True)
        err = res.stderr.decode("utf-8", "replace").replace(salt(), "***")
        raise SystemExit(f"extraction échouée (code {res.returncode}) : {err[:500]}")
    return out


def _sample_id(rec: dict) -> str:
    return f"REAL-EE{rec['tache_numero']}-{rec['sample_key'][:12]}"


def _cell(rec: dict) -> tuple:
    """Cellule du tirage « repeat » : tâche × niveau (CECRL) ou tâche × strate isolée."""
    if rec["strate"] == "CECRL":
        return ("CECRL", rec["tache_numero"], rec["niveau_cecrl"])
    return (rec["strate"], rec["tache_numero"], None)


def reassign_repeat_subset(conn, extraction_id: str) -> int:
    """Recalcule le sous-ensemble « repeat » d'une extraction déjà importée (même règle, déterministe)."""
    rows = conn.execute(
        "SELECT s.sample_id, s.stratum, s.task_type, r.niveau_cecrl, json_extract(s.fixture_json, '$.sample_key') k "
        "FROM sample s JOIN sejourfr_result r USING(sample_id) WHERE s.origin='REAL' AND s.source=? "
        "AND s.status='ACTIVE'",
        (extraction_id,)).fetchall()
    by_cell = defaultdict(list)
    for r in rows:
        rec = {"strate": r["stratum"], "tache_numero": int(r["task_type"][-1]), "niveau_cecrl": r["niveau_cecrl"]}
        by_cell[_cell(rec)].append(r)
    chosen = set()
    for cell, rs in by_cell.items():
        k = REPEAT_PER_CLASSIC_CELL if cell[0] == "CECRL" else REPEAT_PER_ISOLATED_STRATUM
        chosen.update(r["sample_id"] for r in sorted(rs, key=lambda x: x["k"])[:k])
    conn.execute("UPDATE sample SET repeat_subset=0 WHERE origin='REAL' AND source=?", (extraction_id,))
    for sid in chosen:
        conn.execute("UPDATE sample SET repeat_subset=1 WHERE sample_id=?", (sid,))
    conn.commit()
    return len(chosen)


def rebuild_residues(conn, extraction_id: str) -> dict:
    """Recalcule la section RÉSIDUS de l'audit local à partir des textes RÉDIGÉS stockés."""
    audit_file = AUDIT_DIR / f"redaction-{extraction_id}.tsv"
    head = audit_file.read_text(encoding="utf-8").split("\n# RÉSIDUS")[0] if audit_file.exists() else ""
    lines = []
    for r in conn.execute("SELECT sample_id, production, consigne, contexte FROM sample WHERE origin='REAL' AND source=? "
                          "ORDER BY sample_id", (extraction_id,)):
        for label, ctx in residues(r["production"], r["consigne"], r["contexte"]):
            lines.append(f"{r['sample_id']}\t{label}\t{ctx}")
    audit_file.write_text(head.rstrip("\n") + "\n\n# RÉSIDUS À VÉRIFIER À LA MAIN\n" + "\n".join(lines) + "\n",
                          encoding="utf-8")
    return dict(Counter(line.split("\t")[1] for line in lines))


def import_raw(conn, raw: Path, keep_raw: bool = False) -> dict:
    lines = [json.loads(line) for line in raw.read_text(encoding="utf-8").splitlines() if line.strip()]
    recs = [r for r in lines if r["kind"] == "sample"]
    counts = [r for r in lines if r["kind"] == "count"]
    extraction_id = raw.stem

    # contrôle local du plafond candidat (le pseudo-candidat ne sort jamais d'ici)
    per_cand = Counter(r["candidate_key"] for r in recs)
    if per_cand and max(per_cand.values()) > 3:
        raise SystemExit("plafond candidat violé dans l'extraction : import refusé")

    # sous-ensemble repeat : déterministe (ordre de sample_key), stratifié
    by_cell = defaultdict(list)
    for r in recs:
        by_cell[_cell(r)].append(r)
    subset = set()
    for cell, rs in by_cell.items():
        k = REPEAT_PER_CLASSIC_CELL if cell[0] == "CECRL" else REPEAT_PER_ISOLATED_STRATUM
        for r in sorted(rs, key=lambda x: x["sample_key"])[:k]:
            subset.add(r["sample_key"])

    total_red = Counter()
    audit_lines, residue_lines = [], []
    inserted = 0
    for r in recs:
        sid = _sample_id(r)
        if conn.execute("SELECT 1 FROM sample WHERE sample_id=?", (sid,)).fetchone():
            continue
        texte, red, audit = redact(r["texte_soumis"] or "", r["consigne"], r["contexte"])
        r["texte_soumis"] = None  # l'original ne quitte pas cette fonction
        total_red.update(red)
        for label, ctx in audit:
            audit_lines.append(f"{sid}\t{label}\t{ctx}")
        for label, ctx in residues(texte, r["consigne"], r["contexte"]):
            residue_lines.append(f"{sid}\t{label}\t{ctx}")
        task_type = f"EE_TASK_{r['tache_numero']}"
        lo, hi = r["mots_min"], r["mots_max"]
        wc = r["mots_count"] if r["mots_count"] is not None else count_words(texte)
        conn.execute(
            "INSERT INTO sample(sample_id, source, titre, task_type, task_type_source, consigne, contexte, production, "
            "word_count, official_min, official_max, below_official_min, above_official_max, official_length_compliant, "
            "fixture_json, imported_at, origin, stratum, repeat_subset, word_count_redacted, redactions_json, "
            "attempt_type, submitted_month) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
            (sid, extraction_id, f"Production réelle EE{r['tache_numero']} · {r['attempt_type']} · {r['mois']}",
             task_type, "production_tasks.tache_numero", r["consigne"], r["contexte"], texte,
             wc, lo, hi, int(lo is not None and wc < lo), int(hi is not None and wc > hi),
             int(lo is not None and hi is not None and lo <= wc <= hi),
             json.dumps({"sample_key": r["sample_key"], "extraction": extraction_id}, ensure_ascii=False),
             store.now_iso(), "REAL", r["strate"], int(r["sample_key"] in subset), count_words(texte),
             json.dumps(dict(red), ensure_ascii=False), r["attempt_type"], r["mois"]))
        conn.execute("INSERT INTO real_candidate(sample_id, candidate_key) VALUES (?,?)", (sid, r["candidate_key"]))
        scores = {x["code"]: x["note_sur_20"] for x in (r["scores"] or [])}
        status = "NON_EVALUABLE" if r["evaluabilite"] == "NON_EVALUABLE" else "EVALUATED"
        conn.execute(
            "INSERT INTO sejourfr_result(sample_id, created_at, status, word_count, mots_min, mots_max, niveau_cecrl, "
            "niveau_cecrl_ia, note_sur_20, note_communiquer, note_interagir, note_lexique, note_morphosyntaxe, "
            "scores_criteres_json, confiance, plafond_niveau, evaluabilite, modele_utilise, prompt_version, "
            "rubrics_version, versions_ok, error) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
            (sid, store.now_iso(), status, wc, lo, hi, r["niveau_cecrl"], r["niveau_cecrl_ia"], r["note_sur_20"],
             scores.get("communiquer"), scores.get("interagir"), scores.get("lexique"), scores.get("morphosyntaxe"),
             store.dumps(r["scores"]), r["confiance"], r["plafond_niveau"], r["evaluabilite"], r["modele_utilise"],
             r["prompt_version"], r["rubrics_version"],
             int(r["rubrics_version"] == "v15" and r["prompt_version"] == "v9"),
             "prod : condition de plafond T3 réunie (communiquer ≤ 1)" if r["plafond_condition_t3"] else None))
        inserted += 1
    for c in counts:
        conn.execute("INSERT OR REPLACE INTO real_extraction_count VALUES (?,?,?,?,?,?,?,?,?)",
                     (extraction_id, c["tache_numero"], c["strate"], c["niveau"], c["disponible"],
                      c["candidats_disponibles"], c["apres_plafond"], c["retenu"], c["candidats_retenus"]))
    conn.commit()

    AUDIT_DIR.mkdir(parents=True, exist_ok=True)
    audit_file = AUDIT_DIR / f"redaction-{extraction_id}.tsv"
    audit_file.write_text("sample_id\ttype\tcontexte (5 mots)\n" + "\n".join(audit_lines) + "\n"
                          + "\n# RÉSIDUS À VÉRIFIER À LA MAIN\n" + "\n".join(residue_lines) + "\n", encoding="utf-8")
    if not keep_raw:
        raw.unlink()
    return {"extraction_id": extraction_id, "echantillons": len(recs), "inseres": inserted,
            "sous_ensemble_repeat": len(subset), "remplacements": dict(total_red),
            "residus": dict(Counter(line.split("\t")[1] for line in residue_lines)),
            "audit_local": str(audit_file), "brut_supprime": not keep_raw,
            "max_par_candidat": max(per_cand.values()) if per_cand else 0}
