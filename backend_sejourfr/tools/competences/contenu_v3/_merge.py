"""Fusionne un lot de corrections dans `_corrections.json`.

🛑 `contenu/*.json` alimente V300-V317, **déjà appliquées** : on ne l'édite
jamais. Les corrections de cadrage des compétences recentrées vivent ici et
sortiront en `UPDATE` dans une migration neuve.

Une entrée ne porte que les **champs modifiés** d'un sujet. Les références se
patchent par niveau (`INSUFFICIENT` / `EXPECTED` / `EXCELLENT`), et seulement
sur `text` et/ou `pedagogicalNote`.
"""
import json, os, sys

CHEMIN = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_corrections.json")


def fusionner(lot: dict) -> None:
    base = {}
    if os.path.exists(CHEMIN):
        with open(CHEMIN, encoding="utf-8") as f:
            base = json.load(f)
    for skill, sujets in lot.items():
        base.setdefault(skill, {}).update(sujets)
    with open(CHEMIN, "w", encoding="utf-8") as f:
        json.dump(base, f, ensure_ascii=False, indent=2)
        f.write("\n")
    total = sum(len(v) for v in base.values())
    print(f"{CHEMIN} : {len(base)} competences, {total} sujets corriges.")
