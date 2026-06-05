-- ============================================================================
-- V001 — Schéma : utilisateurs & authentification
-- ----------------------------------------------------------------------------
-- Tables : users, password_reset_tokens, email_change_tokens, refresh_tokens
-- Relations : tous les tokens -> users (CASCADE). refresh_tokens.replaced_by
--             auto-référence (rotation des refresh tokens).
-- Racine de l'arbre de dépendances : aucune FK sortante sur users.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
CREATE TABLE users (
    id                uuid NOT NULL PRIMARY KEY,
    email             varchar(255) NOT NULL,
    password_hash     varchar(255),
    first_name        varchar(120),
    last_name         varchar(120),
    target_procedure  varchar(16),
    target_level      varchar(8),
    role              varchar(16) DEFAULT 'USER'::varchar NOT NULL,
    is_active         boolean DEFAULT true NOT NULL,
    created_at        timestamptz DEFAULT now() NOT NULL,
    last_login_at     timestamptz,
    auth_provider     varchar(16) DEFAULT 'LOCAL'::varchar NOT NULL,
    provider_user_id  varchar(255),
    CONSTRAINT users_email_key UNIQUE (email)
);
CREATE UNIQUE INDEX idx_users_email ON users (email);
CREATE UNIQUE INDEX idx_users_provider ON users (auth_provider, provider_user_id) WHERE (provider_user_id IS NOT NULL);

-- ---------------------------------------------------------------------------
-- password_reset_tokens
-- ---------------------------------------------------------------------------
CREATE TABLE password_reset_tokens (
    id          uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  varchar(128) NOT NULL,
    expires_at  timestamp NOT NULL,
    used_at     timestamp,
    created_at  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT password_reset_tokens_token_hash_key UNIQUE (token_hash)
);
CREATE INDEX idx_password_reset_user ON password_reset_tokens (user_id);
CREATE INDEX idx_password_reset_expires ON password_reset_tokens (expires_at);

-- ---------------------------------------------------------------------------
-- email_change_tokens
-- ---------------------------------------------------------------------------
CREATE TABLE email_change_tokens (
    id          uuid NOT NULL PRIMARY KEY,
    user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  varchar(128) NOT NULL,
    new_email   varchar(255) NOT NULL,
    expires_at  timestamptz NOT NULL,
    used_at     timestamptz,
    created_at  timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT email_change_tokens_token_hash_key UNIQUE (token_hash)
);
CREATE INDEX idx_email_change_tokens_user_id ON email_change_tokens (user_id);
CREATE INDEX idx_email_change_tokens_token_hash ON email_change_tokens (token_hash);

-- ---------------------------------------------------------------------------
-- refresh_tokens (rotation : replaced_by pointe vers le token successeur)
-- ---------------------------------------------------------------------------
CREATE TABLE refresh_tokens (
    jti         uuid NOT NULL PRIMARY KEY,
    user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at  timestamptz NOT NULL,
    revoked_at  timestamptz,
    replaced_by uuid REFERENCES refresh_tokens(jti),
    created_at  timestamptz DEFAULT now() NOT NULL,
    user_agent  varchar(500),
    ip_address  varchar(64)
);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_user_active ON refresh_tokens (user_id) WHERE (revoked_at IS NULL);
