#!/usr/bin/env python3
"""Convertit les 6 fichiers de contenu JSON en migrations Flyway de seed.

    python3 tools/competences/generer_seed.py

Trois fichiers SQL par tache TCF (EE1..EO3), deposes dans
src/main/resources/db/migration/300_tcf/competences/ :

    V300..V305  lot 1 — competences + sujets 1 a 5 + leurs references
    V306..V311  lot 1 — guidage de saisie de ces memes sujets (UPDATE)
    V312..V317  lot 2 — sujets 6 a 15 + leurs references, guidage compris

DEUX LOTS, ET POURQUOI. Une competence porte 15 petits sujets. Les cinq
premiers ont ete publies par V300-V311, migrations DEJA APPLIQUEES — y compris
sur la base de developpement du projet. Les regenerer avec dix sujets de plus
changerait leur contenu et invaliderait leur somme de controle Flyway partout
ou elles ont ete jouees. Le lot 2 est donc un AJOUT dans des migrations neuves,
jamais une reecriture : le generateur repartit les sujets par displayOrder
(<= 5 au lot 1, >= 6 au lot 2) et la sortie du lot 1 doit rester identique au
bit pres. Le lot 2 n'insere aucune ligne dans `skills` (les 48 competences
existent depuis V300-V305) et renseigne directement les colonnes de guidage de
V026, sans l'UPDATE separe qu'imposaient V306-V311 pour des lignes deja en base.

CE GENERATEUR EST LA SOURCE DE VERITE DU CONTENU PUBLIE. Les migrations sont
produites, jamais ecrites a la main : pour corriger un sujet ou une reference,
on edite le JSON de contenu/ puis on rejoue ce script. Editer le SQL directement
ferait diverger les deux, et la prochaine regeneration ecraserait la correction.

(Le contenu vivant, lui, s'edite depuis la console d'administration une fois les
migrations appliquees. Ce generateur ne sert plus qu'a republier depuis zero ou
a repartir d'une base propre.)

Les UUID sont DETERMINISTES (uuid5 sur le code metier) : rejouer le generateur
produit exactement le meme SQL, et un identifiant de contenu reste stable d'un
environnement a l'autre. C'est la convention des seeds de contenu du projet.

Le script VALIDE avant d'ecrire (8 competences par tache, 15 sujets par
competence aux rangs 1 a 15, 3 references par sujet aux trois niveaux, coherence
EE/EO mots-vs-duree, guidage complet, codes uniques, et unicite editoriale des
titres et des mises en situation au sein d'une tache) et refuse de produire du
SQL sur du contenu non conforme — sauf sur une collision dont les deux sujets
appartiennent au lot 1 deja publie, qu'il se contente de signaler puisqu'elle
n'est plus corrigeable sans reecrire une migration appliquee.
"""

from __future__ import annotations

import itertools
import json
import re
import sys
import unicodedata
import uuid
from pathlib import Path

ICI = Path(__file__).resolve().parent
CONTENU = ICI / "contenu"
# tools/competences/ -> backend_sejourfr/ -> src/main/resources/...
CIBLE = ICI.parent.parent / "src/main/resources/db/migration/300_tcf/competences"

# Namespace fige : ne JAMAIS le changer, sinon tous les UUID de contenu bougent.
NS = uuid.UUID("6f2b1a54-9c3d-4e78-8a10-5e10c0de0001")

# Sous-plage V300-V399, entierement libre avant ce module (la centaine 300 ne
# portait AUCUNE migration). Les seeds ont d'abord ete numerotes V878-V883, ce
# qui empietait sur la plage des brouillons audio CO b2 (V860-V899) et ne lui
# laissait que 6 numeros. Ici, 94 numeros restent disponibles pour enrichir le
# contenu des competences sans marcher sur une autre famille.
TACHES = [
    ("EE1", 300, "Ecrire un message court"),
    ("EE2", 301, "Raconter une experience"),
    ("EE3", 302, "Donner son opinion"),
    ("EO1", 303, "Entretien dirige : parler de soi"),
    ("EO2", 304, "Jeu de role : demander et obtenir des informations"),
    ("EO3", 305, "Exprimer et developper un point de vue"),
]

HORODATAGE = "'2026-08-06 09:00:00+02'"

