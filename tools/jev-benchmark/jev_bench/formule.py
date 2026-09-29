"""« Niveau JEV via formule SejourFR » : portage Python du calcul serveur v15.

Reproduit, SANS rien modifier côté Java, l'ordre et les arrondis de
``AiEvaluationService.postProcess`` :

1. ``applyCouplage`` (l.1170) : pour ``communiquer`` / ``interagir``,
   ``plafond = moyenne(lexique, morphosyntaxe)`` arrondie HALF_UP à 4 décimales
   ``+ ecart_max`` ; une note STRICTEMENT supérieure est ramenée à
   ``plafond`` tronqué (RoundingMode.DOWN) à 1 décimale. Socle incomplet ⇒ rien.
2. ``applyServerComputedNote`` (l.1437, ``weightedNote``) : Σ note × poids,
   arrondi HALF_UP à 1 décimale, borné à [0, 20].
3. ``applyServerComputedNiveau`` (l.1462) → ``ProductionBilanService.computeNiveau``
   (l.525-576) : note globale == 0 ⇒ ``A1_NON_ATTEINT`` ; sinon compétence =
   moyenne des critères ``source_criteres`` (HALF_UP, 4 décimales ; repli sur la
   note globale si un critère manque) ; ``≥ seuil_b2`` B2, ``≥ seuil_b1`` B1,
   ``≥ seuil_a2`` A2, ``> 0`` A1, sinon A1_NON_ATTEINT.
4. ``applyPlafonds`` (l.1221) : tâche 3 et ``communiquer`` ≤
   ``prise_position_seuil`` ⇒ niveau ramené à ``prise-position-niveau-max``
   (A2, application.yaml) s'il est au-dessus. Jamais relevé.

Paramètres lus dans production-rubrics-v15.json (``commun.niveau``,
``commun.couplage.ecart_max``, ``commun.plafonds.prise_position_seuil``,
``niveau_max``, poids des critères) et, pour ce que le fichier ne porte pas
(niveau du plafond, critères de langue / réalisation), dans application.yaml /
``ProductionEvaluationProperties`` (valeurs par défaut Java).

RÉSULTAT SECONDAIRE — CONVERSION DES RÉPONSES JEV EN NOTES /20 (à faire valider).
Le résultat PRINCIPAL est la question JEV ``niveau_global``. Ce module ne sert qu'à
un niveau SECONDAIRE : « niveau via formule SejourFR ».

Les 4 questions critère renvoient un niveau (A1..B2) et une distribution. Chaque
niveau est ramené au MILIEU de SA BANDE DANS LA FORMULE SERVEUR ACTUELLE, bornes
lues dans le code, jamais inventées :

- seuils ``commun.niveau`` de production-rubrics-v15.json (seuil_a2=2, seuil_b1=6,
  seuil_b2=10) appliqués en ``≥`` continus par
  ``ProductionBilanService.niveauFromCompetence`` (l.568-576), A1 si ``> 0`` ;
- borne haute = ``maximum`` de ``note_sur_20`` dans
  production-evaluation-tool-schema-v9.json (``type: number``, 0–20, décimales
  permises), égale à ``NOTE_MAX = 20`` (AiEvaluationService l.46, borne de
  ``weightedNote`` l.196).

Bandes : A1 ]0 ; 2[, A2 [2 ; 6[, B1 [6 ; 10[, B2 [10 ; 20] ⇒ milieux
A1 = 1, A2 = 4, B1 = 8, B2 = 15. Deux variantes sont calculées et stockées :

- ``argmax_milieu`` : milieu de la bande du choix JEV ;
- ``esperance`` : Σ proba × milieu, probabilités renormalisées sur A1..B2.

Conséquence assumée : la note minimale est 1, donc ``A1_NON_ATTEINT`` ne peut
jamais sortir de la formule (il n'y a pas d'option « 0 » côté JEV).
"""
from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from decimal import ROUND_DOWN, ROUND_HALF_UP, Decimal
from functools import lru_cache

from . import config

LEVEL_ORDER = ("A1_NON_ATTEINT", "A1", "A2", "B1", "B2", "C1", "C2")
NOTE_MAX = Decimal("20")  # AiEvaluationService.NOTE_MAX (l.46)
TOOL_SCHEMA_V9_FILE = config.BACKEND_DIR / "src/main/resources/prompts/production-evaluation-tool-schema-v9.json"
VARIANTS = ("argmax_milieu", "esperance")

