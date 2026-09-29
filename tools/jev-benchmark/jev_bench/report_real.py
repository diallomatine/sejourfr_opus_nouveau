"""Rapport du benchmark JEV sur productions RÉELLES anonymisées (origin=REAL), agrégé.

Aucun texte ni extrait de production : les cas sont désignés par leur clé hachée
(md5(sel || id), 12 premiers caractères). La comparaison avec le synthétique est calculée
SÉPARÉMENT, avec les mêmes fonctions, et présentée côte à côte — jamais fusionnée.
"""
from __future__ import annotations

import json
from collections import Counter, defaultdict

from . import config, store

ORD = {"A1": 1, "A2": 2, "B1": 3, "B2": 4}
LEVELS = ("A1", "A2", "B1", "B2")
JEV_LABELS = LEVELS + ("INSUFFICIENT",)
SHORT = {"EE_TASK_1": "EE1", "EE_TASK_2": "EE2", "EE_TASK_3": "EE3"}
CRIT = ("communiquer", "interagir", "lexique", "morphosyntaxe")


def _jl(v):
    return json.loads(v) if v else {}


def _pct(n, d):
    return "—" if not d else f"{n}/{d} ({100 * n / d:.0f} %)"


def weighted_kappa(pairs: list[tuple[str, str]]) -> float | None:
    """Kappa de Cohen pondéré QUADRATIQUE sur A1..B2 (paires ordinales seulement)."""
    pairs = [(a, b) for a, b in pairs if a in ORD and b in ORD]
    n = len(pairs)
    if n == 0:
        return None
    k = len(LEVELS)
    obs = [[0] * k for _ in range(k)]
    for a, b in pairs:
        obs[ORD[a] - 1][ORD[b] - 1] += 1
    rows = [sum(r) for r in obs]
    cols = [sum(obs[i][j] for i in range(k)) for j in range(k)]
    num = den = 0.0
    for i in range(k):
        for j in range(k):
            w = (i - j) ** 2 / (k - 1) ** 2
            num += w * obs[i][j]
            den += w * rows[i] * cols[j] / n
    return None if den == 0 else round(1 - num / den, 3)


def pair_stats(pairs: list[tuple[str, str]]) -> dict:
    """Référence (SejourFR) × JEV : exact / adjacent / majeur, sens, INSUFFICIENT, kappa."""
    c = Counter()
    for ref, got in pairs:
        if got == "INSUFFICIENT":
            c["insufficient"] += 1
        elif ref in ORD and got in ORD:
            d = ORD[got] - ORD[ref]
            c["exact" if d == 0 else "adjacent" if abs(d) == 1 else "majeur"] += 1
            if d > 0:
                c["jev_plus_haut"] += 1
            elif d < 0:
                c["jev_plus_bas"] += 1
        else:
            c["inconnu"] += 1
    n = c["exact"] + c["adjacent"] + c["majeur"]
    return {"n_ordinal": n, **{k: c[k] for k in ("exact", "adjacent", "majeur", "jev_plus_haut", "jev_plus_bas",
                                                    "insufficient", "inconnu")},
            "kappa_quadratique": weighted_kappa(pairs)}


def fmt(st: dict, kappa: bool = True) -> str:
    return (f"exact {_pct(st['exact'], st['n_ordinal'])} · adjacent {st['adjacent']} · majeur {st['majeur']} · "
            f"JEV plus haut {st['jev_plus_haut']} / plus bas {st['jev_plus_bas']}"
            + (f" · JEV INSUFFICIENT {st['insufficient']}" if st["insufficient"] else "")
            + (f" · κ quadratique {st['kappa_quadratique']}" if kappa else ""))


def real_run(conn):
    for r in conn.execute("SELECT * FROM benchmark_run WHERE mode='real' ORDER BY created_at DESC"):
        f = _jl(r["filters_json"])
        if f.get("origin") == "REAL" and not (r["notes"] or "").startswith("test"):
            return dict(r)
    return None


def synthetic_run(conn, version: str):
    for r in conn.execute("SELECT * FROM benchmark_run WHERE mode='real' AND prompt_version=? ORDER BY created_at DESC",
                          (version,)):
        f = _jl(r["filters_json"])
        if f.get("origin", "SYNTHETIC") == "SYNTHETIC" and not (r["notes"] or "").startswith("test"):
            return dict(r)
    return None


def _load(conn, origin: str, run_id: str):
    samples = {s["sample_id"]: s for s in store.samples(conn, origin=origin)}
    sej = {}
    for r in conn.execute("SELECT * FROM sejourfr_result ORDER BY id"):
        if r["sample_id"] in samples:
            sej[r["sample_id"]] = dict(r)
    jev = defaultdict(dict)
    for r in conn.execute("SELECT * FROM jev_result WHERE run_id=? AND error IS NULL ORDER BY id", (run_id,)):
        if r["sample_id"] in samples:
            jev[r["sample_id"]][r["repeat_index"]] = dict(r)
    return samples, sej, jev


