-- ============================================================================
-- V005 — Schéma : gabarits d'examens blancs
-- ----------------------------------------------------------------------------
-- Tables : exam_templates, exam_template_rules
-- Relations : exam_template_rules -> exam_templates (CASCADE) + themes.
--             Une règle décrit un quota (thème/type/difficulté × nb questions).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- exam_templates
-- ---------------------------------------------------------------------------
CREATE TABLE exam_templates (
    id               uuid NOT NULL PRIMARY KEY,
    module           varchar(16) NOT NULL,
    target_level     varchar(8),
    name             varchar(120) NOT NULL,
    duration_seconds integer NOT NULL,
    total_questions  integer NOT NULL,
    passing_score    integer NOT NULL,
    slug             varchar(64) NOT NULL,
    subtitle         varchar(160),
    description      text,
    target_procedure varchar(8),
    is_free          boolean DEFAULT false NOT NULL,
    is_published     boolean DEFAULT false NOT NULL,
    "position"       integer DEFAULT 0 NOT NULL,
    created_at       timestamptz DEFAULT now() NOT NULL,
    updated_at       timestamptz
);
CREATE UNIQUE INDEX uq_exam_templates_slug ON exam_templates (slug);
CREATE INDEX idx_exam_templates_module_published_position ON exam_templates (module, is_published, "position");

-- ---------------------------------------------------------------------------
-- exam_template_rules
-- ---------------------------------------------------------------------------
CREATE TABLE exam_template_rules (
    id               uuid NOT NULL PRIMARY KEY,
    exam_template_id uuid NOT NULL REFERENCES exam_templates(id) ON DELETE CASCADE,
    theme_id         uuid REFERENCES themes(id),
    question_type    varchar(24),
    question_count   integer NOT NULL,
    difficulty       varchar(8),
    "position"       integer DEFAULT 0 NOT NULL
);
CREATE INDEX idx_etr_template ON exam_template_rules (exam_template_id);
