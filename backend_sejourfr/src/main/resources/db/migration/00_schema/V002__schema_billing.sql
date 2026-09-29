-- ============================================================================
-- V002 — Schéma : facturation (plans, abonnements multi-source)
-- ----------------------------------------------------------------------------
-- Tables : plans, user_subscriptions, processed_external_events
-- Relations : user_subscriptions -> users (CASCADE) + plans.
-- Clé de réconciliation multi-source : (source, original_transaction_id) unique.
-- processed_external_events : double défense anti-replay des webhooks.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- plans (catalogue : abonnements récurrents + passes one-time)
-- ---------------------------------------------------------------------------
CREATE TABLE plans (
    id                uuid NOT NULL PRIMARY KEY,
    code              varchar(64) NOT NULL,
    name              varchar(120) NOT NULL,
    billing_cycle     varchar(16) NOT NULL,
    price             numeric(10,2) NOT NULL,
    original_price    numeric(10,2),
    module_access     varchar(16) DEFAULT 'NONE'::varchar NOT NULL,
    duration_days     integer DEFAULT 0 NOT NULL,
    is_active         boolean DEFAULT true NOT NULL,
    apple_product_id  varchar(128),
    google_product_id varchar(128),
    stripe_price_id   varchar(255),
    purchase_type     varchar(16) DEFAULT 'SUBSCRIPTION'::varchar NOT NULL,
    CONSTRAINT plans_code_key UNIQUE (code)
);
CREATE UNIQUE INDEX ux_plans_apple_product_id ON plans (apple_product_id) WHERE (apple_product_id IS NOT NULL);
CREATE UNIQUE INDEX ux_plans_google_product_id ON plans (google_product_id) WHERE (google_product_id IS NOT NULL);
CREATE UNIQUE INDEX ux_plans_stripe_price_id ON plans (stripe_price_id) WHERE (stripe_price_id IS NOT NULL);

COMMENT ON COLUMN plans.purchase_type IS 'SUBSCRIPTION (abonnement récurrent, lots 2/3/4) ou ONE_TIME (pass à durée fixe, lot 5). En ONE_TIME, duration_days est la source de vérité de la durée Premium.';

-- ---------------------------------------------------------------------------
-- user_subscriptions (source de vérité unique du statut Premium)
-- ---------------------------------------------------------------------------
CREATE TABLE user_subscriptions (
    id                      uuid NOT NULL PRIMARY KEY,
    user_id                 uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id                 uuid NOT NULL REFERENCES plans(id),
    status                  varchar(16) NOT NULL,
    starts_at               timestamptz NOT NULL,
    ends_at                 timestamptz,
    stripe_customer_id      varchar(255),
    stripe_subscription_id  varchar(255),
    source                  varchar(16) NOT NULL,
    external_transaction_id varchar(255),
    original_transaction_id varchar(255) NOT NULL,
    product_id              varchar(128),
    auto_renew              boolean DEFAULT false NOT NULL,
    updated_at              timestamptz DEFAULT now() NOT NULL,
    expiry_reminded_at      timestamptz
);
CREATE INDEX idx_user_subs_user ON user_subscriptions (user_id);
CREATE INDEX idx_user_subs_source ON user_subscriptions (source);
CREATE INDEX idx_us_stripe_sub ON user_subscriptions (stripe_subscription_id);
CREATE UNIQUE INDEX ux_user_subscriptions_source_original ON user_subscriptions (source, original_transaction_id);

COMMENT ON COLUMN user_subscriptions.expiry_reminded_at IS 'Pass one-time : date d''envoi du rappel d''expiration (anti-doublon). NULL si non rappelé / sans objet.';

-- ---------------------------------------------------------------------------
-- processed_external_events (idempotence webhooks Stripe/Apple/Google)
-- ---------------------------------------------------------------------------
CREATE TABLE processed_external_events (
    provider     varchar(32) NOT NULL,
    event_id     varchar(255) NOT NULL,
    processed_at timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT processed_external_events_pkey PRIMARY KEY (provider, event_id)
);
