#!/usr/bin/env bash
# Choisit les questions d'un lot de pilote et les écrit dans pilote_lot_N.json.
#
# Aucun appel réseau, aucun coût : cette étape ne fait que lire la base.
#
# 🛑 SEULES LES `CONNAISSANCE` SONT TIRÉES. Les mises en situation relèvent de
#    l'axe `sit_*` et ne comptent dans aucune métrique de notion (arbitrage du
#    propriétaire, 2026-09-11). Les faire relire par un humain serait du temps
#    perdu sur des questions dont le tag ne servirait à rien.
# 🛑 ON NE RETIRE PAS les questions déjà suggérées : une campagne v4 doit
#    pouvoir repasser sur des questions vues en v3, sinon on ne peut pas
#    comparer deux prompts sur le même échantillon.
#
# Usage : ./selectionner-pilote.sh <numéro de lot> <THÈME> <combien> [BASE]
set -euo pipefail
cd "$(dirname "$0")"

LOT="${1:?numéro de lot}"
THEME="${2:?code du thème}"
COMBIEN="${3:-25}"
DB="${4:-sejourfr_db}"

# 🛑 LE TIRAGE EST STRATIFIÉ PAR MENTION, en tourniquet CSP/CR/NAT.
# Un simple `ORDER BY created_at LIMIT 25` donnait, sur CIV_SOCIETE, un lot
# à 17 CR / 8 CSP / 0 NAT : le pilote n'aurait jamais montré une seule
# question de « Devenir français », qui est la notion la plus distinctive du
# thème et qui n'existe QUE en NAT. Un pilote qui ne voit pas une mention ne
# mesure rien sur elle.
#
# L'ordre reste DÉTERMINISTE (rang dans la mention, puis mention, puis id) :
# relancer la sélection rend exactement le même échantillon, sinon un lot
# repayé ne se compare plus au précédent.
psql -d "$DB" -U diallomatine -t -A -c "
WITH classees AS (
  SELECT q.id, q.statement, q.explanation, q.difficulty,
         row_number() OVER (PARTITION BY q.difficulty
                            ORDER BY q.created_at, q.id) AS rang_mention
  FROM questions q JOIN themes t ON t.id = q.theme_id
  WHERE q.module = 'CIVIQUE' AND q.is_active
    AND q.question_type = 'CONNAISSANCE'
    AND t.code = '${THEME}'
), tirees AS (
  SELECT *, row_number() OVER (ORDER BY rang_mention, difficulty, id) AS rang
  FROM classees
  ORDER BY rang_mention, difficulty, id
  LIMIT ${COMBIEN}
)
SELECT coalesce(json_agg(json_build_object(
         'rang', rang, 'id', id, 'statement', statement,
         'explanation', explanation, 'difficulty', difficulty,
         'choix', (SELECT coalesce(json_agg(json_build_object(
                            'label', c.label, 'correct', c.is_correct)
                          ORDER BY c.display_order, c.id), '[]'::json)
                     FROM choices c WHERE c.question_id = tirees.id)
       ) ORDER BY rang), '[]'::json)::text
FROM tirees;" > "pilote_lot_${LOT}.json"

echo "Lot ${LOT} (${THEME}) : $(jq length "pilote_lot_${LOT}.json") questions -> pilote_lot_${LOT}.json" >&2
