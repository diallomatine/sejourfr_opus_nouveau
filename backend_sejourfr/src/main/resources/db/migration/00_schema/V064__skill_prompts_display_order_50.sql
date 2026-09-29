-- ============================================================================
-- V064 — skill_prompts.display_order : borne haute 20 -> 50
--
-- POURQUOI
-- --------
-- La refonte de la taxonomie V3 (V319) remplace le contenu de plusieurs
-- competences : leurs 15 petits sujets ne correspondent plus a la definition
-- officielle de la tache.
--
-- 🛑 ON NE SUPPRIME PAS UN SUJET. `user_skill_attempts.skill_prompt_id` est en
-- ON DELETE CASCADE : effacer un sujet effacerait les productions des candidats
-- qui l'ont travaille, et les observations que le moteur de maitrise en a
-- tirees. Le geste est le meme que pour une competence — la DESACTIVATION.
--
-- 🛑 Mais desactiver ne libere pas le rang : `uq_skill_prompts_skill_order` ne
-- filtre pas `is_active`, exactement comme `uq_skills_task_order` du cote des
-- competences. Une competence reprise porte donc, le temps que l'historique
-- vive, 15 sujets actifs (rangs 1-15) ET jusqu'a 15 desactivies ranges
-- au-dela — soit 30 rangs, quand le CHECK en autorisait 20.
--
-- MEME DECISION QU'EN V025 POUR LES COMPETENCES
-- ---------------------------------------------
-- `chk_skills_display_order` avait ete pose a 50 et non a 8 pour la meme
-- raison, et le commentaire de V025 le dit : « la regle produit reste vraie,
-- mais elle est verrouillee par un TEST SUR LE SEED, pas par le DDL ».
-- Ici aussi : « 15 sujets actifs par competence » reste verrouille par
-- SkillSeedIT. Le CHECK ne sert qu'a garder une valeur manifestement fausse
-- hors de la base.
--
-- Aucune donnee ne bouge : tous les rangs publies valent 1 a 15.
-- ============================================================================

ALTER TABLE skill_prompts
    DROP CONSTRAINT chk_skill_prompts_display_order;

ALTER TABLE skill_prompts
    ADD CONSTRAINT chk_skill_prompts_display_order
        CHECK (display_order BETWEEN 1 AND 50);

COMMENT ON COLUMN skill_prompts.display_order IS
    'Rang du sujet dans sa competence. 1 a 15 pour les sujets ACTIFS ; au-dela '
    'pour ceux qu''une refonte editoriale a desactives, dont le rang n''est pas '
    'libere par uq_skill_prompts_skill_order. Le « 15 actifs » est verrouille '
    'par SkillSeedIT, pas par le CHECK.';
