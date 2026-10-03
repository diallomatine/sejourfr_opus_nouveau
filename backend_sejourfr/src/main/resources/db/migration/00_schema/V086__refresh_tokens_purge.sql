-- ============================================================================
-- V086 — Purge automatique de refresh_tokens (chantier « Activité utilisateurs », lot 1)
-- ----------------------------------------------------------------------------
-- refresh_tokens reste une table TECHNIQUE (sessions vivantes, rotation,
-- détection de réutilisation). Elle n'est PAS un historique de connexions :
-- les connexions vivent dans user_login_event (V087). Aucune colonne ajoutée.
--
-- La purge quotidienne (RefreshTokenPurgeJob) supprime par lots les lignes
-- expirées depuis plus de sejourfr.security.jwt.refresh-token-purge-grace-days
-- (7 j), révoquées ou non. Une ligne révoquée NON expirée reste : c'est elle qui
-- signale la réutilisation d'un jeton volé (SessionService.rotate).
--
-- 1. replaced_by passe en ON DELETE SET NULL. La colonne n'est jamais lue ; en
--    NO ACTION, un lot qui emporte le successeur d'une ligne restante échouait
--    en entier (contrôle en fin d'instruction).
-- 2. Index sur expires_at : prédicat de la purge, aucun index ne le couvrait.
-- ============================================================================
ALTER TABLE refresh_tokens
    DROP CONSTRAINT refresh_tokens_replaced_by_fkey,
    ADD CONSTRAINT refresh_tokens_replaced_by_fkey
        FOREIGN KEY (replaced_by) REFERENCES refresh_tokens (jti) ON DELETE SET NULL;

CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens (expires_at);
