-- ============================================================================
-- V114 — Référence : nouveaux passes Intégral (7 jours / 1 mois / 2 mois)
-- ----------------------------------------------------------------------------
-- Le catalogue Intégral passait par des durées longues (6 semaines 19,99 €,
-- 3 mois 34,99 €, 1 an 79,99 €). Il devient court et progressif :
--
--   INTEGRAL_PASS_7J  ->   7 j  ·  9,99 €  ·  5 simulations orales
--   INTEGRAL_PASS_1M  ->  30 j  · 19,99 €  · 15 simulations orales
--   INTEGRAL_PASS_2M  ->  60 j  · 29,99 €  · 25 simulations orales
--
-- Le catalogue **Civique est inchangé** (pass 3 mois 9,99 € / pass 1 an 29,99 €).
--
-- ⚠ Ce sont de NOUVEAUX codes, pas une réécriture des anciens. Trois raisons :
--   1. un product ID de store est immuable — « integral_pass_sprint » vendu
--      7 jours resterait un piège durable en console Apple/Google ;
--   2. les souscriptions déjà vendues pointent sur les anciens plans par FK
--      (user_subscriptions.plan_id) et lisent leur duration_days : changer la
--      durée d'un plan réécrirait rétroactivement l'accès acheté ;
--   3. la réversibilité du § « billing » du CLAUDE.md racine impose de ne rien
--      supprimer — les anciens passes sont désactivés, pas effacés.
--
-- Retour arrière : is_active TRUE sur les 3 anciens, FALSE sur les 3 nouveaux.
-- Aucune donnée n'est perdue dans un sens comme dans l'autre.
-- ============================================================================

INSERT INTO plans
  (id, code, name, billing_cycle, price, original_price, module_access, duration_days, is_active,
   apple_product_id, google_product_id, stripe_price_id, purchase_type, realtime_eo_sessions)
VALUES
  ('33333333-0000-0000-0000-000000000035', 'INTEGRAL_PASS_7J', 'Intégral — pass 7 jours', 'NONE',
   9.99, NULL, 'INTEGRAL', 7, TRUE, 'integral_pass_7j', 'integral_pass_7j', NULL, 'ONE_TIME', 5),
  ('33333333-0000-0000-0000-000000000036', 'INTEGRAL_PASS_1M', 'Intégral — pass 1 mois', 'NONE',
   19.99, NULL, 'INTEGRAL', 30, TRUE, 'integral_pass_1m', 'integral_pass_1m', NULL, 'ONE_TIME', 15),
  ('33333333-0000-0000-0000-000000000037', 'INTEGRAL_PASS_2M', 'Intégral — pass 2 mois', 'NONE',
   29.99, NULL, 'INTEGRAL', 60, TRUE, 'integral_pass_2m', 'integral_pass_2m', NULL, 'ONE_TIME', 25);

-- Les anciens passes Intégral deviennent dormants : plus vendus (absents de
-- GET /api/billing/plans, donc du paywall et des grilles de tarifs), mais
-- toujours joignables par les souscriptions existantes et par les webhooks des
-- stores, qui continuent de résoudre leur product ID.
UPDATE plans SET is_active = FALSE
 WHERE code IN ('INTEGRAL_PASS_SPRINT', 'INTEGRAL_PASS_3M', 'INTEGRAL_PASS_1Y');
