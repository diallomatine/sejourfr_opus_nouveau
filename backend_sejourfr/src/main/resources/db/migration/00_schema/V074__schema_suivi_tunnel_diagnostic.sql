-- ============================================================================
-- V074 — CHANTIER « SUIVI » : tout le DDL du tunnel diagnostic -> achat
-- ----------------------------------------------------------------------------
-- Brief : docs/admin/brief-analytics-diagnostic.md.
-- Audit : docs/admin/audit-dashboard-analytics.md (§1, §8.0, §12 « 1b »).
-- Arbitrages opposables et decisions : docs/admin/decisions-suivi.md.
-- Regle : docs/regles/mesure-audience.md.
--
-- UNE SEULE MIGRATION POUR TOUT LE CHANTIER (audit §12) : les lots 2 et 4
-- ecrivent et lisent ces colonnes, ils n'en creent pas. V074 ne se reecrit
-- jamais une fois appliquee ; un besoin decouvert plus tard va en V075.
--
-- 🛑 NULL = INCONNU, JAMAIS ZERO (Q16). Toute colonne de MESURE ajoutee ici est
-- NULLABLE et AUCUNE n'est rattrapee : un compte ou un achat anterieur a la
-- mesure garde NULL, lu « inconnu ». Aucun montant n'est recalcule.
-- Seule exception, et ce n'est pas une mesure : users.is_internal (Q6), qui
-- remplace la liste YAML `excluded-emails` et s'initialise donc depuis elle
-- (fin de fichier, apres la sentinelle).
--
-- 🛑 AUCUN CONTENU CANDIDAT (Q3, invariant V053). `diagnostic_run` est la TRACE
-- du passage dans le tunnel : aucun texte, aucun audio, aucune reponse. Le TCF
-- invite continue de garder sa production sur l'appareil.
-- ============================================================================


