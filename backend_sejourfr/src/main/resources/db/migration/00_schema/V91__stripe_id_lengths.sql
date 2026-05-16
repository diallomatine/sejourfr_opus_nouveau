-- V100 : élargit les colonnes Stripe IDs sur user_subscriptions.
--
-- Les Checkout Session IDs (`cs_test_xxx` / `cs_live_xxx`) font typiquement
-- 66 à 80 caractères — la limite VARCHAR(64) introduite par V050 plante
-- l'insert avec "value too long for type character varying(64)" dès qu'on
-- stocke le session id comme stripe_subscription_id.
--
-- Stripe recommande VARCHAR(255) pour stocker ses identifiants (les
-- formats peuvent évoluer). On s'aligne.

ALTER TABLE user_subscriptions
    ALTER COLUMN stripe_customer_id     TYPE VARCHAR(255),
    ALTER COLUMN stripe_subscription_id TYPE VARCHAR(255);
