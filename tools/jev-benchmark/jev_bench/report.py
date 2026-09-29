"""Rapport agrégé du benchmark, PAR VERSION DE PROMPT (jamais mélangées).

Règles :
- population = échantillons ACTIFS ; runs = runs réels de la version, hors runs de test ;
- niveau visé double (principal + alternatif) : lecture STRICTE (principal seul) et
  lecture SOUPLE (l'un des deux) ;
- null = inconnu, jamais un désaccord ; INSUFFICIENT n'est pas sur l'échelle ordinale :
  il est exact seulement face à INSUFFICIENT, sinon compté à part ;
- JEV pertinence HORS_SUJET et SejourFR A1_NON_ATTEINT sont exclus des taux d'accord et
  listés à part ;
- les textes de production n'apparaissent pas (rapport agrégé).
"""
from __future__ import annotations

import json
from collections import Counter, defaultdict

from . import config, store

ORD = {"A1": 1, "A2": 2, "B1": 3, "B2": 4}
LABELS = ("A1", "A2", "B1", "B2", "INSUFFICIENT")
TASK_SHORT = {"EE_TASK_1": "EE1", "EE_TASK_2": "EE2", "EE_TASK_3": "EE3"}


def _jl(v):
    return json.loads(v) if v else {}


def compare(expected: str | None, got: str | None, alt: str | None = None) -> str:
    """exact / adjacent / majeur / insuff_manque / insuff_a_tort / inconnu."""
    if expected is None or got is None:
        return "inconnu"
    targets = [expected] + ([alt] if alt else [])
    if got in targets:
        return "exact"
    if "INSUFFICIENT" in targets and got not in ORD:
        return "inconnu"
    if expected == "INSUFFICIENT" and not alt:
        return "insuff_manque"
    if got == "INSUFFICIENT":
        return "insuff_a_tort"
    ords = [ORD[t] for t in targets if t in ORD]
    if not ords:
        return "insuff_manque"
    d = min(abs(ORD[got] - o) for o in ords)
    return "adjacent" if d == 1 else "majeur"


def _pct(n, d):
    return "—" if d == 0 else f"{n}/{d} ({100 * n / d:.0f} %)"


def _tally(pairs):
    c = Counter(pairs)
    comparable = sum(c[k] for k in ("exact", "adjacent", "majeur", "insuff_manque", "insuff_a_tort"))
    return c, comparable


def main_run(conn, version: str):
    return conn.execute(
        "SELECT * FROM benchmark_run WHERE mode='real' AND prompt_version=? AND COALESCE(notes,'') NOT LIKE 'test%' "
        "ORDER BY created_at DESC LIMIT 1", (version,)).fetchone()


def load(conn, version: str) -> dict:
    run = main_run(conn, version)
    samples = {s["sample_id"]: s for s in store.samples(conn)}
    sej = {}
    for r in conn.execute("SELECT * FROM sejourfr_result ORDER BY id"):
        sej[r["sample_id"]] = dict(r)
    jev = defaultdict(dict)
    if run:
        for r in conn.execute("SELECT * FROM jev_result WHERE run_id=? AND error IS NULL ORDER BY id", (run["run_id"],)):
            if r["sample_id"] in samples:
                jev[r["sample_id"]][r["repeat_index"]] = dict(r)
    return {"run": dict(run) if run else None, "samples": samples, "sej": sej, "jev": jev}


