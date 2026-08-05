-- ============================================================================
-- V024 — Correctif de données : niveau final faux sur les examens complets
--        dont les épreuves EE/EO étaient VERROUILLÉES (freemium)
-- ----------------------------------------------------------------------------
-- Jusqu'ici, une épreuve EE/EO verrouillée (`attempts.production_locked` sur le
-- parent TCF_COMPLET) était pré-terminée SANS aucune soumission, donc évaluée
-- « toutes tâches à 0 » → A1_NON_ATTEINT, et entrait à ce titre dans le
-- plancher des 4 sous-épreuves. Résultat restitué au candidat : « ton niveau
-- TCF IRN : A1 non atteint », à côté d'un cadenas « réservé à l'abonnement ».
-- C'était un verrou COMMERCIAL restitué comme un verdict de LANGUE.
--
-- Une épreuve verrouillée n'a désormais aucun niveau et sort du plancher
-- (FullTcfExamResponseBuilder). Mais les niveaux déjà PERSISTÉS sur
-- `attempts.final_cecrl_level` gardent la valeur fausse, et ils alimentent les
-- statistiques « meilleur niveau » / « dernier examen » (UserDashboardService,
-- MeService, historiques des fronts).
--
-- On les invalide pour forcer la re-dérivation à la lecture : le prochain
-- `GET /api/full-tcf-exams/{id}` (ou tout appel passant par
-- `buildAndPersistCecrlIfReady`) recalcule et repersiste le plancher correct.
-- Aucune perte : le niveau est intégralement recalculable depuis les
-- sous-attempts, qui ne sont pas touchés.
--
-- Borné, déterministe, idempotent (rejoué, il ne trouve plus rien à faire).
-- Ne touche QUE les examens verrouillés — les examens complets normaux gardent
-- leur niveau persisté.
-- ============================================================================

UPDATE attempts
SET final_cecrl_level = NULL
WHERE epreuve = 'TCF_COMPLET'
  AND production_locked = TRUE
  AND final_cecrl_level IS NOT NULL;
