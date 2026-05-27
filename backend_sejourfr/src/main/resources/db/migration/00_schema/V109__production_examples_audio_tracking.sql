-- ============================================================================
-- V109 : suivi de génération audio des exemples EO (Azure Speech + R2)
-- ============================================================================
-- Les exemples-modèles d'Expression Orale (production_examples rattachés à une
-- tâche TCF_EO) peuvent recevoir un audio que le candidat écoute. On réutilise
-- le pipeline existant (AzureSpeechClient + CloudflareR2Client) via un batch
-- admin. Colonnes de suivi calquées sur audio_question_draft (V095).
--
-- audio_url existe déjà (V107). Cycle de vie de audio_status :
--   NONE -> PENDING -> GENERATING -> GENERATED -> PUBLISHED
--                                              \-> ERROR (relançable)
-- Les exemples EE n'ont jamais d'audio : ils restent en NONE.
-- ============================================================================

ALTER TABLE production_examples
    ADD COLUMN audio_status        VARCHAR(20) NOT NULL DEFAULT 'NONE',
    ADD COLUMN audio_voice         VARCHAR(50),
    ADD COLUMN audio_duration_sec  INTEGER,
    ADD COLUMN audio_generated_at  TIMESTAMPTZ,
    ADD COLUMN audio_batch_id      UUID,
    ADD COLUMN audio_error         TEXT;

ALTER TABLE production_examples
    ADD CONSTRAINT chk_prod_example_audio_status CHECK (
        audio_status IN ('NONE', 'PENDING', 'GENERATING', 'GENERATED', 'PUBLISHED', 'ERROR')
    );

CREATE INDEX idx_prod_examples_audio_status ON production_examples(audio_status);

COMMENT ON COLUMN production_examples.audio_status IS
    'Cycle de génération audio (EO) : NONE -> PENDING -> GENERATING -> GENERATED -> PUBLISHED / ERROR. Le candidat n''entend l''audio que PUBLISHED.';
COMMENT ON COLUMN production_examples.audio_batch_id IS
    'Identifiant du lot de génération (POST /api/admin/production/examples/audio/batch-generate).';