def analyse(conn, version: str) -> dict:
    d = load(conn, version)
    samples, sej, jev, run = d["samples"], d["sej"], d["jev"], d["run"]
    out: dict = {"version": version, "run_id": run["run_id"] if run else None,
                 "questions_hash": run["questions_hash"] if run else None, "n_samples": len(samples)}
    if not run:
        return out
    reps = sorted({r for v in jev.values() for r in v})
    out["repetitions"] = reps
    rows = conn.execute("SELECT COUNT(*), SUM(input_tokens), SUM(output_tokens), SUM(cost_usd), "
                        "SUM(error IS NOT NULL), GROUP_CONCAT(DISTINCT model_returned) FROM jev_result WHERE run_id=?",
                        (run["run_id"],)).fetchone()
    out["appels"] = {"requetes": rows[0], "input_tokens": rows[1], "output_tokens": rows[2],
                     "cout_usd": round(rows[3] or 0, 6), "erreurs": rows[4], "modeles": rows[5]}

    hors_sujet = sorted({sid for sid, v in jev.items() for r in v.values() if r["pertinence_choice"] == "HORS_SUJET"})
    out["hors_sujet"] = hors_sujet
    out["pertinence"] = {r: dict(Counter(v[r]["pertinence_choice"] for v in jev.values() if r in v)) for r in reps}

    # --- JEV vs visé (strict / souple), par répétition et par tâche
    vise = {}
    for r in reps:
        strict, souple = [], []
        per_task = defaultdict(lambda: {"strict": [], "souple": []})
        for sid, s in samples.items():
            j = jev.get(sid, {}).get(r)
            got = j["niveau_global_choice"] if j else None
            if sid in hors_sujet:
                continue
            a = compare(s["niveau_vise_code"], got)
            b = compare(s["niveau_vise_code"], got, s["niveau_vise_alternatif"])
            strict.append(a)
            souple.append(b)
            per_task[TASK_SHORT[s["task_type"]]]["strict"].append(a)
            per_task[TASK_SHORT[s["task_type"]]]["souple"].append(b)
        vise[r] = {"strict": _tally(strict), "souple": _tally(souple),
                   "par_tache": {t: {"strict": _tally(v["strict"]), "souple": _tally(v["souple"])}
                                 for t, v in sorted(per_task.items())}}
    out["jev_vs_vise"] = vise

    # --- matrice de confusion visé (principal) × JEV, deux répétitions cumulées
    mat = defaultdict(Counter)
    for sid, s in samples.items():
        for r in reps:
            j = jev.get(sid, {}).get(r)
            if j and s["niveau_vise_code"]:
                mat[s["niveau_vise_code"]][j["niveau_global_choice"]] += 1
    out["confusion"] = {k: dict(v) for k, v in mat.items()}

    # --- stabilité
    same = n = 0
    dprob, dconf = [], []
    for sid, v in jev.items():
        if 1 in v and 2 in v:
            n += 1
            a, b = v[1], v[2]
            same += a["niveau_global_choice"] == b["niveau_global_choice"]
            pa, pb = _jl(a["niveau_global_probs"]), _jl(b["niveau_global_probs"])
            keys = set(pa) | set(pb)
            dprob.append(sum(abs(pa.get(k, 0) - pb.get(k, 0)) for k in keys) / max(len(keys), 1))
            dconf.append(abs((a["niveau_global_confidence"] or 0) - (b["niveau_global_confidence"] or 0)))
    out["stabilite"] = {"paires": n, "label_identique": same,
                        "variation_moyenne_probabilites": round(sum(dprob) / len(dprob), 4) if dprob else None,
                        "variation_max_probabilites": round(max(dprob), 4) if dprob else None,
                        "variation_moyenne_confiance": round(sum(dconf) / len(dconf), 4) if dconf else None,
                        "variation_max_confiance": round(max(dconf), 4) if dconf else None,
                        "instables": sorted(sid for sid, v in jev.items() if 1 in v and 2 in v
                                            and v[1]["niveau_global_choice"] != v[2]["niveau_global_choice"])}

    # --- SejourFR vs JEV (comparables) et SejourFR vs visé
    sj = {}
    for r in reps:
        pairs, per_task = [], defaultdict(list)
        for sid, s in samples.items():
            x = sej.get(sid)
            if not x or x["status"] != "EVALUATED" or x["niveau_cecrl"] not in ORD or sid in hors_sujet:
                continue
            j = jev.get(sid, {}).get(r)
            c = compare(x["niveau_cecrl"], j["niveau_global_choice"] if j else None)
            pairs.append(c)
            per_task[TASK_SHORT[s["task_type"]]].append(c)
        sj[r] = {"global": _tally(pairs), "par_tache": {t: _tally(v) for t, v in sorted(per_task.items())}}
    out["sejourfr_vs_jev"] = sj
    sv = [compare(s["niveau_vise_code"], sej[sid]["niveau_cecrl"], s["niveau_vise_alternatif"])
          for sid, s in samples.items() if sid in sej and sej[sid]["status"] == "EVALUATED"
          and sej[sid]["niveau_cecrl"] in ORD]
    sv_strict = [compare(s["niveau_vise_code"], sej[sid]["niveau_cecrl"])
                 for sid, s in samples.items() if sid in sej and sej[sid]["status"] == "EVALUATED"
                 and sej[sid]["niveau_cecrl"] in ORD]
    out["sejourfr_vs_vise"] = {"strict": _tally(sv_strict), "souple": _tally(sv)}

    # --- désaccords (JEV r1 vs visé strict) avec distributions complètes
    dis = []
    for sid, s in sorted(samples.items()):
        v = jev.get(sid, {})
        if 1 not in v:
            continue
        verdicts = [compare(s["niveau_vise_code"], v[r]["niveau_global_choice"]) for r in reps if r in v]
        if all(x in ("exact", "inconnu") for x in verdicts):
            continue
        dis.append({
            "sample_id": sid, "tache": TASK_SHORT[s["task_type"]], "titre": s["titre"],
            "vise": s["niveau_vise_code"], "vise_alt": s["niveau_vise_alternatif"],
            "sejourfr": (sej.get(sid) or {}).get("niveau_cecrl") if (sej.get(sid) or {}).get("status") == "EVALUATED" else None,
            "jev": {r: {"choix": v[r]["niveau_global_choice"], "confiance": v[r]["niveau_global_confidence"],
                        "probas": _jl(v[r]["niveau_global_probs"]), "pertinence": v[r]["pertinence_choice"]}
                    for r in reps if r in v},
            "verdict_strict": verdicts,
        })
    out["desaccords"] = dis

    # --- secondaire : formule SejourFR vs JEV natif
    sec = {}
    for variant, col in (("argmax_milieu", "secondaire_formule_argmax_niveau"),
                         ("esperance", "secondaire_formule_esperance_niveau")):
        vs_jev, vs_vise, vs_sej = [], [], []
        for sid, s in samples.items():
            j = jev.get(sid, {}).get(1)
            if not j or sid in hors_sujet:
                continue
            f = j[col]
            vs_jev.append(compare(j["niveau_global_choice"], f) if j["niveau_global_choice"] in ORD else "inconnu")
            vs_vise.append(compare(s["niveau_vise_code"], f))
            x = sej.get(sid)
            if x and x["status"] == "EVALUATED" and x["niveau_cecrl"] in ORD:
                vs_sej.append(compare(x["niveau_cecrl"], f))
        sec[variant] = {"vs_jev_natif": _tally(vs_jev), "vs_vise_strict": _tally(vs_vise),
                        "vs_sejourfr": _tally(vs_sej)}
    out["secondaire"] = sec
    out["_jev"] = jev
    return out


