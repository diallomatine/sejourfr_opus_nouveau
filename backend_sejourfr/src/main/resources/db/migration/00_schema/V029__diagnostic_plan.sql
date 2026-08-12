-- ==========================================================================
-- V029 — Diagnostic TCF rapide et Plan pédagogique
--
-- Le diagnostic réutilise les sujets et les soumissions de production, mais
-- possède son propre profil d'analyse : aucune note /20 et aucune confusion
-- avec les six tâches officielles EE/EO.
-- ==========================================================================

ALTER TABLE production_tasks
    ADD COLUMN diagnostic_code varchar(64),
    ADD COLUMN diagnostic_version integer,
    ADD COLUMN instruction_audio_url varchar(500);

ALTER TABLE production_tasks
    ADD CONSTRAINT chk_prod_task_diagnostic_identity CHECK (
        (diagnostic_code IS NULL AND diagnostic_version IS NULL)
        OR (diagnostic_code IS NOT NULL AND diagnostic_version IS NOT NULL AND diagnostic_version > 0)
    ),
    ADD CONSTRAINT chk_prod_task_diagnostic_audio CHECK (
        instruction_audio_url IS NULL
        OR (diagnostic_code IS NOT NULL AND epreuve = 'TCF_EO')
    ),
    ADD CONSTRAINT uq_prod_task_diagnostic UNIQUE (diagnostic_code, diagnostic_version, epreuve);

-- Ne pas modifier ici chk_prod_task_tcf_irn_ee_word_bounds : sur une base
-- reconstruite, V723 puis V724 doivent encore pouvoir jouer leurs étapes
-- historiques 60-90 puis 40-90. V755 remplace la contrainte par sa forme
-- finale compatible diagnostic juste avant d'insérer le sujet 100-130. Sur
-- une base existante, la contrainte V724 reste donc stricte jusqu'à V755.

CREATE INDEX idx_prod_task_diagnostic_active
    ON production_tasks (diagnostic_code, diagnostic_version, epreuve)
    WHERE diagnostic_code IS NOT NULL AND is_active = true;

ALTER TABLE production_submissions
    ADD COLUMN is_diagnostic boolean NOT NULL DEFAULT false;

-- Un attempt diagnostic correspond à un seul exercice fixe. Cette unicité en
-- base ferme le double-clic concurrent avant qu'un second pipeline IA parte.
CREATE UNIQUE INDEX uq_prod_submission_diagnostic_attempt
    ON production_submissions (attempt_id)
    WHERE is_diagnostic = true;

CREATE TABLE diagnostic_task_skills
(
    production_task_id uuid        NOT NULL REFERENCES production_tasks (id) ON DELETE CASCADE,
    skill_id           uuid        NOT NULL REFERENCES skills (id) ON DELETE RESTRICT,
    display_order      smallint    NOT NULL,
    created_at         timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (production_task_id, skill_id),
    CONSTRAINT uq_diagnostic_task_skill_order UNIQUE (production_task_id, display_order),
    CONSTRAINT chk_diagnostic_task_skill_order CHECK (display_order BETWEEN 1 AND 16)
);

CREATE TABLE diagnostic_sessions
(
    id                   uuid         PRIMARY KEY,
    user_id              uuid         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    diagnostic_code      varchar(64)  NOT NULL,
    diagnostic_version   integer      NOT NULL,
    written_task_id      uuid         NOT NULL REFERENCES production_tasks (id) ON DELETE RESTRICT,
    oral_task_id         uuid         NOT NULL REFERENCES production_tasks (id) ON DELETE RESTRICT,
    written_attempt_id   uuid         NOT NULL REFERENCES attempts (id) ON DELETE RESTRICT,
    oral_attempt_id      uuid         NOT NULL REFERENCES attempts (id) ON DELETE RESTRICT,
    status               varchar(20)  NOT NULL DEFAULT 'IN_PROGRESS',
    summary_json         jsonb,
    error_message        text,
    retry_count          smallint     NOT NULL DEFAULT 0,
    started_at           timestamptz  NOT NULL DEFAULT now(),
    completed_at         timestamptz,
    updated_at           timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT uq_diagnostic_session_user_version
        UNIQUE (user_id, diagnostic_code, diagnostic_version),
    CONSTRAINT uq_diagnostic_session_written_attempt UNIQUE (written_attempt_id),
    CONSTRAINT uq_diagnostic_session_oral_attempt UNIQUE (oral_attempt_id),
    CONSTRAINT chk_diagnostic_session_status CHECK (
        status IN ('IN_PROGRESS', 'ANALYZING', 'COMPLETED', 'FAILED')
    ),
    CONSTRAINT chk_diagnostic_session_retry CHECK (retry_count >= 0),
    CONSTRAINT chk_diagnostic_session_completed CHECK (
        (status = 'COMPLETED' AND completed_at IS NOT NULL AND summary_json IS NOT NULL)
        OR status <> 'COMPLETED'
    )
);

