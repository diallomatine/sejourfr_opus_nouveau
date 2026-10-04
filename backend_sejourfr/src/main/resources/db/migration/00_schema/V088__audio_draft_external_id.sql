-- ============================================================================
-- V088 — Schéma : identifiant externe des brouillons audio (import CO image)
-- ----------------------------------------------------------------------------
-- L'import par lot (POST /api/admin/question-imports/co-image/import) écrit des
-- brouillons audio_question_draft. `external_id` porte l'identifiant éditorial
-- du manifeste (motif [a-z0-9-]{3,64}) et ferme l'anti-doublon : un identifiant
-- déjà connu, QUEL QUE SOIT LE STATUT du brouillon, refuse la question. L'index
-- UNIQUE ferme aussi la course entre deux imports concurrents (le second échoue
-- au commit et compense ses envois R2).
--
-- Nullable : les brouillons existants (V800-V877, saisis par migration) n'en ont
-- pas, et n'en auront pas. Un index UNIQUE PostgreSQL admet plusieurs NULL.
-- ============================================================================

ALTER TABLE audio_question_draft ADD COLUMN external_id varchar(64);

CREATE UNIQUE INDEX uq_audio_draft_external_id ON audio_question_draft (external_id);

COMMENT ON COLUMN audio_question_draft.external_id IS
    'Identifiant éditorial du manifeste d''import (CO image). Unique tous statuts confondus ; NULL pour les brouillons saisis par migration.';
COMMENT ON COLUMN audio_question_draft.choices IS
    'Tableau JSONB de 4 choix : [{label: string, is_correct: boolean, display_order: int, text?: string}]. `text` (import CO image) porte la proposition lue dans l''audio ; label reste la lettre A-D.';
