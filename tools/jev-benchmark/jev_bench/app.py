"""Interface locale du benchmark (Streamlit). Lecture SQLite SEULE.

Règles d'affichage :
- null = inconnu, jamais un désaccord ;
- SejourFR A1_NON_ATTEINT et JEV pertinence HORS_SUJET sont EXCLUS du taux
  d'accord principal et montrés à part (différence de construction attendue) ;
- les cas non notés par SejourFR (hors bornes, erreur, absents) sont exclus, avec compteur.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import pandas as pd
import streamlit as st

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from jev_bench import config  # noqa: E402

ORDER = {"A1": 1, "A2": 2, "B1": 3, "B2": 4}
CRITERES = ("communiquer", "interagir", "lexique", "morphosyntaxe")
SEC_A = "secondaire : niveau via formule SejourFR (a) argmax"
SEC_A_NOTE = "secondaire : note /20 (a)"
SEC_B = "secondaire : niveau via formule SejourFR (b) espérance"
SEC_B_NOTE = "secondaire : note /20 (b)"
SECONDAIRE = [SEC_A, SEC_A_NOTE, SEC_B, SEC_B_NOTE]

st.set_page_config(page_title="Benchmark JEV", layout="wide")


@st.cache_data(ttl=5)
def load() -> dict:
    import sqlite3
    if not config.DB_FILE.exists():
        return {}
    conn = sqlite3.connect(f"file:{config.DB_FILE}?mode=ro", uri=True)
    try:
        return {t: pd.read_sql_query(f"SELECT * FROM {t}", conn)
                for t in ("sample", "benchmark_run", "jev_result", "sejourfr_result")}
    finally:
        conn.close()


def jl(v):
    if v is None or (isinstance(v, float) and pd.isna(v)):
        return None
    try:
        return json.loads(v)
    except (TypeError, ValueError):
        return None


def ecart(a, b) -> str:
    """✓ identique, ~ adjacent, ! écart ≥ 2 paliers, ? inconnu / non comparable."""
    if a not in ORDER or b not in ORDER:
        return "?"
    d = abs(ORDER[a] - ORDER[b])
    return "✓" if d == 0 else ("~" if d == 1 else "!")


def second(probs_json) -> str | None:
    p = jl(probs_json) or {}
    ranked = sorted(p.items(), key=lambda kv: kv[1], reverse=True)
    if len(ranked) < 2:
        return None
    return f"{ranked[1][0]} ({ranked[1][1]:.0%})"


def rate(num, den) -> str:
    return "—" if den == 0 else f"{num}/{den} ({num / den:.0%})"


data = load()
st.title("Benchmark JEV × correcteur SejourFR — expression écrite")
if not data:
    st.warning(f"Base absente : {config.DB_FILE}. Lancer `python -m jev_bench import-fixtures`.")
    st.stop()

origin_sel = st.radio("Origine des productions (réel et synthétique ne sont JAMAIS mélangés)",
                      ["SYNTHETIC", "REAL"], horizontal=True)
all_samples = data["sample"]
if "origin" in all_samples:
    all_samples = all_samples[all_samples["origin"] == origin_sel]
samples = all_samples[all_samples["status"] == "ACTIVE"] if "status" in all_samples else all_samples
if samples.empty:
    st.info(f"Aucun échantillon d'origine {origin_sel}.")
    st.stop()
runs = data["benchmark_run"]
jev = data["jev_result"]
sej = data["sejourfr_result"]

# ------------------------------------------------------------------ version de prompt (jamais mélangées)
VERSION_LABELS = {
    config.PROMPT_VERSION: f"{config.PROMPT_VERSION} — PRINCIPAL (critères de la spec)",
    config.PROMPT_VERSION_V15: f"{config.PROMPT_VERSION_V15} — sensibilité (descripteurs v15)",
}
version_sel = st.radio("Version de prompt (les deux benchmarks ne sont jamais mélangés)",
                       list(config.PROMPT_VERSIONS), format_func=VERSION_LABELS.get, horizontal=True)

# ------------------------------------------------------------------ filtres
st.sidebar.header("Filtres")
tasks = sorted(samples["task_type"].unique())
task_sel = st.sidebar.multiselect("Tâche", tasks, default=tasks)
show_tests = st.sidebar.checkbox("Inclure les runs de test", value=False)
real_runs = runs[(runs["mode"] == "real") & (runs["prompt_version"] == version_sel)]
if not show_tests:
    real_runs = real_runs[~real_runs["notes"].fillna("").str.startswith("test")]
real_runs = real_runs.sort_values("created_at", ascending=False)
run_ids = list(real_runs["run_id"])
run_sel = st.sidebar.selectbox("Run JEV", run_ids if run_ids else ["(aucun run réel)"], key=f"run_{version_sel}")
jev_run = jev[(jev["run_id"] == run_sel) & (jev["prompt_version"] == version_sel)] if run_ids else jev.iloc[0:0]
repeats = sorted(jev_run["repeat_index"].unique()) if not jev_run.empty else [1]
rep_sel = st.sidebar.selectbox("Répétition", repeats, key=f"rep_{version_sel}")
low_conf = st.sidebar.slider("Seuil de faible confiance JEV", 0.0, 1.0, 0.5, 0.05)
only_disagree = st.sidebar.checkbox("Désaccords SejourFR / JEV seulement")
only_low = st.sidebar.checkbox("Confiance faible seulement")
retired = len(all_samples) - len(samples)
st.caption(f"Origine : **{origin_sel}** · version affichée : **{version_sel}** · run {run_sel} · {len(samples)} cas actifs"
           + (f" ({retired} retiré(s), conservé(s) pour trace, exclu(s))" if retired else ""))

if not run_ids:
    st.info(f"Aucun run JEV réel pour la version {version_sel} : les colonnes JEV sont vides. "
            f"{len(runs[runs['mode'] == 'dry'])} dry-run(s) enregistré(s).")

# Dernier résultat SejourFR par échantillon.
sej_last = sej.sort_values("id").groupby("sample_id").tail(1).set_index("sample_id") if not sej.empty else pd.DataFrame()
jr = jev_run[(jev_run["repeat_index"] == rep_sel)].sort_values("id").groupby("sample_id").tail(1).set_index("sample_id") \
    if not jev_run.empty else pd.DataFrame()

rows = []
for _, s in samples[samples["task_type"].isin(task_sel)].iterrows():
    sid = s["sample_id"]
    sr = sej_last.loc[sid] if sid in sej_last.index else None
    j = jr.loc[sid] if sid in jr.index else None
    sej_status = None if sr is None else sr["status"]
    sej_niv = None if sr is None else sr["niveau_cecrl"]
    jev_niv = None if j is None or pd.isna(j["niveau_global_choice"]) else j["niveau_global_choice"]
    pert = None if j is None or pd.isna(j["pertinence_choice"]) else j["pertinence_choice"]
    conf = None if j is None or pd.isna(j["niveau_global_confidence"]) else float(j["niveau_global_confidence"])
    rows.append({
        "sample_id": sid, "tâche": s["task_type"], "cas": s["titre"], "mots": s["word_count"],
        "niveau visé": s["niveau_vise_code"], "visé alt.": s["niveau_vise_alternatif"],
        "statut SejourFR": sej_status, "SejourFR": sej_niv,
        "note SejourFR": None if sr is None else sr["note_sur_20"],
        "JEV global": jev_niv, "confiance": conf,
        "2e niveau": None if j is None else second(j["niveau_global_probs"]),
        SEC_A: None if j is None else j["secondaire_formule_argmax_niveau"],
        SEC_A_NOTE: None if j is None else j["secondaire_formule_argmax_note"],
        SEC_B: None if j is None else j["secondaire_formule_esperance_niveau"],
        SEC_B_NOTE: None if j is None else j["secondaire_formule_esperance_note"],
        "pertinence": pert,
        "écart": ecart(sej_niv, jev_niv),
    })
df = pd.DataFrame(rows)

# ------------------------------------------------------------------ populations
notee = df["statut SejourFR"] == "EVALUATED"
non_notes = df[~notee]
a1na = df[df["SejourFR"] == "A1_NON_ATTEINT"]
hors_sujet = df[df["pertinence"] == "HORS_SUJET"]
principal = df[notee & (df["SejourFR"] != "A1_NON_ATTEINT") & (df["pertinence"] != "HORS_SUJET")]

comp_sj = principal[principal["SejourFR"].isin(ORDER) & principal["JEV global"].isin(ORDER)]
exact_sj = int((comp_sj["écart"] == "✓").sum())
adj_sj = int((comp_sj["écart"] == "~").sum())
maj_sj = int((comp_sj["écart"] == "!").sum())

base_jev = df[(df["pertinence"] != "HORS_SUJET") & df["JEV global"].notna() & df["niveau visé"].notna()]
exact_jev_vise = int((base_jev["JEV global"] == base_jev["niveau visé"]).sum())
base_sej = df[notee & (df["SejourFR"] != "A1_NON_ATTEINT") & df["SejourFR"].notna() & df["niveau visé"].notna()]
exact_sej_vise = int((base_sej["SejourFR"] == base_sej["niveau visé"]).sum())
faible = int((df["confiance"].notna() & (df["confiance"] < low_conf)).sum())

c = st.columns(6)
c[0].metric("Cas", len(df))
c[1].metric("Accord exact SejourFR / JEV", rate(exact_sj, len(comp_sj)))
c[2].metric("JEV / niveau visé", rate(exact_jev_vise, len(base_jev)))
c[3].metric("SejourFR / niveau visé", rate(exact_sej_vise, len(base_sej)))
c[4].metric("Écart adjacent / majeur", f"{adj_sj} / {maj_sj}")
c[5].metric(f"Confiance JEV < {low_conf:.0%}", faible)
st.caption(
    f"Population principale : {len(principal)} cas notés par SejourFR, hors A1_NON_ATTEINT et hors JEV HORS_SUJET. "
    f"Exclus : {len(non_notes)} non notés par SejourFR (hors bornes, erreur, absents), {len(a1na)} A1_NON_ATTEINT, "
    f"{len(hors_sujet)} HORS_SUJET JEV. Une valeur absente est inconnue, jamais un désaccord ; "
    "INSUFFICIENT n'est pas comparé à une échelle de niveau (« ? »).")

with st.expander(f"Cas exclus du taux principal ({len(a1na)} A1_NON_ATTEINT, {len(hors_sujet)} HORS_SUJET, "
                 f"{len(non_notes)} non notés)"):
    st.markdown("**SejourFR = A1_NON_ATTEINT** (verdict « note 0 », souvent hors-sujet — ni A1 ni INSUFFICIENT)")
    st.dataframe(a1na, hide_index=True, width="stretch")
    st.markdown("**JEV pertinence = HORS_SUJET** (JEV sépare niveau et pertinence ; SejourFR les mêle)")
    st.dataframe(hors_sujet, hide_index=True, width="stretch")
    st.markdown("**Non notés par SejourFR**")
    st.dataframe(non_notes[["sample_id", "tâche", "cas", "mots", "statut SejourFR"]], hide_index=True,
                 width="stretch")

# ------------------------------------------------------------------ tableau principal
view = df
if only_disagree:
    view = view[view["écart"].isin(["~", "!"])]
if only_low:
    view = view[view["confiance"].notna() & (view["confiance"] < low_conf)]
st.subheader("Tableau principal — niveau JEV global")
st.dataframe(
    view.drop(columns=SECONDAIRE), hide_index=True, width="stretch",
    column_config={"confiance": st.column_config.NumberColumn(format="%.2f")})

# ------------------------------------------------------------------ secondaire
st.subheader("Secondaire : niveau via formule SejourFR")
st.caption("Résultat SECONDAIRE, jamais le verdict JEV : les 4 réponses critère de JEV converties au milieu de "
           "leur bande dans la formule serveur (A1=1, A2=4, B1=8, B2=15 ; bornes lues dans v15 et le "
           "tool-schema v9), puis passées dans couplage → note → niveau → plafond, comme côté serveur.")
st.dataframe(view[["sample_id", "cas", "SejourFR", "JEV global"] + SECONDAIRE], hide_index=True, width="stretch")

# ------------------------------------------------------------------ vue par critère
st.subheader("Par critère (grille v15) : note SejourFR /20 vs niveau JEV")
crit_rows = []
for _, r in view.iterrows():
    sid = r["sample_id"]
    sr = sej_last.loc[sid] if sid in sej_last.index else None
    j = jr.loc[sid] if sid in jr.index else None
    line = {"sample_id": sid, "cas": r["cas"]}
    for code in CRITERES:
        line[f"{code} SejourFR"] = None if sr is None else sr[f"note_{code}"]
        choice = None if j is None else j[f"{code}_choice"]
        probs = {} if j is None else (jl(j[f"{code}_probs"]) or {})
        line[f"{code} JEV"] = None if choice is None or pd.isna(choice) else \
            f"{choice} ({probs.get(choice, float('nan')):.0%})"
    crit_rows.append(line)
st.dataframe(pd.DataFrame(crit_rows), hide_index=True, width="stretch")

# ------------------------------------------------------------------ stabilité
if not jev_run.empty and jev_run["repeat_index"].nunique() > 1:
    st.subheader("Stabilité entre répétitions (run sélectionné)")
    stab = []
    for sid, g in jev_run.groupby("sample_id"):
        g = g.sort_values("repeat_index")
        choices = list(g["niveau_global_choice"])
        confs = [x for x in g["niveau_global_confidence"] if pd.notna(x)]
        stab.append({"sample_id": sid, "choix par répétition": " / ".join(str(x) for x in choices),
                     "stable": len({x for x in choices if pd.notna(x)}) <= 1,
                     "écart de confiance": (max(confs) - min(confs)) if confs else None})
    sdf = pd.DataFrame(stab)
    st.metric("Échantillons stables", rate(int(sdf["stable"].sum()), len(sdf)))
    st.dataframe(sdf, hide_index=True, width="stretch")

# ------------------------------------------------------------------ détail
st.subheader("Détail d'un cas")
sid = st.selectbox("Échantillon", list(df["sample_id"]),
                   format_func=lambda x: f"{x} — {df.set_index('sample_id').loc[x, 'cas']}")
s = samples.set_index("sample_id").loc[sid]
left, right = st.columns(2)
with left:
    st.markdown(f"**Tâche** {s['task_type']} ({s['task_type_source']}) · **{s['word_count']} mots** "
                f"(bornes {s['official_min']}–{s['official_max']}, "
                f"{'conforme' if s['official_length_compliant'] else 'hors bornes'})")
    st.markdown("**Consigne**")
    st.write(s["consigne"])
    if isinstance(s["contexte"], str) and s["contexte"]:
        st.caption(f"Contexte : {s['contexte']}")
    st.markdown("**Production**")
    st.text(s["production"])
    st.markdown(f"**Niveau visé** : {s['niveau_vise_code']} (alt. {s['niveau_vise_alternatif']}, "
                f"{s['niveau_vise_source']}) — « {s['niveau_vise']} »")
with right:
    pg = jl(s["playground_json"]) or {}
    st.markdown("**Résultat Playground d'origine**")
    for res in (pg.get("autres") or []) + ([pg["playground"]] if pg.get("playground") else []):
        st.write(f"{res['question_version']} → **{res['choice']}**, confiance {res['confidence']:.0%}")
        st.dataframe(pd.DataFrame([res["probabilities"]]), hide_index=True)
    st.markdown("**SejourFR**")
    if sid in sej_last.index:
        sr = sej_last.loc[sid]
        st.write({k: (None if pd.isna(sr[k]) else sr[k]) for k in (
            "status", "niveau_cecrl", "niveau_cecrl_ia", "note_sur_20", "confiance", "plafond_niveau",
            "evaluabilite", "rubrics_version", "prompt_version", "modele_utilise", "error")})
    else:
        st.write("non noté")
    st.markdown("**JEV — distributions complètes**")
    if sid in jr.index:
        j = jr.loc[sid]
        st.caption(f"modèle renvoyé {j['model_returned']} · run {run_sel} · répétition {rep_sel} · "
                   f"{j['input_tokens']} tokens · {j['cost_usd']} $")
        for col in ("niveau_global", "pertinence") + CRITERES:
            probs = jl(j[f"{col}_probs"]) or {}
            st.write(f"{col} → **{j[f'{col}_choice']}** (confiance {j[f'{col}_confidence']})")
            if probs:
                st.dataframe(pd.DataFrame([probs]), hide_index=True)
        st.markdown("**Secondaire : niveau via formule SejourFR**")
        for prefix, label in (("secondaire_formule_argmax", "(a) argmax_milieu"),
                              ("secondaire_formule_esperance", "(b) espérance")):
            st.write(f"{label} → **{j[f'{prefix}_niveau']}** ({j[f'{prefix}_note']}/20)")
        if isinstance(j["error"], str):
            st.error(j["error"])
    else:
        st.write("aucun résultat JEV pour ce run / cette répétition")
