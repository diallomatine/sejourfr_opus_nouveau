-- ============================================================================
-- V081 — Campagnes de service : nombre de tentatives par compte (2026-09-28)
-- ----------------------------------------------------------------------------
-- Une vague sert d'abord les comptes JAMAIS tentes (attempt_count = 0) ; un
-- compte FAILED n'est retente qu'une fois qu'il n'en reste plus aucun, et au
-- plus `maxAttemptsPerRecipient` fois (email/campaigns-config-v2.json) : une
-- adresse morte ne bloque plus les vagues, et la campagne se termine.
-- Un arret SYSTEMIQUE (limite de debit, SMTP injoignable) ne consomme pas de
-- tentative.
--
-- Les lignes deja ecrites ont ete tentees une fois (deterministe, idempotent :
-- seules les lignes encore a 0 sont touchees).
-- ============================================================================
ALTER TABLE email_campaign_log
    ADD COLUMN attempt_count SMALLINT NOT NULL DEFAULT 0;

UPDATE email_campaign_log
   SET attempt_count = 1
 WHERE attempt_count = 0;
