-- ============================================================================
-- V421 — SKU stores des passes one-time (lot 5).
--
-- Convention déterministe (cf. mobile IapService._skuFor) :
--   - Apple  : product id = Plan.code (MAJUSCULES)          → apple_product_id
--   - Google : product id = Plan.code en minuscules         → google_product_id
--
-- On les pose donc directement, pour que verify-receipt retrouve le plan sans
-- UPDATE manuel. PRÉ-REQUIS côté stores : créer les produits avec EXACTEMENT
-- ces identifiants (App Store Connect en MAJ, Play Console en minuscules) —
-- cf. docs/setup-paiement-one-time.md. Stripe n'a pas de SKU (montant dynamique).
-- ============================================================================

UPDATE plans
SET apple_product_id  = code,
    google_product_id = lower(code)
WHERE purchase_type = 'ONE_TIME';
