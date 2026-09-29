"""Vérifications de cohérence (sans framework de test) : formule, comptage, prompts, state.

Cas attendus calculés À LA MAIN en suivant le code Java (voir formule.py) :
ordre couplage → note → niveau → plafond, arrondis HALF_UP / DOWN, bornes ≥ / >.
Option ``--db`` : recalcule le niveau des évaluations v15 de la base LOCALE
(lecture seule) et le compare à ``ai_evaluations.niveau_cecrl``.
"""
from __future__ import annotations

import json
import subprocess

from . import config, formule, prompts
from .length import count_words

# (libellé, tâche, notes brutes, note attendue, niveau attendu, plafond attendu, notes couplées attendues)
CASES = [
    ("couplage : langue A2, réalisation B2 ramenée à 4,5", 2,
     {"communiquer": 11.5, "interagir": 11.5, "lexique": 3.5, "morphosyntaxe": 3.5},
     4.0, "A2", False, {"communiquer": 4.5, "interagir": 4.5}),
    ("T3 communiquer=1 : 5,875 → note 5,9 ; A2 déjà ≤ plafond, pas de trace", 3,
     {"communiquer": 1, "interagir": 7.5, "lexique": 7.5, "morphosyntaxe": 7.5},
     5.9, "A2", False, None),
    ("T3 communiquer=1, reste B2 : B1 (8,875) plafonné A2", 3,
     {"communiquer": 1, "interagir": 11.5, "lexique": 11.5, "morphosyntaxe": 11.5},
     8.9, "A2", True, None),
    ("même notes en T2 : pas de plafond → B1", 2,
     {"communiquer": 1, "interagir": 11.5, "lexique": 11.5, "morphosyntaxe": 11.5},
     8.9, "B1", False, None),
    ("tout B2 → 11,5 B2", 1,
     {"communiquer": 11.5, "interagir": 11.5, "lexique": 11.5, "morphosyntaxe": 11.5},
     11.5, "B2", False, None),
    ("tout A1 → 1,0 A1", 2,
     {"communiquer": 1, "interagir": 1, "lexique": 1, "morphosyntaxe": 1},
     1.0, "A1", False, None),
    ("borne B1 incluse (≥ 6)", 2,
     {"communiquer": 6, "interagir": 6, "lexique": 6, "morphosyntaxe": 6}, 6.0, "B1", False, None),
    ("borne A2 incluse (≥ 2)", 2,
     {"communiquer": 2, "interagir": 2, "lexique": 2, "morphosyntaxe": 2}, 2.0, "A2", False, None),
    ("sous 2 mais > 0 → A1", 2,
     {"communiquer": 1.9, "interagir": 1.9, "lexique": 1.9, "morphosyntaxe": 1.9}, 1.9, "A1", False, None),
    ("couplage tronqué DOWN : 4,525 → 4,5", 2,
     {"communiquer": 7.5, "interagir": 3.5, "lexique": 3.55, "morphosyntaxe": 3.5},
     3.8, "A2", False, {"communiquer": 4.5, "interagir": 3.5}),
    ("note HALF_UP : 4,25 → 4,3", 2,
     {"communiquer": 4, "interagir": 4, "lexique": 4.5, "morphosyntaxe": 4.5}, 4.3, "A2", False, None),
    ("note 0 → A1_NON_ATTEINT", 2,
     {"communiquer": 0, "interagir": 0, "lexique": 0, "morphosyntaxe": 0}, 0.0, "A1_NON_ATTEINT", False, None),
]


def _ans(choice, probs):
    return {"choice": choice, "probabilities": probs, "confidence": 0.5}


VARIANT_CASES = [
    # (libellé, tâche, réponses, variante, note attendue, niveau attendu)
    ("espérance : langue 6 → réalisation ramenée à 7 → (7+7+6+6)/4 = 6,5 B1", 2, {
        "critere_communiquer": _ans("B1", {"B1": 1.0}),
        "critere_interagir": _ans("B2", {"B2": 1.0}),
        "critere_lexique": _ans("A2", {"A2": 0.5, "B1": 0.5}),
        "critere_morphosyntaxe": _ans("A2", {"A2": 0.5, "B1": 0.5}),
    }, "esperance", 6.5, "B1"),
    ("argmax : langue 4 → réalisation ramenée à 5 → 4,5 A2", 2, {
        "critere_communiquer": _ans("B1", {"B1": 1.0}),
        "critere_interagir": _ans("B2", {"B2": 1.0}),
        "critere_lexique": _ans("A2", {"A2": 0.5, "B1": 0.5}),
        "critere_morphosyntaxe": _ans("A2", {"A2": 0.5, "B1": 0.5}),
    }, "argmax_milieu", 4.5, "A2"),
    ("espérance renormalisée ({A2:.3, B1:.3} → 6 partout, borne B1 incluse)", 1, {
        f"critere_{c}": _ans("A2", {"A2": 0.3, "B1": 0.3})
        for c in ("communiquer", "interagir", "lexique", "morphosyntaxe")
    }, "esperance", 6.0, "B1"),
]

WORD_CASES = [
    ("  Bonjour   Marie,\n\nça va ?  ", 5),  # « ? » isolé compte comme un mot
    ("mot insécable collé", 2),  # NBSP : pas un séparateur en Java
    ("", 0),
    ("un", 1),
]


