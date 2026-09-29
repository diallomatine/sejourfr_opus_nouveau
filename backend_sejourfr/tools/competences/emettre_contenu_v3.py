#!/usr/bin/env python3
"""Emet V320 — le CONTENU de la taxonomie V3 (sujets, guidage, references, points).

    cd backend_sejourfr && python3 tools/competences/emettre_contenu_v3.py

V319 a transforme la TABLE des competences : retraits, creations, recentrages,
reordonnancement. Elle n'a pas touche aux sujets — une competence creee y
apparait donc a zero sujet, ce qui s'affiche mais ne casse rien. V320 apporte
la matiere :

  1. les 144 « Vous allez apprendre a : » des 48 competences actives ;
  2. le cadrage corrige des 121 sujets des competences recentrees ;
  3. pour les 19 competences a lot neuf : les anciens sujets desactives et
     ranges au-dela de 15, puis 15 sujets neufs et leurs 45 references.

🛑 TROIS REGLES DURES, les memes que V319.

1. **Aucune suppression de sujet.** `user_skill_attempts.skill_prompt_id` est
   en `ON DELETE CASCADE` : supprimer un sujet effacerait les productions des
   candidats qui l'ont travaille. Le geste est `is_active = false`.
2. **Desactiver ne libere pas le rang** : `uq_skill_prompts_skill_order` ne
   filtre pas `is_active`. Les anciens sujets sont donc ranges en 16..30 — le
   CHECK va jusqu'a 50 depuis V064 — pour que les neufs prennent 1..15.
3. **Tout tient en une transaction** parce que `uq_skill_prompts_skill_order`
   est `DEFERRABLE INITIALLY DEFERRED` (V025) : l'etat intermediaire, ou deux
   sujets partagent un rang, n'est verifie qu'au COMMIT.

FICHIER GENERE — NE PAS EDITER A LA MAIN.
"""

from __future__ import annotations

import json
import uuid
from pathlib import Path

from vue_v3 import charger_v3

ICI = Path(__file__).resolve().parent
RACINE = ICI.parents[1]
SORTIE = (RACINE / "src/main/resources/db/migration/300_tcf/competences"
          / "V320__tcf_competences_contenu_v3.sql")
POINTS = ICI / "contenu_v3/_learning_points.json"
CORRECTIONS = ICI / "contenu_v3/_corrections.json"

# Meme namespace que generer_seed.py et taxonomie_v3.py : un identifiant de
# contenu reste stable d'un environnement a l'autre.
NS = uuid.UUID("6f2b1a54-9c3d-4e78-8a10-5e10c0de0001")
HORODATAGE = "'2026-09-13 09:00:00+02'"
# Les anciens sujets d'une competence a lot neuf sont ranges ici pour liberer
# 1..15. 16 et non 21 : V064 a porte le CHECK a 50.
PREMIER_RANG_SORTIE = 16
NIVEAUX = ("INSUFFICIENT", "EXPECTED", "EXCELLENT")


def uid(kind: str, code: str) -> str:
    return str(uuid.uuid5(NS, f"{kind}:{code}"))


def q(v: str | None) -> str:
    return "NULL" if v is None else "'" + v.replace("'", "''") + "'"


def n(v: int | None) -> str:
    return "NULL" if v is None else str(v)


def j(v) -> str:
    return q(json.dumps(v, ensure_ascii=False))


