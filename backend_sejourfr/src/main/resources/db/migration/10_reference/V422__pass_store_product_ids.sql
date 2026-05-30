-- ============================================================================
-- V422 — Product IDs store (SKU IAP) des passes one-time, dans TOUTES les
-- environnements (dev / test / prod), pour que le paywall mobile charge les
-- produits et que verify-receipt résolve le Plan depuis le productId du reçu.
--
-- Convention finale : apple_product_id = google_product_id = lower(code).
--   - Google impose des Product IDs en minuscules.
--   - Apple les tolère ; on aligne sur la même chaîne (un seul ID par pass,
--     valable sur les deux stores). Les passes DOIVENT être des produits
--     *Consommables* côté Apple (ré-achetables) et *managed in-app* côté Google.
--
-- Idempotent. Remplace l'ancien seed dev-only (V901/V902, supprimés) : ceux-ci
-- ne couvraient pas les profils test/prod (qui ne chargent pas db/migration-dev).
-- Le mobile lit ces IDs via PlanPublicResponse.appleProductId / googleProductId.
-- ============================================================================

UPDATE plans
SET apple_product_id  = lower(code),
    google_product_id = lower(code)
WHERE purchase_type = 'ONE_TIME';
