"""CLI : python -m jev_bench <commande> (aide : --help sur chaque commande)."""
from __future__ import annotations

import argparse
import csv
import json
import subprocess
import sys
from pathlib import Path

from . import config, prompts, store
from .length import length_info


# --------------------------------------------------------------------------- import-fixtures
def cmd_import_fixtures(args) -> int:
    conn = store.connect()
    added = unchanged = conflicts = 0
    with open(args.file, encoding="utf-8") as fh:
        for line in fh:
            if not line.strip():
                continue
            fx = json.loads(line)
            canonical = json.dumps(fx, ensure_ascii=False, sort_keys=True)
            existing = conn.execute("SELECT fixture_json FROM sample WHERE sample_id=?",
                                    (fx["fixture_id"],)).fetchone()
            if existing:
                if existing["fixture_json"] == canonical:
                    unchanged += 1
                else:
                    conflicts += 1
                    print(f"  CONFLIT {fx['fixture_id']} : contenu différent en base, non écrasé")
                continue
            li = length_info(fx["task_type"], fx["production"])
            if li["word_count"] != fx.get("word_count", li["word_count"]):
                print(f"  ATTENTION {fx['fixture_id']} : word_count fixture {fx['word_count']} ≠ recalcul {li['word_count']}")
            conn.execute(
                "INSERT INTO sample(sample_id, source, titre, task_type, task_type_source, task_type_justification, "
                "consigne, contexte, production, word_count, official_min, official_max, below_official_min, "
                "above_official_max, official_length_compliant, niveau_vise, niveau_vise_code, niveau_vise_alternatif, "
                "niveau_vise_source, playground_json, fixture_json, imported_at) "
                "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                (fx["fixture_id"], Path(args.file).stem, fx.get("titre"), fx["task_type"], fx.get("task_type_source"),
                 fx.get("task_type_justification"), fx["consigne"], fx.get("contexte"), fx["production"],
                 li["word_count"], li["official_min"], li["official_max"], int(li["below_official_min"]),
                 int(li["above_official_max"]), int(li["official_length_compliant"]), fx.get("niveau_vise"),
                 fx.get("niveau_vise_code"), fx.get("niveau_vise_alternatif"), fx.get("niveau_vise_source"),
                 json.dumps({"playground": fx.get("playground"), "autres": fx.get("playground_autres") or []},
                            ensure_ascii=False),
                 canonical, store.now_iso()))
            added += 1
            old = fx.get("replaces")
            if old:
                n = conn.execute(
                    "UPDATE sample SET status='RETIRED', replaced_by=?, retired_reason=? "
                    "WHERE sample_id=? AND status='ACTIVE'",
                    (fx["fixture_id"], fx.get("replaces_reason") or "remplacé", old)).rowcount
                print(f"  {old} retiré (conservé pour trace), remplacé par {fx['fixture_id']}" if n
                      else f"  ATTENTION : {old} introuvable ou déjà retiré")
    conn.commit()
    total = conn.execute("SELECT COUNT(*) FROM sample").fetchone()[0]
    print(f"import-fixtures : {added} ajoutée(s), {unchanged} inchangée(s), {conflicts} conflit(s) ; "
          f"{total} échantillon(s) en base ({config.DB_FILE})")
    return 1 if conflicts else 0


