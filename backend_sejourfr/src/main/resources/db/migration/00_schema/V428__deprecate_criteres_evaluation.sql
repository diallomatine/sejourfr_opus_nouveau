-- ============================================================================
-- V428 : Dépréciation de production_tasks.criteres_evaluation
-- ============================================================================
-- La notation IA (critères + poids + barème + descripteurs + consignes) est
-- désormais centralisée à 100 % dans le fichier de rubriques
-- prompts/production-rubrics-<version>.json, indexé par (épreuve, tâche).
-- Le code ne lit PLUS cette colonne (ni EvaluationPromptBuilder ni
-- AiEvaluationService). Ajuster la notation = éditer le JSON, zéro migration.
--
-- Décision (réversibilité) : on CONSERVE la colonne au lieu de la droper —
-- restauration possible sans migration destructive. Un éventuel DROP COLUMN
-- viendra dans un lot ultérieur une fois le nouveau modèle stabilisé.
--
-- On la rend NULLABLE et on retire son DEFAULT '{}' : plus personne ne l'écrit,
-- une tâche peut désormais la laisser à NULL sans contrainte. Le COMMENT
-- documente l'intention.
-- ============================================================================

ALTER TABLE production_tasks ALTER COLUMN criteres_evaluation DROP NOT NULL;
ALTER TABLE production_tasks ALTER COLUMN criteres_evaluation DROP DEFAULT;

COMMENT ON COLUMN production_tasks.criteres_evaluation IS
    'DÉPRÉCIÉ (V428) — non lu par le code. La notation vit dans '
    'prompts/production-rubrics-<version>.json par (épreuve, tâche). '
    'Colonne conservée pour réversibilité ; drop prévu ultérieurement.';
