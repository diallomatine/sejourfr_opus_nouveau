-- ============================================================================
-- V113 — Quota de sessions EO temps réel par plan (valeurs)
-- ----------------------------------------------------------------------------
-- Valeurs PROVISOIRES, ajustables à chaud (admin Plans / SQL) — cf. brief.
-- Seuls les plans INTEGRAL (accès TCF) ouvrent du temps réel ; Civique/Free
-- restent à 0 (défaut V018). Cap par pass, croissant avec la durée.
--
--   Sprint (6 sem)  -> 25
--   Trimestre (3 m) -> 60
--   Annuel (1 an)   -> 120
-- ============================================================================

-- Passes one-time INTEGRAL (mode commercial actif).
UPDATE plans SET realtime_eo_sessions = 25  WHERE code = 'INTEGRAL_PASS_SPRINT';
UPDATE plans SET realtime_eo_sessions = 60  WHERE code = 'INTEGRAL_PASS_3M';
UPDATE plans SET realtime_eo_sessions = 120 WHERE code = 'INTEGRAL_PASS_1Y';

-- Abonnements récurrents INTEGRAL (dormants, mode SUBSCRIPTION) : mêmes paliers
-- par périodicité, pour que le quota fonctionne aussi si on rebascule.
UPDATE plans SET realtime_eo_sessions = 25  WHERE code = 'INTEGRAL_MONTHLY';
UPDATE plans SET realtime_eo_sessions = 60  WHERE code = 'INTEGRAL_QUARTERLY';
UPDATE plans SET realtime_eo_sessions = 60  WHERE code = 'INTEGRAL_3MOIS';
UPDATE plans SET realtime_eo_sessions = 120 WHERE code = 'INTEGRAL_YEARLY';
UPDATE plans SET realtime_eo_sessions = 60  WHERE code = 'INTEGRAL';
