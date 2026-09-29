#!/usr/bin/env python3
"""Produit les « Vous allez apprendre a : » des 48 competences d'expression.

    # 1. Estimer, sans rien appeler ni rien ecrire (defaut) :
    python3 tools/competences/generer_learning_points.py

    # 2. Apres feu vert explicite du proprietaire, et lui seul — GENERE et
    #    depose une REVUE, sans toucher au contenu :
    EVAL_DEEPSEEK_API_KEY=... python3 tools/competences/generer_learning_points.py --go

    # 3. Apres relecture et correction de la revue, et seulement la :
    python3 tools/competences/generer_learning_points.py --inject

🛑 TROIS ETAPES, ET LA RELECTURE EST AU MILIEU (arbitrage du proprietaire,
2026-09-12). `--go` n'ecrit RIEN dans contenu/*.json : il depose

    docs/learning_points_review.json   ← la SOURCE de l'injection, editable
    docs/learning_points_review.md     ← la meme chose, en lecture

groupees par tache puis par competence. On relit les 144 points, on corrige le
JSON, puis `--inject` les recopie dans les 6 fiches de contenu. Enchainer
generation et ecriture ferait entrer dans le seed une matiere que personne n'a
lue — or aucun controle automatique ne dit si un point est JUSTE.

Ensuite seulement : `generer_seed.py` emet la migration V319, et l'on porte
`EXPECTED_LEARNING_POINTS` a 48 dans `SkillSeedIT`, dans la MEME passe.

🛑 SANS `--go`, AUCUN APPEL RESEAU N'EST EMIS. C'est la regle du depot : aucune
mesure ni aucun script n'interroge un fournisseur payant sans demande explicite.
Le mode par defaut lit le contenu, construit les prompts reels, compte les
tokens et affiche le cout estime — c'est ce chiffre qu'on presente avant de
demander le feu vert.

POURQUOI UN LLM ICI, ALORS QUE LE CONTENU DU MODULE EST ECRIT A LA MAIN. Le
modele n'invente rien : il GENERALISE une matiere deja ecrite et deja validee.
Chaque appel recoit le titre de la competence, son explication, son critere
general, les 15 criteres uniques de ses sujets et leurs ~45 items de check-list.
Le style cible est demontre par des exemples tires de ces memes check-lists. Ce
qui reste a faire est une abstraction (« Saluez votre voisine » + « Ouvrez par
Bonjour Monsieur » -> « Saluer de facon adaptee »), pas une redaction.

🛑 ET LA SORTIE SE RELIT. Le script n'ecrit que ce que le contrat accepte
(exactement 3 points, 1 a 6 mots, jamais la prose de la competence recopiee), et
`generer_seed.py` revalide tout avant d'emettre la migration. Mais aucun de ces
controles ne dit si un point est JUSTE : c'est la relecture humaine qui le dit.
"""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

from vue_v3 import charger_v3

ICI = Path(__file__).resolve().parent
CONTENU = ICI / "contenu"
# tools/competences/ -> backend_sejourfr/ -> racine du depot
REVUE_JSON = ICI.parent.parent.parent / "docs/learning_points_review.json"
REVUE_MD = ICI.parent.parent.parent / "docs/learning_points_review.md"
POINTS_V3 = ICI / "contenu_v3/_learning_points.json"
TACHES = ["EE1", "EE2", "EE3", "EO1", "EO2", "EO3"]

# --- Contrat de sortie --------------------------------------------------------
# Les memes bornes que `generer_seed.valider_points`. Elles sont recopiees ici
# plutot qu'importees : ce script doit pouvoir tourner seul, et une divergence
# sera attrapee par la validation de `generer_seed.py`, qui refuse d'emettre.
POINTS = 3
MOTS_MAX = 6

# --- Fournisseur --------------------------------------------------------------
# Les memes defauts que `sejourfr.production-evaluation.deepseek` : correcteur en
# vigueur depuis le 2026-08-08, tarifs du bloc `cost-per-million-*`. Le prix
# voyage avec le modele, comme cote serveur — changer l'un sans l'autre
# afficherait un cout faux.
API_URL = "https://api.deepseek.com/chat/completions"
MODELE = os.environ.get("EVAL_DEEPSEEK_MODEL", "deepseek-v4-flash")
COUT_ENTREE_PAR_M = float(os.environ.get("EVAL_DEEPSEEK_COST_INPUT", "0.22"))
COUT_SORTIE_PAR_M = float(os.environ.get("EVAL_DEEPSEEK_COST_OUTPUT", "0.66"))

# Sortie attendue : un objet a une clé, trois chaines courtes. Un ordre de
# grandeur suffit pour l'estimation — la mesure reelle est publiee a la fin.
TOKENS_SORTIE_ESTIMES = 60

