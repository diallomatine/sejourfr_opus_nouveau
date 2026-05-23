-- ============================================================================
-- V104 — Mapping Plan ↔ SKU stores (Apple App Store + Google Play).
--
-- Pourquoi : quand l'app mobile envoie un reçu d'achat IAP, le backend reçoit
-- un {@code productId} (SKU défini côté store). Il faut retrouver le Plan
-- correspondant (CIVIQUE ou INTEGRAL) sans hardcoder le mapping en config —
-- c'est de la donnée métier, sa place est en DB.
--
-- Convention de naming des SKUs (à définir au lot 4 quand les abonnements
-- récurrents seront en place, ex. "civique.monthly", "integral.monthly"). En
-- attendant, ces colonnes sont NULL — le mapping sera posé via UPDATE quand
-- les vrais SKUs seront décidés et créés côté App Store Connect / Play
-- Console.
--
-- Indexes uniques partiels : un même SKU ne peut pas pointer vers deux Plans.
-- ============================================================================

ALTER TABLE plans
    ADD COLUMN apple_product_id  VARCHAR(128),
    ADD COLUMN google_product_id VARCHAR(128);

CREATE UNIQUE INDEX ux_plans_apple_product_id
    ON plans(apple_product_id)
    WHERE apple_product_id IS NOT NULL;

CREATE UNIQUE INDEX ux_plans_google_product_id
    ON plans(google_product_id)
    WHERE google_product_id IS NOT NULL;
