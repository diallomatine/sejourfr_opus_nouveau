-- ============================================================================
-- V080 — Campagnes d'information de service (incident / reprise)
-- ----------------------------------------------------------------------------
-- Une ligne par (campagne, compte) : c'est ELLE qui rend une campagne
-- idempotente. Relancer une campagne ne sert que les comptes sans ligne SENT
-- ou SKIPPED ; une ligne FAILED (ou PENDING orpheline) est reprise.
--
-- 🛑 Aucune adresse ici : le destinataire est relu sur users.email au moment
-- de l'envoi, et le detail de l'envoi vit dans email_deliveries (V073).
-- ============================================================================
CREATE TABLE email_campaign_log (
    id             UUID         PRIMARY KEY,
    campaign_code  VARCHAR(32)  NOT NULL
        CONSTRAINT ck_email_campaign_log_code
            CHECK (campaign_code IN ('incident', 'reprise')),
    user_id        UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    status         VARCHAR(16)  NOT NULL
        CONSTRAINT ck_email_campaign_log_status
            CHECK (status IN ('PENDING', 'SENT', 'FAILED', 'SKIPPED')),
    sent_at        TIMESTAMPTZ  NULL,
    created_at     TIMESTAMPTZ  NOT NULL,
    updated_at     TIMESTAMPTZ  NOT NULL,
    CONSTRAINT ux_email_campaign_log_code_user UNIQUE (campaign_code, user_id)
);

COMMENT ON TABLE email_campaign_log IS
    'Campagnes de service (incident, reprise) : une ligne par compte servi ou tente. Idempotence des relances.';
