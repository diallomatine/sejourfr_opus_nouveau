-- ============================================================================
-- V008 — Schéma : messagerie support (conversations utilisateur <-> admin)
-- ----------------------------------------------------------------------------
-- Tables : conversations, messages
-- Relations : conversations -> users (CASCADE).
--             messages -> conversations (CASCADE) + users (author).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- conversations
-- ---------------------------------------------------------------------------
CREATE TABLE conversations (
    id               uuid NOT NULL PRIMARY KEY,
    user_id          uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject          varchar(240) NOT NULL,
    status           varchar(16) DEFAULT 'NOUVEAU'::varchar NOT NULL,
    created_at       timestamptz DEFAULT now() NOT NULL,
    last_message_at  timestamptz DEFAULT now() NOT NULL,
    unread_for_admin boolean DEFAULT true NOT NULL,
    unread_for_user  boolean DEFAULT false NOT NULL
);
CREATE INDEX idx_conv_user ON conversations (user_id);
CREATE INDEX idx_conv_status ON conversations (status);

-- ---------------------------------------------------------------------------
-- messages
-- ---------------------------------------------------------------------------
CREATE TABLE messages (
    id              uuid NOT NULL PRIMARY KEY,
    conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_type     varchar(16) NOT NULL,
    author_id       uuid NOT NULL REFERENCES users(id),
    body            text NOT NULL,
    created_at      timestamptz DEFAULT now() NOT NULL
);
CREATE INDEX idx_message_conv ON messages (conversation_id);
CREATE INDEX idx_message_author ON messages (author_id);
