-- ============================================================================
-- V007 — Schéma : suivi utilisateur par question (favoris, stats)
-- ----------------------------------------------------------------------------
-- Table : user_question_statuses
-- Relations : -> users (CASCADE), questions (CASCADE).
-- Unicité (user_id, question_id) : une ligne de suivi par couple.
-- ============================================================================

CREATE TABLE user_question_statuses (
    id            uuid NOT NULL PRIMARY KEY,
    user_id       uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question_id   uuid NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    is_favorite   boolean DEFAULT false NOT NULL,
    wrong_count   integer DEFAULT 0 NOT NULL,
    correct_count integer DEFAULT 0 NOT NULL,
    last_seen_at  timestamptz,
    updated_at    timestamptz,
    CONSTRAINT uk_uqs_user_question UNIQUE (user_id, question_id)
);