# Horodatage propre au lot 2 : ces lignes-la naissent le jour ou l'on porte les
# competences de 5 a 15 sujets. Le lot 1 garde le sien, sinon V300-V311
# changeraient d'un octet et perdraient leur somme de controle Flyway.
HORODATAGE_LOT2 = "'2026-08-10 09:00:00+02'"

# Migrations de MISE A JOUR du guidage de l'ecran de saisie (checklist, etiquettes
# de contrainte, amorce, astuce). Elles sont separees des inserts V300-V305 parce
# que ceux-ci sont deja APPLIQUES : y toucher invaliderait leur somme de controle
# Flyway sur toute base qui les a joues.
TACHES_GUIDAGE = [(code, 306 + i, titre) for i, (code, _, titre) in enumerate(TACHES)]

# Lot 2 : les sujets 6 a 15, apparus quand chaque competence est passee de 5 a
# 15 petits sujets. Migrations NEUVES pour la meme raison que ci-dessus — on
# n'enrichit pas une migration deja jouee, on en ajoute une.
TACHES_LOT2 = [(code, 312 + i, titre) for i, (code, _, titre) in enumerate(TACHES)]

# Nombre de sujets par competence, et frontiere entre les deux lots.
SUJETS_PAR_COMPETENCE = 15
DERNIER_SUJET_LOT1 = 5

# Liste fermee des icones d'etiquette. Les deux fronts la mappent sur une icone
# Lucide ; une valeur hors liste ferait tomber l'affichage sur l'icone par defaut,
# donc on la refuse a la generation plutot qu'a l'execution.
ICONES = {
    "TONE",
    "PERSON",
    "TIME",
    "PLACE",
    "NUMBER",
    "TENSE",
    "STRUCTURE",
    "EXAMPLE",
}


def uid(kind: str, code: str) -> str:
    return str(uuid.uuid5(NS, f"{kind}:{code}"))


def q(value: str | None) -> str:
    """Litteral SQL texte, apostrophes echappees a la mode Postgres."""
    if value is None:
        return "NULL"
    return "'" + value.replace("'", "''") + "'"


def n(value: int | None) -> str:
    return "NULL" if value is None else str(value)


def doc_du_lot(doc: dict, lot: int) -> dict:
    """Vue du contenu restreinte a un lot, dans l'ordre du fichier.

    Le lot 1 (displayOrder <= 5) alimente V300-V311, le lot 2 (>= 6) alimente
    V312-V317. L'ordre des sujets n'est pas retrie : le SQL du lot 1 doit sortir
    identique au bit pres a celui deja applique.
    """
    garde = (
        (lambda p: p["displayOrder"] <= DERNIER_SUJET_LOT1)
        if lot == 1
        else (lambda p: p["displayOrder"] > DERNIER_SUJET_LOT1)
    )
    return {
        **doc,
        "skills": [{**s, "prompts": [p for p in s["prompts"] if garde(p)]} for s in doc["skills"]],
    }


def _normaliser(texte: str) -> str:
    """Forme comparable d'un texte editorial : minuscules, accents replies,
    ponctuation et espaces multiples ecrases. Deux phrases qui ne different que
    par une virgule ou une majuscule sont le meme sujet."""
    plie = unicodedata.normalize("NFD", texte.lower())
    plie = "".join(c for c in plie if unicodedata.category(c) != "Mn")
    return re.sub(r"[^0-9a-z]+", " ", plie).strip()


def _trigrammes(texte: str) -> set[str]:
    rembourre = "  " + texte + " "
    return {rembourre[i : i + 3] for i in range(len(rembourre) - 2)}


def _similarite(a: str, b: str) -> float:
    """Similarite de trigrammes (Jaccard), comme pg_trgm."""
    ta, tb = _trigrammes(a), _trigrammes(b)
    union = ta | tb
    return len(ta & tb) / len(union) if union else 1.0


# Seuil au-dela duquel deux mises en situation racontent la meme chose. 0.85 est
# tres haut : deux phrases qui ne different que par un mot outil le depassent,
# deux mots de contenu changes retombent nettement en dessous.
SEUIL_QUASI_DOUBLON = 0.85


