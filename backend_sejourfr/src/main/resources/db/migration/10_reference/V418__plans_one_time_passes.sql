-- ============================================================================
-- V418 — Passes d'accès one-time (lot 5).
--
-- Bascule du modèle abonnement récurrent (V106) vers des PASSES À DURÉE FIXE,
-- payés une fois, sans reconduction. duration_days devient la source de vérité
-- de la durée Premium (le backend pose ends_at = paiement + duration_days).
--
-- Catalogue :
--   Civique  : 3 mois (9,99 €)  · 1 an (29,99 €)
--   Intégral : sprint 6 semaines (19,99 €) · 3 mois (35,99 €) · 1 an (79,99 €)
--
-- RÉVERSIBILITÉ — on ne supprime RIEN : les 6 plans récurrents (V106) sont
-- seulement désactivés (is_active=FALSE). Revenir à l'abonnement = réactiver
-- ces plans + désactiver les passes + flag billing.mode=SUBSCRIPTION.
-- Cf. CLAUDE.md racine § Paiements (Lot 5).
--
-- billing_cycle = NONE : non pertinent pour un pass (le front affiche la durée
-- via duration_days). Le plan gratuit reste détecté par module_access=NONE.
-- Les SKU stores (stripe_price_id / apple_product_id / google_product_id) sont
-- laissés NULL — à remplir via UPDATE après création côté Stripe / App Store
-- Connect / Play Console (cf. docs/setup-paiement-one-time.md).
-- ============================================================================

-- 1) Désactive les abonnements récurrents (conservés pour revert).
UPDATE plans
SET is_active = FALSE
WHERE code IN (
    'CIVIQUE_MONTHLY', 'CIVIQUE_QUARTERLY', 'CIVIQUE_YEARLY',
    'INTEGRAL_MONTHLY', 'INTEGRAL_QUARTERLY', 'INTEGRAL_YEARLY'
);

-- 2) Passes one-time actifs.
INSERT INTO plans
    (id, code, name, billing_cycle, price, original_price,
     module_access, duration_days, purchase_type, is_active)
VALUES
    ('33333333-0000-0000-0000-000000000030', 'CIVIQUE_PASS_3M',
     'Civique — pass 3 mois', 'NONE', 9.99, NULL,
     'CIVIQUE', 90, 'ONE_TIME', TRUE),
    ('33333333-0000-0000-0000-000000000031', 'CIVIQUE_PASS_1Y',
     'Civique — pass 1 an', 'NONE', 29.99, NULL,
     'CIVIQUE', 365, 'ONE_TIME', TRUE),
    ('33333333-0000-0000-0000-000000000032', 'INTEGRAL_PASS_SPRINT',
     'Intégral — sprint 6 semaines', 'NONE', 19.99, NULL,
     'INTEGRAL', 42, 'ONE_TIME', TRUE),
    ('33333333-0000-0000-0000-000000000033', 'INTEGRAL_PASS_3M',
     'Intégral — pass 3 mois', 'NONE', 35.99, NULL,
     'INTEGRAL', 90, 'ONE_TIME', TRUE),
    ('33333333-0000-0000-0000-000000000034', 'INTEGRAL_PASS_1Y',
     'Intégral — pass 1 an', 'NONE', 79.99, NULL,
     'INTEGRAL', 365, 'ONE_TIME', TRUE);
