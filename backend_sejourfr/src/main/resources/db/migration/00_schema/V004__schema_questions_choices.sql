-- ============================================================================
-- V004 — Schéma : questions & choix (QCM)
-- ----------------------------------------------------------------------------
-- Tables : questions, choices
-- Relations : questions -> themes (NOT NULL), passages, medias.
--             choices -> questions (CASCADE).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- questions
-- ---------------------------------------------------------------------------
CREATE TABLE questions (
    id              uuid NOT NULL PRIMARY KEY,
    module          varchar(16) NOT NULL,
    theme_id        uuid NOT NULL REFERENCES themes(id),
    passage_id      uuid REFERENCES passages(id),
    media_id        uuid REFERENCES medias(id),
    audio_media_id  uuid REFERENCES medias(id),
    difficulty      varchar(8) NOT NULL,
    question_type   varchar(24) NOT NULL,
    statement       text NOT NULL,
    explanation     text,
    is_active       boolean DEFAULT true NOT NULL,
    created_at      timestamptz DEFAULT now() NOT NULL,
    updated_at      timestamptz,
    status          varchar(16) DEFAULT 'ACTIVE'::varchar NOT NULL,
    tcf_sub_theme   varchar(64),
    audio_mode      varchar(32),
    competence_code varchar(64),
    CONSTRAINT chk_question_status CHECK (((status)::text = ANY ((ARRAY['DRAFT','ACTIVE','ARCHIVED'])::text[]))),
    CONSTRAINT chk_question_audio_mode CHECK (((audio_mode IS NULL) OR ((audio_mode)::text = ANY ((ARRAY['WRITTEN_QUESTION','FULL_AUDIO'])::text[]))))
);
CREATE INDEX idx_question_theme ON questions (theme_id);
CREATE INDEX idx_question_difficulty ON questions (difficulty);
CREATE INDEX idx_question_module_active ON questions (module, is_active);
CREATE INDEX idx_questions_status ON questions (status);
CREATE INDEX idx_questions_tcf_sub_theme ON questions (tcf_sub_theme) WHERE (tcf_sub_theme IS NOT NULL);
CREATE INDEX idx_questions_audio_mode ON questions (audio_mode) WHERE (audio_mode IS NOT NULL);
CREATE INDEX idx_questions_competence_code ON questions (competence_code);

COMMENT ON COLUMN questions.status IS 'Cycle de vie : DRAFT (brouillon admin, non utilisable), ACTIVE (utilisable), ARCHIVED (retiré).';
COMMENT ON COLUMN questions.tcf_sub_theme IS 'Sous-thème TCF CO (santé, transports, ...), null pour les questions civique ou non audio.';
COMMENT ON COLUMN questions.audio_mode IS 'Mode d''audio pour les questions de Compréhension Orale : WRITTEN_QUESTION (document seul) ou FULL_AUDIO (tout lu). NULL pour les questions non audio.';
COMMENT ON COLUMN questions.media_id IS 'Média principal : image (CE, CO_IMAGE) ou audio (CO). Pour CO_IMAGE, porte l''image.';
COMMENT ON COLUMN questions.audio_media_id IS 'Second média audio, utilisé uniquement par CO_IMAGE (image dans media_id + audio des 4 propositions ici). NULL sinon.';

-- ---------------------------------------------------------------------------
-- choices
-- ---------------------------------------------------------------------------
CREATE TABLE choices (
    id            uuid NOT NULL PRIMARY KEY,
    question_id   uuid NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    label         text NOT NULL,
    is_correct    boolean DEFAULT false NOT NULL,
    display_order integer DEFAULT 0 NOT NULL
);
CREATE INDEX idx_choice_question ON choices (question_id);
