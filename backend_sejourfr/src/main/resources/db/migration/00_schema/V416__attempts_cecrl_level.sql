-- Niveau CECRL estimé d'une épreuve QCM (CO / CE), calculé une seule fois à la
-- finalisation via TcfLevelEstimatorService (score calibré + garde-fou palier)
-- puis relu par l'examen blanc complet et le profil de niveau par épreuve.
-- Distinct de level_achieved (TargetLevel A2/B1/B2 only) qui ne peut pas porter
-- A1 / A1_NON_ATTEINT, et de final_cecrl_level (plancher du TCF_COMPLET).
ALTER TABLE attempts
    ADD COLUMN cecrl_level VARCHAR(24);

COMMENT ON COLUMN attempts.cecrl_level IS
    'Examens module TCF (CO/CE) : niveau CECRL estimé à la finalisation (TcfLevelEstimatorService), plafonné B2. NULL pour le civique, l''entraînement libre et les attempts pré-V416.';
