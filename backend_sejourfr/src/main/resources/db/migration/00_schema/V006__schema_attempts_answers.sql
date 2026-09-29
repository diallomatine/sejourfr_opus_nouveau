-- ============================================================================
-- V006 — Schéma : tentatives & réponses (runner)
-- ----------------------------------------------------------------------------
-- Tables : attempts, attempt_questions, answers
-- Relations : attempts -> users (CASCADE), exam_templates, attempts (parent,
--             CASCADE, pour les examens blancs TCF complets).
--             attempt_questions -> attempts (CASCADE) + questions.
--             answers -> attempt_questions (CASCADE) + users.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- attempts
-- ---------------------------------------------------------------------------
CREATE TABLE attempts (
    id                        uuid NOT NULL PRIMARY KEY,
    user_id                   uuid REFERENCES users(id) ON DELETE CASCADE,
    exam_template_id          uuid REFERENCES exam_templates(id),
    mode                      varchar(16) NOT NULL,
    status                    varchar(16) NOT NULL,
    score                     integer,
    max_score                 integer,
    started_at                timestamptz DEFAULT now() NOT NULL,
    finished_at               timestamptz,
    type                      varchar(16),
    module                    varchar(16),
    total_questions           integer,
    time_limit_seconds        integer,
    pass_threshold            integer,
    level_achieved            varchar(8),
    lot_numero                integer,
    lot_question_type         varchar(24),
    lot_difficulty            varchar(8),
    lot_theme_id              uuid,
    client_ip                 varchar(45),
    epreuve                   varchar(20) NOT NULL,
    parent_attempt_id         uuid REFERENCES attempts(id) ON DELETE CASCADE,
    module_exam_question_type varchar(24),
    weighted_score            integer,
    max_weighted_score        integer,
    final_cecrl_level         varchar(24),
    slot_number               integer,
    cecrl_level               varchar(24),
    CONSTRAINT chk_attempts_epreuve CHECK (((epreuve)::text = ANY ((ARRAY['CIVIQUE','TCF_CO','TCF_CE','TCF_STRUCTURE','TCF_EO','TCF_EE','TCF_COMPLET'])::text[])))
);
CREATE INDEX idx_attempt_user ON attempts (user_id);
CREATE INDEX idx_attempt_status ON attempts (status);
CREATE INDEX idx_attempts_parent ON attempts (parent_attempt_id) WHERE (parent_attempt_id IS NOT NULL);
CREATE INDEX idx_attempts_demo_quota ON attempts (client_ip, module, type, started_at) WHERE (user_id IS NULL);
CREATE INDEX idx_attempts_module_exam ON attempts (user_id, module, module_exam_question_type, finished_at DESC) WHERE (module_exam_question_type IS NOT NULL);
CREATE INDEX idx_attempts_slot_number ON attempts (user_id, slot_number, started_at DESC) WHERE (slot_number IS NOT NULL);
CREATE INDEX idx_attempts_user_lot ON attempts (user_id, module, lot_question_type, lot_difficulty, lot_numero, finished_at DESC) WHERE (lot_numero IS NOT NULL);
CREATE INDEX idx_attempts_user_lot_civique ON attempts (user_id, lot_theme_id, lot_numero, finished_at DESC) WHERE ((lot_theme_id IS NOT NULL) AND (finished_at IS NOT NULL));

COMMENT ON COLUMN attempts.epreuve IS 'Nature fine de l''epreuve (orthogonale a `mode`). Pour les examens blancs TCF complets, le parent porte TCF_COMPLET et les sous-attempts portent TCF_CO/TCF_CE/TCF_EO/TCF_EE.';
COMMENT ON COLUMN attempts.parent_attempt_id IS 'NULL pour un attempt isole. Renseigne pour les sous-attempts d''un examen blanc TCF complet. CASCADE -> supprimer le parent supprime tous les enfants.';
COMMENT ON COLUMN attempts.final_cecrl_level IS 'TCF_COMPLET uniquement : niveau CECRL plancher des 4 sous-épreuves, persisté à la finalisation. NULL si évaluations IA encore en cours.';
COMMENT ON COLUMN attempts.cecrl_level IS 'Examens module TCF (CO/CE) : niveau CECRL estimé à la finalisation (TcfLevelEstimatorService), plafonné B2. NULL pour le civique, l''entraînement libre et les attempts pré-V416.';

-- ---------------------------------------------------------------------------
-- attempt_questions
-- ---------------------------------------------------------------------------
CREATE TABLE attempt_questions (
    id             uuid NOT NULL PRIMARY KEY,
    attempt_id     uuid NOT NULL REFERENCES attempts(id) ON DELETE CASCADE,
    question_id    uuid NOT NULL REFERENCES questions(id),
    "position"     integer NOT NULL,
    is_correct     boolean,
    time_spent_sec integer
);
CREATE INDEX idx_aq_attempt ON attempt_questions (attempt_id);

-- ---------------------------------------------------------------------------
-- answers (une réponse par attempt_question : contrainte unique)
-- ---------------------------------------------------------------------------
CREATE TABLE answers (
    id                  uuid NOT NULL PRIMARY KEY,
    attempt_question_id uuid NOT NULL REFERENCES attempt_questions(id) ON DELETE CASCADE,
    user_id             uuid REFERENCES users(id),
    answered_at         timestamptz DEFAULT now() NOT NULL,
    selected_choice_ids jsonb,
    is_correct          boolean
);
CREATE UNIQUE INDEX uk_answer_attempt_question ON answers (attempt_question_id);
CREATE INDEX idx_answer_aq ON answers (attempt_question_id);
CREATE INDEX idx_answer_user ON answers (user_id);
