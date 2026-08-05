-- Trace de la GRILLE de notation ayant produit chaque évaluation IA.
--
-- `prompt_version` ne stockait que la version du tool-schema de sortie ("v2"),
-- jamais celle des rubriques (`prompts/production-rubrics-<v>.json`, ex "v4.2")
-- qui portent les critères, leurs poids et les consignes de notation. Deux
-- notes produites sous le même tool-schema mais sous des grilles différentes ne
-- sont pas comparables : sans cette colonne, impossible de relire une note a
-- posteriori, de calibrer, ou de mesurer l'effet d'un retour arrière sur
-- EVAL_RUBRICS_VERSION.
--
-- Nullable : les évaluations antérieures ne peuvent pas être datées de façon
-- fiable (la version courante a changé plusieurs fois), et écrire une valeur
-- devinée serait pire que l'absence d'information.

ALTER TABLE ai_evaluations
    ADD COLUMN rubrics_version varchar(20);

COMMENT ON COLUMN ai_evaluations.rubrics_version IS
    'Version de la grille de notation appliquee (prompts/production-rubrics-<v>.json). NULL pour les evaluations anterieures a la colonne. Distincte de prompt_version qui ne decrit que le tool-schema de sortie.';
