-- ============================================================================
-- V100 — Tokens de confirmation pour changement d'email.
--
-- Quand un user change son email depuis l'app, on crée un token associé au
-- nouvel email demandé (pas encore appliqué) + on envoie un mail de vérif au
-- nouvel email. L'email n'est mis à jour qu'au moment où le user clique sur
-- le lien (GET /api/auth/confirm-email-change?token=...).
--
-- Sécurité : on stocke le HASH du token (SHA-256), pas le token en clair —
-- même pattern que password_reset_tokens (V070).
-- ============================================================================

CREATE TABLE email_change_tokens (
    id           UUID PRIMARY KEY,
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash   VARCHAR(128) NOT NULL UNIQUE,
    new_email    VARCHAR(255) NOT NULL,
    expires_at   TIMESTAMPTZ NOT NULL,
    used_at      TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_email_change_tokens_user_id ON email_change_tokens(user_id);
CREATE INDEX idx_email_change_tokens_token_hash ON email_change_tokens(token_hash);