def compare_versions(a: dict, b: dict) -> dict:
    ja, jb = a.get("_jev") or {}, b.get("_jev") or {}
    changes, deltas = [], []
    for sid in sorted(set(ja) & set(jb)):
        for r in (1, 2):
            if r in ja[sid] and r in jb[sid]:
                x, y = ja[sid][r]["niveau_global_choice"], jb[sid][r]["niveau_global_choice"]
                if x in ORD and y in ORD:
                    deltas.append(ORD[y] - ORD[x])
        x1 = ja[sid].get(1, {}).get("niveau_global_choice")
        y1 = jb[sid].get(1, {}).get("niveau_global_choice")
        if x1 != y1:
            changes.append({"sample_id": sid, a["version"]: x1, b["version"]: y1})
    crit = {}
    for code in ("communiquer", "interagir", "lexique", "morphosyntaxe"):
        diff = up = down = n = 0
        for sid in set(ja) & set(jb):
            for r in (1, 2):
                if r in ja[sid] and r in jb[sid]:
                    x, y = ja[sid][r][f"{code}_choice"], jb[sid][r][f"{code}_choice"]
                    if x in ORD and y in ORD:
                        n += 1
                        diff += x != y
                        up += ORD[y] > ORD[x]
                        down += ORD[y] < ORD[x]
        crit[code] = {"paires": n, "differents": diff, "plus_haut_v15": up, "plus_bas_v15": down}
    return {"criteres": crit, "changements_r1": changes,
            "paires_ordinales": len(deltas),
            "plus_haut": sum(1 for d in deltas if d > 0), "plus_bas": sum(1 for d in deltas if d < 0),
            "identique": sum(1 for d in deltas if d == 0),
            "ecart_moyen_paliers": round(sum(deltas) / len(deltas), 3) if deltas else None}


