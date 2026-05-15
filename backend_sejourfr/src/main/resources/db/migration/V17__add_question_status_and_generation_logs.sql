-- ============================================================================
-- V17 : Pipeline de generation automatique de questions audio (TCF CO)
-- ============================================================================
-- 1. Extension pg_trgm pour la detection de doublons par similarite de transcript.
-- 2. Statut DRAFT/ACTIVE/ARCHIVED sur la table questions (les questions audio
--    generees commencent en DRAFT et passent en ACTIVE apres validation admin).
-- 3. Table d'audit audio_question_generation_logs : tracage des appels API,
--    couts Anthropic + Azure, statut final, rate-limiting.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ---------------------------------------------------------------------------
-- 1. STATUT DES QUESTIONS
-- ---------------------------------------------------------------------------
-- Les questions existantes restent en ACTIVE (defaut). Le boolean is_active
-- conserve sa semantique (visibilite utilisateur final). status apporte le
-- cycle de vie DRAFT -> ACTIVE -> ARCHIVED utilise par la pipeline audio.

ALTER TABLE questions
    ADD COLUMN IF NOT EXISTS status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE';

ALTER TABLE questions
    ADD CONSTRAINT chk_question_status
    CHECK (status IN ('DRAFT', 'ACTIVE', 'ARCHIVED'));

CREATE INDEX IF NOT EXISTS idx_questions_status ON questions(status);

COMMENT ON COLUMN questions.status IS
    'Cycle de vie : DRAFT (brouillon admin, non utilisable), ACTIVE (utilisable), ARCHIVED (retire).';

-- ---------------------------------------------------------------------------
-- 2. TABLE D'AUDIT DES GENERATIONS
-- ---------------------------------------------------------------------------
-- Trace chaque tentative de generation audio :
--   - qui : admin_user_id
--   - quoi : requested_params (JSON de la requete)
--   - cout : tokens Anthropic + caracteres Azure, montants EUR
--   - resultat : status (SUCCESS / FAILED_* / RATE_LIMITED) + error_message
--   - lien : question_id (NULL si echec avant insertion DB)

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

-- Index dedie au rate-limiting : compter les SUCCESS recents d'un admin
CREATE INDEX IF NOT EXISTS idx_audio_gen_logs_rate_limit
    ON audio_question_generation_logs(admin_user_id, created_at DESC)
    WHERE status = 'SUCCESS';

COMMENT ON TABLE audio_question_generation_logs IS
    'Audit des generations de questions audio CO via la pipeline Anthropic + Azure + R2.';
COMMENT ON COLUMN audio_question_generation_logs.requested_params IS
    'Parametres de la requete : niveau, theme, type, competence, consignes (JSONB).';
COMMENT ON COLUMN audio_question_generation_logs.r2_object_key IS
    'Cle de l''objet MP3 dans le bucket R2, ex: audio/<media_uuid>.mp3';