def _key(s: dict) -> str:
    k = _jl(s["fixture_json"]).get("sample_key")
    return (k or s["sample_id"])[:12]


def analyse_real(conn) -> dict:
    run = real_run(conn)
    if not run:
        return {}
    samples, sej, jev = _load(conn, "REAL", run["run_id"])
    out = {"run": run}
    agg = conn.execute("SELECT COUNT(*), SUM(input_tokens), SUM(output_tokens), SUM(cost_usd), SUM(error IS NOT NULL), "
                       "GROUP_CONCAT(DISTINCT model_returned) FROM jev_result WHERE run_id=?", (run["run_id"],)).fetchone()
    out["appels"] = {"requetes": agg[0], "input_tokens": agg[1], "output_tokens": agg[2], "cout_usd": agg[3] or 0,
                     "erreurs": agg[4], "modeles": agg[5]}

    cecrl = [sid for sid, s in samples.items() if s["stratum"] == "CECRL"]
    hors_sujet = [sid for sid in cecrl if jev.get(sid, {}).get(1, {}).get("pertinence_choice") == "HORS_SUJET"]
    comp = [sid for sid in cecrl if sid not in hors_sujet and 1 in jev.get(sid, {})]
    out["n_cecrl"], out["hors_sujet"], out["n_comparables"] = len(cecrl), [_key(samples[s]) for s in hors_sujet], len(comp)
    pairs = [(sej[sid]["niveau_cecrl"], jev[sid][1]["niveau_global_choice"]) for sid in comp]
    out["global"] = pair_stats(pairs)
    out["par_tache"] = {t: pair_stats([(sej[s]["niveau_cecrl"], jev[s][1]["niveau_global_choice"]) for s in comp
                                       if SHORT[samples[s]["task_type"]] == t]) for t in ("EE1", "EE2", "EE3")}
    out["par_niveau"] = {lv: pair_stats([(sej[s]["niveau_cecrl"], jev[s][1]["niveau_global_choice"]) for s in comp
                                         if sej[s]["niveau_cecrl"] == lv]) for lv in LEVELS}
    mat = defaultdict(Counter)
    for ref, got in pairs:
        mat[ref][got] += 1
    out["confusion"] = {k: dict(v) for k, v in mat.items()}
    out["pertinence_cecrl"] = dict(Counter(jev[s][1]["pertinence_choice"] for s in cecrl if 1 in jev.get(s, {})))

    def detail(sid):
        s, x, j = samples[sid], sej[sid], jev[sid][1]
        return {
            "cle": _key(s), "tache": SHORT[s["task_type"]], "type": s["attempt_type"], "mots": s["word_count"],
            "sejourfr": x["niveau_cecrl"], "note": x["note_sur_20"],
            "criteres_sejourfr": [x[f"note_{c}"] for c in CRIT],
            "jev": j["niveau_global_choice"], "probas": _jl(j["niveau_global_probs"]),
            "confiance": j["niveau_global_confidence"], "pertinence": j["pertinence_choice"],
            "criteres_jev": [j[f"{c}_choice"] for c in CRIT],
        }
    dis = [detail(s) for s in comp if jev[s][1]["niveau_global_choice"] != sej[s]["niveau_cecrl"]]
    dis.sort(key=lambda d: (d["tache"], d["sejourfr"], d["cle"]))
    out["desaccords"] = dis
    out["tres_confiant_contre"] = [d for d in dis if (d["confiance"] or 0) >= 0.7
                                   or d["probas"].get(d["jev"], 0) >= 0.8]

    iso = {}
    for stratum in ("A1_NON_ATTEINT", "NON_EVALUABLE"):
        ids = [sid for sid, s in samples.items() if s["stratum"] == stratum and 1 in jev.get(sid, {})]
        rows = []
        for sid in sorted(ids, key=lambda x: (samples[x]["task_type"], _key(samples[x]))):
            j = jev[sid][1]
            rows.append({"cle": _key(samples[sid]), "tache": SHORT[samples[sid]["task_type"]],
                         "mots": samples[sid]["word_count"], "note_sejourfr": sej[sid]["note_sur_20"],
                         "jev": j["niveau_global_choice"], "confiance": j["niveau_global_confidence"],
                         "probas": _jl(j["niveau_global_probs"]), "pertinence": j["pertinence_choice"]})
        iso[stratum] = {"n": len(ids), "jev": dict(Counter(r["jev"] for r in rows)),
                        "pertinence": dict(Counter(r["pertinence"] for r in rows)), "cas": rows}
    out["isolees"] = iso

    same = n = 0
    dp, dc = [], []
    for sid, v in jev.items():
        if 1 in v and 2 in v:
            n += 1
            same += v[1]["niveau_global_choice"] == v[2]["niveau_global_choice"]
            pa, pb = _jl(v[1]["niveau_global_probs"]), _jl(v[2]["niveau_global_probs"])
            keys = set(pa) | set(pb)
            dp.append(sum(abs(pa.get(k, 0) - pb.get(k, 0)) for k in keys) / max(len(keys), 1))
            dc.append(abs((v[1]["niveau_global_confidence"] or 0) - (v[2]["niveau_global_confidence"] or 0)))
    instables = []
    for sid, v in jev.items():
        if 1 in v and 2 in v and v[1]["niveau_global_choice"] != v[2]["niveau_global_choice"]:
            instables.append({"cle": _key(samples[sid]), "strate": samples[sid]["stratum"],
                              "sejourfr": sej[sid]["niveau_cecrl"] if sid in sej else None,
                              "r1": v[1]["niveau_global_choice"], "r2": v[2]["niveau_global_choice"],
                              "p1": _jl(v[1]["niveau_global_probs"]), "p2": _jl(v[2]["niveau_global_probs"])})
    out["stabilite"] = {"paires": n, "identiques": same, "instables": instables,
                        "var_proba_moy": round(sum(dp) / len(dp), 4) if dp else None,
                        "var_proba_max": round(max(dp), 4) if dp else None,
                        "var_conf_moy": round(sum(dc) / len(dc), 4) if dc else None,
                        "var_conf_max": round(max(dc), 4) if dc else None}

    sec = {}
    for variant, col in (("argmax_milieu", "secondaire_formule_argmax_niveau"),
                         ("esperance", "secondaire_formule_esperance_niveau")):
        sec[variant] = pair_stats([(sej[s]["niveau_cecrl"], jev[s][1][col]) for s in comp])
    out["secondaire"] = sec
    return out