-- ---------------------------------------------------------------------------
-- 1. diagnostic_run — un passage dans le tunnel, sans contenu.
--
-- Creee par un appel public dedie, a l'affichage du sujet (lot 2). L'etape 1
-- du tunnel (« sujet vu ») se compte UNIQUEMENT ici : il n'existe pas
-- d'evenement DIAGNOSTIC_SUBJECT_VIEWED en doublon (Q3).
--
-- POURQUOI UNE TABLE DEDIEE et pas des colonnes sur `attempts` ou sur les
-- sessions : le diagnostic s'etale sur trois tables de sessions dont deux
-- exigent un compte (diagnostic_sessions.user_id NOT NULL, V053), et
-- `attempts` est la table du runner. Une trace sans contenu ne touche ni l'un
-- ni l'autre.
--
-- FK vers les sessions en ON DELETE SET NULL (Q3) : GuestAttemptPurgeJob
-- supprime les attempts civiques invites non adoptes, ce qui cascade sur
-- civic_diagnostic_sessions. La run, elle, SURVIT : c'est elle qui compte
-- « soumis anonymes jamais rattaches » (scenario 19). Aucune FK vers
-- analytics_visitor : la purge 395 j des visiteurs ne doit pas emporter un
-- fait du tunnel.
-- ---------------------------------------------------------------------------
CREATE TABLE diagnostic_run
(
    id                          uuid         NOT NULL PRIMARY KEY,
    -- QUICK_TCF = le tunnel TCF (Q2). FULL_TCF n'entre pas dans le tunnel ; il
    -- est prevu pour l'activite (« diagnostics complets soumis »).
    diagnostic_type             varchar(16)  NOT NULL
        CONSTRAINT chk_diagnostic_run_type
            CHECK (diagnostic_type IN ('QUICK_TCF', 'FULL_TCF', 'CIVIQUE')),
    -- ClientPlatform : WEB / IOS / ANDROID / MOBILE (legacy) / UNKNOWN. Pas de
    -- CHECK, meme parti pris que users.signup_platform (V036).
    platform                    varchar(16),
    app_version                 varchar(32),
    -- Identifiant de mesure de l'appareil, tel que recu. Jamais une cle de
    -- claim : AUCUNE recherche heuristique par anonymous_id (arbitrage claim).
    anonymous_id                uuid,
    -- Compte porteur : pose a la creation si l'appelant est connecte, ou a la
    -- claim. SET NULL pour une vraie suppression ; l'anonymisation laisse la
    -- ligne users en place.
    user_id                     uuid         REFERENCES users (id) ON DELETE SET NULL,
    -- Idempotence de la creation : une cle tiree par le client, bornee a son
    -- anonymous_id (meme doctrine que clientSubmissionId, V046).
    client_key                  uuid,
    subject_viewed_at           timestamptz  NOT NULL DEFAULT now(),

    -- « Soumis » : une seule fois par run (Q3).
    submitted_at                timestamptz,
    submitted_authenticated     boolean,

    -- Claim : seul le HASH du jeton est stocke. Le jeton ne voyage que dans la
    -- reponse de creation et dans les requetes d'auth, jamais dans un evenement.
    claim_token_hash            varchar(64),
    claim_token_expires_at      timestamptz,
    claimed_at                  timestamptz,
    claim_kind                  varchar(8)
        CONSTRAINT chk_diagnostic_run_claim_kind CHECK (claim_kind IN ('SIGNUP', 'LOGIN')),
    -- SAME_DEVICE : jeton lu dans le brouillon de l'appareil qui a cree la run.
    -- APP_LINK    : jeton porte par le lien web -> app (lot 3b).
    claimed_via                 varchar(16)
        CONSTRAINT chk_diagnostic_run_claimed_via CHECK (claimed_via IN ('SAME_DEVICE', 'APP_LINK')),

    -- Rattachement a la session reelle, une fois connue.
    diagnostic_session_id       uuid         REFERENCES diagnostic_sessions (id) ON DELETE SET NULL,
    tcf_diagnostic_session_id   uuid         REFERENCES tcf_diagnostic_sessions (id) ON DELETE SET NULL,
    civic_diagnostic_session_id uuid         REFERENCES civic_diagnostic_sessions (id) ON DELETE SET NULL,

    updated_at                  timestamptz  NOT NULL DEFAULT now(),

    CONSTRAINT chk_diagnostic_run_submitted
        CHECK ((submitted_at IS NULL) = (submitted_authenticated IS NULL)),
    CONSTRAINT chk_diagnostic_run_claim_token
        CHECK ((claim_token_hash IS NULL) = (claim_token_expires_at IS NULL)),
    CONSTRAINT chk_diagnostic_run_claim
        CHECK ((claimed_at IS NULL) = (claim_kind IS NULL)
           AND (claimed_at IS NULL) = (claimed_via IS NULL))
);

COMMENT ON TABLE diagnostic_run IS
    'Trace d''un passage dans le tunnel diagnostic (sujet vu, soumis, rattache). AUCUN contenu candidat. Survit a la purge des invites et a la purge 395 j des visiteurs.';
COMMENT ON COLUMN diagnostic_run.claim_token_hash IS
    'SHA-256 hexadecimal du claimToken. Le jeton en clair n''est jamais stocke ni journalise.';
COMMENT ON COLUMN diagnostic_run.subject_viewed_at IS
    'Horodate SERVEUR de creation de la run = etape 1 du tunnel (« sujet vu »).';

-- Entree en cohorte : « les runs dont le sujet a ete vu dans la periode ».
CREATE INDEX idx_diagnostic_run_subject_viewed ON diagnostic_run (subject_viewed_at);
CREATE INDEX idx_diagnostic_run_submitted ON diagnostic_run (submitted_at)
    WHERE submitted_at IS NOT NULL;
CREATE INDEX idx_diagnostic_run_user ON diagnostic_run (user_id)
    WHERE user_id IS NOT NULL;
CREATE INDEX idx_diagnostic_run_anonymous ON diagnostic_run (anonymous_id)
    WHERE anonymous_id IS NOT NULL;