def _reparable(a: dict, b: dict) -> bool:
    """Une collision n'est corrigeable que si un des deux sujets est du lot 2.

    Ce n'est pas de la complaisance, c'est Flyway : les sujets 1 a 5 sont
    publies par V300-V305, migrations DEJA APPLIQUEES. Reecrire l'une d'elles
    pour departager deux sujets du lot 1 invaliderait sa somme de controle sur
    toute base qui l'a jouee — le passe n'est pas reparable. Deux collisions
    reelles vivent dans ce cas (EE1-C5-S3 ⇄ EE1-C5-S5, EO1-C2-S3 ⇄ EO1-C3-S2) :
    on les SIGNALE pour qu'un futur lot 3 ne les reproduise pas, on ne bloque
    pas dessus. Des qu'un sujet du lot 2 est implique, la correction ne coute
    qu'une edition du JSON de contenu : la collision redevient fatale.
    """
    return max(a["displayOrder"], b["displayOrder"]) > DERNIER_SUJET_LOT1


def _signaler(message: str) -> None:
    print(f"AVERTISSEMENT — {message}", file=sys.stderr)


def valider_unicite_editoriale(doc: dict, code_tache: str) -> None:
    """Refuse deux sujets qui racontent la meme chose au sein d'une meme tache.

    Un candidat qui enchaine 15 sujets d'une competence doit rencontrer 15
    situations differentes : un titre ou une mise en situation recopies d'un
    sujet a l'autre donnent l'impression de refaire le meme exercice.

    L'`instruction`, elle, n'est PAS soumise a l'unicite — mesure faite sur les
    720 sujets : 21 groupes partagent une consigne normalisee identique, dans 5
    taches sur 6. C'est la nature de l'objet, pas un defaut : une competence
    entraine UN geste, et la phrase qui decrit ce geste se formule naturellement
    pareil d'un sujet a l'autre (« Illustrez cet argument par un exemple
    concret… »). Ce qui distingue deux sujets, c'est la situation, pas le verbe
    de la consigne — exiger 15 paraphrases du meme ordre degraderait la clarte.
    """
    sujets = [p for s in doc["skills"] for p in s["prompts"]]

    for champ, libelle in (
        ("title", "le meme titre"),
        ("context", "la meme mise en situation"),
    ):
        vus: dict[str, dict] = {}
        for p in sujets:
            cle = _normaliser(p[champ])
            precedent = vus.get(cle)
            if precedent is not None:
                probleme = (
                    f"{code_tache} : {precedent['code']} et {p['code']} portent {libelle}"
                    f" — « {p[champ]} »"
                )
                if _reparable(precedent, p):
                    raise AssertionError(probleme)
                _signaler(probleme + " (lot 1 deja publie — non corrigeable)")
                continue
            vus[cle] = p

    for a, b in itertools.combinations(sujets, 2):
        score = _similarite(_normaliser(a["context"]), _normaliser(b["context"]))
        if score < SEUIL_QUASI_DOUBLON:
            continue
        probleme = (
            f"{code_tache} : {a['code']} et {b['code']} racontent la meme mise en"
            f" situation (similarite {score:.2f} >= {SEUIL_QUASI_DOUBLON})\n"
            f"  {a['code']} : {a['context']}\n"
            f"  {b['code']} : {b['context']}"
        )
        if _reparable(a, b):
            raise AssertionError(probleme)
        _signaler(probleme + "\n  (lot 1 deja publie — non corrigeable)")


