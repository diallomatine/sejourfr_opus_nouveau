-- ============================================================================
-- V018 — Quota de sessions EO temps réel, porté par le plan
-- ----------------------------------------------------------------------------
-- Le nombre de sessions d'expression orale en temps réel (examinateur IA) est
-- désormais une propriété du plan (comme `duration_days`), au lieu d'un mapping
-- en configuration. Source de vérité unique, éditable par l'admin (Plans), et
-- naturellement « adaptée selon le pass » : le quota d'un utilisateur dérive du
-- plan de sa souscription couvrante.
--
-- 0 par défaut : un plan sans accès TCF (Civique, Free) n'ouvre aucune session
-- temps réel. Les valeurs par pass sont posées dans la migration de référence
-- (100_reference). Le décompte de consommation reste dérivé de la table
-- `realtime_sessions` (V016).
-- ============================================================================

ALTER TABLE plans
    ADD COLUMN realtime_eo_sessions int DEFAULT 0 NOT NULL;

COMMENT ON COLUMN plans.realtime_eo_sessions IS 'Nombre de sessions EO temps réel ouvertes par ce pass (0 = non éligible). Cap du quota, consommation dérivée de realtime_sessions.';
