-- ==========================================================================
-- V031 — Moteur de maîtrise des compétences
--
-- Deux extensions STRICTEMENT ADDITIVES de learning_plan_observations. Aucune
-- ligne n'est supprimée, aucune colonne n'est retirée, aucun état n'est
-- persisté : l'état de maîtrise (PRIORITY / TO_REINFORCE / CONSOLIDATING /
-- SOLID) reste dérivé à la lecture par SkillMasteryEngine.
--
-- 1) Les productions faites DANS UN EXAMEN BLANC deviennent une source à part
--    entière. Elles passaient déjà par le même pipeline de correction, mais
--    étaient enregistrées comme des productions d'entraînement : le moteur ne
--    pouvait donc pas leur donner le poids le plus fort, alors que c'est la
--    preuve la moins assistée dont on dispose.
--
-- 2) subject_id : le SUJET travaillé, distinct de source_id qui identifie la
--    TENTATIVE. Sans lui, trois reprises du même exercice après correction
--    ressemblaient à trois preuves indépendantes — exactement ce qu'une
--    maîtrise ne doit pas pouvoir être.
--
-- Le rattrapage ci-dessous est purement DÉTERMINISTE (une jointure SQL sur des
-- lignes déjà en base). Il ne rejoue aucune production, n'appelle aucun LLM et
-- ne fabrique aucune observation : il nomme le sujet d'observations qui
-- existent déjà.
-- ==========================================================================

ALTER TABLE learning_plan_observations
    DROP CONSTRAINT chk_learning_plan_observation_source;

ALTER TABLE learning_plan_observations
    ADD CONSTRAINT chk_learning_plan_observation_source CHECK (
        source_type IN ('DIAGNOSTIC_EE', 'DIAGNOSTIC_EO', 'PRODUCTION_EE',
                        'PRODUCTION_EO', 'MOCK_EXAM_EE', 'MOCK_EXAM_EO',
                        'SKILL_TRAINING', 'TCF_CO', 'TCF_CE')
    );

ALTER TABLE learning_plan_observations
    ADD COLUMN subject_id uuid;

UPDATE learning_plan_observations o
SET subject_id = a.skill_prompt_id
FROM user_skill_attempts a
WHERE o.source_type = 'SKILL_TRAINING'
  AND o.source_id = a.id;

UPDATE learning_plan_observations o
SET subject_id = s.production_task_id
FROM production_submissions s
WHERE o.source_type IN ('DIAGNOSTIC_EE', 'DIAGNOSTIC_EO', 'PRODUCTION_EE', 'PRODUCTION_EO')
  AND o.source_id = s.id;

COMMENT ON COLUMN learning_plan_observations.subject_id IS
    'Sujet travaillé (skill_prompts.id ou production_tasks.id) ; NULL quand la source a disparu. Sert la diversité des contextes, jamais l’identité de la tentative.';
