-- ============================================================================
-- V102 — Refresh tokens stateful avec rotation et révocation.
--
-- Avant : les refresh tokens étaient des JWT auto-suffisants, sans état serveur.
-- Conséquence : impossible de les révoquer. Un token volé restait valide
-- jusqu'à son expiration (30 jours), même après changement de mot de passe.
-- Cf audit sécurité Vuln 3.
--
-- Maintenant : chaque refresh token a une row ici. À chaque /refresh, on
-- révoque l'ancien et on émet un nouveau (rotation). changePassword,
-- resetPassword et confirmEmailChange cascade-révoquent toutes les sessions
-- du user. Un endpoint POST /api/auth/logout révoque la session courante.
--
-- Le JWT contient le `jti` (= cette PK) en claim ; on lookup à chaque /refresh.
-- ============================================================================

CREATE TABLE refresh_tokens (
    jti          UUID PRIMARY KEY,
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at   TIMESTAMPTZ NOT NULL,
    revoked_at   TIMESTAMPTZ,
    -- Quand on rotate : revoked_at posé + replaced_by pointe sur le nouveau jti.
    -- Permet plus tard de détecter un re-use d'un token révoqué (suspect = vol).
    replaced_by  UUID REFERENCES refresh_tokens(jti),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Pour observabilité / forensics ; nullable car le contexte HTTP peut
    -- manquer (ex: création depuis un test).
    user_agent   VARCHAR(500),
    ip_address   VARCHAR(64)
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
-- Index partiel pour les listings "sessions actives" — bien plus petit.
CREATE INDEX idx_refresh_tokens_user_active
    ON refresh_tokens(user_id) WHERE revoked_at IS NULL;