def valider(doc: dict, code_tache: str) -> None:
    """Refuse un contenu non conforme au contrat plutot que de seeder du faux."""
    assert doc["taskCode"] == code_tache, f"{code_tache}: taskCode={doc['taskCode']}"
    section = doc["section"]
    assert section in ("EE", "EO"), section
    assert code_tache.startswith(section), f"{code_tache} incoherent avec {section}"
    skills = doc["skills"]
    assert len(skills) == 8, f"{code_tache}: {len(skills)} competences au lieu de 8"

    ordres = set()
    for skill in skills:
        assert skill["code"].startswith(code_tache + "-C"), skill["code"]
        assert 1 <= skill["displayOrder"] <= 8, skill["code"]
        assert skill["displayOrder"] not in ordres, f"displayOrder double {skill['code']}"
        ordres.add(skill["displayOrder"])
        assert skill["targetLevel"] in ("A1", "A2", "B1", "B2"), skill["code"]
        for champ in ("title", "description", "generalCriterion"):
            assert skill[champ].strip(), f"{skill['code']}.{champ} vide"
        # Le critere general et l'explication sont deux textes DISTINCTS (spec §3,
        # niveau 4) : les confondre etait le defaut du contrat gele initial.
        assert skill["generalCriterion"] != skill["description"], skill["code"]

        prompts = skill["prompts"]
        assert len(prompts) == SUJETS_PAR_COMPETENCE, (
            f"{skill['code']}: {len(prompts)} sujets au lieu de {SUJETS_PAR_COMPETENCE}"
        )
        ordres_p = set()
        for p in prompts:
            assert p["code"].startswith(skill["code"] + "-S"), p["code"]
            # La borne DB va jusqu'a 20 ; le contenu publie, lui, en compte
            # exactement 15, sans trou ni doublon de rang — c'est ce qui repartit
            # proprement les sujets entre le lot 1 (1-5) et le lot 2 (6-15).
            assert 1 <= p["displayOrder"] <= 20, p["code"]
            assert p["displayOrder"] not in ordres_p, f"displayOrder double {p['code']}"
            ordres_p.add(p["displayOrder"])
            assert p["difficultyLevel"] in ("EASY", "MEDIUM", "HARD"), p["code"]
            for champ in ("title", "context", "instruction", "uniqueCriterion"):
                assert p[champ].strip(), f"{p['code']}.{champ} vide"

            mn, mx, dur = (
                p["recommendedMinWords"],
                p["recommendedMaxWords"],
                p["recommendedDurationSeconds"],
            )
            if section == "EE":
                assert mn is not None and mx is not None and dur is None, p["code"]
                assert mn < mx, f"{p['code']}: {mn} >= {mx}"
            else:
                assert dur is not None and mn is None and mx is None, p["code"]
                assert 15 <= dur <= 90, f"{p['code']}: duree {dur}"

            # Guidage de l'ecran de saisie. La check-list DECOUPE la consigne en
            # gestes, elle n'ajoute aucune exigence ; les etiquettes disent
            # comment produire, jamais combien (la longueur/duree est rendue par
            # le front depuis les bornes, la dupliquer ici la ferait diverger).
            liste = p["checklist"]
            assert 2 <= len(liste) <= 4, f"{p['code']}: {len(liste)} items de check-list"
            for item in liste:
                assert 1 <= len(item.split()) <= 6, f"{p['code']}: « {item} »"
            tags = p["constraintTags"]
            assert 1 <= len(tags) <= 3, f"{p['code']}: {len(tags)} etiquettes"
            for tag in tags:
                assert tag["icon"] in ICONES, f"{p['code']}: icone {tag['icon']}"
                assert 1 <= len(tag["label"].split()) <= 3, f"{p['code']}: {tag['label']}"
                interdit = "mot" if section == "EE" else "seconde"
                assert interdit not in tag["label"].lower(), f"{p['code']}: {tag['label']}"
            amorce = p["answerStarter"]
            assert amorce.endswith("…"), f"{p['code']}: amorce sans points de suspension"
            assert 4 <= len(amorce.split()) <= 9, f"{p['code']}: amorce {len(amorce.split())} mots"
            astuce = p["tip"]
            assert astuce.strip(), f"{p['code']}: astuce vide"
            assert len(astuce.split()) <= 15, f"{p['code']}: astuce {len(astuce.split())} mots"
            assert not astuce.lower().startswith("astuce"), f"{p['code']}: « Astuce : » en dur"

            refs = p["references"]
            assert len(refs) == 3, f"{p['code']}: {len(refs)} references"
            niveaux = {r["level"] for r in refs}
            assert niveaux == {"INSUFFICIENT", "EXPECTED", "EXCELLENT"}, p["code"]
            for r in refs:
                assert r["text"].strip(), f"{p['code']}/{r['level']} texte vide"
                assert r["pedagogicalNote"].strip(), f"{p['code']}/{r['level']} note vide"

        attendus = set(range(1, SUJETS_PAR_COMPETENCE + 1))
        assert ordres_p == attendus, (
            f"{skill['code']}: rangs {sorted(ordres_p)} au lieu de 1..{SUJETS_PAR_COMPETENCE}"
        )

    valider_unicite_editoriale(doc, code_tache)


