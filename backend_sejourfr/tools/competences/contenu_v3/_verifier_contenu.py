#!/usr/bin/env python3
"""Contrôle de forme de tous les lots de `contenu_v3/`.

Ce que ce script NE fait PAS : juger la qualité pédagogique d'un sujet. Il
vérifie ce qu'une machine peut vérifier — structure, bornes, unicité, icônes —
pour que la relecture humaine porte sur ce qui compte vraiment.
"""
import glob, json, os, re, sys

ICI = os.path.dirname(os.path.abspath(__file__))
ICONES = {"STRUCTURE", "NUMBER", "PERSON", "TIME", "TONE", "EXAMPLE", "PLACE", "TENSE"}
NIVEAUX = ["INSUFFICIENT", "EXPECTED", "EXCELLENT"]
DIFFS = {"EASY", "MEDIUM", "HARD"}
CHAMPS = {"title", "context", "instruction", "uniqueCriterion", "recommendedMinWords",
          "recommendedMaxWords", "recommendedDurationSeconds", "difficultyLevel",
          "checklist", "constraintTags", "answerStarter", "tip", "references"}
# Une règle sociale présentée comme universelle : refusée depuis le lot 2 de EE1.
REGLE_ABSOLUE = re.compile(r"(un|une|votre)\s+\w+(\s+\w+)?\s+(se vouvoie|se tutoie)", re.I)


def controler(chemin: str) -> list[str]:
    d = json.load(open(chemin, encoding="utf-8"))
    nom = os.path.basename(chemin)
    ko, titres, amorces = [], set(), set()
    oral = d["skillCode"].startswith("EO")

    if len(d["prompts"]) != 15:
        ko.append(f"{nom} : {len(d['prompts'])} sujets au lieu de 15")

    for i, p in enumerate(d["prompts"], 1):
        ref = f"{nom}/S{i}"
        obligatoires = CHAMPS - ({"recommendedDurationSeconds"} if not oral
                                 else {"recommendedMinWords", "recommendedMaxWords"})
        for c in obligatoires - set(p):
            ko.append(f"{ref} : champ manquant « {c} »")
        for c in set(p) - CHAMPS:
            ko.append(f"{ref} : champ inconnu « {c} »")
        if p.get("difficultyLevel") not in DIFFS:
            ko.append(f"{ref} : difficulté « {p.get('difficultyLevel')} »")

        if p["title"] in titres:
            ko.append(f"{ref} : titre en double « {p['title']} »")
        titres.add(p["title"])
        if p["answerStarter"] in amorces:
            ko.append(f"{ref} : amorce en double « {p['answerStarter']} »")
        amorces.add(p["answerStarter"])

        if not (3 <= len(p["checklist"]) <= 4):
            ko.append(f"{ref} : {len(p['checklist'])} gestes de check-list")
        for g in p["checklist"]:
            if len(g.split()) > 6:
                ko.append(f"{ref} : geste trop long « {g} »")
        if len(p["constraintTags"]) != 2:
            ko.append(f"{ref} : {len(p['constraintTags'])} pastilles au lieu de 2")
        for t in p["constraintTags"]:
            if t["icon"] not in ICONES:
                ko.append(f"{ref} : icône inconnue « {t['icon']} »")
            if len(t["label"]) > 28:
                ko.append(f"{ref} : étiquette trop longue « {t['label']} »")
        if not p["tip"] or p["tip"][0].isupper() and not oral:
            pass  # la casse de l'astuce suit la convention de chaque tâche

        if oral:
            if p.get("recommendedDurationSeconds") is None:
                ko.append(f"{ref} : durée conseillée absente")
            if p.get("recommendedMinWords") is not None or p.get("recommendedMaxWords") is not None:
                ko.append(f"{ref} : un sujet oral ne porte pas de bornes de mots")
        else:
            mn, mx = p.get("recommendedMinWords"), p.get("recommendedMaxWords")
            if mn is None or mx is None or mn >= mx:
                ko.append(f"{ref} : bornes de mots invalides ({mn}-{mx})")
            if p.get("recommendedDurationSeconds") is not None:
                ko.append(f"{ref} : un sujet écrit ne porte pas de durée")

        if [r["level"] for r in p["references"]] != NIVEAUX:
            ko.append(f"{ref} : les trois références ne sont pas dans l'ordre attendu")
        textes = set()
        for r in p["references"]:
            if r["text"] in textes:
                ko.append(f"{ref} : deux références identiques")
            textes.add(r["text"])
            if not r["pedagogicalNote"]:
                ko.append(f"{ref}/{r['level']} : note pédagogique vide")
            if REGLE_ABSOLUE.search(r["text"]):
                ko.append(f"{ref}/{r['level']} : règle sociale présentée comme absolue")
            if not oral:
                n = len(r["text"].split())
                if not (p["recommendedMinWords"] <= n <= p["recommendedMaxWords"]):
                    ko.append(f"{ref}/{r['level']} : {n} mots hors de "
                              f"{p['recommendedMinWords']}-{p['recommendedMaxWords']}")
        # L'EXCELLENT ne doit pas gagner en étant simplement plus long.
        lg = [len(r["text"].split()) for r in p["references"]]
        if lg[2] > lg[1] * 2:
            ko.append(f"{ref} : EXCELLENT plus du double de ATTENDU ({lg[1]} → {lg[2]})")
    return ko


def main() -> int:
    total, ko = 0, []
    for chemin in sorted(glob.glob(os.path.join(ICI, "E*.json"))):
        total += 1
        ko += controler(chemin)
    for e in ko:
        print("✗", e)
    print(f"{total} lots, {total * 15} sujets, {len(ko)} anomalies.")
    return 1 if ko else 0


if __name__ == "__main__":
    sys.exit(main())
