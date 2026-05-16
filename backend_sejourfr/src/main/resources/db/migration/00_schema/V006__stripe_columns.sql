-- V15 : colonnes Stripe sur user_subscriptions, pour pouvoir retrouver une
-- subscription depuis un webhook Stripe et exposer le Customer Portal au
-- user (gestion carte, factures, annulation).
--
-- - stripe_customer_id     : identifiant client Stripe (cus_...), nécessaire
--                            pour ouvrir une session du portail client.
-- - stripe_subscription_id : identifiant subscription Stripe (sub_...), sert
--                            de pivot lors des events customer.subscription.*

ALTER TABLE user_subscriptions
    ADD COLUMN IF NOT EXISTS stripe_customer_id     VARCHAR(64),
    ADD COLUMN IF NOT EXISTS stripe_subscription_id VARCHAR(64);

CREATE INDEX IF NOT EXISTS idx_us_stripe_sub
    ON user_subscriptions(stripe_subscription_id);