def rendre(doc: dict, version: int, titre_tache: str) -> str:
    code_tache = doc["taskCode"]
    section = doc["section"]
    skills = doc["skills"]
    nb_sujets = sum(len(s["prompts"]) for s in skills)

    out: list[str] = []
    a = out.append

    a("-- ============================================================================")
    a(f"-- V{version} — Competences TCF : {code_tache} « {titre_tache} »")
    a("--")
    a(f"-- Seed du module « Competences » pour la tache {code_tache} ({section}).")
    a(f"-- {len(skills)} competences, {nb_sujets} petits sujets, {nb_sujets * 3} references.")
    a("--")
    a("-- Tables : skills, skill_prompts, skill_references (DDL en V025).")
    a("--")
    a("-- FICHIER GENERE — NE PAS EDITER A LA MAIN.")
    a("--")
    a("--   cd backend_sejourfr && python3 tools/competences/generer_seed.py")
    a("--")
    a("-- On edite la fiche de contenu tools/competences/contenu/" + code_tache + ".json,")
    a("-- puis on regenere. Une correction faite ici serait ecrasee a la prochaine")
    a("-- generation, et les deux sources auraient diverge entre-temps.")
    a("--")
    a("-- (Le contenu vivant, lui, s'edite depuis la console d'administration une fois")
    a("-- la migration appliquee. Ce generateur ne sert qu'a republier depuis zero.)")
    a("--")
    a("-- Les UUID sont DETERMINISTES (uuid5 sur le code metier) : un identifiant de")
    a("-- contenu reste stable d'un environnement a l'autre, et rejouer la generation")
    a("-- redonne exactement le meme fichier.")
    a("--")
    a("-- Rappel du contrat : un petit sujet porte UN SEUL critere, et ses 3 references")
    a("-- (INSUFFICIENT / EXPECTED / EXCELLENT) ne se distinguent que par le respect de")
    a("-- ce critere — jamais par la quantite de fautes de langue.")
    a("-- ============================================================================")
    a("")

    a("INSERT INTO skills (id, section, task_code, code, title, description,")
    a("                    general_criterion, target_level, display_order, is_active,")
    a("                    created_at, updated_at)")
    a("VALUES")
    lignes = []
    for s in skills:
        lignes.append(
            f"  -- {s['code']} — {s['title']}\n"
            f"  ('{uid('skill', s['code'])}', {q(section)}, {q(code_tache)},"
            f" {q(s['code'])}, {q(s['title'])},\n"
            f"   {q(s['description'])},\n"
            f"   {q(s['generalCriterion'])},\n"
            f"   {q(s['targetLevel'])},"
            f" {s['displayOrder']}, true, {HORODATAGE}, {HORODATAGE})"
        )
    a(",\n".join(lignes) + ";")
    a("")

    a("INSERT INTO skill_prompts (id, skill_id, section, code, title, context, instruction,")
    a("                           unique_criterion, recommended_min_words, recommended_max_words,")
    a("                           recommended_duration_seconds, difficulty_level, display_order,")
    a("                           is_active, created_at, updated_at)")
    a("VALUES")
    lignes = []
    for s in skills:
        for p in s["prompts"]:
            lignes.append(
                f"  -- {p['code']} — {p['difficultyLevel']} — {p['title']}\n"
                f"  ('{uid('prompt', p['code'])}', '{uid('skill', s['code'])}',"
                f" {q(section)}, {q(p['code'])}, {q(p['title'])},\n"
                f"   {q(p['context'])},\n"
                f"   {q(p['instruction'])},\n"
                f"   {q(p['uniqueCriterion'])},\n"
                f"   {n(p['recommendedMinWords'])}, {n(p['recommendedMaxWords'])},"
                f" {n(p['recommendedDurationSeconds'])},"
                f" {q(p['difficultyLevel'])}, {p['displayOrder']},"
                f" true, {HORODATAGE}, {HORODATAGE})"
            )
    a(",\n".join(lignes) + ";")
    a("")

    a("INSERT INTO skill_references (id, skill_prompt_id, level, text, pedagogical_note,")
    a("                              created_at, updated_at)")
    a("VALUES")
    lignes = []
    ordre = {"INSUFFICIENT": 0, "EXPECTED": 1, "EXCELLENT": 2}
    for s in skills:
        for p in s["prompts"]:
            for r in sorted(p["references"], key=lambda x: ordre[x["level"]]):
                lignes.append(
                    f"  -- {p['code']} / {r['level']}\n"
                    f"  ('{uid('ref', p['code'] + '/' + r['level'])}',"
                    f" '{uid('prompt', p['code'])}', {q(r['level'])},\n"
                    f"   {q(r['text'])},\n"
                    f"   {q(r['pedagogicalNote'])}, {HORODATAGE}, {HORODATAGE})"
                )
    a(",\n".join(lignes) + ";")
    a("")

    return "\n".join(out)


