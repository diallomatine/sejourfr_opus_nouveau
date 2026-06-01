-- ============================================================================
-- V009 — Schéma : brouillons de questions audio CO (workflow batch)
-- ----------------------------------------------------------------------------
-- Table : audio_question_draft
-- Relations : -> themes. Transcripts + SSML pré-générés hors-ligne, audio
--             synthétisé par lots de 10 (batch_id).
-- ============================================================================

CREATE TABLE audio_question_draft (
    id                  uuid NOT NULL PRIMARY KEY,
    difficulty          varchar(2) NOT NULL,
    competence_code     varchar(50),
    theme_id            uuid NOT NULL REFERENCES themes(id),
    transcript_text     text NOT NULL,
    ssml_text           text NOT NULL,
    statement           text NOT NULL,
    explanation         text,
    choices             jsonb NOT NULL,
    voice_recommended   varchar(50),
    status              varchar(20) DEFAULT 'TEXT_VALIDATED'::varchar NOT NULL,
    audio_url           text,
    audio_duration_sec  integer,
    audio_voice_used    varchar(50),
    audio_generated_at  timestamptz,
    batch_id            uuid,
    created_at          timestamptz DEFAULT now() NOT NULL,
    audio_validated_at  timestamptz,
    audio_validated_by  varchar(100),
    rejection_reason    text,
    CONSTRAINT chk_audio_draft_difficulty CHECK (((difficulty)::text = ANY ((ARRAY['A2','B1','B2'])::text[]))),
    CONSTRAINT chk_audio_draft_status CHECK (((status)::text = ANY ((ARRAY['TEXT_VALIDATED','AUDIO_GENERATING','AUDIO_PENDING_REVIEW','PUBLISHED','REJECTED'])::text[])))
);
CREATE INDEX idx_audio_draft_status ON audio_question_draft (status);
CREATE INDEX idx_audio_draft_created ON audio_question_draft (created_at);
CREATE INDEX idx_audio_draft_batch ON audio_question_draft (batch_id) WHERE (batch_id IS NOT NULL);

COMMENT ON TABLE audio_question_draft IS 'Brouillons de questions audio CO (workflow batch). Transcripts + SSML pre-generes hors-ligne, audio synthese par lots de 10.';
COMMENT ON COLUMN audio_question_draft.choices IS 'Tableau JSONB de 4 choix : [{label: string, is_correct: boolean, display_order: int}].';
COMMENT ON COLUMN audio_question_draft.batch_id IS 'Regroupe les drafts traites dans une meme execution de batch-generate. NULL avant traitement.';
