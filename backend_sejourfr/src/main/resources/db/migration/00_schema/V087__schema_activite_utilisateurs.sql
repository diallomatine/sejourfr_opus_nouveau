-- ============================================================================
-- V087 — Activité des utilisateurs (chantier « Activité utilisateurs », lot 2)
-- ----------------------------------------------------------------------------
-- Deux tables de MESURE, rétention 365 j (purge accrochée à la passe
-- quotidienne AnalyticsRetentionJob, analytics-config-v2.json). Aucune
-- migration de données : avant la date de début de mesure (ACTIVE_USERS,
-- LOGINS), les indicateurs valent null, jamais 0.
--
-- ON DELETE CASCADE vers users ne joue que sur une vraie suppression : la
-- suppression de compte étant une ANONYMISATION, AccountDeletionService
-- supprime ces lignes explicitement.
--
-- Plateformes : convention ClientPlatform (MOBILE = ancienne application,
-- système inconnu ; UNKNOWN = client sans en-tête). varchar et non char :
-- Hibernate refuse bpchar sous ddl-auto: validate.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Connexions : une ligne par OUVERTURE DE SESSION (login ou inscription,
-- locale, Google ou Apple). Jamais de refresh, jamais d'IP, jamais de
-- User-Agent. Écrite après le commit de l'authentification, dans sa propre
-- transaction : un échec d'insertion n'empêche jamais une connexion.
-- ----------------------------------------------------------------------------
CREATE TABLE user_login_event (
    id           uuid         NOT NULL,
    user_id      uuid         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    occurred_at  timestamptz  NOT NULL,
    kind         varchar(16)  NOT NULL,
    auth_method  varchar(16)  NOT NULL,
    platform     varchar(16)  NOT NULL,
    CONSTRAINT pk_user_login_event PRIMARY KEY (id),
    CONSTRAINT chk_user_login_event_kind
        CHECK (kind IN ('LOGIN', 'SIGNUP')),
    CONSTRAINT chk_user_login_event_auth_method
        CHECK (auth_method IN ('LOCAL', 'GOOGLE', 'APPLE')),
    CONSTRAINT chk_user_login_event_platform
        CHECK (platform IN ('WEB', 'IOS', 'ANDROID', 'MOBILE', 'UNKNOWN'))
);

-- Lecture par période + purge par date
CREATE INDEX idx_user_login_event_occurred ON user_login_event (occurred_at DESC);
-- Suppression de compte
CREATE INDEX idx_user_login_event_user ON user_login_event (user_id, occurred_at DESC);

-- ----------------------------------------------------------------------------
-- Présence et activité : une ligne par compte × jour (Europe/Paris) ×
-- plateforme. Toute requête authentifiée (heartbeat compris) l'entretient, au
-- plus une écriture par minute et par (compte, plateforme, jour).
-- ----------------------------------------------------------------------------
CREATE TABLE user_activity_day (
    user_id        uuid         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    day            date         NOT NULL,
    platform       varchar(16)  NOT NULL,
    first_seen_at  timestamptz  NOT NULL,
    last_seen_at   timestamptz  NOT NULL,
    CONSTRAINT pk_user_activity_day PRIMARY KEY (user_id, day, platform),
    CONSTRAINT chk_user_activity_day_platform
        CHECK (platform IN ('WEB', 'IOS', 'ANDROID', 'MOBILE', 'UNKNOWN')),
    CONSTRAINT chk_user_activity_day_order CHECK (last_seen_at >= first_seen_at)
);

-- « En ligne maintenant »
CREATE INDEX idx_user_activity_day_last_seen ON user_activity_day (last_seen_at DESC);
-- « Actifs sur la période » + purge par jour
CREATE INDEX idx_user_activity_day_day ON user_activity_day (day, platform);
