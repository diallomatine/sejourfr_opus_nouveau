#!/usr/bin/env python3
"""Taxonomie V3 des 48 competences — la table de transition, et son SQL.

Ce module porte UNE chose : le passage de la taxonomie publiee (V300-V317) a la
taxonomie V3 validee par le proprietaire le 2026-09-13
(`docs/taxonomie-competences-v3.md`).

    cd backend_sejourfr && python3 tools/competences/taxonomie_v3.py

Il ecrit `db/migration/300_tcf/competences/V319__tcf_competences_taxonomie_v3.sql`.

POURQUOI UNE MIGRATION DE TRANSITION, ET PAS UNE REGENERATION
--------------------------------------------------------------
V300-V317 sont **deja appliquees**. Les reecrire invaliderait leur somme de
controle Flyway sur toute base qui les a jouees, et effacerait l'historique des
candidats qui ont produit sur les competences retirees. On ajoute donc une
migration qui *transforme*, elle ne republie rien.

TROIS REGLES DURES
------------------
1. **On ne SUPPRIME jamais une competence** : `AdminSkillService.deleteSkill`
   le refuse deja (409) parce que la suppression emporterait les sujets en
   cascade, donc l'historique. Le geste est `is_active = false`.
2. **Desactiver ne libere PAS le rang** : `uq_skills_task_order` ne filtre pas
   `is_active`. Chaque competence retiree est donc **rangee au-dela de 8** (le
   CHECK va jusqu'a 50) pour liberer sa place.
3. **Le reordonnancement est possible en UNE transaction** parce que
   `uq_skills_task_order` est `DEFERRABLE INITIALLY DEFERRED` (V025) : les
   collisions transitoires ne sont verifiees qu'au COMMIT. Aucun rang
   « parking » n'est necessaire pour les echanges — seulement pour les sorties.
"""

from __future__ import annotations

import uuid
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
SORTIE = (
    RACINE
    / "src/main/resources/db/migration/300_tcf/competences"
    / "V319__tcf_competences_taxonomie_v3.sql"
)

# Namespace fige, identique a generer_seed.py : un identifiant de contenu reste
# stable d'un environnement a l'autre.
NS = uuid.UUID("6f2b1a54-9c3d-4e78-8a10-5e10c0de0001")

# Les lignes nees de la V3 portent leur propre horodatage : les lots precedents
# gardent le leur, sinon leurs migrations changeraient d'un octet.
HORODATAGE_V3 = "'2026-09-13 09:00:00+02'"


def uid(code: str) -> str:
    return str(uuid.uuid5(NS, f"skill:{code}"))


