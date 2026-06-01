-- ============================================================================
-- V417 — Nature commerciale d'un plan : abonnement récurrent vs pass one-time.
--
-- Lot 5 (bascule achat unique). Le front rend une grille de passes pour
-- ONE_TIME, le toggle de périodicité pour SUBSCRIPTION. Les plans existants
-- (lots 2/3/4) deviennent SUBSCRIPTION par défaut ; ils restent en base
-- (réversibilité), seul leur is_active bascule selon le mode actif.
-- ============================================================================

ALTER TABLE plans
    ADD COLUMN purchase_type VARCHAR(16) NOT NULL DEFAULT 'SUBSCRIPTION';

COMMENT ON COLUMN plans.purchase_type IS
    'SUBSCRIPTION (abonnement récurrent, lots 2/3/4) ou ONE_TIME (pass à durée fixe, lot 5). En ONE_TIME, duration_days est la source de vérité de la durée Premium.';