CREATE INDEX idx_diagnostic_session_user_updated
    ON diagnostic_sessions (user_id, updated_at DESC);

CREATE TABLE diagnostic_production_analyses
(
    id                     uuid         PRIMARY KEY,
    submission_id          uuid         NOT NULL REFERENCES production_submissions (id) ON DELETE CASCADE,
    analysis_json          jsonb        NOT NULL,
    level_estimate         varchar(20)  NOT NULL,
    task_completion        varchar(24)  NOT NULL,
    communication_status   varchar(24)  NOT NULL,
    model_used             varchar(80)  NOT NULL,
    schema_version         varchar(20)  NOT NULL,
    tokens_input           integer,
    tokens_output          integer,
    cost_estimate_cents    integer,
    analyzed_at            timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT uq_diagnostic_analysis_submission UNIQUE (submission_id),
    CONSTRAINT chk_diagnostic_analysis_level CHECK (
        level_estimate IN ('A1_NON_ATTEINT', 'A1', 'A2', 'B1', 'B2')
    ),
    CONSTRAINT chk_diagnostic_analysis_completion CHECK (
        task_completion IN ('COMPLETED', 'PARTIAL', 'NOT_COMPLETED')
    ),
    CONSTRAINT chk_diagnostic_analysis_communication CHECK (
        communication_status IN ('EFFECTIVE', 'PARTIAL', 'INEFFECTIVE')
    )
);

CREATE TABLE learning_plan_observations
(
    id                   uuid         PRIMARY KEY,
    user_id              uuid         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    skill_id             uuid         NOT NULL REFERENCES skills (id) ON DELETE RESTRICT,
    source_type          varchar(24)  NOT NULL,
    source_id            uuid         NOT NULL,
    observed             boolean      NOT NULL,
    status               varchar(20)  NOT NULL,
    evidence             text,
    explanation          text,
    confidence           varchar(10),
    baseline             boolean      NOT NULL DEFAULT false,
    observed_at          timestamptz  NOT NULL DEFAULT now(),
    created_at           timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT uq_learning_plan_observation_source
        UNIQUE (user_id, skill_id, source_type, source_id),
    CONSTRAINT chk_learning_plan_observation_source CHECK (
        source_type IN ('DIAGNOSTIC_EE', 'DIAGNOSTIC_EO', 'PRODUCTION_EE',
                        'PRODUCTION_EO', 'SKILL_TRAINING', 'TCF_CO', 'TCF_CE')
    ),
    CONSTRAINT chk_learning_plan_observation_status CHECK (
        status IN ('NOT_OBSERVED', 'PRIORITY', 'TO_REINFORCE', 'SOLID')
    ),
    CONSTRAINT chk_learning_plan_observation_confidence CHECK (
        confidence IS NULL OR confidence IN ('LOW', 'MEDIUM', 'HIGH')
    ),
    CONSTRAINT chk_learning_plan_observation_coherence CHECK (
        (observed = false AND status = 'NOT_OBSERVED' AND evidence IS NULL)
        OR (observed = true AND status <> 'NOT_OBSERVED' AND evidence IS NOT NULL)
    )
);

CREATE INDEX idx_learning_plan_user_recent
    ON learning_plan_observations (user_id, observed_at DESC);

CREATE INDEX idx_learning_plan_user_skill_recent
    ON learning_plan_observations (user_id, skill_id, observed_at DESC);

COMMENT ON COLUMN production_tasks.diagnostic_code IS
    'Identité stable d’un sujet de diagnostic SejourFR ; NULL pour les tâches TCF classiques.';
COMMENT ON COLUMN production_tasks.instruction_audio_url IS
    'URL publique R2 de la consigne fixe ; générée explicitement une seule fois par l’administration.';
COMMENT ON TABLE diagnostic_sessions IS
    'Agrégat reprenable web/mobile qui relie les deux attempts EE/EO d’une version du diagnostic initial.';
COMMENT ON TABLE diagnostic_production_analyses IS
    'Analyse structurée sans note /20 du profil diagnostic, séparée des ai_evaluations TCF officielles.';
COMMENT ON TABLE learning_plan_observations IS
    'Signaux pédagogiques horodatés et sourcés ; extensibles ultérieurement à CO/CE.';
COMMENT ON COLUMN production_submissions.is_diagnostic IS
    'Purpose persistant : bifurque le pipeline avant la notation TCF /20 et impose une soumission par attempt.';
