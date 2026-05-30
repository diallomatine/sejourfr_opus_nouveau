-- ============================================================================
-- V901 (DEV/TEST UNIQUEMENT — chargé via classpath:db/migration-dev) —
-- SKU stores des passes one-time, pour que verify-receipt fonctionne en
-- sandbox sans manip manuelle.
--
-- Convention déterministe (cf. mobile IapService._skuFor) :
--   - Apple  : product id = Plan.code (MAJUSCULES)   → apple_product_id
--   - Google : product id = Plan.code en minuscules  → google_product_id
--
-- ⚠ NON appliqué en prod (le profil prod ne charge que classpath:db/migration).
-- En prod, poser les SKU au go-live (après création des produits stores) via
-- la console admin → Plans, ou un SQL ponctuel. Cf. docs/setup-paiement-one-time.md.
-- ============================================================================

UPDATE plans
SET apple_product_id  = code,
    google_product_id = lower(code)
WHERE purchase_type = 'ONE_TIME';
