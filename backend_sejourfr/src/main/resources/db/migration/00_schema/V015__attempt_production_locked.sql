-- ============================================================================
-- V015 — EE/EO verrouillées dans un examen blanc TCF complet
-- ----------------------------------------------------------------------------
-- Un compte gratuit a droit à l'examen blanc TCF complet : le PREMIER inclut
-- l'expression écrite et orale (EE/EO), évaluées par l'IA, une seule fois.
-- Les examens complets suivants restent rejouables en compréhension (CO+CE)
-- mais leurs épreuves EE/EO sont verrouillées (réservées à l'abonnement).
--
-- `production_locked` marque, sur le parent TCF_COMPLET, que ses sous-épreuves
-- EE/EO sont verrouillées. Source de vérité unique exposée aux fronts
-- (FullTcfExamResponse.SubAttempt.locked) pour distinguer « verrouillé » de
-- « non passé / abandonné » (les deux comptent A1_NON_ATTEINT au bilan, mais
-- le message affiché diffère). Toujours false pour les abonnés (accès illimité)
-- et pour le 1ᵉʳ examen complet d'un compte gratuit.
-- ============================================================================

ALTER TABLE attempts ADD COLUMN production_locked boolean NOT NULL DEFAULT false;
