-- ============================================================================
-- V17 : Pipeline de génération automatique de questions audio (TCF CO)
-- ============================================================================
-- 1. Extension pg_trgm pour la détection de doublons par similarité de transcript.
-- 2. Statut DRAFT/ACTIVE/ARCHIVED sur la table questions (les questions audio
--    générées commencent en DRAFT et passent en ACTIVE après validation admin).
-- 3. Table d'audit audio_question_generation_logs : traçage des appels API,
--    coûts Anthropic + Azure, statut final, rate-limiting.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ---------------------------------------------------------------------------
-- 1. STATUT DES QUESTIONS
-- ---------------------------------------------------------------------------
-- Les questions existantes restent en ACTIVE (défaut). Le boolean is_active
-- conserve sa sémantique (visibilité utilisateur final). status apporte le
-- cycle de vie DRAFT -> ACTIVE -> ARCHIVED utilisé par la pipeline audio.

ALTER TABLE questions
    ADD COLUMN IF NOT EXISTS status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE';

ALTER TABLE questions
    ADD CONSTRAINT chk_question_status
    CHECK (status IN ('DRAFT', 'ACTIVE', 'ARCHIVED'));

CREATE INDEX IF NOT EXISTS idx_questions_status ON questions(status);

COMMENT ON COLUMN questions.status IS
    'Cycle de vie : DRAFT (brouillon admin, non utilisable), ACTIVE (utilisable), ARCHIVED (retiré).';

-- ---------------------------------------------------------------------------
-- 2. TABLE D'AUDIT DES GÉNÉRATIONS
-- ---------------------------------------------------------------------------
-- Trace chaque tentative de génération audio :
--   - qui : admin_user_id
--   - quoi : requested_params (JSON de la requête)
--   - coût : tokens Anthropic + caractères Azure, montants EUR
--   - résultat : status (SUCCESS / FAILED_* / RATE_LIMITED) + error_message
--   - lien : question_id (NULL si échec avant insertion DB)

CREATE TABLE IF NOT EXISTS audio_question_generation_logs (
    id                          UUID PRIMARY KEY,
    question_id                 UUID REFERENCES questions(id) ON DELETE SET NULL,
    admin_user_id               UUID NOT NULL REFERENCES users(id),
    requested_params            JSONB NOT NULL,
    prompt_version              VARCHAR(32),
    anthropic_model             VARCHAR(64),
    anthropic_input_tokens      INTEGER,
    anthropic_output_tokens     INTEGER,
    anthropic_cache_read_tokens INTEGER,
    anthropic_cost_eur          NUMERIC(8, 5),
    azure_voice_names           VARCHAR(512),
    azure_characters_count      INTEGER,
    azure_cost_eur              NUMERIC(8, 5),
    r2_object_key               VARCHAR(256),
    duration_ms                 INTEGER,
    status                      VARCHAR(32) NOT NULL,
    error_message               TEXT,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_generation_status CHECK (status IN (
        'SUCCESS',
        'FAILED_VALIDATION',
        'FAILED_RATE_LIMIT',
        'FAILED_ANTHROPIC',
        'FAILED_ANTHROPIC_PARSE',
        'FAILED_CONTENT_VALIDATION',
        'FAILED_DUPLICATE',
        'FAILED_AZURE_SPEECH',
        'FAILED_R2_UPLOAD',
        'FAILED_DB',
        'FAILED_TIMEOUT',
        'REJECTED_BY_ADMIN'
    ))
);

CREATE INDEX IF NOT EXISTS idx_audio_gen_logs_admin
    ON audio_question_generation_logs(admin_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audio_gen_logs_status
    ON audio_question_generation_logs(status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audio_gen_logs_question
    ON audio_question_generation_logs(question_id)
    WHERE question_id IS NOT NULL;

-- Index dédié au rate-limiting : compter les SUCCESS récents d'un admin
CREATE INDEX IF NOT EXISTS idx_audio_gen_logs_rate_limit
    ON audio_question_generation_logs(admin_user_id, created_at DESC)
    WHERE status = 'SUCCESS';

COMMENT ON TABLE audio_question_generation_logs IS
    'Audit des générations de questions audio CO via la pipeline Anthropic + Azure + R2.';
COMMENT ON COLUMN audio_question_generation_logs.requested_params IS
    'Paramètres de la requête : niveau, thème, type, compétence, consignes (JSONB).';
COMMENT ON COLUMN audio_question_generation_logs.r2_object_key IS
    'Clé de l''objet MP3 dans le bucket R2, ex: audio/<media_uuid>.mp3';