SYSTEME = """\
Tu rediges la rubrique « Vous allez apprendre a : » d'une micro-competence \
d'expression du TCF IRN.

Rends EXACTEMENT 3 points. Chaque point :
- est un GESTE a l'infinitif, pas une phrase et pas une consigne d'exercice ;
- fait 2 a 6 mots ;
- ne nomme AUCUN element d'un sujet precis (pas de voisine, de propriétaire, de \
prénom, de lieu) : il vaut pour les 15 sujets de la competence ;
- ne se termine pas par un point ;
- ne recopie ni l'explication ni le critere general qu'on te donne.

Les trois points se completent et ne se recouvrent pas. Ils vont du plus \
elementaire au plus fin.

Exemples du registre attendu (competence « Adapter le message au destinataire ») :
  Choisir tu ou vous
  Saluer de facon adaptee
  Rester dans le bon registre
"""


def demande(skill: dict) -> str:
    """Le message utilisateur : toute la matiere deja ecrite de la competence."""
    criteres = "\n".join(f"  - {p['uniqueCriterion']}" for p in skill["prompts"])
    gestes = "\n".join(
        f"  - {item}"
        for p in skill["prompts"]
        for item in (p.get("checklist") or [])
    )
    return (
        f"Competence : {skill['title']}\n"
        f"Palier : {skill['targetLevel']}\n\n"
        f"Explication :\n{skill['description']}\n\n"
        f"Critere general :\n{skill['generalCriterion']}\n\n"
        f"Criteres de ses {len(skill['prompts'])} petits sujets :\n{criteres}\n\n"
        f"Gestes demandes sur ces sujets (a generaliser, jamais a recopier) :\n{gestes}\n"
    )


SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "required": ["learning_points"],
    "properties": {
        "learning_points": {
            "type": "array",
            "minItems": POINTS,
            "maxItems": POINTS,
            "items": {"type": "string", "maxLength": 48},
        }
    },
}


