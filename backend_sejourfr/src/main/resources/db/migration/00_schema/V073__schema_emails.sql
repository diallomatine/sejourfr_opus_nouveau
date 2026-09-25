-- ============================================================================
-- V073 — LE SYSTEME D'EMAILS : preferences, journal d'envoi, activite reelle
-- ----------------------------------------------------------------------------
-- Brief : docs/email/brief-emails-sejourfr.md. Audit : AUDIT_emails_phase1.md.
-- Arbitrages opposables : docs/email/REPONSES_AUDIT_emails.md.
-- Decisions prises en autonomie : docs/email/decisions.md.
-- Regle metier : docs/regles/emails.md.
--
-- 🛑 PURE ADDITION. Aucune table existante n'est modifiee, aucune donnee
-- existante n'est reecrite. Trois index sont AJOUTES sur des tables de pratique
-- (answers, user_skill_attempts, realtime_sessions) pour la vue d'activite.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. user_email_preferences — une ligne ABSENTE vaut les valeurs par defaut.
-- ----------------------------------------------------------------------------
-- Pas de migration de masse : la ligne naît a la premiere modification (page
-- « Notifications par e-mail » ou lien de desabonnement). Les requetes du
-- scheduler lisent COALESCE(engagement_enabled, TRUE).
-- Aucun champ ne concerne les mails REQUIRED : ils ne se desactivent pas.
CREATE TABLE user_email_preferences (
    user_id              UUID        PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    engagement_enabled   BOOLEAN     NOT NULL DEFAULT TRUE,
    marketing_enabled    BOOLEAN     NOT NULL DEFAULT FALSE,
    -- Preuve du consentement MARKETING (opt-in) : posee quand marketing passe a
    -- TRUE, jamais effacee ensuite (c'est une preuve datee, pas un etat).
    marketing_consent_at TIMESTAMPTZ NULL,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE user_email_preferences IS
    'Preferences email du compte. Ligne absente = engagement actif, marketing inactif.';


-- ----------------------------------------------------------------------------
-- 2. email_deliveries — le journal de CHAQUE envoi (et de chaque refus trace).
-- ----------------------------------------------------------------------------
-- 🛑 On n'y stocke JAMAIS le HTML ni les variables : elles peuvent contenir une
-- URL a token (reset, changement d'email). Une relance differee RECONSTRUIT les
-- variables depuis la source (user, acces, reference_id, occurred_at).
--
-- user_id est NULLABLE : l'accuse de reception du formulaire de contact et la
-- reponse du support partent vers un visiteur qui n'a pas forcement de compte.
-- Le ON DELETE CASCADE ne se declenchera en pratique jamais (un compte est
-- ANONYMISE, pas supprime) : AccountDeletionService purge ces lignes a la main.
CREATE TABLE email_deliveries (
    id                  UUID         PRIMARY KEY,
    user_id             UUID         NULL REFERENCES users (id) ON DELETE CASCADE,
    -- Pas de CHECK sur email_type : la liste grandit a chaque nouveau mail, et
    -- l'enum Java (EmailType) est l'autorite. Les CHECK portent sur les axes fermes.
    email_type          VARCHAR(64)  NOT NULL,
    category            VARCHAR(16)  NOT NULL
        CONSTRAINT ck_email_deliveries_category
            CHECK (category IN ('REQUIRED', 'ENGAGEMENT', 'MARKETING')),
    recipient           VARCHAR(320) NOT NULL,
    status              VARCHAR(16)  NOT NULL
        CONSTRAINT ck_email_deliveries_status
            CHECK (status IN ('PENDING', 'SENT', 'FAILED', 'SKIPPED')),
    provider            VARCHAR(16)  NOT NULL
        CONSTRAINT ck_email_deliveries_provider
            CHECK (provider IN ('SPRING_MAIL', 'BREVO')),
    -- Servira aux webhooks Brevo (rebonds, plaintes). Toujours NULL en Spring Mail.
    provider_message_id VARCHAR(255) NULL,
    deduplication_key   VARCHAR(255) NULL,
    -- La source a relire pour reconstruire les variables d'une relance differee
    -- (id de l'acces, du jeton de reset, du message support...). Jamais un secret.
    reference_id        UUID         NULL,
    -- L'instant du FAIT metier quand aucune table ne le porte (PASSWORD_CHANGED :
    -- aucune ligne n'enregistre un changement de mot de passe). Une date n'est
    -- pas une donnee sensible.
    occurred_at         TIMESTAMPTZ  NULL,
    -- Pourquoi une ligne est SKIPPED (preference, allowlist dev, cle consommee).
    skip_reason         VARCHAR(32)  NULL
        CONSTRAINT ck_email_deliveries_skip_reason
            CHECK (skip_reason IS NULL
                   OR skip_reason IN ('PREFERENCE', 'ALLOWLIST', 'KEY_CONSUMED')),
    -- Tronque a 500 caracteres, adresses masquees : jamais de donnee sensible.
    error_message       VARCHAR(500) NULL,
    -- Nombre de tentatives SMTP faites sur CETTE ligne (relance immediate).
    attempt_count       SMALLINT     NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ  NOT NULL,
    sent_at             TIMESTAMPTZ  NULL,
    failed_at           TIMESTAMPTZ  NULL
);

COMMENT ON TABLE email_deliveries IS
    'Journal des envois email. Retention 12 mois (EmailRetentionService), purge a la suppression du compte.';

-- 🛑 L'ANTI-DOUBLON EST ICI, ET NULLE PART AILLEURS.
-- L'envoi fait « INSERT PENDING d'abord » (INSERT ... ON CONFLICT DO NOTHING) :
-- deux appels concurrents sur la meme cle => une seule ligne gagne, sans
-- SELECT prealable. Une ligne FAILED ne bloque pas : la relance reste possible.
-- SKIPPED bloque (decision D-1) : c'est ce qui permet de CONSOMMER une cle sans
-- envoyer (adoption d'un diagnostic invite, complement C des arbitrages).
CREATE UNIQUE INDEX ux_email_deliveries_dedup
    ON email_deliveries (deduplication_key)
    WHERE status IN ('PENDING', 'SENT', 'SKIPPED');

-- Le plafond ENGAGEMENT (1 par jour calendaire Europe/Paris) compte ici.
CREATE INDEX idx_email_deliveries_user_cat_created
    ON email_deliveries (user_id, category, created_at);

-- Nombre de tentatives deja echouees pour une cle (plafond de relance differee).
CREATE INDEX idx_email_deliveries_key
    ON email_deliveries (deduplication_key)
    WHERE deduplication_key IS NOT NULL;

-- Balayages du scheduler : PENDING bloques (> 1 h) et FAILED a relancer.
CREATE INDEX idx_email_deliveries_pending
    ON email_deliveries (created_at)
    WHERE status = 'PENDING';
CREATE INDEX idx_email_deliveries_failed
    ON email_deliveries (created_at)
    WHERE status = 'FAILED';

-- Purge de retention (12 mois) et purge a la suppression d'un compte.
CREATE INDEX idx_email_deliveries_created ON email_deliveries (created_at);
CREATE INDEX idx_email_deliveries_recipient ON email_deliveries (lower(recipient));


-- ----------------------------------------------------------------------------
-- 3. L'ACTIVITE D'ENTRAINEMENT — une seule autorite, une VUE.
-- ----------------------------------------------------------------------------
-- Arbitrage n°1 : « activite » = tout ACTE produit par le candidat lui-meme,
-- diagnostics et examens blancs compris :
--   * une reponse QCM                        answers.answered_at
--   * une production EE/EO                   production_submissions.submitted_at
--   * un petit sujet de competence           user_skill_attempts.created_at
--   * une simulation orale REELLEMENT jointe realtime_sessions.connected_at
--
-- 🛑 JAMAIS attempts.started_at ni attempts.finished_at : ouvrir une carte n'est
-- pas s'entrainer (276 attempts sans aucun acte mesures en local), et
-- finished_at est pose par le SYSTEME (cloture paresseuse, fin d'evaluation),
-- jusqu'a 9 jours apres le dernier acte — il ouvrirait un faux episode.
--
-- Meme doctrine que V048 (v_ai_usage) : une VUE, pas une table. Les quatre
-- sources ecrivent deja leur date ; une cinquieme ecriture ferait deux verites.
-- Lue par le scheduler d'emails, jamais recopiee en Java.
CREATE VIEW v_derniere_activite_entrainement AS
SELECT actes.user_id,
       max(actes.acte_at) AS derniere_activite_at
FROM (
    SELECT a.user_id, a.answered_at AS acte_at
    FROM answers a
    WHERE a.user_id IS NOT NULL
    UNION ALL
    SELECT ps.user_id, ps.submitted_at
    FROM production_submissions ps
    UNION ALL
    SELECT usa.user_id, usa.created_at
    FROM user_skill_attempts usa
    UNION ALL
    SELECT rs.user_id, rs.connected_at
    FROM realtime_sessions rs
    WHERE rs.connected_at IS NOT NULL
) actes
GROUP BY actes.user_id;

COMMENT ON VIEW v_derniere_activite_entrainement IS
    'Derniere activite d''entrainement par compte : max des 4 actes du candidat. Jamais attempts.started_at/finished_at.';

-- Les index qui manquaient a la vue (idx_answer_user ne porte pas la date,
-- l'index des petits sujets commence par skill_prompt_id apres user_id).
CREATE INDEX idx_answers_user_answered
    ON answers (user_id, answered_at DESC)
    WHERE user_id IS NOT NULL;
CREATE INDEX idx_user_skill_attempts_user_created
    ON user_skill_attempts (user_id, created_at DESC);
CREATE INDEX idx_rt_session_user_connected
    ON realtime_sessions (user_id, connected_at DESC)
    WHERE connected_at IS NOT NULL;
