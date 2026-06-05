-- ============================================================================
-- V100 — Référence : plans (catalogue abonnements + passes)
-- ----------------------------------------------------------------------------
-- Table plans. 6 abonnements récurrents (is_active=false, dormants) + 5 passes one-time + Free.
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

INSERT INTO plans
  (id, code, name, billing_cycle, price, original_price, module_access, duration_days, is_active,
   apple_product_id, google_product_id, stripe_price_id, purchase_type)
VALUES
  ('33333333-0000-0000-0000-000000000002', 'CIVIQUE_3MOIS', 'Civique — 3 mois', 'THREE_MONTHS', '5.99', '9.99', 'CIVIQUE', '90',
   'false', NULL, NULL, NULL, 'SUBSCRIPTION'),
  ('33333333-0000-0000-0000-000000000010', 'CIVIQUE_MONTHLY', 'Civique — mensuel', 'MONTHLY', '4.99', NULL, 'CIVIQUE', '30', 'false',
   'CIVIQUE_MONTHLY', 'civique_monthly', NULL, 'SUBSCRIPTION'),
  ('33333333-0000-0000-0000-000000000031', 'CIVIQUE_PASS_1Y', 'Civique — pass 1 an', 'NONE', '29.99', NULL, 'CIVIQUE', '365', 'true',
   'civique_pass_1y', 'civique_pass_1y', NULL, 'ONE_TIME'),
  ('33333333-0000-0000-0000-000000000030', 'CIVIQUE_PASS_3M', 'Civique — pass 3 mois', 'NONE', '9.99', NULL, 'CIVIQUE', '90', 'true',
   'civique_pass_3m', 'civique_pass_3m', NULL, 'ONE_TIME'),
  ('33333333-0000-0000-0000-000000000011', 'CIVIQUE_QUARTERLY', 'Civique — trimestriel', 'THREE_MONTHS', '12.72', '14.97', 'CIVIQUE',
   '90', 'false', 'CIVIQUE_QUARTERLY', 'civique_quarterly', NULL, 'SUBSCRIPTION'),
  ('33333333-0000-0000-0000-000000000012', 'CIVIQUE_YEARLY', 'Civique — annuel', 'YEARLY', '38.93', '59.88', 'CIVIQUE', '365',
   'false', 'CIVIQUE_YEARLY', 'civique_yearly', NULL, 'SUBSCRIPTION'),
  ('33333333-0000-0000-0000-000000000001', 'FREE', 'Gratuit', 'NONE', '0.00', NULL, 'NONE', '0', 'true', NULL, NULL, NULL,
   'SUBSCRIPTION'),
  ('33333333-0000-0000-0000-000000000003', 'INTEGRAL_3MOIS', 'Intégral (Civique + TCF) — 3 mois', 'THREE_MONTHS', '14.99', '19.99',
   'INTEGRAL', '90', 'false', NULL, NULL, NULL, 'SUBSCRIPTION'),
  ('33333333-0000-0000-0000-000000000020', 'INTEGRAL_MONTHLY', 'Intégral — mensuel', 'MONTHLY', '9.99', NULL, 'INTEGRAL', '30',
   'false', 'INTEGRAL_MONTHLY', 'integral_monthly', NULL, 'SUBSCRIPTION'),
  ('33333333-0000-0000-0000-000000000034', 'INTEGRAL_PASS_1Y', 'Intégral — pass 1 an', 'NONE', '79.99', NULL, 'INTEGRAL', '365',
   'true', 'integral_pass_1y', 'integral_pass_1y', NULL, 'ONE_TIME'),
  ('33333333-0000-0000-0000-000000000033', 'INTEGRAL_PASS_3M', 'Intégral — pass 3 mois', 'NONE', '34.99', NULL, 'INTEGRAL', '90',
   'true', 'integral_pass_3m', 'integral_pass_3m', NULL, 'ONE_TIME'),
  ('33333333-0000-0000-0000-000000000032', 'INTEGRAL_PASS_SPRINT', 'Intégral — sprint 6 semaines', 'NONE', '19.99', NULL, 'INTEGRAL',
   '42', 'true', 'integral_pass_sprint', 'integral_pass_sprint', NULL, 'ONE_TIME'),
  ('33333333-0000-0000-0000-000000000021', 'INTEGRAL_QUARTERLY', 'Intégral — trimestriel', 'THREE_MONTHS', '25.47', '29.97',
   'INTEGRAL', '90', 'false', 'INTEGRAL_QUARTERLY', 'integral_quarterly', NULL, 'SUBSCRIPTION'),
  ('33333333-0000-0000-0000-000000000022', 'INTEGRAL_YEARLY', 'Intégral — annuel', 'YEARLY', '77.93', '119.88', 'INTEGRAL', '365',
   'false', 'INTEGRAL_YEARLY', 'integral_yearly', NULL, 'SUBSCRIPTION');