def sql() -> str:
    vue = charger_v3()
    points = json.loads(POINTS.read_text(encoding="utf-8"))
    corrections = json.loads(CORRECTIONS.read_text(encoding="utf-8"))
    neufs = [s for s in vue if s["origine"] == "contenu_v3"]

    out: list[str] = []
    a = out.append
    a("-- ==========================================================================")
    a("-- V320 — Contenu de la taxonomie V3 des competences d'expression")
    a("--")
    a("-- FICHIER GENERE — NE PAS EDITER A LA MAIN.")
    a("--   cd backend_sejourfr && python3 tools/competences/emettre_contenu_v3.py")
    a("--")
    a("-- Fait suite a V319, qui a transforme la table des competences sans toucher")
    a("-- aux sujets. Trois apports :")
    a(f"--   1. {len(points) * 3} points d'apprentissage sur {len(points)} competences actives ;")
    a(f"--   2. le cadrage corrige de {sum(len(v) for v in corrections.values())} sujets"
      f" ({len(corrections)} competences recentrees) ;")
    a(f"--   3. {len(neufs)} lots neufs : anciens sujets desactives, {len(neufs) * 15} sujets"
      f" et {len(neufs) * 45} references inseres.")
    a("--")
    a("-- 🛑 AUCUNE SUPPRESSION. user_skill_attempts.skill_prompt_id est en")
    a("-- ON DELETE CASCADE : supprimer un sujet effacerait les productions des")
    a("-- candidats. Le geste est is_active = false.")
    a("--")
    a("-- 🛑 Desactiver ne libere pas le rang : uq_skill_prompts_skill_order ne")
    a("-- filtre pas is_active. Les anciens sujets passent en 16..30 (le CHECK va")
    a("-- jusqu'a 50 depuis V064) pour que les neufs occupent 1..15.")
    a("--")
    a("-- L'etat intermediaire, ou deux sujets partagent un rang, est licite :")
    a("-- uq_skill_prompts_skill_order est DEFERRABLE INITIALLY DEFERRED (V025).")
    a("-- ==========================================================================")
    a("")

    # ---- 1. Les 144 points d'apprentissage --------------------------------
    a("-- --------------------------------------------------------------------------")
    a(f"-- 1. « Vous allez apprendre a : » — {len(points) * 3} points, {len(points)} competences")
    a("--")
    a("-- Colonne ajoutee par V063. Les points sont RELUS a la main : la generation")
    a("-- n'a servi que de premiere redaction (journal, D01).")
    a("-- --------------------------------------------------------------------------")
    a("UPDATE skills s SET")
    a("    learning_points = v.points::jsonb,")
    a(f"    updated_at      = {HORODATAGE}")
    a("FROM (VALUES")
    lignes = []
    for s in vue:
        lignes.append(f"  -- {s['code']} — {s['titre']}\n"
                      f"  ({q(s['code'])}, {j(points[s['code']])})")
    a(",\n".join(lignes))
    a(") AS v(code, points)")
    a("WHERE s.code = v.code;")
    a("")

    # ---- 2. Le cadrage corrige des competences recentrees ------------------
    patches = [(code, patch) for skill in corrections for code, patch in corrections[skill].items()]
    par_code = {p["code"]: p for s in vue for p in s["prompts"] if "code" in p}
    a("-- --------------------------------------------------------------------------")
    a(f"-- 2. Cadrage corrige — {len(patches)} sujets de {len(corrections)} competences recentrees")
    a("--")
    a("-- Les SITUATIONS sont conservees : seuls la consigne, le critere unique, le")
    a("-- guidage et, quand la V3 l'imposait, les references changent. Voir le")
    a("-- journal D02/D03.")
    a("-- --------------------------------------------------------------------------")
    a("UPDATE skill_prompts p SET")
    a("    title                        = v.title,")
    a("    instruction                  = v.instruction,")
    a("    unique_criterion             = v.unique_criterion,")
    a("    checklist                    = v.checklist::jsonb,")
    a("    constraint_tags              = v.constraint_tags::jsonb,")
    a("    answer_starter               = v.answer_starter,")
    a("    tip                          = v.tip,")
    a("    recommended_min_words        = v.recommended_min_words,")
    a("    recommended_max_words        = v.recommended_max_words,")
    a("    recommended_duration_seconds = v.recommended_duration_seconds,")
    a("    difficulty_level             = v.difficulty_level,")
    a(f"    updated_at                   = {HORODATAGE}")
    a("FROM (VALUES")
    lignes = []
    for code, _ in patches:
        p = par_code[code]
        lignes.append(
            f"  -- {code}\n"
            f"  ({q(code)}, {q(p['title'])},\n"
            f"   {q(p['instruction'])},\n"
            f"   {q(p['uniqueCriterion'])},\n"
            f"   {j(p['checklist'])},\n"
            f"   {j(p['constraintTags'])},\n"
            f"   {q(p['answerStarter'])}, {q(p['tip'])},\n"
            f"   {n(p['recommendedMinWords'])}, {n(p['recommendedMaxWords'])},"
            f" {n(p['recommendedDurationSeconds'])}, {q(p['difficultyLevel'])})")
    a(",\n".join(lignes))
    a(") AS v(code, title, instruction, unique_criterion, checklist, constraint_tags,")
    a("       answer_starter, tip, recommended_min_words, recommended_max_words,")
    a("       recommended_duration_seconds, difficulty_level)")
    a("WHERE p.code = v.code;")
    a("")

    refs = [(code, niveau) for code, patch in patches
            for niveau in patch.get("references", {})]
    a(f"-- Les {len(refs)} references dont la V3 a change le texte ou la note : une")
    a("-- reference modele qui montre ce que le critere vient d'interdire ferait")
    a("-- mentir l'ecran.")
    a("UPDATE skill_references r SET")
    a("    text             = v.text,")
    a("    pedagogical_note = v.note,")
    a(f"    updated_at       = {HORODATAGE}")
    a("FROM (VALUES")
    lignes = []
    for code, niveau in refs:
        p = par_code[code]
        ref = next(x for x in p["references"] if x["level"] == niveau)
        lignes.append(f"  -- {code} / {niveau}\n"
                      f"  ({q(code)}, {q(niveau)},\n"
                      f"   {q(ref['text'])},\n"
                      f"   {q(ref['pedagogicalNote'])})")
    a(",\n".join(lignes))
    # Les deux relations de l'UPDATE tiennent dans UNE clause FROM : la liste
    # de valeurs, puis skill_prompts, qui porte le code editorial du sujet.
    a(") AS v(prompt_code, level, text, note), skill_prompts p")
    a("FROM_MARKER")
    a("")

    # ---- 3. Les lots neufs -------------------------------------------------
    a("-- --------------------------------------------------------------------------")
    a(f"-- 3. Les {len(neufs)} lots neufs")
    a("--")
    a("-- Pour chaque competence : les anciens sujets sortent du catalogue (jamais")
    a("-- de la base), puis 15 sujets neufs prennent les rangs 1..15.")
    a("-- --------------------------------------------------------------------------")
    a("")
    a("-- 3a. Les sujets des 7 competences RETIREES par V319.")
    a("--")
    a("-- V319 a desactive les competences, pas leurs sujets : ceux-ci restaient")
    a("-- actifs sous une competence qui ne s'affiche plus. Inatteignables, mais")
    a("-- comptes comme publies par tout controle qui interroge skill_prompts seul.")
    a("-- Ils sortent ici, sans changer de rang : leur competence ne reviendra pas.")
    a("UPDATE skill_prompts p")
    a("   SET is_active = false, updated_at = " + HORODATAGE)
    a("  FROM skills s")
    a(" WHERE s.id = p.skill_id AND NOT s.is_active AND p.is_active;")
    a("")
    a("-- 3b. Les anciens sujets des competences a lot neuf : desactives et ranges")
    a("--     au-dela de 15, pour que les sujets neufs prennent 1..15.")
    for s in neufs:
        anciens = s["premierCodeLibre"] - 1
        if anciens <= 0:
            a(f"-- {s['code']} : competence creee par V319, aucun ancien sujet.")
            continue
        a(f"-- {s['code']} — {s['remplace']}")
        a("UPDATE skill_prompts")
        a(f"   SET is_active = false, display_order = display_order + {PREMIER_RANG_SORTIE - 1},")
        a(f"       updated_at = {HORODATAGE}")
        a(f" WHERE skill_id = '{uid('skill', s['code'])}' AND display_order <= {anciens};")
    a("")

    a("-- 3c. Les sujets neufs.")
    a("INSERT INTO skill_prompts (id, skill_id, section, code, title, context, instruction,")
    a("                           unique_criterion, recommended_min_words, recommended_max_words,")
    a("                           recommended_duration_seconds, difficulty_level, display_order,")
    a("                           checklist, constraint_tags, answer_starter, tip,")
    a("                           is_active, created_at, updated_at)")
    a("VALUES")
    lignes = []
    for s in neufs:
        section = s["code"][:2]
        for i, p in enumerate(s["prompts"], start=1):
            code = f"{s['code']}-S{s['premierCodeLibre'] + i - 1}"
            lignes.append(
                f"  -- {code} — {p['difficultyLevel']} — {p['title']}\n"
                f"  ('{uid('prompt', code)}', '{uid('skill', s['code'])}',"
                f" {q(section)}, {q(code)}, {q(p['title'])},\n"
                f"   {q(p['context'])},\n"
                f"   {q(p['instruction'])},\n"
                f"   {q(p['uniqueCriterion'])},\n"
                f"   {n(p.get('recommendedMinWords'))}, {n(p.get('recommendedMaxWords'))},"
                f" {n(p.get('recommendedDurationSeconds'))},"
                f" {q(p['difficultyLevel'])}, {i},\n"
                f"   {j(p['checklist'])},\n"
                f"   {j(p['constraintTags'])},\n"
                f"   {q(p['answerStarter'])}, {q(p['tip'])},\n"
                f"   true, {HORODATAGE}, {HORODATAGE})")
    a(",\n".join(lignes) + ";")
    a("")

    a("-- 3d. Leurs references.")
    a("INSERT INTO skill_references (id, skill_prompt_id, level, text, pedagogical_note,")
    a("                              created_at, updated_at)")
    a("VALUES")
    lignes = []
    for s in neufs:
        for i, p in enumerate(s["prompts"], start=1):
            code = f"{s['code']}-S{s['premierCodeLibre'] + i - 1}"
            for niveau in NIVEAUX:
                r = next(x for x in p["references"] if x["level"] == niveau)
                lignes.append(
                    f"  -- {code} / {niveau}\n"
                    f"  ('{uid('ref', code + '/' + niveau)}', '{uid('prompt', code)}',"
                    f" {q(niveau)},\n"
                    f"   {q(r['text'])},\n"
                    f"   {q(r['pedagogicalNote'])}, {HORODATAGE}, {HORODATAGE})")
    a(",\n".join(lignes) + ";")
    a("")

    # ---- 4. Le filet -------------------------------------------------------
    a("-- --------------------------------------------------------------------------")
    a("-- 4. Filet — la migration echoue plutot que de livrer un catalogue faux.")
    a("--")
    a("-- 🛑 Borne aux competences d'EXPRESSION. V318 a seede six competences de")
    a("-- COMPREHENSION (CO-A2..CE-B2) : elles n'ont ni petit sujet ni point")
    a("-- d'apprentissage, et c'est voulu — le module Competences ne couvre que")
    a("-- EE et EO. Sans cette borne, le filet refuserait un catalogue correct.")
    a("-- --------------------------------------------------------------------------")
    a("DO $$")
    a("DECLARE")
    a("    manquants int;")
    a("    hors_contrat int;")
    a("BEGIN")
    a("    SELECT count(*) INTO manquants")
    a("      FROM skills")
    a("     WHERE is_active AND section IN ('EE', 'EO')")
    a("       AND (learning_points IS NULL OR jsonb_array_length(learning_points) <> 3);")
    a("    IF manquants > 0 THEN")
    a("        RAISE EXCEPTION 'V320 : % competence(s) active(s) sans 3 points d''apprentissage',")
    a("            manquants;")
    a("    END IF;")
    a("")
    a("    SELECT count(*) INTO hors_contrat")
    a("      FROM (SELECT s.code, count(p.id) AS actifs")
    a("              FROM skills s")
    a("              LEFT JOIN skill_prompts p ON p.skill_id = s.id AND p.is_active")
    a("             WHERE s.is_active AND s.section IN ('EE', 'EO')")
    a("             GROUP BY s.code) t")
    a("     WHERE t.actifs <> 15;")
    a("    IF hors_contrat > 0 THEN")
    a("        RAISE EXCEPTION 'V320 : % competence(s) active(s) n''ont pas 15 sujets actifs',")
    a("            hors_contrat;")
    a("    END IF;")
    a("")
    a("    SELECT count(*) INTO hors_contrat")
    a("      FROM (SELECT p.code, count(r.id) AS refs")
    a("              FROM skill_prompts p")
    a("              JOIN skills s ON s.id = p.skill_id AND s.is_active")
    a("                            AND s.section IN ('EE', 'EO')")
    a("              LEFT JOIN skill_references r ON r.skill_prompt_id = p.id")
    a("             WHERE p.is_active")
    a("             GROUP BY p.code) t")
    a("     WHERE t.refs <> 3;")
    a("    IF hors_contrat > 0 THEN")
    a("        RAISE EXCEPTION 'V320 : % sujet(s) actif(s) n''ont pas 3 references', hors_contrat;")
    a("    END IF;")
    a("END $$;")
    a("")

    texte = "\n".join(out)
    # La clause WHERE de l'UPDATE des references demande une jointure : on la
    # pose ici plutot que de compliquer la construction ligne a ligne.
    texte = texte.replace(
        "FROM_MARKER",
        "WHERE r.skill_prompt_id = p.id AND p.code = v.prompt_code AND r.level = v.level;")
    return texte


def main() -> None:
    SORTIE.parent.mkdir(parents=True, exist_ok=True)
    SORTIE.write_text(sql(), encoding="utf-8")
    print(f"Ecrit {SORTIE.relative_to(RACINE)} ({SORTIE.stat().st_size // 1024} Ko)")


if __name__ == "__main__":
    main()
