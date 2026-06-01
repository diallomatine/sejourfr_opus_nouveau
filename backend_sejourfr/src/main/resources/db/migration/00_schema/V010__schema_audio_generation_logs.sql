-- ============================================================================
-- V010 — Schéma : audit des générations audio CO (Anthropic + Azure + R2)
-- ----------------------------------------------------------------------------
-- Table : audio_question_generation_logs
-- Relations : -> users (admin), questions (SET NULL si la question est supprimée).
-- ============================================================================

CREATE TABLE audio_question_generation_logs (
    id                          uuid NOT NULL PRIMARY KEY,
    question_id                 uuid REFERENCES questions(id) ON DELETE SET NULL,
    admin_user_id               uuid NOT NULL REFERENCES users(id),
    requested_params            jsonb NOT NULL,
    prompt_version              varchar(32),
    anthropic_model             varchar(64),
    anthropic_input_tokens      integer,
    anthropic_output_tokens     integer,
    anthropic_cache_read_tokens integer,
    anthropic_cost_eur          numeric(8,5),
    azure_voice_names           varchar(512),
    azure_characters_count      integer,
    azure_cost_eur              numeric(8,5),
    r2_object_key               varchar(256),
    duration_ms                 integer,
    status                      varchar(32) NOT NULL,
    error_message               text,
    created_at                  timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT chk_generation_status CHECK (((status)::text = ANY ((ARRAY['SUCCESS','FAILED_VALIDATION','FAILED_RATE_LIMIT','FAILED_ANTHROPIC','FAILED_ANTHROPIC_PARSE','FAILED_CONTENT_VALIDATION','FAILED_DUPLICATE','FAILED_AZURE_SPEECH','FAILED_R2_UPLOAD','FAILED_DB','FAILED_TIMEOUT','REJECTED_BY_ADMIN'])::text[])))
);
CREATE INDEX idx_audio_gen_logs_admin ON audio_question_generation_logs (admin_user_id, created_at DESC);
CREATE INDEX idx_audio_gen_logs_status ON audio_question_generation_logs (status, created_at DESC);
CREATE INDEX idx_audio_gen_logs_question ON audio_question_generation_logs (question_id) WHERE (question_id IS NOT NULL);
CREATE INDEX idx_audio_gen_logs_rate_limit ON audio_question_generation_logs (admin_user_id, created_at DESC) WHERE ((status)::text = 'SUCCESS'::text);

COMMENT ON TABLE audio_question_generation_logs IS 'Audit des générations de questions audio CO via la pipeline Anthropic + Azure + R2.';
COMMENT ON COLUMN audio_question_generation_logs.requested_params IS 'Paramètres de la requête : niveau, thème, type, compétence, consignes (JSONB).';
COMMENT ON COLUMN audio_question_generation_logs.r2_object_key IS 'Clé de l''objet MP3 dans le bucket R2, ex: audio/<media_uuid>.mp3';
