-- ============================================================================
-- Migration ponctuelle (HORS Flyway) — abonnements récurrents → passes one-time
--
-- Pour chaque user_subscription rattachée à un plan SUBSCRIPTION (Civique /
-- Intégral), on bascule vers le PASS one-time du même module dont la durée est
-- la plus proche de l'ancien cycle (« meilleure formule »), on coupe la
-- reconduction (auto_renew=false), et on CONSERVE la date de fin existante
-- (ends_at = ancienne date de renouvellement) ainsi que le statut.
--
-- Idempotent : relancer ne touche plus rien (les lignes pointent déjà vers des
-- plans ONE_TIME).
--
-- ⚠️ PRODUCTION : pour de VRAIS abonnements Stripe/Apple/Google encore actifs,
-- ce script ne stoppe PAS la facturation côté store — il faut en plus annuler
-- la subscription côté Stripe (cancel_at_period_end) / store. Ici c'est prévu
-- pour des données de test.
--
-- Usage : psql -d <db> -U <user> -f scripts/migrate_subscriptions_to_passes.sql
-- ============================================================================

BEGIN;

-- Aperçu AVANT
\echo '--- AVANT ---'
SELECT COALESCE(u.email, '(guest)') AS email, us.status, us.auto_renew,
       p.code AS plan, p.purchase_type, us.ends_at::date
FROM user_subscriptions us
JOIN plans p ON p.id = us.plan_id
LEFT JOIN users u ON u.id = us.user_id
ORDER BY us.updated_at DESC;

-- Conversion : plan récurrent -> pass one-time du même module, durée la plus
-- proche. ends_at et status inchangés.
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
  -- garde-fou : il existe bien un pass cible pour ce module
  AND EXISTS (
        SELECT 1 FROM plans np
        WHERE np.purchase_type = 'ONE_TIME' AND np.is_active
          AND np.module_access = cur.module_access
  );

-- Aperçu APRÈS
\echo '--- APRES ---'
SELECT COALESCE(u.email, '(guest)') AS email, us.status, us.auto_renew,
       p.code AS plan, p.purchase_type, p.duration_days, us.ends_at::date
FROM user_subscriptions us
JOIN plans p ON p.id = us.plan_id
LEFT JOIN users u ON u.id = us.user_id
ORDER BY us.updated_at DESC;

COMMIT;
