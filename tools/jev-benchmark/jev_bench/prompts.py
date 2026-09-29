"""Assemblage DÉTERMINISTE des questions JEV et du state, pour DEUX versions de prompt coexistantes.

- ``jev-independent-v1`` (PRINCIPAL) : options de niveau des questions critère = §19–22 de la spec ;
- ``jev-v15-aligned-v1`` (SECONDAIRE, sensibilité) : options = échelle CECRL commune de la grille
  v15 + descripteurs de la tâche v15 (la v15 n'a AUCUN descripteur par critère).

Les textes vivent dans ``jev_bench/prompts/<version>/*.json`` ; ce module ne fait que les
assembler, dans un ordre fixe, sans horodatage ni aléa. Le hash sha256 porte sur la
sérialisation canonique (clés triées) des questions assemblées. Les deux versions ne
se mélangent jamais : chaque run porte sa version et son hash.
"""
from __future__ import annotations

import hashlib
import json
from functools import lru_cache

from . import config

TASK_TYPES = ("EE_TASK_1", "EE_TASK_2", "EE_TASK_3")
CRITERE_CODES = ("communiquer", "interagir", "lexique", "morphosyntaxe")
LEVELS = ("A1", "A2", "B1", "B2")
GLOBAL_CHOICES = LEVELS + ("INSUFFICIENT",)
PERTINENCE_CHOICES = ("DANS_LE_SUJET", "PARTIEL", "HORS_SUJET")
QUESTION_KEYS = ("niveau_global", "pertinence") + tuple(f"critere_{c}" for c in CRITERE_CODES)

# Champs du state : JAMAIS de niveau visé, actuel, cible, ni de résultat antérieur.
STATE_FIELDS = ("exam", "modality", "task_type", "consigne", "contexte", "production")


def _dir(version: str):
    if version not in config.PROMPT_VERSIONS:
        raise ValueError(f"version de prompt inconnue : {version} (connues : {config.PROMPT_VERSIONS})")
    return config.PROMPTS_DIR / version


@lru_cache(maxsize=None)
def load_common(version: str = config.PROMPT_VERSION) -> dict:
    d = json.loads((_dir(version) / "common.json").read_text(encoding="utf-8"))
    if d["prompt_version"] != version:
        raise ValueError(f"{version}/common.json annonce {d['prompt_version']}")
    return d


@lru_cache(maxsize=None)
def load_task(task_type: str, version: str = config.PROMPT_VERSION) -> dict:
    if task_type not in TASK_TYPES:
        raise ValueError(f"task_type inconnu : {task_type}")
    n = task_type[-1]
    return json.loads((_dir(version) / f"ee_task_{n}.json").read_text(encoding="utf-8"))


def _critere_options(common: dict, task: dict) -> dict:
    crit = common["critere"]
    if "echelle_cecrl_v15" in crit:  # jev-v15-aligned-v1
        return {k: {"echelle_cecrl": crit["echelle_cecrl_v15"][k],
                    "descripteur_de_la_tache": task["descripteurs_v15"][k]} for k in crit["choix"]}
    return {k: common["niveaux"][k] for k in crit["choix"]}  # jev-independent-v1 : §19–22


def build_questions(task_type: str, version: str = config.PROMPT_VERSION) -> dict:
    common = load_common(version)
    task = load_task(task_type, version)

    ng = common["niveau_global"]
    niveaux = common["niveaux"]
    questions: dict = {
        "niveau_global": {
            "type": "choice",
            "instructions": {
                "question": ng["question"],
                "cadre": ng["cadre"],
                "type_de_tache": task["titre"],
                "adaptation_a_la_tache": task["adaptation"],
                "insufficient": ng["insufficient"],
            },
            "criteria": {k: niveaux[k] for k in GLOBAL_CHOICES},
        },
        "pertinence": {
            "type": "choice",
            "instructions": {
                "question": common["pertinence"]["question"],
                "regles": common["pertinence"]["regles"],
            },
            "criteria": {k: common["pertinence"]["criteria"][k] for k in PERTINENCE_CHOICES},
        },
    }
    crit_common = common["critere"]
    by_code = {c["code"]: c for c in task["criteres"]}
    for code in CRITERE_CODES:
        c = by_code[code]
        questions[f"critere_{code}"] = {
            "type": "choice",
            "instructions": {
                "question": crit_common["question"],
                "critere": c["label"],
                "description": c["description"],
                "type_de_tache": task["titre"],
                "regles": crit_common["regles"],
            },
            "criteria": _critere_options(common, task),
        }
    assert tuple(questions) == QUESTION_KEYS
    return questions


def canonical(obj) -> str:
    return json.dumps(obj, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def questions_hash(questions: dict) -> str:
    return hashlib.sha256(canonical(questions).encode("utf-8")).hexdigest()


def all_questions_hash(version: str = config.PROMPT_VERSION) -> str:
    """Hash global d'une version : les trois jeux de questions EE, dans l'ordre des tâches."""
    return questions_hash({t: build_questions(t, version) for t in TASK_TYPES})


def build_state(sample: dict) -> dict:
    state = {
        "exam": "TCF IRN",
        "modality": "EE",
        "task_type": sample["task_type"],
        "consigne": sample["consigne"],
        "contexte": sample.get("contexte"),
        "production": sample["production"],
    }
    assert tuple(state) == STATE_FIELDS
    return state


def build_payload(sample: dict, model: str, version: str = config.PROMPT_VERSION) -> dict:
    return {
        "model": model,
        "state": build_state(sample),
        "questions": build_questions(sample["task_type"], version),
    }
