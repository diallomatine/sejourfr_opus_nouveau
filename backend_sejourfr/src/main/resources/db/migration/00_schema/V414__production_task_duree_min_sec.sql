-- Durée minimale acceptable pour une tâche EO (en secondes).
-- L'objectif officiel reste duree_max_sec (180 s T1 / 210 s T2-T3) ; en dessous
-- de duree_min_sec (120 s = 2 min) la production est jugée insuffisante mais
-- N'EST PAS bloquée : l'utilisateur reçoit quand même son évaluation IA, avec un
-- avertissement et une note minorée (cf. AiEvaluationService).
ALTER TABLE production_tasks ADD COLUMN duree_min_sec INTEGER;
