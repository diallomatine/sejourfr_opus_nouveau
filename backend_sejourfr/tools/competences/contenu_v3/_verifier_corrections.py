#!/usr/bin/env python3
"""Contrôle `_corrections.json` contre le contenu déjà seedé.

Vérifie que chaque correction vise un sujet qui existe, ne touche que des
champs connus, n'emploie que des icônes connues, et qu'aucune consigne
corrigée ne réintroduit la formulation que la V3 a justement retirée.
"""
import json, os, re, sys

ICI = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.join(ICI, "..", "contenu")

CHAMPS = {"title", "instruction", "uniqueCriterion", "checklist", "constraintTags",
          "answerStarter", "tip", "recommendedMinWords", "recommendedMaxWords",
          "recommendedDurationSeconds", "difficultyLevel", "references"}
ICONES = {"STRUCTURE", "NUMBER", "PERSON", "TIME", "TONE", "EXAMPLE", "PLACE", "TENSE"}
NIVEAUX = {"INSUFFICIENT", "EXPECTED", "EXCELLENT"}

# Ce que la V3 a retiré, compétence par compétence : si l'un de ces motifs
# survit dans un champ corrigé, la correction n'a pas fait son travail.
INTERDITS = {
    "EE2-C2": re.compile(r"\boù vous étiez\b|\ble lieu\b|situez la|placez-vous", re.I),
    "EE2-C3": re.compile(r"imparfait|passé composé", re.I),
    "EE2-C8": re.compile(r"bilan personnel|et une conséquence|conséquence et", re.I),
    "EO1-C6": re.compile(r"trois étapes|au moins trois|ressenti", re.I),
    "EO2-C7": re.compile(r"laquelle vous choisissez|choisissez en|puis choisis|justifiez (?:votre|-le|ce)|en justifiant", re.I),
    "EO3-C1": re.compile(r"immédiatement|dès (?:la première|les premiers|vos premiers|le début|l'ouverture|d'entrée)|avant tout(?:e)? ", re.I),
    "EO3-C5": re.compile(r"deuxième|second\b|seconde\b", re.I),
    "EO3-C8": re.compile(r"conclusion|conclure|conclu|quatre (?:temps|étapes)", re.I),
}
CHAMPS_TEXTE = ("title", "instruction", "uniqueCriterion", "answerStarter", "tip")


def main() -> int:
    corrections = json.load(open(os.path.join(ICI, "_corrections.json"), encoding="utf-8"))
    base = {}
    for tache in ("EE1", "EE2", "EE3", "EO1", "EO2", "EO3"):
        d = json.load(open(os.path.join(BASE, f"{tache}.json"), encoding="utf-8"))
        for s in d["skills"]:
            for p in s["prompts"]:
                base[p["code"]] = (s["code"], p)

    erreurs, sujets = [], 0
    for skill, lot in corrections.items():
        motif = INTERDITS.get(skill)
        for code, patch in lot.items():
            sujets += 1
            if code not in base:
                erreurs.append(f"{code} : sujet inconnu dans contenu/")
                continue
            if base[code][0] != skill:
                erreurs.append(f"{code} : rattaché à {base[code][0]}, pas à {skill}")
            for champ in patch:
                if champ not in CHAMPS:
                    erreurs.append(f"{code} : champ inconnu « {champ} »")
            for tag in patch.get("constraintTags", []):
                if tag.get("icon") not in ICONES:
                    erreurs.append(f"{code} : icône inconnue « {tag.get('icon')} »")
                if len(tag.get("label", "")) > 28:
                    erreurs.append(f"{code} : étiquette trop longue « {tag['label']} »")
            for niveau, bloc in patch.get("references", {}).items():
                if niveau not in NIVEAUX:
                    erreurs.append(f"{code} : niveau de référence inconnu « {niveau} »")
                for champ in bloc:
                    if champ not in ("text", "pedagogicalNote"):
                        erreurs.append(f"{code} : champ de référence inconnu « {champ} »")
            for geste in patch.get("checklist", []):
                if len(geste.split()) > 6:
                    erreurs.append(f"{code} : geste de check-list trop long « {geste} »")
            if motif:
                for champ in CHAMPS_TEXTE:
                    if champ in patch and motif.search(patch[champ]):
                        erreurs.append(f"{code} : « {champ} » garde ce que la V3 a retiré → {patch[champ][:70]}")
                for niveau, bloc in patch.get("references", {}).items():
                    for champ, valeur in bloc.items():
                        if motif.search(valeur):
                            erreurs.append(f"{code}/{niveau} : « {champ} » garde ce que la V3 a retiré")
                for geste in patch.get("checklist", []):
                    if motif.search(geste):
                        erreurs.append(f"{code} : check-list garde ce que la V3 a retiré → {geste}")

    for e in erreurs:
        print("✗", e)
    print(f"{len(corrections)} competences, {sujets} sujets, {len(erreurs)} anomalies.")
    return 1 if erreurs else 0


if __name__ == "__main__":
    sys.exit(main())
