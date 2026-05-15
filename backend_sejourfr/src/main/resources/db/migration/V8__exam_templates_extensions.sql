-- V8 : étend exam_templates et exam_template_rules pour la nouvelle stratégie
-- d'examens blancs.
--
-- - exam_templates       : slug public, accroche/description, ciblage par
--                          procédure (CSP/CR/NAT) en plus de target_level
--                          (A2/B1/B2 pour TCF), flag gratuit, flag publié,
--                          ordre d'affichage, timestamps.
-- - exam_template_rules  : difficulty (pour exprimer « 20 A2 + 20 B1 + 20 B2 »
--                          sur un même thème), position (ordre des règles),
--                          theme_id devient nullable (règle « tout le module »).
-- - attempts             : level_achieved pour le niveau CECRL atteint en TCF.

-- ---------------------------------------------------------------------------
-- exam_templates
-- ---------------------------------------------------------------------------

ALTER TABLE exam_templates
    ADD COLUMN IF NOT EXISTS slug             VARCHAR(64),
    ADD COLUMN IF NOT EXISTS subtitle         VARCHAR(160),
    ADD COLUMN IF NOT EXISTS description      TEXT,
    ADD COLUMN IF NOT EXISTS target_procedure VARCHAR(8),
    ADD COLUMN IF NOT EXISTS is_free          BOOLEAN     NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS is_published     BOOLEAN     NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS position         INTEGER     NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at       TIMESTAMPTZ;

-- Backfill défensif des lignes existantes : on utilise l'UUID complet pour
-- garantir l'unicité (les 4 seeds historiques de V2 partagent le préfixe
-- 44444444-..., donc un SUBSTRING court entrerait en collision). Ces lignes
-- restent is_published=false par défaut, donc invisibles côté public.
UPDATE exam_templates
SET slug = 'legacy-' || id::text
WHERE slug IS NULL;

ALTER TABLE exam_templates
    ALTER COLUMN slug SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_exam_templates_slug
    ON exam_templates(slug);

CREATE INDEX IF NOT EXISTS idx_exam_templates_module_published_position
    ON exam_templates(module, is_published, position);

-- ---------------------------------------------------------------------------
-- exam_template_rules
-- ---------------------------------------------------------------------------

ALTER TABLE exam_template_rules
    ADD COLUMN IF NOT EXISTS difficulty VARCHAR(8),
    ADD COLUMN IF NOT EXISTS position   INTEGER NOT NULL DEFAULT 0;

ALTER TABLE exam_template_rules
    ALTER COLUMN theme_id DROP NOT NULL;

-- ---------------------------------------------------------------------------
-- attempts
-- ---------------------------------------------------------------------------

ALTER TABLE attempts
    ADD COLUMN IF NOT EXISTS level_achieved VARCHAR(8);
