#!/usr/bin/env python3
"""La vue V3 des 48 competences : ce que le candidat verra apres la bascule.

Trois sources, une seule lecture — et c'est la raison d'etre de ce module :
sans lui, chaque script (learningPoints, emetteur SQL, controles) recomposerait
la meme table dans son coin, et la deuxieme copie divergerait de la premiere.

    from vue_v3 import charger_v3
    for s in charger_v3():
        print(s["code"], s["rang"], len(s["prompts"]))

D'ou vient quoi
---------------
* **Le cadre** (titre, critere, description, rang) vient de `taxonomie_v3.py`
  pour les competences RECENTREES et CREEES, et de `contenu/*.json` pour les
  22 inchangees.
* **Les sujets** viennent, dans cet ordre de priorite :
  1. `contenu_v3/<code>.json` — lot neuf, qui remplace l'ancien ;
  2. `contenu/*.json` + `contenu_v3/_corrections.json` — lot conserve, cadrage
     corrige ;
  3. `contenu/*.json` tel quel.

🛑 `contenu/*.json` alimente V300-V317, **deja appliquees** : ce module le LIT,
il ne l'ecrit jamais. Toute matiere neuve vit dans `contenu_v3/`.
"""

from __future__ import annotations

import json
from pathlib import Path

from taxonomie_v3 import CREE, GARDE, NIVEAU_CREEES, RECENTRE, RETIRE, TAXONOMIE

ICI = Path(__file__).resolve().parent
CONTENU = ICI / "contenu"
V3 = ICI / "contenu_v3"
CORRECTIONS = V3 / "_corrections.json"

CHAMPS_PATCHABLES = {"title", "instruction", "uniqueCriterion", "checklist",
                     "constraintTags", "answerStarter", "tip", "recommendedMinWords",
                     "recommendedMaxWords", "recommendedDurationSeconds", "difficultyLevel"}


def _corriger(prompt: dict, patch: dict) -> dict:
    """Applique un patch de `_corrections.json` sur un sujet deja seede."""
    sujet = json.loads(json.dumps(prompt))
    for champ, valeur in patch.items():
        if champ in CHAMPS_PATCHABLES:
            sujet[champ] = valeur
        elif champ == "references":
            par_niveau = {r["level"]: r for r in sujet["references"]}
            for niveau, bloc in valeur.items():
                par_niveau[niveau].update(bloc)
        else:
            raise ValueError(f"{prompt['code']} : champ de correction inconnu « {champ} »")
    return sujet


def charger_v3() -> list[dict]:
    base: dict[str, tuple[dict, dict]] = {}
    for tache in TAXONOMIE:
        doc = json.loads((CONTENU / f"{tache}.json").read_text(encoding="utf-8"))
        for s in doc["skills"]:
            base[s["code"]] = (doc, s)

    corrections = json.loads(CORRECTIONS.read_text(encoding="utf-8")) if CORRECTIONS.exists() else {}

    vue: list[dict] = []
    for tache, entrees in TAXONOMIE.items():
        for e in entrees:
            if e["verdict"] == RETIRE:
                continue
            code = e["code"]
            ancienne = base.get(code, (None, None))[1]
            lot = V3 / f"{code}.json"

            if lot.exists():
                neuf = json.loads(lot.read_text(encoding="utf-8"))
                prompts = neuf["prompts"]
                origine, premier, remplace = "contenu_v3", neuf["premierCodeLibre"], neuf["remplace"]
            else:
                if ancienne is None:
                    raise ValueError(f"{code} : ni lot neuf ni competence seedee")
                patchs = corrections.get(code, {})
                prompts = [_corriger(p, patchs[p["code"]]) if p["code"] in patchs else p
                           for p in ancienne["prompts"]]
                origine, premier, remplace = "contenu", None, None

            if e["verdict"] == GARDE:
                titre, critere = ancienne["title"], ancienne["generalCriterion"]
                description = ancienne["description"]
                niveau = ancienne["targetLevel"]
            else:
                titre, critere = e["titre"], e["critere"]
                description = e["description"]
                niveau = NIVEAU_CREEES[code] if e["verdict"] == CREE else ancienne["targetLevel"]

            vue.append({
                "code": code, "tache": tache, "rang": e["ordre"], "verdict": e["verdict"],
                "titre": titre, "critere": critere, "description": description,
                "targetLevel": niveau, "origine": origine, "premierCodeLibre": premier,
                "remplace": remplace, "prompts": prompts,
                "prompts_corriges": sorted(corrections.get(code, {})) if origine == "contenu" else [],
            })
    return vue


def main() -> None:
    vue = charger_v3()
    par_origine: dict[str, int] = {}
    corriges = 0
    for s in vue:
        par_origine[s["origine"]] = par_origine.get(s["origine"], 0) + 1
        corriges += len(s["prompts_corriges"])
        assert len(s["prompts"]) == 15, f"{s['code']} : {len(s['prompts'])} sujets"
    assert len(vue) == 48, len(vue)
    print(f"Vue V3 : {len(vue)} competences, {len(vue) * 15} sujets.")
    print(f"  lots neufs : {par_origine.get('contenu_v3', 0)} competences")
    print(f"  lots conserves : {par_origine.get('contenu', 0)} competences, {corriges} sujets corriges")
    for verdict in (GARDE, RECENTRE, CREE):
        print(f"  {verdict} : {sum(1 for s in vue if s['verdict'] == verdict)}")


if __name__ == "__main__":
    main()
