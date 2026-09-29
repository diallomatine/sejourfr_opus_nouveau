-- ============================================================================
-- V014 — Support : la boite de reception admin accueille le formulaire de
--        contact (potentiellement des invites, sans compte).
-- ----------------------------------------------------------------------------
-- Les conversations etaient strictement user <-> admin (user_id / author_id
-- NOT NULL). Un message de contact peut venir d'un visiteur non connecte : on
-- rend ces FK nullable et on stocke nom + email du contact pour pouvoir lui
-- repondre par email. Les conversations in-app existantes restent valides
-- (user_id renseigne, contact_* a NULL).
-- ============================================================================

ALTER TABLE conversations
    ALTER COLUMN user_id DROP NOT NULL,
    ADD COLUMN contact_name  varchar(120),
    ADD COLUMN contact_email varchar(255);

ALTER TABLE messages
    ALTER COLUMN author_id DROP NOT NULL;
