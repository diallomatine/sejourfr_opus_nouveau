#!/usr/bin/env python3
"""Les huit controles du proprietaire, appliques a un lot de 15 sujets.

    python3 _controle.py EE1-C2.json

Ce n'est PAS un test du depot (les fronts n'en prennent plus, et celui-ci
porte sur du contenu editorial, pas sur du code). C'est le filet de la
redaction : il attrape ce qui se verifie mecaniquement — longueurs, plage de
mots, gradation, variete des quatre objets — pour que la relecture humaine
porte sur ce qui ne se verifie pas : la justesse pedagogique.
"""
import json, re, sys
from collections import Counter

OBJETS = {"Personne décrite": "personne", "Groupe décrit": "groupe",
          "Lieu décrit": "lieu", "Objet décrit": "objet"}
NIVEAUX = ["INSUFFICIENT", "EXPECTED", "EXCELLENT"]

# Profil par TACHE. Les deux taches du chantier n'attendent pas la meme chose,
# et confondre leurs regles est precisement l'erreur que les audits ont trouvee
# dans l'ancien contenu.
#
#   EE1 — decrire une personne, un groupe, un lieu ou un objet, EN REACTION A
#         UN MESSAGE recu. 30-60 mots.
#   EE3 — donner son OPINION au sujet d'un lieu, d'un objet, d'une personne ou
#         d'un groupe. 40-90 mots. Aucun message recu n'est exige.
PROFILS = {
    "EE1": {
        "bornes": (30, 60),
        "message_recu": True,
        "verbe": re.compile(r"décri[rvt]", re.IGNORECASE),
        "verbe_dit": "décrire",
    },
    "EE3": {
        "bornes": (40, 90),
        "message_recu": False,
        "verbe": re.compile(r"avis|opinion|pens[ez]|position", re.IGNORECASE),
        "verbe_dit": "donner un avis",
    },
}

# 🛑 Marqueurs du DEBAT DE SOCIETE, que la tache 3 IRN ne demande pas. L'audit
# des 120 anciens sujets a montre que c'est la derive naturelle de cette
# competence : on glisse de « cette boulangerie » a « faut-il generaliser ».
DEBAT = re.compile(
    r"(faut-il|généralis|en général|la société|tout le monde devrait"
    r"|les gens devraient|de manière générale)", re.IGNORECASE)
ICONES = {"TONE","PERSON","TIME","PLACE","NUMBER","TENSE","STRUCTURE","EXAMPLE"}

# Formules de politesse, comptées pour interdire qu'EXCELLENT ne se distingue
# que par elles.
FORMULES = re.compile(
    r"(bien cordialement|cordialement|je vous prie d'agréer|salutations"
    r"|je reste à votre disposition|je vous remercie|merci d'avance"
    r"|je me permets|veuillez agréer|par avance)", re.IGNORECASE)

# Règles sociales absolues : une astuce ne dit jamais « un X se vouvoie ». Le
# TCF évalue l'adaptation AU CONTEXTE DONNÉ, pas une convention unique — c'est
# au `context` de poser l'usage établi (« que vous avez toujours vouvoyée »).
REGLE_ABSOLUE = re.compile(
    r"(un|une|votre)\s+\w+(\s+\w+)?\s+(se vouvoie|se tutoie)", re.IGNORECASE)

def mots(t): return len(re.findall(r"[\w'’-]+", t))

