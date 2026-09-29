#!/usr/bin/env bash
# LES MÉTRIQUES DU PRÉ-TAGGING — à lancer APRÈS la relecture humaine.
#
#   ./mesurer.sh [PROMPT_VERSION] [BATCH_ID ...]
#
#   ./mesurer.sh                                   # la dernière version servie
#   ./mesurer.sh PROMPT_TAG_NOTION_v3              # toutes ses suggestions
#   ./mesurer.sh PROMPT_TAG_NOTION_v3 <batch_id>   # UN lot précis
#   ./mesurer.sh PROMPT_TAG_NOTION_v3 <id1> <id2>  # plusieurs lots
#
# 🛑 POURQUOI LE FILTRE EST PARAMÉTRABLE, ET PAS ÉCRIT EN DUR.
# Une version de prompt = une CALIBRATION. Mélanger deux versions dans le même
# taux de VALIDATED produit un nombre qui ne veut plus rien dire — c'est
# exactement pourquoi `prompt_version` est NOT NULL en base. Et le jour où le
# job complet tournera en v3 sur 790 questions, ses suggestions ne doivent pas
# contaminer les métriques des 50 du pilote : d'où le filtre par `batch_id`.
#
# 🛑 TOUT SE COMPTE EN `COUNT(DISTINCT question_id)`. Le verdict est écrit sur
# TOUTES les suggestions d'une question relue (une question porte souvent une
# alternative) : un `COUNT(*)` surcompterait.
#
# 🛑 UNE SUGGESTION PEUT ÊTRE « AUCUNE NOTION » (`notion_id IS NULL`). Ce n'est
# ni une erreur ni une absence : c'est un verdict du modèle, et confirmé par un
# humain il désigne un TROU DU RÉFÉRENTIEL. C'est le signal le plus précieux du
# job complet, il a donc sa métrique à lui (§4).
set -euo pipefail

PROMPT_VERSION="${1:-}"
shift || true
BATCHS=("$@")

PSQL=(psql -d sejourfr_db -U diallomatine -t -A -F ' | ')

if [[ -z "$PROMPT_VERSION" ]]; then
  PROMPT_VERSION="$("${PSQL[@]}" -c \
    "SELECT prompt_version FROM question_notion_suggestions
      GROUP BY 1 ORDER BY max(created_at) DESC LIMIT 1;")"
  [[ -z "$PROMPT_VERSION" ]] && { echo "Aucune suggestion en base." >&2; exit 1; }
  echo "(version non précisée — on mesure la plus récente : ${PROMPT_VERSION})" >&2
fi

