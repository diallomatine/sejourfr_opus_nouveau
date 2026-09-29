-- Nettoyage des données écrites dans la base LOCALE de dev (sejourfr_db) par
-- `python -m jev_bench score-sejourfr`. JAMAIS en production.
--
-- Périmètre : tout ce qui descend d'une production_tasks dont le titre commence
-- par « [JEV-BENCH] » (tâches insérées par l'outil), et ce que le backend a
-- écrit en traitant leurs soumissions :
--   production_submissions (+ ai_evaluations, transcriptions… en cascade),
--   learning_plan_observations (source_id = soumission),
--   learning_evidence (attempt de la soumission),
--   attempts d'entraînement créés pour ces soumissions,
--   progression_prediction_log (journal « shadow » du compte seed user@, lignes créées depuis
--     :'depuis' sans issue — le replay ne le reconstruit pas),
--   production_tasks [JEV-BENCH].
--
-- Usage :
--   psql -X -v ON_ERROR_STOP=1 -d sejourfr_db -U diallomatine \
--        -v depuis='2026-09-29 23:00:00+02' \
--        -f tools/jev-benchmark/jev_bench/sql/cleanup_local_sejourfr_db.sql
-- (:'depuis' = début de la première session de benchmark ; ne sert qu'au journal de prédictions.)
--
-- ⚠️ APRÈS ce script, reconstruire la projection de progression du compte seed
-- (progression_state et progression_state_family_aggregate sont des agrégats
-- incrémentaux : supprimer les preuves ne les recalcule pas). Backend local
-- lancé, jeton ADMIN :
--   TOKEN=$(curl -s localhost:8080/api/auth/login -H 'Content-Type: application/json' \
--           -d '{"email":"admin@sejourfr.fr","password":"Admin123!"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["accessToken"])')
--   curl -s -X POST -H "Authorization: Bearer $TOKEN" \
--        localhost:8080/api/admin/progression/utilisateurs/aaaaaaaa-0000-0000-0000-000000000002/replay
--
-- Les refresh_tokens des connexions de l outil se suppriment EN DERNIER (après le replay) avec
-- cleanup_local_refresh_tokens.sql.

BEGIN;

CREATE TEMP TABLE jev_tasks ON COMMIT DROP AS
    SELECT id FROM production_tasks WHERE titre LIKE '[JEV-BENCH]%';

CREATE TEMP TABLE jev_subs ON COMMIT DROP AS
    SELECT id, attempt_id FROM production_submissions
    WHERE production_task_id IN (SELECT id FROM jev_tasks);

-- Garde-fou : un attempt qui porterait AUSSI des soumissions hors benchmark
-- n'est pas supprimé (ni ses preuves).
CREATE TEMP TABLE jev_attempts ON COMMIT DROP AS
    SELECT DISTINCT s.attempt_id AS id FROM jev_subs s
    WHERE NOT EXISTS (
        SELECT 1 FROM production_submissions ps
        WHERE ps.attempt_id = s.attempt_id AND ps.id NOT IN (SELECT id FROM jev_subs));

SELECT (SELECT count(*) FROM jev_tasks)    AS taches,
       (SELECT count(*) FROM jev_subs)     AS soumissions,
       (SELECT count(*) FROM jev_attempts) AS attempts;

DELETE FROM learning_plan_observations
 WHERE source_type = 'PRODUCTION_EE' AND source_id IN (SELECT id FROM jev_subs);

DELETE FROM learning_evidence WHERE attempt_id IN (SELECT id FROM jev_attempts);

DELETE FROM production_submissions WHERE id IN (SELECT id FROM jev_subs);

DELETE FROM attempts WHERE id IN (SELECT id FROM jev_attempts);

DELETE FROM production_tasks WHERE id IN (SELECT id FROM jev_tasks);

DELETE FROM progression_prediction_log
 WHERE user_id = 'aaaaaaaa-0000-0000-0000-000000000002'
   AND created_at >= :'depuis'::timestamptz
   AND outcome_at IS NULL;

COMMIT;