# --------------------------------------------------------------------------- check-prompts
def _check_version(version: str, v15: dict) -> int:
    errors = 0
    common = prompts.load_common(version)
    for t in prompts.TASK_TYPES:
        n = t[-1]
        task = prompts.load_task(t, version)
        ours = task["criteres"]
        ref = v15["rubrics"][f"EE_T{n}"]["criteres"]
        if [c["code"] for c in ours] != [c["code"] for c in ref]:
            print(f"  ÉCART {version} {t} : codes {[c['code'] for c in ours]} ≠ v15 {[c['code'] for c in ref]}")
            errors += 1
            continue
        for a, b in zip(ours, ref):
            for field in ("label", "description"):
                if a[field] != b[field]:
                    errors += 1
                    print(f"  ÉCART {version} {t}.{a['code']}.{field}\n    prompt : {a[field]!r}\n    v15    : {b[field]!r}")
        if "descripteurs_v15" in task:
            desc_ref = v15["rubrics"][f"EE_T{n}"]["descripteurs"]
            for lvl, txt in task["descripteurs_v15"].items():
                if desc_ref.get(lvl) != txt:
                    errors += 1
                    print(f"  ÉCART {version} {t} : descripteur v15 {lvl} différent")
        q = prompts.build_questions(t, version)
        for c in ref:
            ins = q[f"critere_{c['code']}"]["instructions"]
            if ins["critere"] != c["label"] or ins["description"] != c["description"]:
                errors += 1
                print(f"  ÉCART {version} {t} : la question critere_{c['code']} assemblée ne reprend pas v15 à l'identique")
    if "echelle_cecrl_v15" in common["critere"]:
        sec = next(x for x in v15["commun"]["sections"] if x["titre"].startswith("Echelle CECRL"))
        lines = sec["contenu"].split("\n")
        for lvl, txt in common["critere"]["echelle_cecrl_v15"].items():
            if f"{lvl} : {txt}" not in lines:
                errors += 1
                print(f"  ÉCART {version} : échelle CECRL v15 {lvl} différente")
    print(f"prompt_version : {version}")
    for t in prompts.TASK_TYPES:
        print(f"  {t} questions_hash = {prompts.questions_hash(prompts.build_questions(t, version))}")
    print(f"  global questions_hash = {prompts.all_questions_hash(version)}")
    return errors


def cmd_check_prompts(args) -> int:
    v15 = json.loads(config.RUBRICS_V15_FILE.read_text(encoding="utf-8"))
    errors = 0
    if v15.get("rubrics-version") != "v15":
        print(f"  ÉCART : le fichier de grille annonce {v15.get('rubrics-version')}")
        errors += 1
    for version in config.PROMPT_VERSIONS:
        errors += _check_version(version, v15)
    if prompts.all_questions_hash(config.PROMPT_VERSIONS[0]) == prompts.all_questions_hash(config.PROMPT_VERSIONS[1]):
        errors += 1
        print("  ÉCART : les deux versions produisent les mêmes questions")
    print("check-prompts : OK (deux versions ; intitulés, descriptions et copies v15 identiques à la grille)"
          if errors == 0 else f"check-prompts : {errors} écart(s)")
    return 1 if errors else 0


# --------------------------------------------------------------------------- selfcheck
def cmd_selfcheck(args) -> int:
    from .selfcheck import run_selfcheck
    return run_selfcheck(with_db=args.db)


# --------------------------------------------------------------------------- score-sejourfr
def cmd_score_sejourfr(args) -> int:
    from .sejourfr_scoring import score_all
    conn = store.connect()
    ss = store.samples(conn, task=args.task, limit=args.limit, ids=args.ids)
    if not ss:
        print("aucun échantillon : lancer d'abord import-fixtures")
        return 1
    report = score_all(conn, ss, args.base_url, poll_timeout_s=args.timeout)
    for r in report:
        print("  " + "  ".join(f"{k}={v}" for k, v in r.items()))
    return 0


