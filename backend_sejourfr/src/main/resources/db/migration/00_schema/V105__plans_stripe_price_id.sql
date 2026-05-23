-- ============================================================================
-- V105 — Stripe Price ID sur plans (passage en abonnements récurrents).
--
-- Pourquoi : le passage du mode one-shot Stripe (Payment Link / Checkout
-- Session mode=PAYMENT) au mode abonnement récurrent (Checkout Session
-- mode=SUBSCRIPTION) demande de connaître le Price ID Stripe de chaque Plan.
-- On le stocke directement sur la ligne plans plutôt qu'en config :
-- 1 Plan = 1 SKU = 1 Stripe Price ID. Cohérent avec apple_product_id /
-- google_product_id ajoutés en V104.
--
-- NULL accepté pour le plan FREE (pas de SKU Stripe). Index unique partiel
-- pour empêcher deux Plans de pointer sur le même Price.
-- ============================================================================

ALTER TABLE plans
    ADD COLUMN stripe_price_id VARCHAR(255);

CREATE UNIQUE INDEX ux_plans_stripe_price_id
    ON plans(stripe_price_id)
    WHERE stripe_price_id IS NOT NULL;