CREATE UNIQUE INDEX ux_diagnostic_run_claim_token ON diagnostic_run (claim_token_hash)
    WHERE claim_token_hash IS NOT NULL;
CREATE UNIQUE INDEX ux_diagnostic_run_client_key ON diagnostic_run (anonymous_id, client_key)
    WHERE client_key IS NOT NULL;


-- ---------------------------------------------------------------------------
-- 2. analytics_event — ce que l'ingestion en lot et le tunnel exigent.
--
-- event_id : identifiant tire par le CLIENT a la creation de l'evenement
-- (brief §10) — c'est lui qui rend un lot rejouable sans doublon (scenario 10).
-- dedup_key reste : c'est une idempotence METIER (« ce rapport-la »), pas une
-- idempotence de TRANSPORT. Les deux sont uniques ; l'insertion du lot fait
-- ON CONFLICT DO NOTHING sans cible, donc l'un ou l'autre suffit a ecarter un
-- rejeu.
--
-- occurred_at reste la date RETENUE (celle des KPI). received_at est l'horloge
-- serveur. Une horodate client plus d'une tolerance dans le futur est ramenee
-- a received_at (brief §4.1).
--
-- diagnostic_run_id / journey_id : colonnes et non proprietes jsonb, parce
-- qu'elles se JOIGNENT (etapes 4 a 6 du tunnel). FK en SET NULL : l'ingestion
-- verifie leur existence avant d'ecrire, et l'effacement d'un parcours ne doit
-- pas effacer le geste. `plan_id` du brief = journey.id (Q8).
--
-- is_internal : resolu A L'INGESTION (brief §4.1). NULL = ligne anterieure.
-- ---------------------------------------------------------------------------
ALTER TABLE analytics_event
    ADD COLUMN event_id          uuid,
    ADD COLUMN received_at       timestamptz,
    ADD COLUMN platform          varchar(16),
    ADD COLUMN app_version       varchar(32),
    ADD COLUMN diagnostic_type   varchar(16)
        CONSTRAINT chk_analytics_event_diagnostic_type
            CHECK (diagnostic_type IN ('QUICK_TCF', 'FULL_TCF', 'CIVIQUE')),
    ADD COLUMN diagnostic_run_id uuid REFERENCES diagnostic_run (id) ON DELETE SET NULL,
    ADD COLUMN journey_id        uuid REFERENCES journey (id) ON DELETE SET NULL,
    ADD COLUMN is_internal       boolean;

ALTER TABLE analytics_event
    ADD CONSTRAINT ux_analytics_event_event_id UNIQUE (event_id);

COMMENT ON COLUMN analytics_event.event_id IS
    'Identifiant tire par le client a la creation de l''evenement. Unique : un lot rejoue n''ecrit rien. NULL = evenement recu par l''endpoint unitaire (legacy).';
COMMENT ON COLUMN analytics_event.received_at IS
    'Horloge serveur a la reception. NULL = ligne anterieure a V074.';
COMMENT ON COLUMN analytics_event.is_internal IS
    'Vrai si l''evenement vient d''un compte interne (users.is_internal), directement ou via analytics_identity. Resolu a l''ingestion. NULL = ligne anterieure a V074.';

-- Etapes 4 a 6 du tunnel : « existe-t-il un RAPPORT VU sur cette run ».
CREATE INDEX idx_analytics_event_run ON analytics_event (diagnostic_run_id, event)
    WHERE diagnostic_run_id IS NOT NULL;
-- Purge de retention : balaie par date retenue. idx_analytics_event_date
-- (V043) la couvre deja ; rien a ajouter.


