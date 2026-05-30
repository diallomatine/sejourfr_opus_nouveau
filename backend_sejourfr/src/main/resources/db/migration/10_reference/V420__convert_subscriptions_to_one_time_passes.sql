-- ============================================================================
-- V420 — Conversion des abonnements récurrents existants en passes one-time.
--
-- Bascule du lot 5 : chaque user_subscription rattachée à un plan SUBSCRIPTION
-- (Civique / Intégral) passe au PASS one-time du MÊME module dont la durée est
-- la plus proche de l'ancien cycle (« meilleure formule »). On coupe la
-- reconduction (auto_renew=false) et on CONSERVE la date de fin existante
-- (ends_at = ancienne date de renouvellement) ainsi que le statut.
--
-- Naturellement sans effet si aucune souscription récurrente n'existe (filtre
-- purchase_type='SUBSCRIPTION'), et ne touche jamais le plan FREE / sans module.
--
-- ⚠ Ne stoppe PAS la facturation côté store : pour de VRAIS abonnements
-- Stripe/Apple/Google encore actifs, il faut en plus annuler la subscription
-- chez le provider (Stripe cancel_at_period_end, etc.).
-- ============================================================================

UPDATE user_subscriptions us
SET plan_id = (
        SELECT np.id
        FROM plans np
        WHERE np.purchase_type = 'ONE_TIME'
          AND np.is_active
          AND np.module_access = cur.module_access
        ORDER BY abs(np.duration_days - cur.duration_days), np.duration_days
        LIMIT 1
    ),
    auto_renew = false
FROM plans cur
WHERE cur.id = us.plan_id
  AND cur.purchase_type = 'SUBSCRIPTION'
  AND cur.module_access IN ('CIVIQUE', 'INTEGRAL')
  AND EXISTS (
        SELECT 1 FROM plans np
        WHERE np.purchase_type = 'ONE_TIME' AND np.is_active
          AND np.module_access = cur.module_access
  );
