-- ============================================================================
-- V012 — Suppression de compte (RGPD + App Store Guideline 5.1.1(v))
-- ----------------------------------------------------------------------------
-- Stratégie : anonymisation. Le compte n'est pas physiquement supprimé (on
-- conserve l'historique d'abonnement anonymisé pour l'obligation comptable),
-- mais les données personnelles directes sont effacées et `deleted_at` est
-- posé. L'expiration / la non-réutilisation se lisent via ce flag.
-- ============================================================================

ALTER TABLE users ADD COLUMN deleted_at timestamptz;

CREATE INDEX idx_users_deleted_at ON users (deleted_at) WHERE deleted_at IS NOT NULL;
