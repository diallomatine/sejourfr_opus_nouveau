-- ============================================================================
-- V132 — Renseigne les Product IDs IAP sur les 6 plans récurrents (V106).
--
-- V106 avait laissé apple_product_id / google_product_id à NULL (à remplir
-- quand les SKUs seraient créés dans les stores). Sans ces valeurs,
-- verify-receipt lève 400 « Aucun Plan configuré pour {apple,google}ProductId=… »
-- car le backend retrouve le Plan via ces colonnes.
--
-- Convention de casse (alignée sur le mobile `_skuFor`) :
--   - Apple (App Store Connect) accepte les MAJUSCULES → on garde le Plan.code
--     tel quel (INTEGRAL_MONTHLY, …). Le mobile envoie plan.code pour APPLE.
--   - Google Play n'accepte QUE des minuscules → google_product_id = LOWER(code)
--     (integral_monthly, …). Le mobile envoie plan.code.toLowerCase() pour GOOGLE.
-- Ces valeurs doivent matcher au caractère près les Product IDs créés dans
-- App Store Connect / Play Console.
--
-- Liste explicite (pas de LIKE 'CIVIQUE_%') pour ne PAS toucher les plans
-- legacy désactivés CIVIQUE_3MOIS / INTEGRAL_3MOIS. Idempotent.
-- ============================================================================

UPDATE plans
SET apple_product_id  = code,
    google_product_id = LOWER(code)
WHERE code IN (
    'CIVIQUE_MONTHLY', 'CIVIQUE_QUARTERLY', 'CIVIQUE_YEARLY',
    'INTEGRAL_MONTHLY', 'INTEGRAL_QUARTERLY', 'INTEGRAL_YEARLY'
);