def rendre_guidage(doc: dict, version: int, titre_tache: str) -> str:
    """Migration de MISE A JOUR du guidage de l'ecran de saisie.

    Pourquoi un UPDATE et pas un INSERT enrichi : les migrations V300-V305 sont
    deja appliquees. Les rejouer avec des colonnes en plus invaliderait leur
    somme de controle Flyway sur toute base qui les a jouees, y compris la base
    de developpement du projet.
    """
    code_tache = doc["taskCode"]
    skills = doc["skills"]
    sujets = [p for s in skills for p in s["prompts"]]

    out: list[str] = []
    a = out.append

    a("-- ============================================================================")
    a(f"-- V{version} — Competences TCF : guidage de saisie, tache {code_tache}")
    a("--")
    a(f"-- Renseigne le guidage des {len(sujets)} petits sujets de « {titre_tache} » :")
    a("--   checklist        ce qu'il faut faire, en 2 a 4 gestes a l'imperatif")
    a("--   constraint_tags  1 a 3 etiquettes {label, icon} — le COMMENT, jamais")
    a("--                    la longueur ni la duree (le front les rend depuis les")
    a("--                    bornes deja en base ; les dupliquer les ferait diverger)")
    a("--   answer_starter   l'amorce grisee du champ de reponse")
    a("--   tip              l'astuce affichee sous la zone de production")
    a("--")
    a("-- Colonnes ajoutees par V026. UPDATE et non INSERT : les lignes existent")
    a(f"-- deja (V{300 + (version - 306)}), et cette migration-la est deja appliquee — la")
    a("-- rejouer invaliderait sa somme de controle Flyway.")
    a("--")
    a("-- FICHIER GENERE — NE PAS EDITER A LA MAIN.")
    a("--   cd backend_sejourfr && python3 tools/competences/generer_seed.py")
    a("-- ============================================================================")
    a("")
    a("UPDATE skill_prompts p SET")
    a("    checklist       = v.checklist::jsonb,")
    a("    constraint_tags = v.constraint_tags::jsonb,")
    a("    answer_starter  = v.answer_starter,")
    a("    tip             = v.tip,")
    a(f"    updated_at      = {HORODATAGE}")
    a("FROM (VALUES")

    lignes = []
    for p in sujets:
        checklist = json.dumps(p["checklist"], ensure_ascii=False)
        tags = json.dumps(p["constraintTags"], ensure_ascii=False)
        lignes.append(
            f"  -- {p['code']}\n"
            f"  ({q(p['code'])},\n"
            f"   {q(checklist)},\n"
            f"   {q(tags)},\n"
            f"   {q(p['answerStarter'])},\n"
            f"   {q(p['tip'])})"
        )
    a(",\n".join(lignes))
    a(") AS v(code, checklist, constraint_tags, answer_starter, tip)")
    a("WHERE p.code = v.code;")
    a("")

    return "\n".join(out)