# Le filtre de lot, construit une fois et réutilisé par toutes les requêtes.
if [[ ${#BATCHS[@]} -gt 0 ]]; then
  liste="$(printf "'%s'," "${BATCHS[@]}")"
  FILTRE_LOT="AND s.batch_id IN (${liste%,})"
  echo "Périmètre : ${PROMPT_VERSION} · ${#BATCHS[@]} lot(s)" >&2
else
  FILTRE_LOT=""
  echo "Périmètre : ${PROMPT_VERSION} · tous les lots" >&2
fi
echo >&2

# La « meilleure » suggestion d'une question, c'est celle que le SERVEUR compare
# pour décider VALIDATED vs CORRECTED. On la reproduit à l'identique :
# confiance décroissante, puis le code pour un départage déterministe — une
# suggestion « aucune notion » n'a pas de code, elle passe en dernier.
MEILLEURE="
  WITH s_filtre AS (
    SELECT s.* FROM question_notion_suggestions s
     WHERE s.prompt_version = '${PROMPT_VERSION}' ${FILTRE_LOT}
  ),
  meilleure AS (
    SELECT DISTINCT ON (s.question_id)
           s.question_id, s.notion_id, s.confidence, s.review_verdict, s.reviewed_at,
           n.code AS notion_proposee
      FROM s_filtre s
      LEFT JOIN civic_notions n ON n.id = s.notion_id
     ORDER BY s.question_id, s.confidence DESC, n.code NULLS LAST
  )"

# ----------------------------------------------------------------------------
# §0 — CE QU'ON PEUT LIRE AVANT QUE L'HUMAIN AIT RELU.
# Les sections 1 a 6 mesurent la QUALITE du modele, et elles ont toutes besoin
# d'un `review_verdict` : sans relecture, elles ne disent rien. Cette
# section-ci mesure ce que le modele a PRODUIT, ce qui est disponible des la
# fin d'un lot et suffit a decider si un pilote merite d'etre relu.
# ----------------------------------------------------------------------------
echo "=== 0. Ce que le modèle a proposé (lisible sans relecture) ==="
echo
echo "    Répartition par notion proposée :"
"${PSQL[@]}" -c "${MEILLEURE}
SELECT coalesce(notion_proposee, '(aucune notion pertinente)') AS notion,
       count(*) AS n,
       round(avg(confidence), 2) AS confiance_moyenne,
       round(min(confidence), 2) AS mini
FROM meilleure GROUP BY 1 ORDER BY n DESC, 1;"

echo
echo "    Étalement de la confiance — une confiance plate rend le tri humain inutile :"
"${PSQL[@]}" -c "${MEILLEURE}
SELECT CASE WHEN confidence >= 0.90 THEN '>= 0,90'
            WHEN confidence >= 0.70 THEN '0,70-0,89'
            ELSE '< 0,70' END AS tranche,
       count(*) AS n,
       round(100.0*count(*)/NULLIF(sum(count(*)) OVER (),0),1) || ' %' AS part
FROM meilleure GROUP BY 1 ORDER BY 1 DESC;"

echo
echo "    Où le modèle HÉSITE : proposition -> alternative, et l'écart de confiance."
echo "    Ce sont les frontières du référentiel à relire en premier."
"${PSQL[@]}" -c "
WITH s_filtre AS (
  SELECT s.* FROM question_notion_suggestions s
   WHERE s.prompt_version = '${PROMPT_VERSION}' ${FILTRE_LOT}
),
paires AS (
  SELECT s.question_id,
         (array_agg(coalesce(n.code,'(aucune)') ORDER BY s.confidence DESC, n.code NULLS LAST))[1] AS retenue,
         (array_agg(coalesce(n.code,'(aucune)') ORDER BY s.confidence DESC, n.code NULLS LAST))[2] AS alternative,
         max(s.confidence) - min(s.confidence) AS ecart
    FROM s_filtre s LEFT JOIN civic_notions n ON n.id = s.notion_id
   GROUP BY s.question_id HAVING count(*) > 1
)
SELECT retenue || '  <->  ' || alternative AS frontiere_disputee,
       count(*) AS n, round(avg(ecart), 2) AS ecart_moyen
FROM paires GROUP BY 1 ORDER BY n DESC, 1;"

echo
echo "    « Aucune notion » proposée, avec ce que le modèle en dit."
echo "    Depuis V058/V059, une AUCUNE qui pointe vers un AUTRE THÈME est un"
echo "    défaut de rangement du corpus, pas un trou du référentiel :"
"${PSQL[@]}" -c "
SELECT left(q.statement, 70), t.code, left(s.rationale, 110)
  FROM question_notion_suggestions s
  JOIN questions q ON q.id = s.question_id
  JOIN themes t ON t.id = q.theme_id
 WHERE s.prompt_version = '${PROMPT_VERSION}' ${FILTRE_LOT}
   AND s.notion_id IS NULL
 ORDER BY t.code, q.statement;"

echo
echo "=== 1. Avancement de la relecture ==="
"${PSQL[@]}" -c "${MEILLEURE}
SELECT count(*) FILTER (WHERE review_verdict IS NOT NULL) || ' relues sur '
    || count(*) || ' proposées'
FROM meilleure;"

echo
echo "=== 2. Les quatre issues ==="
"${PSQL[@]}" -c "${MEILLEURE}
SELECT coalesce(review_verdict,'(pas encore relue)') AS issue,
       count(*) AS n,
       round(100.0*count(*)/NULLIF(sum(count(*)) OVER (),0),1) || ' %' AS part
FROM meilleure GROUP BY 1 ORDER BY n DESC;"

echo
echo "=== 3. Par tranche de confiance — c'est CETTE table qui autorise ou non la validation en masse ==="
"${PSQL[@]}" -c "${MEILLEURE}
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
         AS precision_du_modele
FROM meilleure GROUP BY 1 ORDER BY 1 DESC;"

echo
echo "=== 4. « Aucune notion pertinente » — les TROUS DU RÉFÉRENTIEL ==="
echo "    (confirmé = le modèle a dit « aucune » ET l'humain l'a suivi)"
"${PSQL[@]}" -c "${MEILLEURE}
SELECT
  count(*) FILTER (WHERE notion_id IS NULL) AS proposees_sans_notion,
  count(*) FILTER (WHERE notion_id IS NULL AND review_verdict='VALIDATED') AS trous_confirmes,
  count(*) FILTER (WHERE notion_id IS NULL AND review_verdict='CORRECTED') AS finalement_rattachees,
  count(*) FILTER (WHERE notion_id IS NULL AND review_verdict IS NULL)     AS pas_encore_relues
FROM meilleure;"

echo
echo "    Les questions concernées (à regrouper quand elles seront nombreuses) :"
"${PSQL[@]}" -c "${MEILLEURE}
SELECT coalesce(m.review_verdict,'à relire') || '  ·  ' || left(q.statement, 90)
FROM meilleure m JOIN questions q ON q.id = m.question_id
WHERE m.notion_id IS NULL
ORDER BY m.review_verdict NULLS FIRST
LIMIT 40;"

echo
echo "=== 5. Confusions restantes : ce que le modèle a proposé -> ce que l'humain a retenu ==="
"${PSQL[@]}" -c "${MEILLEURE}
SELECT coalesce(m.notion_proposee,'(aucune notion)') || '  ->  ' || coalesce(nr.code,'(rien)') AS correction,
       count(*) AS n
FROM meilleure m
JOIN questions q ON q.id = m.question_id
LEFT JOIN civic_notions nr ON nr.id = q.civic_notion_id
WHERE m.review_verdict = 'CORRECTED'
GROUP BY 1 ORDER BY n DESC;"

echo
echo "=== 6. Temps de relecture (d'après reviewed_at) ==="
"${PSQL[@]}" -c "${MEILLEURE}
, ecarts AS (
  SELECT extract(epoch FROM reviewed_at - lag(reviewed_at) OVER (ORDER BY reviewed_at)) AS sec
  FROM meilleure WHERE reviewed_at IS NOT NULL
)
-- Un écart > 5 min est une pause, pas une décision : l'inclure ferait dire à la
-- moyenne qu'une question prend un quart d'heure parce que le relecteur a pris
-- un café. La médiane est de toute façon la valeur à regarder.
SELECT CASE WHEN count(*) = 0 THEN 'pas encore mesurable'
       ELSE count(*) || ' intervalles · mediane '
            || round(percentile_cont(0.5) WITHIN GROUP (ORDER BY sec)::numeric,1)
            || ' s/question · moyenne ' || round(avg(sec)::numeric,1) || ' s' END
FROM ecarts WHERE sec IS NOT NULL AND sec < 300;"