def fmt_tally(t):
    c, n = t
    return (f"exact {_pct(c['exact'], n)} · adjacent {c['adjacent']} · majeur {c['majeur']}"
            + (f" · INSUFFICIENT manqué {c['insuff_manque']}" if c["insuff_manque"] else "")
            + (f" · INSUFFICIENT à tort {c['insuff_a_tort']}" if c["insuff_a_tort"] else "")
            + (f" · non comparables {c['inconnu']}" if c["inconnu"] else ""))


def to_markdown(res: dict) -> str:
    L = [f"### `{res['version']}`", ""]
    if not res.get("run_id"):
        return "\n".join(L + ["Aucun run réel.", ""])
    ap = res["appels"]
    L += [f"Run `{res['run_id']}` · hash des questions `{res['questions_hash'][:12]}…` · modèle(s) renvoyé(s) "
          f"`{ap['modeles']}` · {ap['requetes']} requêtes, {ap['erreurs']} erreur(s) · "
          f"{ap['input_tokens']} tokens d'entrée, {ap['output_tokens']} de sortie · **{ap['cout_usd']:.4f} $**", ""]
    L += [f"**Pertinence JEV** : " + " ; ".join(f"r{r} {v}" for r, v in res["pertinence"].items())
          + (f" — HORS_SUJET exclus des taux : {', '.join(res['hors_sujet'])}" if res["hors_sujet"] else ""), ""]
    L += ["**JEV vs niveau visé**", "", "| | strict (niveau principal) | souple (principal ou alternatif) |", "|---|---|---|"]
    for r, v in res["jev_vs_vise"].items():
        L.append(f"| répétition {r} | {fmt_tally(v['strict'])} | {fmt_tally(v['souple'])} |")
    L += ["", "| Tâche | strict r1 | souple r1 | strict r2 | souple r2 |", "|---|---|---|---|---|"]
    tasks = sorted(res["jev_vs_vise"][res["repetitions"][0]]["par_tache"])
    for t in tasks:
        cells = []
        for r in res["repetitions"]:
            pt = res["jev_vs_vise"][r]["par_tache"][t]
            cells += [_pct(pt["strict"][0]["exact"], pt["strict"][1]), _pct(pt["souple"][0]["exact"], pt["souple"][1])]
        L.append(f"| {t} | " + " | ".join(cells) + " |")
    L += ["", "**Matrice de confusion** (visé principal en ligne × JEV en colonne, 2 répétitions cumulées)", "",
          "| visé \\ JEV | " + " | ".join(LABELS) + " |", "|---" * (len(LABELS) + 1) + "|"]
    for v in LABELS:
        row = res["confusion"].get(v, {})
        if row:
            L.append(f"| **{v}** | " + " | ".join(str(row.get(x, 0) or "·") for x in LABELS) + " |")
    st = res["stabilite"]
    L += ["", f"**Stabilité r1 / r2** : label identique {_pct(st['label_identique'], st['paires'])} · "
          f"variation moyenne des probabilités {st['variation_moyenne_probabilites']} (max {st['variation_max_probabilites']}) · "
          f"variation moyenne de confiance {st['variation_moyenne_confiance']} (max {st['variation_max_confiance']})"
          + (f" · instables : {', '.join(st['instables'])}" if st["instables"] else ""), ""]
    L += ["**SejourFR vs JEV** (notés SejourFR, hors A1_NON_ATTEINT et HORS_SUJET)", ""]
    for r, v in res["sejourfr_vs_jev"].items():
        L.append(f"- r{r} : {fmt_tally(v['global'])} — " + " ; ".join(
            f"{t} {_pct(x[0]['exact'], x[1])}" for t, x in v["par_tache"].items()))
    sv = res["sejourfr_vs_vise"]
    L += [f"- rappel SejourFR vs visé : strict {fmt_tally(sv['strict'])} ; souple {fmt_tally(sv['souple'])}", ""]
    L += ["**Désaccords JEV / visé** (strict, au moins une répétition ; distributions complètes du niveau global)", "",
          "| cas | tâche | visé | SejourFR | JEV r1 (conf.) — probas | JEV r2 (conf.) — probas | pertinence r1/r2 |",
          "|---|---|---|---|---|---|---|"]
    for x in res["desaccords"]:
        def cell(r):
            j = x["jev"].get(r)
            if not j:
                return "—"
            pr = " ".join(f"{k} {v:.2f}" for k, v in sorted(j["probas"].items(), key=lambda kv: -kv[1]) if v)
            return f"**{j['choix']}** ({j['confiance']}) — {pr}"
        vise = x["vise"] + (f"/{x['vise_alt']}" if x["vise_alt"] else "")
        pert = "/".join(str(x["jev"][r]["pertinence"]) for r in sorted(x["jev"]))
        L.append(f"| {x['sample_id']} {x['titre']} | {x['tache']} | {vise} | {x['sejourfr'] or '—'} | {cell(1)} | {cell(2)} | {pert} |")
    L += ["", "**Secondaire : niveau via formule SejourFR** (r1, A1=1 · A2=4 · B1=8 · B2=15)", ""]
    for variant, v in res["secondaire"].items():
        L.append(f"- {variant} : vs JEV natif {fmt_tally(v['vs_jev_natif'])} ; vs visé {fmt_tally(v['vs_vise_strict'])} ; "
                 f"vs SejourFR {fmt_tally(v['vs_sejourfr'])}")
    L.append("")
    return "\n".join(L)