def rendre_lot2(doc: dict, version: int, titre_tache: str, version_lot1: int) -> str:
    """Migration du LOT 2 : les sujets 6 a 15 et leurs references.

    Pourquoi une migration a part, et pas V300-V305 enrichies : celles-ci sont
    DEJA APPLIQUEES, base de developpement du projet comprise. Y ajouter dix
    sujets changerait leur contenu et invaliderait leur somme de controle
    Flyway. Le contenu se complete par ajout, jamais par reecriture.

    Deux differences avec le lot 1, toutes les deux dues au fait que ces lignes
    sont NEUVES : aucune insertion dans `skills` (les 8 competences de la tache
    existent depuis le lot 1), et le guidage de saisie est renseigne
    directement, la ou V306-V311 devaient passer par un UPDATE separe pour
    remplir des colonnes ajoutees apres coup par V026.
    """
    code_tache = doc["taskCode"]
    section = doc["section"]
    skills = doc["skills"]
    sujets = [p for s in skills for p in s["prompts"]]

    out: list[str] = []
    a = out.append

    a("-- ============================================================================")
    a(f"-- V{version} — Competences TCF : {code_tache} « {titre_tache} » (lot 2)")
    a("--")
    a(f"-- Seed des sujets 6 a {SUJETS_PAR_COMPETENCE} des {len(skills)} competences de"
      f" {code_tache} ({section}) :")
    a(f"-- {len(sujets)} petits sujets, {len(sujets) * 3} references, guidage de saisie compris.")
    a("--")
    a("-- POURQUOI UN LOT SEPARE. Chaque competence est passee de 5 a"
      f" {SUJETS_PAR_COMPETENCE} sujets.")
    a(f"-- Les cinq premiers sont publies par V{version_lot1}, migration DEJA APPLIQUEE — y")
    a("-- compris sur la base de developpement du projet. L'enrichir des dix nouveaux")
    a("-- sujets changerait son contenu et invaliderait sa somme de controle Flyway")
    a("-- partout ou elle a ete jouee. On complete donc par AJOUT, jamais par")
    a("-- reecriture : les sujets 1 a 5 restent la ou ils sont nes.")
    a("--")
    a("-- Aucune ligne `skills` ici : les 8 competences de la tache existent deja. Et le")
    a("-- guidage (checklist, constraint_tags, answer_starter, tip) est renseigne")
    a(f"-- DIRECTEMENT, la ou V{version_lot1 + 6} devait passer par un UPDATE separe :")
    a("-- ces colonnes de V026 sont en place depuis longtemps, et ces lignes-ci sont neuves.")
    a("--")
    a("-- Tables : skill_prompts, skill_references (DDL en V025, guidage en V026).")
    a("--")
    a("-- FICHIER GENERE — NE PAS EDITER A LA MAIN.")
    a("--")
    a("--   cd backend_sejourfr && python3 tools/competences/generer_seed.py")
    a("--")
    a("-- On edite la fiche de contenu tools/competences/contenu/" + code_tache + ".json,")
    a("-- puis on regenere. Une correction faite ici serait ecrasee a la prochaine")
    a("-- generation, et les deux sources auraient diverge entre-temps.")
    a("--")
    a("-- (Le contenu vivant, lui, s'edite depuis la console d'administration une fois")
    a("-- la migration appliquee. Ce generateur ne sert qu'a republier depuis zero.)")
    a("--")
    a("-- Les UUID sont DETERMINISTES (uuid5 sur le code metier) : un identifiant de")
    a("-- contenu reste stable d'un environnement a l'autre, et rejouer la generation")
    a("-- redonne exactement le meme fichier.")
    a("--")
    a("-- Rappel du contrat : un petit sujet porte UN SEUL critere, et ses 3 references")
    a("-- (INSUFFICIENT / EXPECTED / EXCELLENT) ne se distinguent que par le respect de")
    a("-- ce critere — jamais par la quantite de fautes de langue.")
    a("-- ============================================================================")
    a("")

    a("INSERT INTO skill_prompts (id, skill_id, section, code, title, context, instruction,")
    a("                           unique_criterion, recommended_min_words, recommended_max_words,")
    a("                           recommended_duration_seconds, difficulty_level, display_order,")
    a("                           checklist, constraint_tags, answer_starter, tip,")
    a("                           is_active, created_at, updated_at)")
    a("VALUES")
    lignes = []
    for s in skills:
        for p in s["prompts"]:
            checklist = json.dumps(p["checklist"], ensure_ascii=False)
            tags = json.dumps(p["constraintTags"], ensure_ascii=False)
            lignes.append(
                f"  -- {p['code']} — {p['difficultyLevel']} — {p['title']}\n"
                f"  ('{uid('prompt', p['code'])}', '{uid('skill', s['code'])}',"
                f" {q(section)}, {q(p['code'])}, {q(p['title'])},\n"
                f"   {q(p['context'])},\n"
                f"   {q(p['instruction'])},\n"
                f"   {q(p['uniqueCriterion'])},\n"
                f"   {n(p['recommendedMinWords'])}, {n(p['recommendedMaxWords'])},"
                f" {n(p['recommendedDurationSeconds'])},"
                f" {q(p['difficultyLevel'])}, {p['displayOrder']},\n"
                f"   {q(checklist)}::jsonb,\n"
                f"   {q(tags)}::jsonb,\n"
                f"   {q(p['answerStarter'])},\n"
                f"   {q(p['tip'])},\n"
                f"   true, {HORODATAGE_LOT2}, {HORODATAGE_LOT2})"
            )
    a(",\n".join(lignes) + ";")
    a("")

    a("INSERT INTO skill_references (id, skill_prompt_id, level, text, pedagogical_note,")
    a("                              created_at, updated_at)")
    a("VALUES")
    lignes = []
    ordre = {"INSUFFICIENT": 0, "EXPECTED": 1, "EXCELLENT": 2}
    for s in skills:
        for p in s["prompts"]:
            for r in sorted(p["references"], key=lambda x: ordre[x["level"]]):
                lignes.append(
                    f"  -- {p['code']} / {r['level']}\n"
                    f"  ('{uid('ref', p['code'] + '/' + r['level'])}',"
                    f" '{uid('prompt', p['code'])}', {q(r['level'])},\n"
                    f"   {q(r['text'])},\n"
                    f"   {q(r['pedagogicalNote'])}, {HORODATAGE_LOT2}, {HORODATAGE_LOT2})"
                )
    a(",\n".join(lignes) + ";")
    a("")

    return "\n".join(out)


