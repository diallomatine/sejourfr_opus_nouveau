-- ============================================================================
-- V19 : Ajout du mode audio sur les questions
-- ============================================================================
-- Permet de distinguer deux formats de question audio CO :
--   - WRITTEN_QUESTION : document sonore + question/choix ecrits (defaut historique)
--   - FULL_AUDIO       : tout lu dans l'audio (question + choix entendus)
--
-- Les questions non audio (CE, STRUCTURE) gardent audio_mode = NULL.
-- ============================================================================

ALTER TABLE questions ADD COLUMN IF NOT EXISTS audio_mode VARCHAR(32);

ALTER TABLE questions ADD CONSTRAINT chk_question_audio_mode
    CHECK (audio_mode IS NULL OR audio_mode IN ('WRITTEN_QUESTION', 'FULL_AUDIO'));

CREATE INDEX IF NOT EXISTS idx_questions_audio_mode
    ON questions(audio_mode)
    WHERE audio_mode IS NOT NULL;

COMMENT ON COLUMN questions.audio_mode IS
    'Mode d''audio pour les questions de Comprehension Orale : WRITTEN_QUESTION (document seul) ou FULL_AUDIO (tout lu). NULL pour les questions non audio.';