# Valeurs par défaut Java (ProductionEvaluationProperties.Couplage) : le fichier v15 ne les porte pas.
CRITERES_REALISATION = ("communiquer", "interagir")
CRITERES_LANGUE = ("lexique", "morphosyntaxe")


@dataclass(frozen=True)
class Params:
    seuil_b2: Decimal
    seuil_b1: Decimal
    seuil_a2: Decimal
    source_criteres: tuple
    ecart_max: Decimal
    prise_position_seuil: Decimal
    prise_position_niveau_max: str
    niveau_max: str
    poids: dict = field(default_factory=dict)  # {task_number: {code: Decimal}}


def _yaml_value(key: str, default: str) -> str:
    """Lecture ciblée d'une clé scalaire de application.yaml (bloc plafonds), sans dépendance YAML."""
    try:
        text = config.APPLICATION_YAML.read_text(encoding="utf-8")
    except OSError:
        return default
    m = re.search(r"^\s*plafonds:\s*$(.*?)^\s{0,4}\S", text, flags=re.M | re.S)
    scope = m.group(1) if m else text
    m2 = re.search(rf"^\s*{re.escape(key)}:\s*([A-Za-z0-9_.]+)", scope, flags=re.M)
    return m2.group(1) if m2 else default


@lru_cache(maxsize=None)
def load_params() -> Params:
    rub = json.loads(config.RUBRICS_V15_FILE.read_text(encoding="utf-8"))
    commun = rub["commun"]
    niv = commun["niveau"]
    poids = {}
    for n in (1, 2, 3):
        poids[n] = {c["code"]: Decimal(str(c["poids"])) for c in rub["rubrics"][f"EE_T{n}"]["criteres"]}
    niveau_max = str(rub.get("niveau_max"))
    if niveau_max != "B2":
        raise ValueError(f"niveau_max inattendu dans v15 : {niveau_max}")
    return Params(
        seuil_b2=Decimal(str(niv["seuil_b2"])),
        seuil_b1=Decimal(str(niv["seuil_b1"])),
        seuil_a2=Decimal(str(niv["seuil_a2"])),
        source_criteres=tuple(niv["source_criteres"]),
        ecart_max=Decimal(str(commun["couplage"]["ecart_max"])),
        prise_position_seuil=Decimal(str(commun["plafonds"]["prise_position_seuil"])),
        prise_position_niveau_max=_yaml_value("prise-position-niveau-max", "A2"),
        niveau_max=niveau_max,
        poids=poids,
    )


def _schema_note_bounds() -> tuple[Decimal, Decimal]:
    """(minimum, maximum) de ``note_sur_20`` dans le tool-schema v9 (propriété d'un score critère)."""
    schema = json.loads(TOOL_SCHEMA_V9_FILE.read_text(encoding="utf-8"))
    found = []

    def walk(node):
        if isinstance(node, dict):
            props = node.get("properties")
            if isinstance(props, dict) and isinstance(props.get("note_sur_20"), dict):
                found.append(props["note_sur_20"])
            for v in node.values():
                walk(v)
        elif isinstance(node, list):
            for v in node:
                walk(v)

    walk(schema)
    if not found:
        raise ValueError("note_sur_20 introuvable dans le tool-schema v9")
    spec = found[0]
    if spec.get("type") != "number":
        raise ValueError(f"note_sur_20 : type inattendu {spec.get('type')}")
    return Decimal(str(spec["minimum"])), Decimal(str(spec["maximum"]))


@lru_cache(maxsize=None)
def band_midpoints() -> dict:
    """Milieux des bandes de la formule serveur : A1 ]0;a2[, A2 [a2;b1[, B1 [b1;b2[, B2 [b2;max]."""
    p = load_params()
    lo, hi = _schema_note_bounds()
    if hi != NOTE_MAX or lo != 0:
        raise ValueError(f"bornes du tool-schema v9 ({lo}–{hi}) ≠ NOTE_MAX Java ({NOTE_MAX})")
    two = Decimal("2")
    return {
        "A1": (lo + p.seuil_a2) / two,
        "A2": (p.seuil_a2 + p.seuil_b1) / two,
        "B1": (p.seuil_b1 + p.seuil_b2) / two,
        "B2": (p.seuil_b2 + hi) / two,
    }


def _mean4(values) -> Decimal:
    s = sum(values, Decimal("0"))
    return (s / Decimal(len(values))).quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP)


