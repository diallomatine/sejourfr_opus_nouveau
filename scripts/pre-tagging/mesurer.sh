#!/usr/bin/env bash
# Les métriques du pilote, à lancer APRÈS la relecture humaine des 50 questions.
#
# 🛑 Tout se compte en COUNT(DISTINCT question_id) : le verdict est écrit sur
#    TOUTES les suggestions d'une question relue, donc COUNT(*) surcompterait
#    les questions qui portent une alternative.
set -euo pipefail
PSQL=(psql -d sejourfr_db -U diallomatine -t -A -F ' | ')

echo "=== 1. Avancement de la relecture ==="
"${PSQL[@]}" -c "
SELECT count(DISTINCT question_id) FILTER (WHERE review_verdict IS NOT NULL) || ' relues sur '
    || count(DISTINCT question_id) || ' proposées'
FROM question_notion_suggestions WHERE prompt_version='PROMPT_TAG_NOTION_v1';"

echo
echo "=== 2. Les quatre taux ==="
"${PSQL[@]}" -c "
WITH relu AS (
  SELECT DISTINCT ON (question_id) question_id, review_verdict
  FROM question_notion_suggestions
  WHERE prompt_version='PROMPT_TAG_NOTION_v1' AND review_verdict IS NOT NULL
  ORDER BY question_id, confidence DESC
)
SELECT review_verdict,
       count(*) AS n,
       round(100.0*count(*)/NULLIF(sum(count(*)) OVER (),0),1) || ' %' AS taux
FROM relu GROUP BY review_verdict ORDER BY n DESC;"

echo
echo "=== 3. Par tranche de confiance (la métrique qui autorise ou non la validation en masse) ==="
"${PSQL[@]}" -c "
WITH meilleure AS (
  SELECT DISTINCT ON (question_id) question_id, confidence, review_verdict
  FROM question_notion_suggestions
  WHERE prompt_version='PROMPT_TAG_NOTION_v1'
  ORDER BY question_id, confidence DESC
)
SELECT CASE WHEN confidence >= 0.90 THEN '>= 0,90'
            WHEN confidence >= 0.70 THEN '0,70-0,89'
            ELSE '< 0,70' END AS tranche,
       count(*) AS total,
       count(*) FILTER (WHERE review_verdict='VALIDATED') AS valides,
       count(*) FILTER (WHERE review_verdict='CORRECTED') AS corriges,
       count(*) FILTER (WHERE review_verdict='REJECTED')  AS rejetes,
       count(*) FILTER (WHERE review_verdict='SKIPPED')   AS passes,
       coalesce(round(100.0*count(*) FILTER (WHERE review_verdict='VALIDATED')
              / NULLIF(count(*) FILTER (WHERE review_verdict IS NOT NULL),0),1)::text || ' %','—')
         AS taux_accord
FROM meilleure GROUP BY 1 ORDER BY 1 DESC;"

echo
echo "=== 4. Ce que le modèle a proposé vs ce que l'humain a retenu (les vraies confusions) ==="
"${PSQL[@]}" -c "
WITH meilleure AS (
  SELECT DISTINCT ON (s.question_id) s.question_id, n.code AS propose, s.review_verdict
  FROM question_notion_suggestions s JOIN civic_notions n ON n.id = s.notion_id
  WHERE s.prompt_version='PROMPT_TAG_NOTION_v1'
  ORDER BY s.question_id, s.confidence DESC
)
SELECT m.propose || '  ->  ' || coalesce(nr.code,'(aucune)') AS correction, count(*) AS n
FROM meilleure m
JOIN questions q ON q.id = m.question_id
LEFT JOIN civic_notions nr ON nr.id = q.civic_notion_id
WHERE m.review_verdict = 'CORRECTED'
GROUP BY 1 ORDER BY n DESC;"

echo
echo "=== 5. Durée de relecture (bornes réelles, d'après reviewed_at) ==="
"${PSQL[@]}" -c "
WITH relu AS (
  SELECT DISTINCT ON (question_id) question_id, reviewed_at
  FROM question_notion_suggestions
  WHERE prompt_version='PROMPT_TAG_NOTION_v1' AND reviewed_at IS NOT NULL
  ORDER BY question_id, confidence DESC
), ecarts AS (
  SELECT extract(epoch FROM reviewed_at - lag(reviewed_at) OVER (ORDER BY reviewed_at)) AS sec
  FROM relu
)
-- Les écarts > 5 min sont des pauses, pas des décisions : on les écarte, sinon
-- un café fausse la moyenne sur 50 questions.
SELECT count(*) || ' intervalles retenus · mediane ' ||
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY sec)::numeric,1) || ' s/question · moyenne ' ||
       round(avg(sec)::numeric,1) || ' s'
FROM ecarts WHERE sec IS NOT NULL AND sec < 300;"