def controler(chemin: str) -> int:
    d = json.load(open(chemin, encoding="utf-8"))
    p = d["prompts"]
    pb: list[str] = []
    # La tache se lit sur le code de competence : EE1-C2 -> EE1.
    tache = d["skillCode"].split("-")[0]
    profil = PROFILS[tache]
    borne_min, borne_max = profil["bornes"]

    if len(p) != 15:
        pb.append(f"{len(p)} sujets au lieu de 15")

    objets, diff = Counter(), Counter()
    titres, amorces = set(), set()

    for x in p:
        t = x["title"]
        # 1. EE1 seulement : le contexte CITE le message auquel on repond.
        if profil["message_recu"] and "«" not in x["context"]:
            pb.append(f"{t} : le contexte ne cite aucun message reçu")
        # 1b. EE3 : aucun debat de societe, nulle part dans le sujet.
        if tache == "EE3":
            zone = " ".join([x["context"], x["instruction"], x["uniqueCriterion"]])
            trouve = DEBAT.search(zone)
            if trouve:
                pb.append(f"{t} : débat de société — « {trouve.group(0)} »")
        # 2. l'un des quatre objets officiels, et lui seul.
        tags = [g["label"] for g in x["constraintTags"]]
        vus = [OBJETS[g] for g in tags if g in OBJETS]
        if len(vus) != 1:
            pb.append(f"{t} : objet décrit absent ou multiple ({tags})")
        else:
            objets[vus[0]] += 1
        for g in x["constraintTags"]:
            if g["icon"] not in ICONES:
                pb.append(f"{t} : icône inconnue {g['icon']}")
        # 3. plage de mots officielle de la tache.
        if (x["recommendedMinWords"], x["recommendedMaxWords"]) != (borne_min, borne_max):
            pb.append(f"{t} : bornes {x['recommendedMinWords']}-{x['recommendedMaxWords']}"
                      f" au lieu de {borne_min}-{borne_max}")
        # 4. guidage.
        if len(x["checklist"]) != 3:
            pb.append(f"{t} : {len(x['checklist'])} gestes au lieu de 3")
        for g in x["checklist"]:
            if mots(g) > 5:
                pb.append(f"{t} : geste trop long « {g} »")
        if not x.get("answerStarter") or not x.get("tip"):
            pb.append(f"{t} : amorce ou astuce manquante")
        if x["tip"][:1].isupper():
            pb.append(f"{t} : l'astuce commence par une majuscule")
        if REGLE_ABSOLUE.search(x["tip"]) or REGLE_ABSOLUE.search(x["uniqueCriterion"]):
            pb.append(f"{t} : règle sociale absolue — l'usage se pose dans le contexte")
        # 5. les 3 references, graduees, dans la plage.
        niv = [r["level"] for r in x["references"]]
        if niv != NIVEAUX:
            pb.append(f"{t} : niveaux {niv}")
        for r in x["references"]:
            n = mots(r["text"])
            if not borne_min <= n <= borne_max:
                pb.append(f"{t} · {r['level']} : {n} mots hors de {borne_min}-{borne_max}")
            if not r["pedagogicalNote"].strip():
                pb.append(f"{t} · {r['level']} : note pédagogique vide")
        # 6b. EXCELLENT est plus PRECIS, jamais plus cérémonieux.
        #     La marche EXPECTED -> EXCELLENT doit venir de la précision, de la
        #     cohérence et de l'adaptation au destinataire — pas d'une formule
        #     de politesse de plus. Sans ce garde-fou, on apprendrait au
        #     candidat que « mieux » veut dire « plus formel », ce que le TCF
        #     ne demande nulle part.
        att = len(FORMULES.findall(x["references"][1]["text"]))
        exc = len(FORMULES.findall(x["references"][2]["text"]))
        if exc > att:
            pb.append(f"{t} : EXCELLENT accumule les formules ({exc} contre {att})")

        # 6. la production attendue est bien celle de la tache.
        if not profil["verbe"].search(x["instruction"]):
            pb.append(f"{t} : la consigne ne demande pas de {profil['verbe_dit']}")
        # 7. accents : un « a » isole ou un « e » final suspect trahit la saisie.
        joint = " ".join([x["context"], x["instruction"], x["uniqueCriterion"]]
                         + [r["text"] for r in x["references"]])
        if re.search(r"\b(a partir|deja|apres|tres|etre|meme|ou est)\b", joint):
            pb.append(f"{t} : accent manquant")
        titres.add(t); amorces.add(x["answerStarter"])
        diff[x["difficultyLevel"]] += 1

    if len(titres) != len(p): pb.append("titre en double")
    if len(amorces) != len(p): pb.append("amorce en double")
    # 8. variete : les objets ATTENDUS du lot, aucun au-dela de la moitie.
    #
    # ⚠️ Deux competences de la taxonomie V3 ont un perimetre volontairement
    # restreint — « Décrire une personne ou un groupe » (rang 5) et « Décrire
    # un lieu ou un objet » (rang 6). Leur imposer les quatre objets serait
    # leur demander de sortir de leur propre definition. Le lot le declare :
    # `objetsAttendus` dans le JSON, les quatre par defaut.
    attendus = set(d.get("objetsAttendus") or OBJETS.values())
    manquants = attendus - set(objets)
    if manquants:
        pb.append(f"objets attendus absents : {sorted(manquants)}")
    hors = set(objets) - attendus
    if hors:
        pb.append(f"objets hors du périmètre du lot : {sorted(hors)}")
    # Le plafond suit le nombre d'objets attendus : à deux, la moitié chacun
    # est l'équilibre, pas un déséquilibre.
    plafond = len(p) // 2 if len(attendus) > 2 else (len(p) * 2) // 3
    for o, n in objets.items():
        if n > plafond:
            pb.append(f"objet « {o} » sur {n} sujets : trop dominant (max {plafond})")
    if diff["HARD"] < 2 or diff["EASY"] < 2:
        pb.append(f"progression déséquilibrée : {dict(diff)}")

    print(f"── {d['skillCode']} · rang {d['rang']} — {d['titre']}")
    print(f"   tâche        : {tache} · {borne_min}-{borne_max} mots")
    print(f"   objets       : {dict(objets)}")
    print(f"   difficultés  : {dict(diff)}")
    longs = [mots(r["text"]) for x in p for r in x["references"]]
    print(f"   références   : {len(longs)} · {min(longs)}-{max(longs)} mots")
    if pb:
        print(f"   🔴 {len(pb)} problème(s) :")
        for m in pb: print(f"      - {m}")
        return 1
    print("   ✅ les huit contrôles passent")
    return 0

if __name__ == "__main__":
    sys.exit(max(controler(c) for c in (sys.argv[1:] or ["EE1-C2.json"])))