def apply_couplage(notes: dict, p: Params) -> dict:
    out = dict(notes)
    langue = [notes[c] for c in CRITERES_LANGUE if notes.get(c) is not None]
    if len(langue) != len(CRITERES_LANGUE) or not langue:
        return out
    plafond = _mean4(langue) + p.ecart_max
    for code in CRITERES_REALISATION:
        v = out.get(code)
        if v is None or v <= plafond:
            continue
        out[code] = plafond.quantize(Decimal("0.1"), rounding=ROUND_DOWN)
    return out


def weighted_note(notes: dict, poids: dict) -> Decimal | None:
    if set(notes) != set(poids) or any(v is None for v in notes.values()):
        return None
    s = sum((notes[c] * poids[c] for c in poids), Decimal("0"))
    r = s.quantize(Decimal("0.1"), rounding=ROUND_HALF_UP)
    return min(max(r, Decimal("0")), NOTE_MAX)


def niveau_from_competence(c: Decimal, p: Params) -> str:
    if c >= p.seuil_b2:
        return "B2"
    if c >= p.seuil_b1:
        return "B1"
    if c >= p.seuil_a2:
        return "A2"
    if c > 0:
        return "A1"
    return "A1_NON_ATTEINT"


def compute_niveau(notes: dict, note_globale: Decimal | None, p: Params) -> str | None:
    if note_globale is not None and note_globale == 0:
        return "A1_NON_ATTEINT"
    src = [notes[c] for c in p.source_criteres if notes.get(c) is not None]
    if p.source_criteres and len(src) == len(p.source_criteres):
        competence = _mean4(src)
    elif note_globale is not None:
        competence = note_globale
    elif src:
        competence = _mean4(src)
    else:
        return None
    return niveau_from_competence(competence, p)


def apply_plafonds(notes: dict, task_number: int, niveau: str | None, p: Params) -> tuple[str | None, bool]:
    if niveau is None:
        return niveau, False
    com = notes.get("communiquer")
    if task_number == 3 and com is not None and com <= p.prise_position_seuil:
        cap = p.prise_position_niveau_max
        if LEVEL_ORDER.index(niveau) > LEVEL_ORDER.index(cap):
            return cap, True
    return niveau, False


def pipeline(raw_notes: dict, task_number: int, p: Params | None = None) -> dict:
    """Notes /20 brutes par critère → notes couplées, note globale, niveau (dans l'ordre Java)."""
    p = p or load_params()
    notes = {k: (None if v is None else Decimal(str(v))) for k, v in raw_notes.items()}
    coupled = apply_couplage(notes, p)
    note = weighted_note(coupled, p.poids[task_number])
    niveau = compute_niveau(coupled, note, p)
    niveau, plafond = apply_plafonds(coupled, task_number, niveau, p)
    return {
        "notes_brutes": {k: _f(v) for k, v in notes.items()},
        "notes_couplees": {k: _f(v) for k, v in coupled.items()},
        "note_sur_20": _f(note),
        "niveau": niveau,
        "plafond_applique": plafond,
    }


def _f(v):
    return None if v is None else float(v)


def note_from_answer(answer: dict | None, variant: str) -> Decimal | None:
    """Réponse JEV d'une question critère → note /20 selon la variante."""
    if not answer:
        return None
    if variant == "argmax_milieu":
        choice = answer.get("choice")
        return band_midpoints().get(choice)
    if variant == "esperance":
        probs = answer.get("probabilities") or {}
        items = [(k, Decimal(str(v))) for k, v in probs.items() if k in band_midpoints() and v is not None]
        total = sum((v for _, v in items), Decimal("0"))
        if total <= 0:
            return None
        return sum((band_midpoints()[k] * v for k, v in items), Decimal("0")) / total
    raise ValueError(variant)


def niveau_via_formule(answers: dict, task_number: int, variant: str) -> dict:
    notes = {code: note_from_answer(answers.get(f"critere_{code}"), variant)
             for code in ("communiquer", "interagir", "lexique", "morphosyntaxe")}
    if any(v is None for v in notes.values()):
        return {"variant": variant, "niveau": None, "note_sur_20": None, "plafond_applique": False,
                "notes_brutes": {k: _f(v) for k, v in notes.items()}, "notes_couplees": None,
                "erreur": "critère(s) sans réponse exploitable"}
    out = pipeline(notes, task_number)
    out["variant"] = variant
    out["milieux_bandes"] = {k: float(v) for k, v in band_midpoints().items()}
    return out