def main() -> int:
    CIBLE.mkdir(parents=True, exist_ok=True)
    manquants = [c for c, _, _ in TACHES if not (CONTENU / f"{c}.json").exists()]
    if manquants:
        print(f"Contenu manquant : {', '.join(manquants)}", file=sys.stderr)
        return 1

    tous_codes: set[str] = set()
    total_sujets = 0
    for code, version, titre in TACHES:
        doc = json.loads((CONTENU / f"{code}.json").read_text(encoding="utf-8"))
        valider(doc, code)

        for s in doc["skills"]:
            assert s["code"] not in tous_codes, f"code competence double : {s['code']}"
            tous_codes.add(s["code"])
            for p in s["prompts"]:
                assert p["code"] not in tous_codes, f"code sujet double : {p['code']}"
                tous_codes.add(p["code"])
                total_sujets += 1

        # Lot 1 — sujets 1 a 5, deja publies : la sortie doit rester identique
        # au bit pres, sinon V300-V311 perdent leur somme de controle Flyway.
        lot1 = doc_du_lot(doc, 1)
        nom = f"V{version}__tcf_competences_{code.lower()}.sql"
        (CIBLE / nom).write_text(rendre(lot1, version, titre), encoding="utf-8")

        vg = next(v for c, v, _ in TACHES_GUIDAGE if c == code)
        nom_g = f"V{vg}__tcf_competences_guidage_{code.lower()}.sql"
        (CIBLE / nom_g).write_text(rendre_guidage(lot1, vg, titre), encoding="utf-8")

        # Lot 2 — sujets 6 a 15, migration neuve.
        lot2 = doc_du_lot(doc, 2)
        v2 = next(v for c, v, _ in TACHES_LOT2 if c == code)
        nom_2 = f"V{v2}__tcf_competences_{code.lower()}_lot2.sql"
        (CIBLE / nom_2).write_text(rendre_lot2(lot2, v2, titre, version), encoding="utf-8")

        n1 = sum(len(s["prompts"]) for s in lot1["skills"])
        n2 = sum(len(s["prompts"]) for s in lot2["skills"])
        print(f"{nom} + {nom_g} + {nom_2} — 8 competences, {n1} sujets (lot 1)"
              f" + {n2} sujets (lot 2)")

    print(f"\nTotal : 48 competences, {total_sujets} sujets, {total_sujets * 3} references")
    assert total_sujets == 720, total_sujets
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
