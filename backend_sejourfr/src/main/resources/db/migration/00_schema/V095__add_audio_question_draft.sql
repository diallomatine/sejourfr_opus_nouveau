-- ============================================================================
-- V095 : Drafts de questions audio TCF CO (workflow batch)
-- ============================================================================
-- Pipeline parallele au workflow unitaire (V070). Les transcripts + SSML +
-- question + choix sont pre-generes hors-ligne (Claude desktop) puis inseres
-- manuellement dans cette table en status TEXT_VALIDATED.
--
-- L'admin lance ensuite la generation audio (Azure Speech + Cloudflare R2)
-- par batch de 10. Apres ecoute et validation, le draft est promu en question
-- "live" (tables questions/choices/medias) -> status PUBLISHED.
--
-- Cycle de vie :
--   TEXT_VALIDATED       (insertion SQL)
--     -> AUDIO_GENERATING (batch lance, en cours)
--     -> AUDIO_PENDING_REVIEW (audio genere, attend ecoute admin)
--     -> PUBLISHED        (copie vers tables principales)
--     -> REJECTED         (rejet manuel)
-- ============================================================================

CREATE TABLE audio_question_draft (
    id                    UUID PRIMARY KEY,
    difficulty            VARCHAR(2) NOT NULL,
    competence_code       VARCHAR(50),
    theme_id              UUID NOT NULL REFERENCES themes(id),
    transcript_text       TEXT NOT NULL,
    ssml_text             TEXT NOT NULL,
    statement             TEXT NOT NULL,
    explanation           TEXT,
    choices               JSONB NOT NULL,
    voice_recommended     VARCHAR(50),
    status                VARCHAR(20) NOT NULL DEFAULT 'TEXT_VALIDATED',
    audio_url             TEXT,
    audio_duration_sec    INTEGER,
    audio_voice_used      VARCHAR(50),
    audio_generated_at    TIMESTAMPTZ,
    batch_id              UUID,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    audio_validated_at    TIMESTAMPTZ,
    audio_validated_by    VARCHAR(100),
    rejection_reason      TEXT,

    CONSTRAINT chk_audio_draft_difficulty
        CHECK (difficulty IN ('A2', 'B1', 'B2')),

    CONSTRAINT chk_audio_draft_status
        CHECK (status IN (
            'TEXT_VALIDATED',
            'AUDIO_GENERATING',
            'AUDIO_PENDING_REVIEW',
            'PUBLISHED',
            'REJECTED'
        ))
);

CREATE INDEX idx_audio_draft_status ON audio_question_draft(status);
CREATE INDEX idx_audio_draft_batch ON audio_question_draft(batch_id) WHERE batch_id IS NOT NULL;
CREATE INDEX idx_audio_draft_created ON audio_question_draft(created_at);

COMMENT ON TABLE audio_question_draft IS
    'Brouillons de questions audio CO (workflow batch). Transcripts + SSML pre-generes hors-ligne, audio synthese par lots de 10.';
COMMENT ON COLUMN audio_question_draft.choices IS
    'Tableau JSONB de 4 choix : [{label: string, is_correct: boolean, display_order: int}].';
COMMENT ON COLUMN audio_question_draft.batch_id IS
    'Regroupe les drafts traites dans une meme execution de batch-generate. NULL avant traitement.';