# --------------------------------------------------------------------------- run
def cmd_run(args) -> int:
    from . import runner
    conn = store.connect()
    ss = store.samples(conn, task=args.task, niveau_vise=args.niveau_vise, limit=args.limit, ids=args.ids,
                       origin=args.origin, repeat_subset=args.repeat_subset)
    if not ss:
        print("aucun échantillon sélectionné (import-fixtures / extract-real fait ?)")
        return 1
    filters = {"task": args.task, "niveau_vise": args.niveau_vise, "limit": args.limit, "ids": args.ids,
               "origin": args.origin, "repeat_subset": args.repeat_subset,
               "repeat_only_subset": args.repeat_only_subset, "model": args.model}
    if args.origin == "REAL" and not args.dry_run:
        if not args.confirm_real:
            print("REFUS : run réel sur des productions RÉELLES sans --confirm-real (décision explicite du propriétaire).")
            return 2
        if args.budget_usd > 0.10:
            print("REFUS : sur des productions réelles, --budget-usd doit être ≤ 0,10 $.")
            return 2
        if args.model == config.DEFAULT_MODEL:
            print("REFUS : sur des productions réelles, le modèle doit être ÉPINGLÉ (ex. --model jev-1.13.0).")
            return 2
    if args.dry_run:
        summary = runner.dry_run(conn, ss, args.model, args.repeat, filters, args.prompt_version)
        print(json.dumps(summary, ensure_ascii=False, indent=2))
        return 0
    ests = [runner.estimate_request(prompts.build_payload(s, args.model, args.prompt_version)) for s in ss]
    reps = [(args.repeat if (not args.repeat_only_subset or s.get("repeat_subset")) else 1) for s in ss]
    tokens = sum(e["input_tokens_conservative"] * k for e, k in zip(ests, reps))
    print(f"RUN RÉEL [{args.prompt_version} · {args.origin} · modèle {args.model}] : {len(ss)} échantillon(s), "
          f"{sum(reps)} requête(s), coût estimé ≈ {runner.cost_usd(tokens):.4f} $ "
          f"({tokens} tokens d'entrée, estimation conservatrice) ; budget {args.budget_usd} $")
    if not args.yes:
        answer = input("Confirmer l'appel PAYANT à l'API JEV ? [oui/N] ")
        if answer.strip().lower() not in ("oui", "o", "yes", "y"):
            print("annulé")
            return 1
    summary = runner.real_run(conn, ss, args.model, args.repeat, filters, resume_run_id=args.resume,
                              version=args.prompt_version, budget_usd=args.budget_usd, notes=args.notes,
                              repeat_subset_only=args.repeat_only_subset)
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0


# --------------------------------------------------------------------------- export
EXPORT_SQL = """
SELECT :version AS prompt_version_filtre, s.origin, s.stratum, s.sample_id, s.titre, s.task_type, s.word_count, s.official_min, s.official_max,
       s.official_length_compliant, s.niveau_vise_code, s.niveau_vise_alternatif, s.niveau_vise,
       json_extract(s.playground_json, '$.playground.choice') AS playground_choice,
       json_extract(s.playground_json, '$.playground.confidence') AS playground_confidence,
       json_extract(s.playground_json, '$.playground.question_version') AS playground_question_version,
       sr.status AS sejourfr_status, sr.niveau_cecrl AS sejourfr_niveau, sr.niveau_cecrl_ia AS sejourfr_niveau_ia,
       sr.note_sur_20 AS sejourfr_note, sr.note_communiquer AS sejourfr_communiquer,
       sr.note_interagir AS sejourfr_interagir, sr.note_lexique AS sejourfr_lexique,
       sr.note_morphosyntaxe AS sejourfr_morphosyntaxe, sr.confiance AS sejourfr_confiance,
       sr.plafond_niveau AS sejourfr_plafond, sr.rubrics_version, sr.prompt_version AS sejourfr_prompt_version,
       sr.modele_utilise AS sejourfr_modele,
       j.run_id, j.repeat_index, j.model_returned, j.prompt_version AS jev_prompt_version, j.questions_hash,
       j.niveau_global_choice, j.niveau_global_confidence, j.niveau_global_probs,
       j.pertinence_choice, j.pertinence_confidence,
       j.communiquer_choice, j.interagir_choice, j.lexique_choice, j.morphosyntaxe_choice,
       j.secondaire_formule_argmax_niveau AS secondaire_niveau_via_formule_sejourfr_argmax,
       j.secondaire_formule_argmax_note AS secondaire_note_via_formule_sejourfr_argmax,
       j.secondaire_formule_esperance_niveau AS secondaire_niveau_via_formule_sejourfr_esperance,
       j.secondaire_formule_esperance_note AS secondaire_note_via_formule_sejourfr_esperance,
       j.input_tokens, j.cost_usd, j.error AS jev_error
FROM sample s
LEFT JOIN sejourfr_result sr ON sr.id = (SELECT MAX(id) FROM sejourfr_result WHERE sample_id = s.sample_id)
LEFT JOIN jev_result j ON j.sample_id = s.sample_id AND j.prompt_version = :version
     AND j.run_id IN (SELECT run_id FROM benchmark_run WHERE mode = 'real' AND prompt_version = :version
                      AND (:mode = 'all' OR COALESCE(notes, '') NOT LIKE 'test%'))
WHERE s.status = 'ACTIVE' AND s.origin = :origin
ORDER BY s.sample_id, j.run_id, j.repeat_index
"""


