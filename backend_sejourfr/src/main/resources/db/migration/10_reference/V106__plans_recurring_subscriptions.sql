-- ============================================================================
-- V106 — Plans en abonnements récurrents (Stripe Subscription + IAP).
--
-- Pourquoi : passage du modèle one-shot 3 mois (CIVIQUE_3MOIS / INTEGRAL_3MOIS)
-- au modèle abonnement récurrent avec 3 périodicités (mensuel / trimestriel /
-- annuel) × 2 modules (CIVIQUE / INTEGRAL) = 6 SKUs. Le trimestriel donne une
-- remise sur le mensuel, l'annuel une remise plus forte.
--
-- Les anciens plans sont désactivés (is_active=FALSE) plutôt que supprimés :
-- les souscriptions historiques (dev seed, données réelles si présentes)
-- restent valides jusqu'à leur ends_at, mais le plan n'apparaît plus dans la
-- listing publique GET /api/billing/plans.
--
-- Prix indicatifs (l'admin pourra les ajuster en DB sans toucher au code).
-- Le mensuel CIVIQUE = 4,99€ ; -15% au trimestriel (12,72€ ≈ 4,24€/mois) ;
-- -35% à l'annuel (38,93€ ≈ 3,24€/mois). Idem ratios pour INTEGRAL.
--
-- Les colonnes apple_product_id, google_product_id et stripe_price_id sont
-- laissées NULL pour l'instant — à remplir via UPDATE quand les SKUs auront
-- été créés dans App Store Connect / Play Console / Stripe Dashboard.
--
-- duration_days reste 30/90/365 pour cohérence affichage mais ce n'est plus
-- la source de vérité de la durée Premium : Stripe / Apple / Google posent
-- ends_at directement depuis leurs périodes de facturation.
-- ============================================================================

UPDATE plans
SET is_active = FALSE
WHERE code IN ('CIVIQUE_3MOIS', 'INTEGRAL_3MOIS');

INSERT INTO plans (id, code, name, billing_cycle, price, original_price, module_access, duration_days, is_active)
VALUES
    -- Civique : module civique seul (CSP / CR / NAT)
    ('33333333-0000-0000-0000-000000000010', 'CIVIQUE_MONTHLY',
     'Civique — mensuel', 'MONTHLY', 4.99, NULL, 'CIVIQUE', 30, TRUE),
    ('33333333-0000-0000-0000-000000000011', 'CIVIQUE_QUARTERLY',
     'Civique — trimestriel', 'THREE_MONTHS', 12.72, 14.97, 'CIVIQUE', 90, TRUE),
    ('33333333-0000-0000-0000-000000000012', 'CIVIQUE_YEARLY',
     'Civique — annuel', 'YEARLY', 38.93, 59.88, 'CIVIQUE', 365, TRUE),

    -- Intégral : civique + TCF + EE/EO IA
    ('33333333-0000-0000-0000-000000000020', 'INTEGRAL_MONTHLY',
     'Intégral — mensuel', 'MONTHLY', 9.99, NULL, 'INTEGRAL', 30, TRUE),
    ('33333333-0000-0000-0000-000000000021', 'INTEGRAL_QUARTERLY',
     'Intégral — trimestriel', 'THREE_MONTHS', 25.47, 29.97, 'INTEGRAL', 90, TRUE),
    ('33333333-0000-0000-0000-000000000022', 'INTEGRAL_YEARLY',
     'Intégral — annuel', 'YEARLY', 77.93, 119.88, 'INTEGRAL', 365, TRUE);