def run_selfcheck(with_db: bool = False) -> int:
    failures = 0

    def check(label, ok, detail=""):
        nonlocal failures
        print(f"  [{'OK' if ok else 'ÉCHEC'}] {label}{'' if ok else ' — ' + detail}")
        if not ok:
            failures += 1

    print("Formule SejourFR (cas calculés à la main depuis le code Java)")
    for label, tn, notes, note, niveau, plafond, coupled in CASES:
        r = formule.pipeline(notes, tn)
        ok = r["note_sur_20"] == note and r["niveau"] == niveau and r["plafond_applique"] == plafond
        if coupled:
            ok = ok and all(r["notes_couplees"][k] == v for k, v in coupled.items())
        check(label, ok, json.dumps(r, ensure_ascii=False))

    print("Conversion des réponses JEV (secondaire, deux variantes)")
    mids = {k: float(v) for k, v in formule.band_midpoints().items()}
    check("milieux lus dans le code : A1=1, A2=4, B1=8, B2=15",
          mids == {"A1": 1.0, "A2": 4.0, "B1": 8.0, "B2": 15.0}, str(mids))
    for label, tn, answers, variant, note, niveau in VARIANT_CASES:
        r = formule.niveau_via_formule(answers, tn, variant)
        check(label, r["note_sur_20"] == note and r["niveau"] == niveau, json.dumps(r, ensure_ascii=False))

    print("Comptage de mots (règle Java)")
    for text, expected in WORD_CASES:
        got = count_words(text)
        check(repr(text[:30]), got == expected, f"{got} ≠ {expected}")

    print("Prompts et state")
    for v in config.PROMPT_VERSIONS:
        for t in prompts.TASK_TYPES:
            q = prompts.build_questions(t, v)
            check(f"{v} {t} : 6 questions dans l'ordre", tuple(q) == prompts.QUESTION_KEYS)
            check(f"{v} {t} : choix niveau_global", tuple(q["niveau_global"]["criteria"]) == prompts.GLOBAL_CHOICES)
            check(f"{v} {t} : choix pertinence", tuple(q["pertinence"]["criteria"]) == prompts.PERTINENCE_CHOICES)
            check(f"{v} {t} : choix critères A1..B2",
                  all(tuple(q[f"critere_{c}"]["criteria"]) == prompts.LEVELS for c in prompts.CRITERE_CODES))
            check(f"{v} {t} : assemblage déterministe",
                  prompts.questions_hash(q) == prompts.questions_hash(prompts.build_questions(t, v)))
    for t in prompts.TASK_TYPES:
        a = prompts.build_questions(t, config.PROMPT_VERSIONS[0])
        b = prompts.build_questions(t, config.PROMPT_VERSIONS[1])
        check(f"{t} : les versions ne diffèrent que par les options des questions critère",
              {k: a[k] for k in ("niveau_global", "pertinence")} == {k: b[k] for k in ("niveau_global", "pertinence")}
              and all(a[f"critere_{c}"]["instructions"] == b[f"critere_{c}"]["instructions"]
                      for c in prompts.CRITERE_CODES))
    fake = {"task_type": "EE_TASK_2", "consigne": "c", "contexte": None, "production": "p",
            "niveau_vise": "B1", "niveau_vise_code": "B1", "playground": {"choice": "B1"}}
    state = prompts.build_state(fake)
    check("state sans niveau visé / Playground", set(state) == set(prompts.STATE_FIELDS)
          and "B1" not in json.dumps(state))

    if with_db:
        failures += _db_crosscheck()
    print(f"\n{'SELFCHECK OK' if failures == 0 else f'{failures} ÉCHEC(S)'}")
    return 1 if failures else 0


def _db_crosscheck() -> int:
    """Recalcule le niveau des évaluations v15 LOCALES (lecture seule) et compare."""
    print("Recoupement base locale (v15, lecture seule)")
    sql = ("SET default_transaction_read_only = on;\n"
           "SELECT json_agg(t) FROM (SELECT e.niveau_cecrl, e.note_sur_20, t.tache_numero, "
           "e.feedback_json->'scores_criteres' sc, e.feedback_json->>'plafond_niveau' plafond "
           "FROM ai_evaluations e JOIN production_submissions s ON s.id = e.submission_id "
           "JOIN production_tasks t ON t.id = s.production_task_id "
           "WHERE e.rubrics_version = 'v15' AND t.epreuve = 'TCF_EE' AND e.evaluabilite = 'EVALUABLE') t;")
    try:
        res = subprocess.run(["psql", "-X", "-q", "-At", "-d", config.LOCAL_DB_NAME, "-U", config.LOCAL_DB_USER],
                             input=sql, capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.TimeoutExpired) as exc:
        print(f"  (base locale indisponible : {exc})")
        return 0
    if res.returncode != 0 or not res.stdout.strip() or res.stdout.strip() == "":
        print(f"  (base locale indisponible : {res.stderr.strip()[:200]})")
        return 0
    rows = json.loads(res.stdout.strip() or "null") or []
    bad = 0
    for r in rows:
        notes = {x["code"]: x["note_sur_20"] for x in (r["sc"] or [])}
        out = formule.pipeline(notes, r["tache_numero"])
        ok = out["niveau"] == r["niveau_cecrl"] and abs(out["note_sur_20"] - float(r["note_sur_20"])) < 1e-9 \
            and (out["plafond_applique"] == (r["plafond"] is not None))
        if not ok:
            bad += 1
            print(f"  [ÉCART] base={r['niveau_cecrl']}/{r['note_sur_20']} plafond={r['plafond']} "
                  f"python={out['niveau']}/{out['note_sur_20']} plafond={out['plafond_applique']} notes={notes}")
    print(f"  {len(rows) - bad}/{len(rows)} évaluations v15 EE recalculées à l'identique")
    return 1 if bad else 0
