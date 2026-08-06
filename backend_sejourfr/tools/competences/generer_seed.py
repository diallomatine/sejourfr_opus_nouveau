#!/usr/bin/env python3
"""Convertit les 6 fichiers de contenu JSON en migrations Flyway de seed.

    python3 tools/competences/generer_seed.py

Un fichier SQL par tache TCF (EE1..EO3), numerotes V300..V305, deposes dans
src/main/resources/db/migration/300_tcf/competences/.

CE GENERATEUR EST LA SOURCE DE VERITE DU CONTENU PUBLIE. Les six migrations sont
produites, jamais ecrites a la main : pour corriger un sujet ou une reference,
on edite le JSON de contenu/ puis on rejoue ce script. Editer le SQL directement
ferait diverger les deux, et la prochaine regeneration ecraserait la correction.

(Le contenu vivant, lui, s'edite depuis la console d'administration une fois les
migrations appliquees. Ce generateur ne sert plus qu'a republier depuis zero ou
a repartir d'une base propre.)

Les UUID sont DETERMINISTES (uuid5 sur le code metier) : rejouer le generateur
produit exactement le meme SQL, et un identifiant de contenu reste stable d'un
environnement a l'autre. C'est la convention des seeds de contenu du projet.

Le script VALIDE avant d'ecrire (8 competences par tache, 5 sujets par
competence, 3 references par sujet aux trois niveaux, coherence EE/EO
mots-vs-duree, codes uniques) et refuse de produire du SQL sur du contenu non
conforme.
"""

from __future__ import annotations

import json
import sys
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


def uid(kind: str, code: str) -> str:
    return str(uuid.uuid5(NS, f"{kind}:{code}"))


def q(value: str | None) -> str:
    """Litteral SQL texte, apostrophes echappees a la mode Postgres."""
    if value is None:
        return "NULL"
    return "'" + value.replace("'", "''") + "'"


def n(value: int | None) -> str:
    return "NULL" if value is None else str(value)


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
        assert len(prompts) == 5, f"{skill['code']}: {len(prompts)} sujets au lieu de 5"
        ordres_p = set()
        for p in prompts:
            assert p["code"].startswith(skill["code"] + "-S"), p["code"]
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

            refs = p["references"]
            assert len(refs) == 3, f"{p['code']}: {len(refs)} references"
            niveaux = {r["level"] for r in refs}
            assert niveaux == {"INSUFFICIENT", "EXPECTED", "EXCELLENT"}, p["code"]
            for r in refs:
                assert r["text"].strip(), f"{p['code']}/{r['level']} texte vide"
                assert r["pedagogicalNote"].strip(), f"{p['code']}/{r['level']} note vide"


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

        nom = f"V{version}__tcf_competences_{code.lower()}.sql"
        (CIBLE / nom).write_text(rendre(doc, version, titre), encoding="utf-8")
        print(f"{nom} — 8 competences, {sum(len(s['prompts']) for s in doc['skills'])} sujets")

    print(f"\nTotal : 48 competences, {total_sujets} sujets, {total_sujets * 3} references")
    assert total_sujets == 240, total_sujets
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