def tokens(texte: str) -> int:
    """Ordre de grandeur, sans dependance.

    ~4 caracteres par token en francais. On n'installe pas un tokenizer pour
    une estimation qu'on publie explicitement comme telle — le cout REEL est
    recalcule depuis les compteurs du fournisseur apres la campagne.
    """
    return max(1, len(texte) // 4)


def charger() -> list[tuple[str, dict, dict]]:
    """(code de tache, en-tete de tache, competence) pour les 48 competences V3.

    🛑 La matiere vient de `vue_v3.charger_v3()`, jamais de `contenu/*.json`
    directement : les 19 competences recentrees ont un cadrage corrige, les 7
    creees n'existent pas encore dans `contenu/`, et les 7 retirees ne doivent
    surtout pas recevoir de points. La forme rendue reste celle de `contenu/`
    pour que `demande()` et `valider_sortie()` n'aient pas a changer.
    """
    entetes = {}
    for code in TACHES:
        doc = json.loads((CONTENU / f"{code}.json").read_text(encoding="utf-8"))
        entetes[code] = {"taskTitle": doc.get("taskTitle", code),
                         "taskTargetLevel": doc.get("taskTargetLevel", "")}
    out = []
    for s in charger_v3():
        out.append((s["tache"], entetes[s["tache"]], {
            "code": s["code"],
            "title": s["titre"],
            "description": s["description"],
            "generalCriterion": s["critere"],
            "targetLevel": s["targetLevel"],
            "prompts": s["prompts"],
        }))
    return out


def estimer(lot: list[tuple[str, dict, dict]]) -> tuple[int, int, float]:
    entree = sum(tokens(SYSTEME) + tokens(demande(s)) for _, _, s in lot)
    sortie = len(lot) * TOKENS_SORTIE_ESTIMES
    cout = entree / 1e6 * COUT_ENTREE_PAR_M + sortie / 1e6 * COUT_SORTIE_PAR_M
    return entree, sortie, cout


def valider_sortie(points: list[str], skill: dict) -> list[str]:
    """Le contrat, applique a la sortie du modele. Une sortie hors contrat est
    REFUSEE : on prefere une competence sans points a une carte qui redevient de
    la prose."""
    if not isinstance(points, list) or len(points) != POINTS:
        raise ValueError(f"{len(points) if isinstance(points, list) else '?'} points")
    propres = []
    for point in points:
        if not isinstance(point, str) or not point.strip():
            raise ValueError("point vide")
        texte = point.strip().rstrip(".")
        mots = len(texte.split())
        if not 1 <= mots <= MOTS_MAX:
            raise ValueError(f"« {texte} » fait {mots} mots")
        if texte.lower() in (skill["generalCriterion"].lower(), skill["description"].lower()):
            raise ValueError("point recopie de la prose de la competence")
        propres.append(texte)
    if len({p.lower() for p in propres}) != POINTS:
        raise ValueError("points en double")
    return propres


def appeler(skill: dict, cle: str) -> tuple[list[str], int, int]:
    corps = json.dumps({
        "model": MODELE,
        "temperature": 0,
        "thinking": {"type": "disabled"},
        "messages": [
            {"role": "system", "content": SYSTEME},
            {"role": "user", "content": demande(skill)},
        ],
        "tools": [{
            "type": "function",
            "function": {
                "name": "learning_points",
                "description": "Les 3 points d'apprentissage de la competence.",
                "parameters": SCHEMA,
            },
        }],
        "tool_choice": {"type": "function", "function": {"name": "learning_points"}},
    }).encode("utf-8")

    requete = urllib.request.Request(
        API_URL,
        data=corps,
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {cle}"},
    )
    with urllib.request.urlopen(requete, timeout=120) as reponse:
        charge = json.loads(reponse.read())

    usage = charge.get("usage", {})
    arguments = charge["choices"][0]["message"]["tool_calls"][0]["function"]["arguments"]
    points = json.loads(arguments)["learning_points"]
    return (valider_sortie(points, skill),
            usage.get("prompt_tokens", 0),
            usage.get("completion_tokens", 0))


def rendre_revue_md(revue: dict) -> str:
    """La revue, en lecture. 🛑 Le JSON reste la SOURCE : c'est lui qu'on corrige."""
    out: list[str] = []
    a = out.append
    a("# Revue — « Vous allez apprendre à : »")
    a("")
    a("🛑 **Ce fichier est une VUE. La source est"
      " `docs/learning_points_review.json`** — c'est lui qu'il faut corriger,")
    a("puis `python3 tools/competences/generer_learning_points.py --inject`.")
    a("")
    a(f"Modèle : `{revue['modele']}` · coût réel : **{revue['coutReelUsd']:.4f} $**"
      f" ({revue['tokensEntree']} entrée, {revue['tokensSortie']} sortie)")
    a("")
    a("Contrat : **exactement 3 points**, 1 à 6 mots, à l'infinitif, sans nommer"
      " d'élément d'un sujet précis.")
    a("Les contrôles n'ont vérifié que la **forme** — jamais la justesse.")
    a("")
    total = sum(len(t["competences"]) for t in revue["taches"])
    a_corriger = sum(1 for t in revue["taches"] for c in t["competences"]
                     if c.get("aCorrigerManuellement"))
    a(f"**{total - a_corriger} / {total} compétences** générées."
      + (f" ⚠️ **{a_corriger} à corriger à la main.**" if a_corriger else ""))
    a("")
    # 🛑 Sans cette ligne, la vue laisserait croire que ce qui suit est la
    # sortie du modele. Ce qui suit est ce que la RELECTURE a retenu.
    if revue.get("relecture"):
        a(f"🛑 **Relu et corrigé à la main :** {revue['relecture']}")
        a("")

    for tache in revue["taches"]:
        a(f"## {tache['taskCode']} — {tache['titre']} · palier {tache['palier']}")
        a("")
        for c in tache["competences"]:
            a(f"### `{c['code']}` — {c['titre']}")
            a(f"*Palier {c['palier']}*")
            a("")
            if c.get("aCorrigerManuellement"):
                a(f"> ⚠️ **À CORRIGER MANUELLEMENT** — {c['erreur']}")
                a(">")
                a("> Écrire les 3 points dans le JSON, puis `--inject`.")
            else:
                for point in c["learningPoints"]:
                    a(f"- {point}")
            a("")
    return "\n".join(out) + "\n"


def main() -> int:
    if "--inject" in sys.argv:
        return injecter()

    go = "--go" in sys.argv
    lot = charger()
    entree, sortie, cout = estimer(lot)

    print(f"Competences           : {len(lot)}")
    print(f"Modele                : {MODELE}")
    print(f"Tokens d'entree       : ~{entree:,}".replace(",", " "))
    print(f"Tokens de sortie      : ~{sortie:,}".replace(",", " "))
    print(f"Tarif                 : {COUT_ENTREE_PAR_M} $/M entree,"
          f" {COUT_SORTIE_PAR_M} $/M sortie")
    print(f"COUT ESTIME           : {cout:.4f} $")

    if not go:
        print("\n🛑 Aucun appel emis. Estimation seule.")
        print("   Relancer avec --go APRES feu vert explicite du proprietaire.")
        return 0

    cle = os.environ.get("EVAL_DEEPSEEK_API_KEY") or os.environ.get("DEEPSEEK_API_KEY")
    if not cle:
        print("\nEVAL_DEEPSEEK_API_KEY absente.", file=sys.stderr)
        return 1

    print()
    taches: dict[str, dict] = {}
    total_in = total_out = 0
    echecs = 0
    for code, doc, skill in lot:
        tache = taches.setdefault(code, {
            "taskCode": code,
            "titre": doc.get("taskTitle", code),
            "palier": doc.get("taskTargetLevel", ""),
            "competences": [],
        })
        entree_c = {
            "code": skill["code"],
            "titre": skill["title"],
            "palier": skill["targetLevel"],
        }
        try:
            points, t_in, t_out = appeler(skill, cle)
            total_in += t_in
            total_out += t_out
            entree_c["learningPoints"] = points
            print(f"  {skill['code']:<10} {' · '.join(points)}")
        except (urllib.error.URLError, KeyError, ValueError, json.JSONDecodeError) as cause:
            echecs += 1
            # 🛑 Une sortie hors contrat n'est pas ecrite : la competence est
            # MARQUEE, pour qu'elle se voie dans la revue au lieu de manquer.
            entree_c["learningPoints"] = []
            entree_c["aCorrigerManuellement"] = True
            entree_c["erreur"] = str(cause)
            print(f"  {skill['code']:<10} ⚠️  A CORRIGER — {cause}", file=sys.stderr)
        tache["competences"].append(entree_c)

    revue = {
        "modele": MODELE,
        "tokensEntree": total_in,
        "tokensSortie": total_out,
        "coutReelUsd": total_in / 1e6 * COUT_ENTREE_PAR_M
                       + total_out / 1e6 * COUT_SORTIE_PAR_M,
        "taches": [taches[c] for c in TACHES if c in taches],
    }
    REVUE_JSON.parent.mkdir(parents=True, exist_ok=True)
    REVUE_JSON.write_text(json.dumps(revue, ensure_ascii=False, indent=2) + "\n",
                          encoding="utf-8")
    REVUE_MD.write_text(rendre_revue_md(revue), encoding="utf-8")

    print(f"\nCout REEL : {revue['coutReelUsd']:.4f} $"
          f" ({total_in} entree, {total_out} sortie)")
    print(f"\nRevue deposee :\n  {REVUE_JSON}\n  {REVUE_MD}")
    if echecs:
        print(f"\n⚠️  {echecs} competence(s) a corriger a la main dans le JSON.",
              file=sys.stderr)
    print("\n🛑 Rien n'a ete ecrit dans le contenu.")
    print("   Relire les points, corriger le JSON de revue, puis :")
    print("   python3 tools/competences/generer_learning_points.py --inject")
    return 0


def injecter() -> int:
    """Recopie la revue RELUE dans les 6 fiches de contenu.

    🛑 Deuxieme etape, jamais enchainee a la premiere : la relecture humaine est
    entre les deux. Le contrat est revalide ici — une revue corrigee a la main
    peut avoir introduit un point trop long ou un doublon.
    """
    if not REVUE_JSON.exists():
        print(f"Revue introuvable : {REVUE_JSON}", file=sys.stderr)
        print("Lancer d'abord --go (apres feu vert).", file=sys.stderr)
        return 1

    revue = json.loads(REVUE_JSON.read_text(encoding="utf-8"))
    par_code = {c["code"]: c for t in revue["taches"] for c in t["competences"]}

    restants = [code for code, c in par_code.items()
                if c.get("aCorrigerManuellement") or len(c.get("learningPoints") or []) != POINTS]
    if restants:
        print(f"{len(restants)} competence(s) encore sans 3 points :", file=sys.stderr)
        for code in restants:
            print(f"  {code}", file=sys.stderr)
        print("\nRien n'a ete injecte — un seed a moitie rempli afficherait le"
              " bloc sur certaines fiches seulement.", file=sys.stderr)
        return 1

    points: dict[str, list[str]] = {}
    for _, _, skill in charger():
        entree = par_code.get(skill["code"])
        if entree is None:
            print(f"{skill['code']} absente de la revue.", file=sys.stderr)
            return 1
        points[skill["code"]] = valider_sortie(entree["learningPoints"], skill)

    POINTS_V3.write_text(json.dumps(points, ensure_ascii=False, indent=2) + "\n",
                         encoding="utf-8")
    print(f"{len(points)} competences ecrites dans {POINTS_V3}.")
    print("\n🛑 contenu/*.json N'A PAS ETE TOUCHE : V300-V317 sont deja appliquees.")
    print("\nSuite :")
    print("  python3 tools/competences/emettre_contenu_v3.py   # emet V320")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