def q(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


# ---------------------------------------------------------------- la table V3
#
# `garde`    : la competence reste active, on ne touche qu'a son rang.
# `recentre` : titre et/ou critere changent (le contenu, lui, suit ailleurs).
# `cree`     : competence neuve, code neuf — jamais le code d'une retiree, qui
#              rattacherait un contenu neuf a l'historique d'une autre.
# `retire`   : `is_active = false` + rang range au-dela de 8.

GARDE, RECENTRE, CREE, RETIRE = "garde", "recentre", "cree", "retire"

TAXONOMIE: dict[str, list[dict]] = {
    "EE1": [
        {
            "verdict": RECENTRE,
            "code": "EE1-C2",
            "ordre": 1,
            "titre": "Répondre précisément à la demande du message",
            "description": "La tâche 1 part toujours d'un message reçu. Cette compétence entraîne la lecture de ce qu'il demande, et la réponse à cette demande-là — sans s'écarter vers ce qu'on aurait envie de raconter.",
            "critere": "Identifier ce que le message reçu demande, et y répondre sans s'écarter.",
        },
        {
            "verdict": RECENTRE,
            "code": "EE1-C1",
            "ordre": 2,
            "titre": "Adapter la réponse au destinataire",
            "description": "On ne répond pas de la même façon à un ami, à un voisin ou à un service. Cette compétence entraîne le choix du ton, du tutoiement ou du vouvoiement et des formules, que le TCF observe dès la première ligne.",
            "critere": "Choisir le ton, le tutoiement ou le vouvoiement et les formules qui conviennent à la personne qui a écrit.",
        },
        {
            "verdict": CREE,
            "code": "EE1-C9",
            "ordre": 3,
            "titre": "Identifier clairement ce qui est décrit",
            "description": "Avant de décrire, il faut dire de quoi on parle. Cette compétence entraîne l'annonce nette de ce que le message demande de décrire — une personne, un groupe, un lieu ou un objet — pour que le lecteur sache tout de suite de quoi il s'agit.",
            "critere": "Nommer sans ambiguïté la personne, le groupe, le lieu ou l'objet dont il est question.",
        },
        {
            "verdict": CREE,
            "code": "EE1-C10",
            "ordre": 4,
            "titre": "Sélectionner les caractéristiques pertinentes",
            "description": "En trente à soixante mots, on ne peut pas tout dire. Cette compétence entraîne le choix : retenir les quelques traits qui comptent pour celui qui lit, et laisser le reste de côté.",
            "critere": "Choisir les quelques traits qui comptent pour le lecteur, plutôt que d'énumérer tout ce qu'on pourrait dire.",
        },
        {
            "verdict": RECENTRE,
            "code": "EE1-C7",
            "ordre": 5,
            "titre": "Décrire une personne ou un groupe",
            "description": "Faire voir quelqu'un à quelqu'un d'autre : son aspect, son âge, son caractère, son rôle. Un groupe se décrit aussi — sa composition, son ambiance —, et c'est l'un des quatre objets que la tâche 1 peut demander.",
            "critere": "Donner l'aspect, l'âge, le caractère, le rôle, ou la composition et l'ambiance d'un groupe.",
        },
        {
            "verdict": CREE,
            "code": "EE1-C11",
            "ordre": 6,
            "titre": "Décrire un lieu ou un objet",
            "description": "Faire voir un endroit ou une chose à quelqu'un qui ne l'a pas sous les yeux. Cette compétence entraîne le vocabulaire de l'espace, de la forme, de la matière et de l'usage.",
            "critere": "Situer et caractériser un lieu ou un objet : aspect, taille, matière, ambiance, usage, état.",
        },
        {
            "verdict": RECENTRE,
            "code": "EE1-C3",
            "ordre": 7,
            "titre": "Donner des détails concrets et précis",
            "description": "Une description vague ne montre rien. Cette compétence entraîne l'appui sur des éléments vérifiables — une couleur, un nombre, un emplacement, un moment — plutôt que sur des adjectifs passe-partout.",
            "critere": "Appuyer la description sur des éléments vérifiables — couleur, nombre, emplacement, moment — plutôt que sur des mots vagues.",
        },
        {
            "verdict": RECENTRE,
            "code": "EE1-C8",
            "ordre": 8,
            "titre": "Relier les informations dans une description cohérente",
            "description": "Trente à soixante mots, c'est court : l'ordre des phrases fait la différence entre une description qui se suit et une liste de détails jetés. Cette compétence entraîne l'enchaînement et la clôture.",
            "critere": "Enchaîner les phrases dans un ordre lisible et refermer la description naturellement.",
        },
        {"verdict": RETIRE, "code": "EE1-C4", "ordre": 9,
         "motif": "Demander une information, une aide ou une autorisation n'est pas décrire. Acte transactionnel, hors du périmètre de la tâche 1 IRN — sa place est en EO2."},
        {"verdict": RETIRE, "code": "EE1-C5", "ordre": 10,
         "motif": "Inviter, proposer, accepter ou refuser : acte transactionnel du format TCF « tout public », sans rapport avec la description."},
        {"verdict": RETIRE, "code": "EE1-C6", "ordre": 11,
         "motif": "S'excuser n'est ni décrire une personne, ni un groupe, ni un lieu, ni un objet."},
    ],
    "EE2": [
        {"verdict": GARDE, "code": "EE2-C1", "ordre": 1},
        {
            "verdict": RECENTRE,
            "code": "EE2-C2",
            "ordre": 2,
            "titre": "Présenter la situation et les personnes",
            "description": "Après le repère de temps et de lieu, le lecteur a besoin de savoir avec qui l'on était et ce que l'on faisait. Cette compétence entraîne le cadre humain du récit, sans redire ce que la première phrase a déjà posé.",
            "critere": "Dire avec qui l'on était et ce que l'on faisait, sans redire le moment ni le lieu.",
        },
        {
            "verdict": RECENTRE,
            "code": "EE2-C3",
            "ordre": 3,
            "titre": "Utiliser les temps du passé de manière compréhensible",
            "description": "Un récit se tient au passé, et ce qui avance ne se dit pas comme ce qui décrit autour. Cette compétence entraîne cette distinction — sans imposer une forme grammaticale plutôt qu'une autre.",
            "critere": "Employer les temps du passé de manière cohérente pour distinguer les actions du contexte.",
        },
        {
            "verdict": CREE,
            "code": "EE2-C9",
            "ordre": 4,
            "titre": "Expliquer une action, un choix ou une réaction",
            "description": "Raconter ce qui s'est passé ne suffit pas : le candidat est officiellement évalué sur sa capacité à décrire, raconter ET expliquer. Cette compétence entraîne le pourquoi — du choix, du fait, ou de la réaction.",
            "critere": "Dire pourquoi on a fait cela, pourquoi c'est arrivé, ou pourquoi on a réagi ainsi.",
        },
        {"verdict": GARDE, "code": "EE2-C5", "ordre": 5},
        {"verdict": GARDE, "code": "EE2-C6", "ordre": 6},
        {"verdict": GARDE, "code": "EE2-C7", "ordre": 7},
        {
            "verdict": RECENTRE,
            "code": "EE2-C8",
            "ordre": 8,
            "titre": "Terminer par le résultat ou ce que cela a apporté",
            "description": "Un récit se referme. Cette compétence entraîne la dernière phrase — comment cela s'est terminé, ou ce que cela a changé — sans exiger un dénouement spectaculaire que la plupart des expériences quotidiennes n'ont pas.",
            "critere": "Dire comment la situation s'est terminée ou ce qu'elle a changé — un résultat spectaculaire n'est pas exigé.",
        },
        {"verdict": RETIRE, "code": "EE2-C4", "ordre": 9,
         "motif": "« Introduire un événement déclencheur » suppose un récit à péripétie, alors que la tâche 2 couvre aussi les activités quotidiennes et le compte rendu d'expérience."},
    ],
    "EE3": [
        {
            "verdict": RECENTRE,
            "code": "EE3-C1",
            "ordre": 1,
            "titre": "Exprimer une position claire",
            "description": "La tâche 3 demande un avis sur un lieu, un objet, une personne ou un groupe. Cette compétence entraîne la position identifiable, posée sur cet objet-là et pas sur un débat général.",
            "critere": "Répondre directement à la question posée sur ce lieu, cet objet, cette personne ou ce groupe, et rendre son avis identifiable.",
        },
        {"verdict": GARDE, "code": "EE3-C2", "ordre": 2},
        {"verdict": GARDE, "code": "EE3-C3", "ordre": 3},
        {"verdict": GARDE, "code": "EE3-C4", "ordre": 4},
        {
            "verdict": RECENTRE,
            "code": "EE3-C5",
            "ordre": 5,
            "titre": "Faire progresser son propos sans se répéter",
            "description": "En quarante à quatre-vingt-dix mots, on n'empile pas des arguments : on avance. Cette compétence entraîne l'idée qui fait progresser, sans quota d'arguments ni retour sur ce qui vient d'être dit.",
            "critere": "Apporter une idée nouvelle qui avance — sans quota d'arguments ni retour sur la précédente.",
        },
        {
            "verdict": CREE,
            "code": "EE3-C9",
            "ordre": 6,
            "titre": "Adapter son expression au destinataire et au contexte",
            "description": "On ne donne pas son avis de la même façon à un ami, à un voisin ou à un service. Cette compétence entraîne le choix du ton, du niveau de politesse et du vocabulaire — sans supposer que le contexte est forcément formel.",
            "critere": "Choisir le ton, le niveau de politesse et le vocabulaire qui conviennent à la personne et à la situation, familière ou non.",
        },
        {
            "verdict": RECENTRE,
            "code": "EE3-C7",
            "ordre": 7,
            "titre": "Nuancer ou reconnaître une limite",
            "description": "Reconnaître une exception ou un avis opposé sans renoncer à sa position : c'est le marqueur de niveau le plus rentable de la tâche 3. Cette compétence l'entraîne comme une possibilité, jamais comme un passage obligé.",
            "critere": "Pouvoir concéder une exception ou un avis opposé sans perdre sa position — une possibilité de haut niveau, jamais un passage obligé.",
        },
        {
            "verdict": RECENTRE,
            "code": "EE3-C8",
            "ordre": 8,
            "titre": "Enchaîner ses idées de façon cohérente",
            "description": "Ce qui se lit, en quatre-vingt-dix mots, c'est l'enchaînement — pas une conclusion de dissertation. Cette compétence entraîne les liens justes entre les idées, et une fin qui n'a pas besoin d'être annoncée.",
            "critere": "Relier les idées avec des connecteurs justes ; une conclusion formelle n'est pas exigée.",
        },
        {"verdict": RETIRE, "code": "EE3-C6", "ordre": 9,
         "motif": "La tâche 3 IRN ne demande ni de comparer deux documents, ni d'opposer systématiquement deux possibilités. Non structurante."},
    ],
    "EO1": [
        {"verdict": GARDE, "code": "EO1-C1", "ordre": 1},
        {"verdict": GARDE, "code": "EO1-C2", "ordre": 2},
        {"verdict": GARDE, "code": "EO1-C3", "ordre": 3},
        {"verdict": GARDE, "code": "EO1-C4", "ordre": 4},
        {"verdict": GARDE, "code": "EO1-C5", "ordre": 5},
        {
            "verdict": RECENTRE,
            "code": "EO1-C6",
            "ordre": 6,
            "titre": "Raconter brièvement une expérience passée",
            "description": "L'entretien dirigé porte surtout sur le présent, mais l'examinateur demande parfois un souvenir. Cette compétence entraîne le récit court — sans basculer dans le récit développé, qui est la tâche 2.",
            "critere": "Répondre à une question personnelle par un récit court, sans basculer dans le récit développé de la tâche 2.",
        },
        {"verdict": GARDE, "code": "EO1-C7", "ordre": 7},
        {"verdict": GARDE, "code": "EO1-C8", "ordre": 8},
    ],
    "EO2": [
        {"verdict": GARDE, "code": "EO2-C1", "ordre": 1},
        {"verdict": GARDE, "code": "EO2-C2", "ordre": 2},
        {
            "verdict": RECENTRE,
            "code": "EO2-C3",
            "ordre": 3,
            "titre": "Demander les informations et les conditions",
            "description": "Prix, horaire, documents, inscription, règles : tout ce qu'il faut savoir pour agir. Cette compétence réunit ce que deux compétences disaient séparément — demander un renseignement et demander une modalité sont le même geste.",
            "critere": "Obtenir ce qu'il faut savoir pour agir : prix, horaire, lieu, durée, documents, inscription, règles, services inclus.",
        },
        {
            "verdict": CREE,
            "code": "EO2-C9",
            "ordre": 4,
            "titre": "Réagir à une réponse ou une contrainte imprévue",
            "description": "Dans une vraie interaction, l'interlocuteur dit souvent non, ou répond à côté. Cette compétence entraîne la suite de l'échange : insister poliment, proposer une autre solution, s'adapter sans se bloquer.",
            "critere": "Poursuivre l'échange quand la réponse n'est pas celle attendue : insister poliment, proposer une autre solution, s'adapter.",
        },
        {"verdict": GARDE, "code": "EO2-C5", "ordre": 5},
        {"verdict": GARDE, "code": "EO2-C6", "ordre": 6},
        {
            "verdict": RECENTRE,
            "code": "EO2-C7",
            "ordre": 7,
            "titre": "Explorer plusieurs possibilités",
            "description": "Interroger les options et leurs différences fait partie de l'obtention d'informations. Trancher, non : l'objectif officiel de la tâche 2 est d'obtenir, pas de choisir.",
            "critere": "Interroger plusieurs options et leurs différences — trancher n'est pas exigé.",
        },
        {"verdict": GARDE, "code": "EO2-C8", "ordre": 8},
        {"verdict": RETIRE, "code": "EO2-C4", "ordre": 9,
         "motif": "« Demander les conditions et les modalités » disait la même chose que « Demander des informations pratiques ». Fondue dans le rang 3 ; la place libérée va à l'interaction imprévue."},
    ],
    "EO3": [
        {
            "verdict": RECENTRE,
            "code": "EO3-C1",
            "ordre": 1,
            "titre": "Annoncer une position claire",
            "description": "La tâche 3 pose une question et attend un avis. Cette compétence entraîne la position identifiable — sans exiger un temps de réaction que notre correcteur, qui travaille sur la transcription, ne mesure pas.",
            "critere": "Répondre clairement à la question et rendre son opinion identifiable.",
        },
        {
            "verdict": RECENTRE,
            "code": "EO3-C8",
            "ordre": 2,
            "titre": "Tenir un discours continu et organisé",
            "description": "C'est la caractéristique explicite de la tâche 3 orale, et ce qui la distingue le plus de l'écrit : parler de manière continue. Cette compétence entraîne le propos suivi, nourri et lié — remontée au rang 2 pour cette raison.",
            "critere": "Développer un propos suivi, organisé et suffisamment nourri, avec des reprises et des liens clairs entre les idées.",
        },
        {"verdict": GARDE, "code": "EO3-C2", "ordre": 3},
        {"verdict": GARDE, "code": "EO3-C3", "ordre": 4},
        {"verdict": GARDE, "code": "EO3-C4", "ordre": 5},
        {
            "verdict": RECENTRE,
            "code": "EO3-C5",
            "ordre": 6,
            "titre": "Enchaîner une idée nouvelle",
            "description": "À l'oral, l'enjeu n'est pas de compter les arguments mais de faire avancer le propos. Cette compétence entraîne l'idée qui ajoute, sans quota ni retour sur la précédente.",
            "critere": "Apporter une idée qui fait avancer le propos, sans quota d'arguments ni retour sur la précédente.",
        },
        {
            "verdict": CREE,
            "code": "EO3-C9",
            "ordre": 7,
            "titre": "Reformuler pour relancer son propos",
            "description": "À l'oral, on se reprend. Cette compétence entraîne la reformulation utile : redire autrement pour préciser ou repartir, au lieu de tourner en rond sur la même idée. Elle est lisible dans une transcription, contrairement au débit ou aux pauses.",
            "critere": "Reprendre autrement ce que l'on vient de dire pour préciser ou repartir, au lieu de tourner en rond.",
        },
        {
            "verdict": RECENTRE,
            "code": "EO3-C7",
            "ordre": 8,
            "titre": "Nuancer ou reconnaître une limite",
            "description": "Introduire une réserve ou une concession sans perdre sa position : réellement B2, et parfaitement tenable à l'oral.",
            "critere": "Introduire une réserve, une concession ou une exception sans perdre sa position.",
        },
        {"verdict": RETIRE, "code": "EO3-C6", "ordre": 9,
         "motif": "Décalque de EE3-C6, non structurante à l'oral. Remplacée par une compétence mesurable dans la transcription (EO3-C9)."},
    ],
}

# Palier pedagogique interne de chaque competence creee. 🛑 Ce n'est PAS un
# referentiel officiel : France Education international ne rattache aucun niveau
# CECRL a une tache. Les ecrans disent « Niveau vise ».
NIVEAU_CREEES = {
    "EE1-C9": "A2",
    "EE1-C10": "A2",
    "EE1-C11": "A2",
    "EE2-C9": "B1",
    "EE3-C9": "B2",
    "EO2-C9": "B1",
    "EO3-C9": "B2",
}


def sql() -> str:
    lignes: list[str] = []
    a = lignes.append

    a("-- " + "=" * 74)
    a("-- V319 — Taxonomie V3 des 48 competences d'expression")
    a("--")
    a("-- Passage de la taxonomie publiee (V300-V317) a la taxonomie V3, validee")
    a("-- par le proprietaire le 2026-09-13. Reference : docs/taxonomie-competences-v3.md")
    a("--")
    a("-- FICHIER GENERE — NE PAS EDITER A LA MAIN.")
    a("--   cd backend_sejourfr && python3 tools/competences/taxonomie_v3.py")
    a("--")
    a("-- 7 competences RETIREES (is_active = false, rang range au-dela de 8),")
    a("-- 7 CREEES, 19 RECENTREES (titre et/ou critere), 1 tache reordonnee (EO3).")
    a("-- Les 48 rangs actifs restent 48.")
    a("--")
    a("-- 🛑 AUCUNE SUPPRESSION. Une competence sur laquelle un candidat a produit")
    a("-- emporterait ses sujets en cascade, donc son historique. Le geste est la")
    a("-- DESACTIVATION : elle sort du catalogue, tout est conserve.")
    a("--")
    a("-- 🛑 Desactiver ne libere PAS le rang : uq_skills_task_order ne filtre pas")
    a("-- is_active. Chaque retiree est donc rangee au-dela de 8 (le CHECK va")
    a("-- jusqu'a 50), sinon la place ne serait pas reutilisable.")
    a("--")
    a("-- Le reordonnancement tient en UNE transaction : uq_skills_task_order est")
    a("-- DEFERRABLE INITIALLY DEFERRED (V025), donc les collisions transitoires ne")
    a("-- sont verifiees qu'au COMMIT.")
    a("--")
    a("-- 🛑 Les competences CREEES portent un code NEUF (C9, C10, C11) — jamais")
    a("-- celui d'une retiree, qui rattacherait un contenu neuf a l'historique")
    a("-- d'une autre compétence.")
    a("--")
    a("-- ⚠️ Leurs SUJETS arrivent par une migration separee : une competence sans")
    a("-- petit sujet s'affiche a zero, elle ne casse rien.")
    a("-- " + "=" * 74)
    a("")

    # 1. Sorties d'abord : elles liberent les rangs que la suite va occuper.
    a("-- " + "-" * 74)
    a("-- 1. Les 7 competences RETIREES — desactivees et rangees au-dela de 8.")
    a("-- " + "-" * 74)
    a("")
    for tache, entrees in TAXONOMIE.items():
        for e in (x for x in entrees if x["verdict"] == RETIRE):
            a(f"-- {e['code']} — {e['motif']}")
            a("UPDATE skills")
            a(f"   SET is_active = false, display_order = {e['ordre']}, updated_at = {HORODATAGE_V3}")
            a(f" WHERE code = {q(e['code'])};")
            a("")

    # 2. Recentrages et reordonnancements sur les lignes qui restent.
    a("-- " + "-" * 74)
    a("-- 2. Les 19 competences RECENTREES et les rangs qui bougent.")
    a("--")
    a("-- Un titre ou un critere qui change ne change PAS l'identite de la ligne :")
    a("-- ses sujets, ses references et les observations des candidats restent")
    a("-- attaches. Le contenu qui ne correspondrait plus est repris ailleurs.")
    a("-- " + "-" * 74)
    a("")
    for tache, entrees in TAXONOMIE.items():
        actifs = [x for x in entrees if x["verdict"] in (GARDE, RECENTRE)]
        if not any(x["verdict"] == RECENTRE for x in actifs):
            continue
        a(f"-- --- {tache} " + "-" * (70 - len(tache)))
        for e in actifs:
            if e["verdict"] == GARDE:
                continue
            a(f"-- {e['code']} → « {e['titre']} » (rang {e['ordre']})")
            a("UPDATE skills")
            a(f"   SET title = {q(e['titre'])},")
            a(f"       description = {q(e['description'])},")
            a(f"       general_criterion = {q(e['critere'])},")
            a(f"       display_order = {e['ordre']},")
            a(f"       updated_at = {HORODATAGE_V3}")
            a(f" WHERE code = {q(e['code'])};")
            a("")

    # Rangs des GARDE qui bougent quand meme (EO3 reordonnee).
    bouges: list[tuple[str, str, int]] = []
    for tache, entrees in TAXONOMIE.items():
        for e in entrees:
            if e["verdict"] != GARDE:
                continue
            rang_origine = int(e["code"].split("-C")[1])
            if rang_origine != e["ordre"]:
                bouges.append((tache, e["code"], e["ordre"]))
    if bouges:
        a("-- Rangs qui bougent sans que le texte change (EO3 est reordonnee : sa")
        a("-- compétence de continuité remonte du rang 8 au rang 2).")
        for _, code, ordre in bouges:
            a("UPDATE skills")
            a(f"   SET display_order = {ordre}, updated_at = {HORODATAGE_V3}")
            a(f" WHERE code = {q(code)};")
        a("")

    # 3. Creations.
    a("-- " + "-" * 74)
    a("-- 3. Les 7 competences CREEES.")
    a("--")
    a("-- UUID deterministes (uuid5 sur le code metier), meme namespace que")
    a("-- generer_seed.py : l'identifiant est le meme sur toutes les bases.")
    a("-- " + "-" * 74)
    a("")
    a("INSERT INTO skills (id, section, task_code, code, title, description,")
    a("                    general_criterion, target_level, display_order, is_active,")
    a("                    created_at, updated_at)")
    a("VALUES")
    valeurs: list[str] = []
    for tache, entrees in TAXONOMIE.items():
        section = tache[:2]
        for e in (x for x in entrees if x["verdict"] == CREE):
            valeurs.append(
                f"  -- {e['code']} — {e['titre']}\n"
                f"  ('{uid(e['code'])}', '{section}', '{tache}', {q(e['code'])}, {q(e['titre'])},\n"
                f"   {q(e['description'])},\n"
                f"   {q(e['critere'])},\n"
                f"   '{NIVEAU_CREEES[e['code']]}', {e['ordre']}, true, {HORODATAGE_V3}, {HORODATAGE_V3})"
            )
    a(",\n".join(valeurs) + ";")
    a("")

    # 4. Filet.
    a("-- " + "-" * 74)
    a("-- 4. Filet : exactement 8 competences ACTIVES par tache, rangs 1 a 8.")
    a("--")
    a("-- La regle produit est verrouillee par SkillSeedIT ; ce bloc la verifie")
    a("-- aussi a l'application, pour qu'une migration incomplete ne passe pas.")
    a("-- " + "-" * 74)
    a("DO $$")
    a("DECLARE")
    a("  mauvaise text;")
    a("BEGIN")
    a("  SELECT string_agg(task_code || ' (' || n || ')', ', ')")
    a("    INTO mauvaise")
    a("    FROM (SELECT task_code, count(*) AS n FROM skills")
    a("           WHERE is_active GROUP BY task_code) t")
    a("   WHERE n <> 8;")
    a("  IF mauvaise IS NOT NULL THEN")
    a("    RAISE EXCEPTION 'Taxonomie V3 : taches sans 8 competences actives : %', mauvaise;")
    a("  END IF;")
    a("")
    a("  SELECT string_agg(code || ' (rang ' || display_order || ')', ', ')")
    a("    INTO mauvaise")
    a("    FROM skills")
    a("   WHERE is_active AND display_order NOT BETWEEN 1 AND 8;")
    a("  IF mauvaise IS NOT NULL THEN")
    a("    RAISE EXCEPTION 'Taxonomie V3 : competences actives hors des rangs 1-8 : %', mauvaise;")
    a("  END IF;")
    a("END $$;")
    a("")
    return "\n".join(lignes)


def verifier() -> None:
    """Le contrat de la table, avant meme d'ecrire une ligne de SQL."""
    total_actifs = crees = retires = recentres = 0
    for tache, entrees in TAXONOMIE.items():
        actifs = [e for e in entrees if e["verdict"] != RETIRE]
        rangs = sorted(e["ordre"] for e in actifs)
        assert rangs == list(range(1, 9)), f"{tache} : rangs actifs {rangs}"
        sortis = sorted(e["ordre"] for e in entrees if e["verdict"] == RETIRE)
        assert all(r > 8 for r in sortis), f"{tache} : une retiree occupe un rang legal"
        assert len(set(sortis)) == len(sortis), f"{tache} : deux retirees au meme rang"
        codes = [e["code"] for e in entrees]
        assert len(set(codes)) == len(codes), f"{tache} : code en double"
        total_actifs += len(actifs)
        crees += sum(1 for e in entrees if e["verdict"] == CREE)
        retires += sum(1 for e in entrees if e["verdict"] == RETIRE)
        recentres += sum(1 for e in entrees if e["verdict"] == RECENTRE)
    assert total_actifs == 48, total_actifs
    assert crees == retires == 7, (crees, retires)
    assert set(NIVEAU_CREEES) == {
        e["code"] for entrees in TAXONOMIE.values() for e in entrees if e["verdict"] == CREE
    }
    print(f"Contrat V3 : {total_actifs} actives, {crees} creees, {retires} retirees, {recentres} recentrees.")


def main() -> None:
    verifier()
    SORTIE.write_text(sql(), encoding="utf-8")
    print(f"Ecrit {SORTIE.relative_to(RACINE)}")


if __name__ == "__main__":
    main()
