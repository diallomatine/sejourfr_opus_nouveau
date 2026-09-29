-- ============================================================================
-- V036 — Funnel d'acquisition PAR COMPTE : provenance, plateforme, et les deux
--        seules etapes qui n'existent que dans le navigateur.
-- ----------------------------------------------------------------------------
-- OBJECTIF : piloter TikTok -> inscription -> diagnostic commence -> diagnostic
-- termine -> ecran Premium affiche -> clic abonnement -> paiement, avec de
-- VRAIS chiffres.
--
-- PRINCIPE DIRECTEUR : tout ce qui peut se lire sur les vraies tables se lit
-- sur les vraies tables. `users` porte l'inscription, `diagnostic_sessions`
-- porte le diagnostic commence (started_at) et termine (completed_at),
-- `user_subscriptions` porte le paiement. On n'ajoute donc AUCUN evenement
-- pour ces etapes-la : elles sont deja en base, exactes, et deja purgees avec
-- le compte. Ne pas creer d'evenement « SIGNUP » ni « DIAGNOSTIC_COMPLETED »
-- ici : ce serait une seconde verite, condamnee a diverger de la premiere.
--
-- CE QUI MANQUAIT VRAIMENT, c'est la PROVENANCE (aucune colonne n'existait sur
-- `users`) et les deux etapes qui ne laissent aucune trace serveur : l'ecran
-- Premium AFFICHE et le CLIC sur l'abonnement. D'ou les colonnes ci-dessous et
-- la table `user_funnel_events`, bornee a 3 lignes par compte.
--
-- A NE PAS CONFONDRE AVEC `page_views` (V020), qui reste inchangee : celle-ci
-- est l'agregat ANONYME du pre-inscription (aucun identifiant, aucun cookie),
-- support de la promesse de /confidentialite. Le funnel ci-dessous est
-- NOMINATIF par construction — il ne concerne que des comptes existants, qui
-- ont accepte les CGU. Les deux mesures cohabitent, elles ne fusionnent pas.
--
-- AUCUN RECALCUL RETROACTIF : les comptes anterieurs gardent une provenance
-- NULL, rendue « inconnu » a la lecture. On n'invente pas d'ou vient quelqu'un.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Provenance d'un compte : celle du PREMIER JOUR, jamais reecrite ensuite.
-- ---------------------------------------------------------------------------
ALTER TABLE users
    ADD COLUMN signup_source   varchar(40),
    ADD COLUMN signup_platform varchar(16);

COMMENT ON COLUMN users.signup_source IS
    'Reseau de provenance a l''inscription (meme allowlist que page_views.source : tiktok / instagram / whatsapp / facebook / youtube / direct / autre). NULL = compte anterieur a la mesure, rendu « inconnu » a la lecture. Jamais reecrit apres la creation.';
COMMENT ON COLUMN users.signup_platform IS
    'Plateforme d''inscription : WEB / MOBILE / UNKNOWN. NULL = compte anterieur a la mesure. Jamais reecrit apres la creation.';

-- La cohorte d'inscription est lue par fenetre glissante et regroupee par
-- provenance : c'est ce GROUP BY qui a besoin de l'index.
CREATE INDEX idx_users_created_at ON users (created_at DESC) WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- Plateforme de la session de diagnostic.
-- ---------------------------------------------------------------------------
ALTER TABLE diagnostic_sessions
    ADD COLUMN platform varchar(16);

COMMENT ON COLUMN diagnostic_sessions.platform IS
    'Plateforme sur laquelle la session a ete creee (WEB / MOBILE / UNKNOWN). NULL = session anterieure a la mesure.';

-- ---------------------------------------------------------------------------
-- user_funnel_events — PREMIERE OCCURRENCE SEULEMENT.
--
-- L'unicite (user_id, event) est ce qui borne la table : au plus 3 lignes par
-- compte, pour toujours. C'est aussi ce qui rend l'endpoint d'ecriture sur
-- sans rate-limit — un client qui rejoue son evenement ne cree rien.
--
-- Ce qu'on mesure, c'est « ce compte a-t-il vu l'ecran Premium ? », pas
-- « combien de fois ». Un compteur d'occurrences n'aurait servi aucune des
-- questions posees et aurait ouvert l'inflation.
-- ---------------------------------------------------------------------------
CREATE TABLE user_funnel_events
(
    id          uuid        NOT NULL PRIMARY KEY,
    user_id     uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    event       varchar(48) NOT NULL,
    -- Contexte du moment de l'evenement : il peut differer de celui de
    -- l'inscription (inscrit sur le web, paywall vu sur mobile).
    platform    varchar(16),
    source      varchar(40),
    occurred_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_user_funnel_event UNIQUE (user_id, event),
    CONSTRAINT chk_user_funnel_event CHECK (
        event IN ('PAYWALL_VIEWED', 'SUBSCRIBE_CLICKED', 'CHECKOUT_STARTED')
    )
);

COMMENT ON TABLE user_funnel_events IS
    'Les deux etapes de funnel non deductibles des vraies tables (ecran Premium affiche, clic abonnement) plus le depart de paiement pose par le serveur. Premiere occurrence seulement : au plus 3 lignes par compte.';

-- Lecture admin type : « les PAYWALL_VIEWED des 30 derniers jours ».
CREATE INDEX idx_user_funnel_events_event_date ON user_funnel_events (event, occurred_at DESC);