def cmd_export(args) -> int:
    """Un fichier PAR version de prompt : les deux benchmarks ne sont jamais mélangés."""
    conn = store.connect()
    config.EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    stamp = store.now_iso().replace(":", "").replace("+0000", "Z")
    versions = [args.prompt_version] if args.prompt_version else list(config.PROMPT_VERSIONS)
    for version in versions:
        rows = [dict(r) for r in conn.execute(EXPORT_SQL, {"version": version, "mode": args.mode,
                                                           "origin": args.origin})]
        out = str(config.EXPORT_DIR / f"benchmark-{args.origin.lower()}-{version}-{stamp}.{args.format}")
        if args.format == "json":
            with open(out, "w", encoding="utf-8") as fh:
                json.dump({"prompt_version": version, "rows": rows}, fh, ensure_ascii=False, indent=2)
        else:
            with open(out, "w", encoding="utf-8", newline="") as fh:
                fields = list(rows[0].keys()) if rows else []
                w = csv.DictWriter(fh, fieldnames=fields)
                w.writeheader()
                w.writerows(rows)
        print(f"export {args.format} [{version}] : {len(rows)} ligne(s) → {out}")
    return 0


# --------------------------------------------------------------------------- extract-real
def cmd_extract_real(args) -> int:
    from . import real_import
    conn = store.connect()
    raw = Path(args.file) if args.file else real_import.extract()
    summary = real_import.import_raw(conn, raw, keep_raw=args.keep_raw)
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0


# --------------------------------------------------------------------------- report
def cmd_report(args) -> int:
    from .report import build
    conn = store.connect()
    data, md = build(conn)
    config.EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    stamp = store.now_iso().replace(":", "").replace("+0000", "Z")
    js = config.EXPORT_DIR / f"rapport-{stamp}.json"
    js.write_text(json.dumps(data, ensure_ascii=False, indent=2, default=str), encoding="utf-8")
    print(md)
    print(f"\n(JSON détaillé : {js})")
    return 0


def cmd_report_real(args) -> int:
    from .report_real import build
    conn = store.connect()
    data, md = build(conn)
    config.EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    stamp = store.now_iso().replace(":", "").replace("+0000", "Z")
    js = config.EXPORT_DIR / f"rapport-reel-{stamp}.json"
    js.write_text(json.dumps(data, ensure_ascii=False, indent=2, default=str), encoding="utf-8")
    print(md)
    print(f"\n(JSON détaillé : {js})")
    return 0