def analyse_synthetic(conn, version: str = config.PROMPT_VERSION) -> dict:
    run = synthetic_run(conn, version)
    if not run:
        return {}
    samples, sej, jev = _load(conn, "SYNTHETIC", run["run_id"])
    comp = [sid for sid in samples if sid in sej and sej[sid]["status"] == "EVALUATED"
            and sej[sid]["niveau_cecrl"] in ORD and 1 in jev.get(sid, {})
            and jev[sid][1]["pertinence_choice"] != "HORS_SUJET"]
    pairs = [(sej[s]["niveau_cecrl"], jev[s][1]["niveau_global_choice"]) for s in comp]
    return {"run_id": run["run_id"], "global": pair_stats(pairs),
            "par_tache": {t: pair_stats([(sej[s]["niveau_cecrl"], jev[s][1]["niveau_global_choice"]) for s in comp
                                         if SHORT[samples[s]["task_type"]] == t]) for t in ("EE1", "EE2", "EE3")}}


def to_markdown(res: dict, syn: dict) -> str:
    L = []
    run, ap = res["run"], res["appels"]
    L += [f"Run `{run['run_id']}` · prompt `{run['prompt_version']}` (hash `{run['questions_hash'][:12]}…`) · modèle "
          f"demandé `{run['model_requested']}`, renvoyé `{ap['modeles']}` · {ap['requetes']} requêtes, "
          f"{ap['erreurs']} erreur(s) · {ap['input_tokens']} tokens d'entrée, {ap['output_tokens']} de sortie · "
          f"**{ap['cout_usd']:.4f} $**", ""]
    L += ["## 1. JEV vs SejourFR — strate CECRL", "",
          f"{res['n_cecrl']} productions CECRL ; JEV HORS_SUJET : {len(res['hors_sujet'])}"
          + (f" ({', '.join(res['hors_sujet'])})" if res["hors_sujet"] else "") + f" ; comparables : {res['n_comparables']}.",
          f"Pertinence JEV sur la strate : {res['pertinence_cecrl']}.", "",
          f"**Global** : {fmt(res['global'])}", ""]
    L += ["## 2. Par tâche", "", "| Tâche | Résultat |", "|---|---|"]
    L += [f"| {t} | {fmt(v)} |" for t, v in res["par_tache"].items()]
    L += ["", "## 3. Par niveau SejourFR et matrice de confusion", "", "| SejourFR | Résultat |", "|---|---|"]
    L += [f"| {lv} | {fmt(v, kappa=False)} |" for lv, v in res["par_niveau"].items() if v["n_ordinal"] or v["insufficient"]]
    L += ["", "(Pas de kappa par niveau : la référence n'y a qu'une seule classe.)"]
    L += ["", "SejourFR en ligne × JEV en colonne (répétition 1) :", "",
          "| SejourFR \\ JEV | " + " | ".join(JEV_LABELS) + " |", "|---" * (len(JEV_LABELS) + 1) + "|"]
    for lv in LEVELS:
        row = res["confusion"].get(lv, {})
        if row:
            L.append(f"| **{lv}** | " + " | ".join(str(row.get(x, 0) or "·") for x in JEV_LABELS) + " |")
    L += ["", f"## 4. Désaccords ({len(res['desaccords'])})", "",
          "Critères dans l'ordre communiquer / interagir / lexique / morphosyntaxe.", "",
          "| clé | tâche | type | mots | SejourFR (note ; critères) | JEV (conf.) | distribution JEV | pertinence | critères JEV |",
          "|---|---|---|---|---|---|---|---|---|"]
    for d in res["desaccords"]:
        dist = " ".join(f"{k} {d['probas'].get(k, 0):.2f}" for k in JEV_LABELS)
        crit = "/".join("—" if v is None else f"{v:g}" for v in d["criteres_sejourfr"])
        L.append(f"| `{d['cle']}` | {d['tache']} | {d['type']} | {d['mots']} | {d['sejourfr']} ({d['note']} ; {crit}) | "
                 f"**{d['jev']}** ({d['confiance']}) | {dist} | {d['pertinence']} | {'/'.join(d['criteres_jev'])} |")
    L += ["", f"## 5. JEV très confiant contre SejourFR (confiance ≥ 0,7 ou proba du choix ≥ 0,8) : "
          f"{len(res['tres_confiant_contre'])}", ""]
    L += [f"- `{d['cle']}` {d['tache']} : SejourFR {d['sejourfr']} ({d['note']}) → JEV **{d['jev']}** "
          f"(conf. {d['confiance']}, p = {d['probas'].get(d['jev'], 0):.2f})" for d in res["tres_confiant_contre"]] or ["- aucun"]
    L += ["", "## 6. Strates isolées (jamais mêlées aux statistiques CECRL)", ""]
    for stratum, v in res["isolees"].items():
        L += [f"**{stratum}** ({v['n']}) — JEV : {v['jev']} ; pertinence : {v['pertinence']}", "",
              "| clé | tâche | mots | note SejourFR | JEV (conf.) | distribution | pertinence |", "|---|---|---|---|---|---|---|"]
        for r in v["cas"]:
            dist = " ".join(f"{k} {r['probas'].get(k, 0):.2f}" for k in JEV_LABELS)
            L.append(f"| `{r['cle']}` | {r['tache']} | {r['mots']} | {r['note_sejourfr']} | **{r['jev']}** "
                     f"({r['confiance']}) | {dist} | {r['pertinence']} |")
        L.append("")
    st = res["stabilite"]
    L += ["## 7. Stabilité (sous-ensemble répété)", "",
          f"Niveau identique {_pct(st['identiques'], st['paires'])} · variation moyenne des probabilités "
          f"{st['var_proba_moy']} (max {st['var_proba_max']}) · variation moyenne de confiance {st['var_conf_moy']} "
          f"(max {st['var_conf_max']}).", ""]
    for x in st["instables"]:
        top = lambda p: " ".join(f"{k} {v:.2f}" for k, v in sorted(p.items(), key=lambda kv: -kv[1])[:2])
        L.append(f"- instable `{x['cle']}` ({x['strate']}, SejourFR {x['sejourfr']}) : r1 **{x['r1']}** ({top(x['p1'])}) "
                 f"/ r2 **{x['r2']}** ({top(x['p2'])})")
    L.append("")
    L += ["## 8. Coût et secondaire", "",
          f"Coût réel {ap['cout_usd']:.4f} $ · {ap['input_tokens']} tokens d'entrée · {ap['output_tokens']} de sortie.", "",
          "Secondaire — niveau via formule SejourFR (A1=1 · A2=4 · B1=8 · B2=15) appliquée aux 4 critères JEV, "
          "comparé au niveau SejourFR :", ""]
    L += [f"- {k} : {fmt(v)}" for k, v in res["secondaire"].items()]
    L += ["", "## 9. Rappel du benchmark synthétique (calculé séparément, mêmes métriques)", ""]
    if syn:
        L += [f"Run `{syn['run_id']}` (`jev-independent-v1`, 28 comparables) : {fmt(syn['global'])}", ""]
        L += [f"- {t} : {fmt(v)}" for t, v in syn["par_tache"].items()]
    L.append("")
    return "\n".join(L)


def build(conn) -> tuple[dict, str]:
    res = analyse_real(conn)
    syn = analyse_synthetic(conn)
    return {"reel": res, "synthetique": syn}, to_markdown(res, syn) if res else "Aucun run réel sur origin=REAL."
