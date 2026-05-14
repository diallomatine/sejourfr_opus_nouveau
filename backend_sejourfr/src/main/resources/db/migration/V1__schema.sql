-- ============================================================================
-- SejourFR - Schema initial
-- ============================================================================
-- Convention : tous les ids en UUID, timestamps en TIMESTAMPTZ, enums en VARCHAR
-- (Hibernate ecrit les enums en STRING).
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ---------------------------------------------------------------------------
-- Users
-- ---------------------------------------------------------------------------
CREATE TABLE users (
    id                UUID PRIMARY KEY,
    email             VARCHAR(255) NOT NULL UNIQUE,
    password_hash     VARCHAR(255) NOT NULL,
    first_name        VARCHAR(120),
    last_name         VARCHAR(120),
    target_procedure  VARCHAR(16),
    target_level      VARCHAR(8),
    role              VARCHAR(16) NOT NULL DEFAULT 'USER',
    is_active         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login_at     TIMESTAMPTZ
);

CREATE UNIQUE INDEX idx_users_email ON users(email);

-- ---------------------------------------------------------------------------
-- Plans + Abonnements
-- ---------------------------------------------------------------------------
CREATE TABLE plans (
    id              UUID PRIMARY KEY,
    code            VARCHAR(64) NOT NULL UNIQUE,
    name            VARCHAR(120) NOT NULL,
    billing_cycle   VARCHAR(16) NOT NULL,
    price           NUMERIC(10, 2) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE user_subscriptions (
    id          UUID PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id     UUID NOT NULL REFERENCES plans(id),
    status      VARCHAR(16) NOT NULL,
    starts_at   TIMESTAMPTZ NOT NULL,
    ends_at     TIMESTAMPTZ
);

CREATE INDEX idx_user_subs_user ON user_subscriptions(user_id);

-- ---------------------------------------------------------------------------
-- Thèmes
-- ---------------------------------------------------------------------------
CREATE TABLE themes (
    id              UUID PRIMARY KEY,
    module          VARCHAR(16) NOT NULL,
    code            VARCHAR(64) NOT NULL,
    name            VARCHAR(200) NOT NULL,
    description     TEXT,
    display_order   INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT uk_theme_code UNIQUE (code)
);

CREATE INDEX idx_theme_module ON themes(module);

-- ---------------------------------------------------------------------------
-- Médias
-- ---------------------------------------------------------------------------
CREATE TABLE medias (
    id                  UUID PRIMARY KEY,
    type                VARCHAR(16) NOT NULL,
    url                 VARCHAR(500) NOT NULL,
    storage_key         VARCHAR(500),
    original_filename   VARCHAR(255),
    content_type        VARCHAR(120),
    size_bytes          BIGINT,
    duration_sec        INTEGER,
    alt_text            VARCHAR(500),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- Passages
-- ---------------------------------------------------------------------------
CREATE TABLE passages (
    id          UUID PRIMARY KEY,
    type        VARCHAR(16) NOT NULL,
    content     TEXT,
    media_id    UUID REFERENCES medias(id),
    theme_id    UUID REFERENCES themes(id)
);

-- ---------------------------------------------------------------------------
-- Questions + Choices
-- ---------------------------------------------------------------------------
CREATE TABLE questions (
    id              UUID PRIMARY KEY,
    module          VARCHAR(16) NOT NULL,
    theme_id        UUID NOT NULL REFERENCES themes(id),
    passage_id      UUID REFERENCES passages(id),
    media_id        UUID REFERENCES medias(id),
    difficulty      VARCHAR(8) NOT NULL,
    question_type   VARCHAR(24) NOT NULL,
    statement       TEXT NOT NULL,
    explanation     TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ
);

CREATE INDEX idx_question_module_active ON questions(module, is_active);
CREATE INDEX idx_question_theme ON questions(theme_id);
CREATE INDEX idx_question_difficulty ON questions(difficulty);

CREATE TABLE choices (
    id              UUID PRIMARY KEY,
    question_id     UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    label           TEXT NOT NULL,
    is_correct      BOOLEAN NOT NULL DEFAULT FALSE,
    display_order   INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_choice_question ON choices(question_id);

-- ---------------------------------------------------------------------------
-- Exam templates
-- ---------------------------------------------------------------------------
CREATE TABLE exam_templates (
    id                  UUID PRIMARY KEY,
    module              VARCHAR(16) NOT NULL,
    target_level        VARCHAR(8),
    name                VARCHAR(120) NOT NULL,
    duration_seconds    INTEGER NOT NULL,
    total_questions     INTEGER NOT NULL,
    passing_score       INTEGER NOT NULL
);

CREATE TABLE exam_template_rules (
    id                  UUID PRIMARY KEY,
    exam_template_id    UUID NOT NULL REFERENCES exam_templates(id) ON DELETE CASCADE,
    theme_id            UUID NOT NULL REFERENCES themes(id),
    question_type       VARCHAR(24),
    question_count      INTEGER NOT NULL
);

CREATE INDEX idx_etr_template ON exam_template_rules(exam_template_id);

-- ---------------------------------------------------------------------------
-- Attempts + AttemptQuestion + Answer
-- ---------------------------------------------------------------------------
CREATE TABLE attempts (
    id                  UUID PRIMARY KEY,
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exam_template_id    UUID REFERENCES exam_templates(id),
    mode                VARCHAR(16) NOT NULL,
    status              VARCHAR(16) NOT NULL,
    score               INTEGER,
    max_score           INTEGER,
    started_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at         TIMESTAMPTZ
);

CREATE INDEX idx_attempt_user ON attempts(user_id);
CREATE INDEX idx_attempt_status ON attempts(status);

CREATE TABLE attempt_questions (
    id              UUID PRIMARY KEY,
    attempt_id      UUID NOT NULL REFERENCES attempts(id) ON DELETE CASCADE,
    question_id     UUID NOT NULL REFERENCES questions(id),
    position        INTEGER NOT NULL,
    is_correct      BOOLEAN,
    time_spent_sec  INTEGER
);

CREATE INDEX idx_aq_attempt ON attempt_questions(attempt_id);

CREATE TABLE answers (
    id                      UUID PRIMARY KEY,
    attempt_question_id     UUID NOT NULL REFERENCES attempt_questions(id) ON DELETE CASCADE,
    choice_id               UUID NOT NULL REFERENCES choices(id),
    user_id                 UUID NOT NULL REFERENCES users(id),
    answered_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_answer_aq ON answers(attempt_question_id);
CREATE INDEX idx_answer_user ON answers(user_id);

-- ---------------------------------------------------------------------------
-- User question status (favoris, compteurs)
-- ---------------------------------------------------------------------------
CREATE TABLE user_question_statuses (
    id              UUID PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question_id     UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    is_favorite     BOOLEAN NOT NULL DEFAULT FALSE,
    wrong_count     INTEGER NOT NULL DEFAULT 0,
    correct_count   INTEGER NOT NULL DEFAULT 0,
    last_seen_at    TIMESTAMPTZ,
    CONSTRAINT uk_uqs_user_question UNIQUE (user_id, question_id)
);

-- ---------------------------------------------------------------------------
-- Conversations + Messages
-- ---------------------------------------------------------------------------
CREATE TABLE conversations (
    id                  UUID PRIMARY KEY,
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject             VARCHAR(240) NOT NULL,
    status              VARCHAR(16) NOT NULL DEFAULT 'NOUVEAU',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_message_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    unread_for_admin    BOOLEAN NOT NULL DEFAULT TRUE,
    unread_for_user     BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_conv_user ON conversations(user_id);
CREATE INDEX idx_conv_status ON conversations(status);

CREATE TABLE messages (
    id                  UUID PRIMARY KEY,
    conversation_id     UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_type         VARCHAR(16) NOT NULL,
    author_id           UUID NOT NULL REFERENCES users(id),
    body                TEXT NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_message_conv ON messages(conversation_id);
CREATE INDEX idx_message_author ON messages(author_id);