# --------------------------------------------------------------------------- ui
def cmd_ui(args) -> int:
    app = config.PACKAGE_DIR / "app.py"
    cmd = [sys.executable, "-m", "streamlit", "run", str(app), "--server.port", str(args.port),
           "--server.address", "localhost", "--browser.gatherUsageStats", "false"]
    if args.headless:
        cmd += ["--server.headless", "true"]
    return subprocess.call(cmd, cwd=str(config.TOOL_DIR))


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="python -m jev_bench",
                                description="Benchmark local JEV vs correcteur SejourFR (productions EE).")
    sub = p.add_subparsers(dest="command", required=True)

    s = sub.add_parser("import-fixtures", help="importe les fixtures JSONL dans SQLite (sans écraser)")
    s.add_argument("--file", default=str(config.FIXTURES_FILE),
                   help="ex. fixtures/synthetic_ee_v1.jsonl (défaut) ou fixtures/synthetic_ee_v2.jsonl")
    s.set_defaults(func=cmd_import_fixtures)

    s = sub.add_parser("check-prompts", help="vérifie que les critères des prompts sont identiques à la grille v15")
    s.set_defaults(func=cmd_check_prompts)

    s = sub.add_parser("selfcheck", help="cas calculés à la main : formule SejourFR, comptage, prompts")
    s.add_argument("--db", action="store_true", help="recoupe aussi avec les évaluations v15 de la base LOCALE (lecture seule)")
    s.set_defaults(func=cmd_selfcheck)

    s = sub.add_parser("score-sejourfr", help="note les fixtures par le correcteur SejourFR via le backend LOCAL (appels DeepSeek payants)")
    s.add_argument("--base-url", default=config.LOCAL_BACKEND_DEFAULT, help="backend LOCAL uniquement (localhost)")
    s.add_argument("--task", choices=prompts.TASK_TYPES)
    s.add_argument("--limit", type=int)
    s.add_argument("--ids", nargs="*")
    s.add_argument("--timeout", type=float, default=300.0, help="délai max de poll par soumission (s)")
    s.set_defaults(func=cmd_score_sejourfr)

    s = sub.add_parser("run", help="run JEV : --dry-run (aucun appel) ou réel (PAYANT, confirmation demandée)")
    s.add_argument("--dry-run", action="store_true", help="n'appelle rien : écrit les payloads et estime le coût")
    s.add_argument("--repeat", type=int, default=1)
    s.add_argument("--limit", type=int)
    s.add_argument("--task", choices=prompts.TASK_TYPES)
    s.add_argument("--niveau-vise", choices=["A1", "A2", "B1", "B2", "INSUFFICIENT"])
    s.add_argument("--ids", nargs="*")
    s.add_argument("--model", default=config.DEFAULT_MODEL, help="ex. jev-latest ou jev-1.13.0")
    s.add_argument("--resume", help="run_id réel à reprendre (ne relance pas les répétitions réussies)")
    s.add_argument("--yes", action="store_true", help="ne pas demander de confirmation (run réel)")
    s.add_argument("--prompt-version", choices=config.PROMPT_VERSIONS, default=config.PROMPT_VERSION,
                   help="jev-independent-v1 (principal) ou jev-v15-aligned-v1 (sensibilité)")
    s.add_argument("--budget-usd", type=float, default=0.20,
                   help="arrêt si le coût RÉEL cumulé (usage API) dépasse ce montant")
    s.add_argument("--notes", help="libellé du run (commencer par « test » pour un appel de validation)")
    s.add_argument("--origin", choices=store.ORIGINS, default="SYNTHETIC",
                   help="SYNTHETIC (défaut) ou REAL — jamais les deux dans un même run")
    s.add_argument("--repeat-subset", action="store_true", help="REAL : seulement le sous-ensemble stratifié « repeat »")
    s.add_argument("--repeat-only-subset", action="store_true",
                   help="--repeat appliqué au seul sous-ensemble « repeat » (les autres cas : 1 répétition)")
    s.add_argument("--confirm-real", action="store_true",
                   help="OBLIGATOIRE pour un run réel sur origin=REAL (décision explicite du propriétaire)")
    s.set_defaults(func=cmd_run)

    s = sub.add_parser("export", help="exporte les résultats (un fichier PAR version de prompt) dans data/exports/")
    s.add_argument("--format", choices=["csv", "json"], default="csv")
    s.add_argument("--prompt-version", choices=config.PROMPT_VERSIONS, help="une seule version (défaut : les deux, fichiers séparés)")
    s.add_argument("--mode", choices=["main", "all"], default="main", help="main : exclut les runs de test")
    s.add_argument("--origin", choices=store.ORIGINS, default="SYNTHETIC", help="une seule origine par fichier")
    s.set_defaults(func=cmd_export)

    s = sub.add_parser("extract-real", help="extraction ANONYMISÉE des productions EE réelles (prod, lecture seule) "
                                            "+ rédaction locale + import SQLite (origin=REAL) + suppression du brut")
    s.add_argument("--file", help="importer un brut déjà extrait (data/raw/…) au lieu d'interroger la prod")
    s.add_argument("--keep-raw", action="store_true", help="ne pas supprimer le brut (déconseillé)")
    s.set_defaults(func=cmd_extract_real)

    s = sub.add_parser("report", help="rapport agrégé PAR version de prompt (Markdown + JSON dans data/exports/)")
    s.set_defaults(func=cmd_report)

    s = sub.add_parser("report-real", help="rapport agrégé sur productions RÉELLES (origin=REAL), sans aucun texte")
    s.set_defaults(func=cmd_report_real)

    s = sub.add_parser("ui", help="lance l'interface Streamlit (lecture SQLite seule)")
    s.add_argument("--port", type=int, default=8501)
    s.add_argument("--headless", action="store_true")
    s.set_defaults(func=cmd_ui)
    return p


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    if getattr(args, "repeat", 1) < 1:
        print("--repeat doit être ≥ 1")
        return 2
    return args.func(args)