def build(conn) -> tuple[dict, str]:
    results = {v: analyse(conn, v) for v in config.PROMPT_VERSIONS}
    cmp_ = compare_versions(results[config.PROMPT_VERSIONS[0]], results[config.PROMPT_VERSIONS[1]])
    total = conn.execute("SELECT COUNT(*), SUM(input_tokens), SUM(output_tokens), SUM(cost_usd) FROM jev_result").fetchone()
    md = [to_markdown(results[v]) for v in config.PROMPT_VERSIONS]
    md.append("### Comparaison `jev-independent-v1` → `jev-v15-aligned-v1`\n")
    md.append(f"- Paires ordinales comparées (cas × répétition) : {cmp_['paires_ordinales']} ; v15-aligned plus haut "
              f"{cmp_['plus_haut']}, plus bas {cmp_['plus_bas']}, identique {cmp_['identique']} ; écart moyen "
              f"{cmp_['ecart_moyen_paliers']} palier.")
    md.append("- ⚠️ La question `niveau_global` est IDENTIQUE dans les deux versions (seules les options des questions "
              "critère diffèrent) : l'identité des niveaux globaux est un contrôle de reproductibilité, pas un résultat "
              "de sensibilité.")
    md.append("- Questions critère (cas × répétition), v15-aligned par rapport à independent : " + " ; ".join(
        f"{k} {v['differents']}/{v['paires']} différents (↑{v['plus_haut_v15']} ↓{v['plus_bas_v15']})"
        for k, v in cmp_["criteres"].items()) + ".")
    md.append("- Cas qui changent de niveau global (r1) : " + (", ".join(
        f"{c['sample_id']} {c[config.PROMPT_VERSIONS[0]]}→{c[config.PROMPT_VERSIONS[1]]}" for c in cmp_["changements_r1"])
        or "aucun") + "\n")
    md.append(f"### Coût réel total (tous appels, test compris)\n\n{total[0]} requêtes · {total[1]} tokens d'entrée · "
              f"{total[2]} tokens de sortie · **{(total[3] or 0):.4f} $**\n")
    for v in results.values():
        v.pop("_jev", None)
    return {"versions": results, "comparaison": cmp_,
            "total": {"requetes": total[0], "input_tokens": total[1], "output_tokens": total[2],
                      "cout_usd": total[3]}}, "\n".join(md)
