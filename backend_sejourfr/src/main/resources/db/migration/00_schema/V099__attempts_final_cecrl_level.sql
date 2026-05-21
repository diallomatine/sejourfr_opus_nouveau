-- ============================================================================
-- V099 : Niveau CECRL plancher pour les examens blancs TCF complets
-- ============================================================================
-- Renseigné uniquement sur le parent attempt TCF_COMPLET (epreuve =
-- 'TCF_COMPLET'), à la finalisation. C'est le niveau le plus bas des 4
-- sous-épreuves (CO + CE + EE + EO) — règle officielle TCF IRN où le niveau
-- final correspond au plancher des 4 compétences.
--
-- Valeurs attendues : A1_NON_ATTEINT | A1 | A2 | B1 | B2 | C1 | C2 (cf.
-- enum NiveauCecrl). NULL tant que toutes les évaluations IA EE/EO ne sont
-- pas remontées EVALUATED.
-- ============================================================================

ALTER TABLE attempts
    ADD COLUMN final_cecrl_level VARCHAR(24);

COMMENT ON COLUMN attempts.final_cecrl_level IS
    'TCF_COMPLET uniquement : niveau CECRL plancher des 4 sous-épreuves, persisté à la finalisation. NULL si évaluations IA encore en cours.';
