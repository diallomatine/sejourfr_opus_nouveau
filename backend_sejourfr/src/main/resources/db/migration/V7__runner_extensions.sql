-- ============================================================================
-- V7 : Extensions du runner (sessions / réponses / favoris / médias)
-- ============================================================================
-- Aligne le schéma avec les nouvelles entités :
--   - attempts : type, module, total_questions, time_limit_seconds, pass_threshold
--   - answers  : passage d'un row-par-choix à un row-par-question avec liste
--                de choix sélectionnés (JSONB) + flag is_correct
--   - user_question_statuses : updated_at
--   - medias   : transcript
-- ============================================================================

-- ---------------------------------------------------------------------------
-- attempts : nouvelles colonnes pour le runner
-- ---------------------------------------------------------------------------
ALTER TABLE attempts
    ADD COLUMN IF NOT EXISTS type                VARCHAR(16),
    ADD COLUMN IF NOT EXISTS module              VARCHAR(16),
    ADD COLUMN IF NOT EXISTS total_questions     INTEGER,
    ADD COLUMN IF NOT EXISTS time_limit_seconds  INTEGER,
    ADD COLUMN IF NOT EXISTS pass_threshold      INTEGER;

-- ---------------------------------------------------------------------------
-- answers : refonte
--   Avant : (attempt_question_id, choice_id, user_id, answered_at)
--           => une ligne par choix sélectionné
--   Après : (attempt_question_id UNIQUE, user_id, selected_choice_ids jsonb,
--            is_correct, answered_at)
--           => une ligne par question répondue
-- ---------------------------------------------------------------------------
ALTER TABLE answers
    DROP CONSTRAINT IF EXISTS answers_choice_id_fkey;

ALTER TABLE answers
    DROP COLUMN IF EXISTS choice_id;

ALTER TABLE answers
    ADD COLUMN IF NOT EXISTS selected_choice_ids JSONB,
    ADD COLUMN IF NOT EXISTS is_correct          BOOLEAN;

-- user_id était NOT NULL dans le schéma initial. Le nouveau code peut
-- s'appuyer sur attempt_question.attempt.user_id, donc on autorise NULL
-- (le @PrePersist sur Answer le re-renseigne automatiquement).
ALTER TABLE answers
    ALTER COLUMN user_id DROP NOT NULL;

-- Une réponse unique par attempt_question.
CREATE UNIQUE INDEX IF NOT EXISTS uk_answer_attempt_question
    ON answers (attempt_question_id);

-- ---------------------------------------------------------------------------
-- user_question_statuses : timestamp de dernière modification
-- ---------------------------------------------------------------------------
ALTER TABLE user_question_statuses
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

-- ---------------------------------------------------------------------------
-- medias : transcription textuelle (utile pour les audios TCF)
-- ---------------------------------------------------------------------------
ALTER TABLE medias
    ADD COLUMN IF NOT EXISTS transcript TEXT;
