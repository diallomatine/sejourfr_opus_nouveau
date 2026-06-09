-- ============================================================================
-- V013 — Ancre du chrono des examens (examen blanc TCF complet)
-- ----------------------------------------------------------------------------
-- Le chrono global d'un examen blanc TCF complet (90 min) ne doit démarrer
-- qu'au lancement de la 1re épreuve (Compréhension orale), pas à la création
-- de l'examen (le candidat lit d'abord le hub de progression).
--
-- `timer_started_at` est NULL tant que l'examen n'a pas réellement commencé,
-- puis posé au premier « Commencer · Compréhension orale ». Le front ancre le
-- compte à rebours dessus ; tant qu'il est NULL, le chrono affiche la durée
-- pleine sans décompter. Distinct de `started_at` (création), qui reste la
-- référence de tri / dédup par slot des grilles d'examens.
-- ============================================================================

ALTER TABLE attempts ADD COLUMN timer_started_at timestamptz;
