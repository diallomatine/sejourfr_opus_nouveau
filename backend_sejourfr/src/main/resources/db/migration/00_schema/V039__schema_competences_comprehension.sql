-- ============================================================================
-- V039 — Schéma : les compétences de COMPRÉHENSION (CO / CE) entrent dans
--        `skills`, à côté des micro-compétences d'expression (EE / EO).
-- ----------------------------------------------------------------------------
-- OBJET — le Plan adaptatif doit pouvoir désigner « CO-B1 » comme priorité
-- exactement comme il désigne « EE1-C3 ». `LearningPlanSourceType` déclare déjà
-- TCF_CO / TCF_CE et `SkillMasteryEngine` sait les pondérer
-- (`getWeightComprehension()`) : la plomberie du moteur existe, il ne manquait
-- que le référentiel.
--
-- CE QUI CHANGE, ET RIEN D'AUTRE :
--   1. `section` accepte 'CO' et 'CE' — c'est l'axe DOMAINE ;
--   2. `task_code` devient NULLABLE — une compétence de compréhension
--      n'appartient à AUCUNE des 6 tâches officielles du TCF, et l'enum
--      `SkillTaskCode` reste le référentiel figé des seules EE1..EO3. On ne le
--      pollue pas avec des valeurs CO/CE : le domaine se lit sur `section`, le
--      niveau sur `target_level`.
--
-- CE QUI NE CHANGE PAS :
--   - `skill_prompts.section` reste borné à ('EE','EO') : une compétence de
--     compréhension n'a AUCUN petit sujet (brief §13 et §71 — son entraînement
--     est une série de 20 QCM, pas une page de 5 petits sujets). La FK composite
--     (skill_id, section) rend donc structurellement impossible de rattacher un
--     petit sujet à une compétence CO/CE ;
--   - `chk_skills_task_code` et `chk_skills_section_matches_task` sont laissés
--     tels quels : un CHECK dont l'expression vaut NULL est SATISFAIT, donc les
--     lignes CO/CE les traversent sans les affaiblir pour les lignes EE/EO ;
--   - `chk_skills_target_level` accepte déjà A2/B1/B2.
--
-- ⚠️ Cette migration est de la DDL PURE. Les 6 compétences elles-mêmes sont du
-- CONTENU et vivent dans la plage 300 (V318), après les lots du module — un
-- INSERT de contenu posé en 00_schema s'exécuterait avant sa propre plage.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Le domaine s'élargit
-- ---------------------------------------------------------------------------
ALTER TABLE skills DROP CONSTRAINT chk_skills_section;
ALTER TABLE skills
    ADD CONSTRAINT chk_skills_section CHECK (section IN ('EE', 'EO', 'CO', 'CE'));

-- ---------------------------------------------------------------------------
-- 2. La tâche devient facultative, mais jamais ambiguë
-- ---------------------------------------------------------------------------
ALTER TABLE skills ALTER COLUMN task_code DROP NOT NULL;

-- Le seul état interdit par la nullabilité : une compétence d'expression
-- orpheline de tâche, ou une compétence de compréhension qui s'en attribuerait
-- une. L'équivalence est stricte dans les deux sens — sans elle, `task_code`
-- deviendrait un champ « parfois rempli », et tout code qui le lit devrait
-- deviner pourquoi il manque.
ALTER TABLE skills
    ADD CONSTRAINT chk_skills_task_code_presence CHECK (
        (section IN ('EE', 'EO') AND task_code IS NOT NULL)
            OR (section IN ('CO', 'CE') AND task_code IS NULL)
        );

-- ---------------------------------------------------------------------------
-- 3. L'unicité du rang d'affichage suit
-- ---------------------------------------------------------------------------
-- `uq_skills_task_order UNIQUE (task_code, display_order)` ne contraint plus
-- rien pour les lignes CO/CE : Postgres considère deux NULL comme distincts,
-- donc six compétences (NULL, 1) y seraient légales. Le rang reste pourtant
-- l'ordre pédagogique du domaine (A2 -> B1 -> B2) : on le verrouille par un
-- index unique PARTIEL, exactement sur les lignes que l'autre contrainte laisse
-- passer. Les deux ensembles sont disjoints par construction (cf. point 2), il
-- n'y a donc jamais deux règles pour une même ligne.
CREATE UNIQUE INDEX uq_skills_section_order_comprehension
    ON skills (section, display_order)
    WHERE task_code IS NULL;

COMMENT ON COLUMN skills.task_code IS
    'Tache TCF d''appartenance (EE1..EO3), NULL pour une competence de comprehension : CO/CE n''appartiennent a aucune des 6 taches officielles. Le domaine se lit sur `section`, le niveau sur `target_level`.';

COMMENT ON TABLE skills IS
    'Competences TCF. Expression : 8 par tache (EE1..EE3, EO1..EO3), entrainees par des petits sujets. Comprehension : une par niveau et par domaine (CO/CE x A2/B1/B2), sans petit sujet — entrainees par une serie ciblee de QCM.';