-- ---------------------------------------------------------------------------
-- 3. analytics_visitor — la source DECLAREE, brute.
--
-- ft_source est normalisee par util/TrafficSource a l'ingestion : « ig » y
-- devient « autre », et plus rien ne permet de le ranger sous instagram
-- (scenario 17). On garde donc la valeur declaree, en minuscules et bornee,
-- et le REGROUPEMENT se fait a la lecture par la config versionnee
-- (analytics-config-vN.json, utmSourceGroups) : reversible, sans migration.
-- NULL = visiteur anterieur, ou aucune source declaree.
-- ---------------------------------------------------------------------------
ALTER TABLE analytics_visitor
    ADD COLUMN ft_source_raw varchar(40);

COMMENT ON COLUMN analytics_visitor.ft_source_raw IS
    'Source declaree au first touch, minuscules, charset borne [a-z0-9._-], 40 car. Jamais reecrite. Regroupee a la lecture par analytics-config utmSourceGroups.';


-- ---------------------------------------------------------------------------
-- 4. users — contexte d'inscription et exclusion interne.
--
-- Poses SERVEUR a la creation du compte, jamais reecrits (meme doctrine que
-- signup_source, V036). signup_context / signup_diagnostic_* sont ecrits par
-- le lot 2 (claim dans la transaction d'auth). Comptes anterieurs : NULL,
-- affiches « inconnu », jamais rattrapes.
--
-- is_internal (Q6) : SEULE autorite de l'exclusion des statistiques. NOT NULL
-- DEFAULT false : ce n'est pas une mesure mais un attribut du compte.
-- ---------------------------------------------------------------------------
ALTER TABLE users
    ADD COLUMN signup_context           varchar(24)
        CONSTRAINT chk_users_signup_context
            CHECK (signup_context IN ('AFTER_DIAGNOSTIC', 'OUTSIDE_DIAGNOSTIC')),
    ADD COLUMN signup_diagnostic_type   varchar(16)
        CONSTRAINT chk_users_signup_diagnostic_type
            CHECK (signup_diagnostic_type IN ('QUICK_TCF', 'FULL_TCF', 'CIVIQUE')),
    ADD COLUMN signup_diagnostic_run_id uuid REFERENCES diagnostic_run (id) ON DELETE SET NULL,
    ADD COLUMN signup_anonymous_id      uuid,
    ADD COLUMN is_internal              boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN users.signup_context IS
    'AFTER_DIAGNOSTIC si l''inscription a claime >= 1 run soumise, OUTSIDE_DIAGNOSTIC sinon. Pose serveur a la creation. NULL = compte anterieur a la mesure.';
COMMENT ON COLUMN users.signup_anonymous_id IS
    'Identifiant de mesure recu a l''inscription (corps ou en-tete X-Sejourfr-Anonymous-Id). NULL = absent ou compte anterieur. Efface a l''anonymisation.';
COMMENT ON COLUMN users.is_internal IS
    'Compte interne / de test, exclu des statistiques par defaut. Seule autorite (remplace sejourfr.analytics.excluded-emails).';

CREATE INDEX idx_users_internal ON users (id) WHERE is_internal;


-- ---------------------------------------------------------------------------
-- 5. purchase_intent — l'intention d'achat, posee serveur (Q12).
--
-- Creee avant CHAQUE demarrage d'achat, quel que soit le CTA. Usage unique,
-- TTL en config (analytics-config purchaseIntentTtlHours). Le diagnostic_run_id
-- est RESOLU SERVEUR depuis le parcours (Q8), jamais recu du client.
-- Intention perdue, expiree, consommee ou d'un autre compte => l'achat est
-- range origin = UNKNOWN, sans reconstruction.
-- ---------------------------------------------------------------------------
CREATE TABLE purchase_intent
(
    id                uuid         NOT NULL PRIMARY KEY,
    user_id           uuid         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    -- AnalyticsCtaLocation. Pas de CHECK : l'enum Java est l'autorite et grandit.
    cta_location      varchar(32)  NOT NULL,
    -- Code du plan (plans.code) = productId cote stores.
    product_id        varchar(128) NOT NULL,
    platform          varchar(16),
    journey_id        uuid         REFERENCES journey (id) ON DELETE SET NULL,
    diagnostic_run_id uuid         REFERENCES diagnostic_run (id) ON DELETE SET NULL,
    created_at        timestamptz  NOT NULL DEFAULT now(),
    expires_at        timestamptz  NOT NULL,
    consumed_at       timestamptz,
    CONSTRAINT chk_purchase_intent_expiry CHECK (expires_at > created_at)
);

COMMENT ON TABLE purchase_intent IS
    'Intention d''achat serveur (Q12) : transportee par metadata.intentId (Stripe) ou persistee par le mobile et renvoyee avec verify-receipt. Usage unique.';

CREATE INDEX idx_purchase_intent_user ON purchase_intent (user_id, created_at DESC);


-- ---------------------------------------------------------------------------
-- 6. user_subscriptions — decomposition du revenu et attribution.
--
-- `amount_eur_cents` (V043) EST le brut paye en euros : on ne cree pas de
-- seconde colonne « gross » (une regle = une autorite). La decomposition se
-- fige A L'ECRITURE par les regles de revenus versionnees
-- (revenue-rules-vN.json) et porte leur numero : un changement de regle n'a
-- aucun effet retroactif.
--
-- Invariant du brief §6.1, tenu PAR LA BASE :
--   amount_eur_cents = vat_cents + provider_fee_cents + net_ex_vat_cents.
-- La decomposition est tout ou rien.
--
-- purchased_at : starts_at n'est pas la date d'achat quand les pass
-- s'empilent (le nouveau demarre a la fin du precedent).
-- ---------------------------------------------------------------------------
ALTER TABLE user_subscriptions
    ADD COLUMN purchased_at          timestamptz,
    ADD COLUMN vat_cents             integer,
    ADD COLUMN provider_fee_cents    integer,
    ADD COLUMN net_after_fee_cents   integer,
    ADD COLUMN net_ex_vat_cents      integer,
    ADD COLUMN fee_source            varchar(16)
        CONSTRAINT chk_user_subscriptions_fee_source CHECK (fee_source IN ('ACTUAL', 'ESTIMATED')),
    ADD COLUMN revenue_rules_version integer,
    ADD COLUMN origin                varchar(16)
        CONSTRAINT chk_user_subscriptions_origin
            CHECK (origin IN ('DIAGNOSTIC_PLAN', 'OTHER_CTA', 'UNKNOWN')),
    ADD COLUMN diagnostic_run_id     uuid REFERENCES diagnostic_run (id) ON DELETE SET NULL,
    ADD COLUMN journey_id            uuid REFERENCES journey (id) ON DELETE SET NULL,
    ADD COLUMN purchase_intent_id    uuid REFERENCES purchase_intent (id) ON DELETE SET NULL,
    -- Statut de paiement du provider (Stripe payment_status...). Pas de CHECK :
    -- l'enum Java du lot 2 est l'autorite.
    ADD COLUMN payment_status        varchar(24);

ALTER TABLE user_subscriptions
    ADD CONSTRAINT chk_user_subscriptions_revenue_all_or_nothing CHECK (
        (vat_cents IS NULL) = (provider_fee_cents IS NULL)
        AND (vat_cents IS NULL) = (net_after_fee_cents IS NULL)
        AND (vat_cents IS NULL) = (net_ex_vat_cents IS NULL)
        AND (vat_cents IS NULL) = (fee_source IS NULL)
        AND (vat_cents IS NULL) = (revenue_rules_version IS NULL)
        ),
    ADD CONSTRAINT chk_user_subscriptions_revenue_invariant CHECK (
        vat_cents IS NULL
        OR (amount_eur_cents IS NOT NULL
            AND amount_eur_cents = vat_cents + provider_fee_cents + net_ex_vat_cents)
        );

COMMENT ON COLUMN user_subscriptions.purchased_at IS
    'Date reelle de l''achat (≠ starts_at pour un pass empile). NULL = ligne anterieure a la mesure.';
COMMENT ON COLUMN user_subscriptions.net_ex_vat_cents IS
    'KPI principal : revenu HT apres frais, fige a l''ecriture. NULL = inconnu, jamais zero.';
COMMENT ON COLUMN user_subscriptions.origin IS
    'DIAGNOSTIC_PLAN / OTHER_CTA via purchase_intent ; UNKNOWN si l''intention manque ou est invalide. NULL = ligne anterieure a la mesure.';

CREATE INDEX idx_user_subscriptions_purchased_at ON user_subscriptions (purchased_at)
    WHERE purchased_at IS NOT NULL;
CREATE INDEX idx_user_subscriptions_run ON user_subscriptions (diagnostic_run_id)
    WHERE diagnostic_run_id IS NOT NULL;


-- ---------------------------------------------------------------------------
-- 7. payment_refunds — un remboursement, eventuellement partiel.
--
-- Plusieurs lignes par achat possibles (remboursements partiels successifs).
-- Idempotence : (provider, provider_refund_id) unique, un webhook rejoue
-- n'ecrit rien. net_ex_vat_delta_cents <= 0, fige a l'ecriture par les regles
-- de revenus en vigueur (Stripe garde ses frais : delta = -HT ; store :
-- delta = -net_ex_vat, brief §6.4).
-- ---------------------------------------------------------------------------
CREATE TABLE payment_refunds
(
    id                     uuid         NOT NULL PRIMARY KEY,
    subscription_id        uuid         NOT NULL REFERENCES user_subscriptions (id) ON DELETE CASCADE,
    provider               varchar(16)  NOT NULL
        CONSTRAINT chk_payment_refunds_provider CHECK (provider IN ('STRIPE', 'APPLE', 'GOOGLE')),
    provider_refund_id     varchar(255) NOT NULL,
    refunded_amount_cents  integer      NOT NULL CONSTRAINT chk_payment_refunds_amount CHECK (refunded_amount_cents > 0),
    currency               varchar(3)   NOT NULL,
    -- NULL si la devise n'a pas de taux (meme regle que amount_eur_cents).
    refunded_eur_cents     integer,
    net_ex_vat_delta_cents integer
        CONSTRAINT chk_payment_refunds_delta CHECK (net_ex_vat_delta_cents <= 0),
    revenue_rules_version  integer,
    refunded_at            timestamptz  NOT NULL,
    created_at             timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT ux_payment_refunds_provider_refund UNIQUE (provider, provider_refund_id),
    CONSTRAINT chk_payment_refunds_rules
        CHECK ((net_ex_vat_delta_cents IS NULL) = (revenue_rules_version IS NULL))
);

COMMENT ON TABLE payment_refunds IS
    'Remboursements (partiels possibles), un par identifiant provider. Le statut REFUNDED de user_subscriptions reste pose par les webhooks existants.';

CREATE INDEX idx_payment_refunds_subscription ON payment_refunds (subscription_id);
CREATE INDEX idx_payment_refunds_refunded_at ON payment_refunds (refunded_at);


-- ---------------------------------------------------------------------------
-- 8. Initialisation de users.is_internal depuis l'ancienne liste YAML (Q6).
--
-- La liste `sejourfr.analytics.excluded-emails` est SUPPRIMEE dans la meme
-- passe : ces trois comptes (seed dev + compte d'administration) etaient sa
-- valeur par defaut. Sur une base neuve, le seed dev (V900) passe APRES ce
-- fichier : migration-dev/V901 pose le meme drapeau pour lui.
-- Le test UsersIsInternalMigrationIT rejoue le SQL ci-dessous, coupe sur la
-- sentinelle. Ne pas la supprimer.
-- ---------------------------------------------------------------------------
-- @@INITIALISATION_IS_INTERNAL@@
UPDATE users
SET is_internal = TRUE
WHERE lower(email) IN ('admin@sejourfr.fr', 'user@sejourfr.fr', 'karim.test@sejourfr.fr');
