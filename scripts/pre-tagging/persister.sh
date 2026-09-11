#!/usr/bin/env bash
# Range les propositions d'un lot dans `question_notion_suggestions`.
#
# 🛑 CE SCRIPT NE POSE AUCUN TAG. Il n'écrit que dans la table des SUGGESTIONS.
#    `questions.civic_notion_id` n'apparaît nulle part dans ce fichier, et
#    c'est délibéré : poser un tag est un geste humain, dans l'écran
#    d'administration. Aucun seuil de confiance n'y change rien.
# 🛑 LA CLÉ DE CONFLIT INCLUT LE `batch_id` (V290). Sans lui, une campagne
#    écrasait la précédente : deux propositions identiques sur la même question
#    — et « aucune notion » en est une — entraient en collision. Mesuré le
#    2026-09-11 : trois lignes d'une campagne close ont disparu en silence,
#    dont une écrasée par une simple ALTERNATIVE de la campagne suivante.
# 🛑 IL NE RÉÉCRIT JAMAIS UNE SUGGESTION DÉJÀ RELUE. Le `ON CONFLICT` est
#    conditionné à `review_verdict IS NULL` : un verdict humain est la seule
#    chose de cette table qui ait coûté du temps de cerveau. Une campagne qui
#    repasse sur une question déjà tranchée doit la laisser tranquille.
# 🛑 UNE ALTERNATIVE N'A PAS DE RATIONALE, ET ON N'EN INVENTE PAS. Le schéma
#    de l'outil ne demande au modèle qu'une justification, celle de sa
#    proposition. Recopier ce texte sur la ligne de l'alternative — ce que
#    faisait la première version — donnait à lire une justification de
#    l'alternative qui n'avait jamais été écrite : le relecteur y voyait le
#    modèle défendre deux notions avec les mêmes mots. On stocke NULL, et
#    l'écran dit qu'il n'y a pas de justification séparée.
# 🛑 `notion = AUCUNE` devient une ligne RÉELLE avec `notion_id = NULL`, jamais
#    une notion technique nommée « AUCUNE ». C'est ce qui rend mesurable le
#    « aucune notion pertinente confirmée par l'humain » : un trou du
#    référentiel est une information, pas une absence de données.
#
# Usage : ./persister.sh <questions.json> <reponse.json> <THÈME> [BASE]
#
# Les CHEMINS sont explicites, et pas un numéro de lot : le pilote unitaire et
# la campagne Batch API ne nomment pas leurs fichiers pareil, et une seconde
# copie de cette logique divergerait de la première.
set -euo pipefail
cd "$(dirname "$0")"

IN="${1:?fichier des questions du lot}"
REP="${2:?fichier de reponse du modele}"
THEME="${3:?code du thème}"
DB="${4:-sejourfr_db}"

# La version et le modèle viennent du prompt partagé : les réécrire ici, c'est
# se garantir qu'un jour la campagne portera une étiquette qui ment.
source "$(dirname "$0")/prompt-v4.sh"

[[ -f "$IN" && -f "$REP" ]] || { echo "Manque $IN ou $REP." >&2; exit 1; }
LOT="$(basename "$REP" .json)"

mkdir -p tsv
BATCH="${BATCH_ID:-$(uuidgen | tr 'A-Z' 'a-z')}"

# rang -> id de question, puis aplatissement proposition + alternative.
# L'alternative est une LIGNE À PART ET PAS UN CHAMP : c'est ce qui permet à la
# file de revue de trier sur le MAX des confiances d'une question, et à
# l'écran de montrer les deux hypothèses côte à côte.
jq -r --slurpfile q "$IN" '
  ($q[0] | map({key: (.rang|tostring), value: .id}) | from_entries) as $ids
  | [ .content[] | select(.type=="tool_use") | .input.propositions[] ]
  | map(
      [ { qid: $ids[(.rang|tostring)], notion: .notion,
          conf: .confiance, rat: .rationale } ]
      + (if .alternative then
          [ { qid: $ids[(.rang|tostring)], notion: .alternative,
              conf: (.alternative_confiance // 0.5),
              rat: "" } ]
         else [] end)
    )
  | flatten
  | .[] | [.qid, .notion, (.conf|tostring), (.rat|gsub("[\t\n]"; " "))] | @tsv
' "$REP" > "tsv/${LOT}.tsv"

LIGNES="$(wc -l < "tsv/${LOT}.tsv" | tr -d ' ')"
echo "Lot ${LOT} : ${LIGNES} suggestions à ranger (propositions + alternatives)." >&2

psql -d "$DB" -U diallomatine -v ON_ERROR_STOP=1 <<SQL
BEGIN;

CREATE TEMP TABLE entrantes (
    question_id uuid, code text, confidence numeric(4,3), rationale text
) ON COMMIT DROP;

\copy entrantes FROM 'tsv/${LOT}.tsv' WITH (FORMAT text, DELIMITER E'\t')

-- Un code inconnu est une ERREUR, pas une ligne à ignorer : il voudrait dire
-- que le référentiel servi au modèle n'est plus celui de la base.
DO \$\$
DECLARE inconnus text;
BEGIN
    SELECT string_agg(DISTINCT e.code, ', ') INTO inconnus
    FROM entrantes e
    WHERE e.code <> 'AUCUNE'
      AND NOT EXISTS (SELECT 1 FROM civic_notions n
                       WHERE n.code = e.code AND n.is_active
                         AND n.theme_code = '${THEME}');
    IF inconnus IS NOT NULL THEN
        RAISE EXCEPTION 'Codes hors referentiel actif de ${THEME} : %', inconnus;
    END IF;
END \$\$;

INSERT INTO question_notion_suggestions
    (question_id, notion_id, confidence, model, prompt_version, rationale, batch_id)
SELECT e.question_id,
       n.id,
       e.confidence,
       '${MODEL}',
       '${PROMPT_VERSION}',
       nullif(e.rationale, ''),
       '${BATCH}'::uuid
FROM entrantes e
         LEFT JOIN civic_notions n ON n.code = e.code AND n.is_active
ON CONFLICT (question_id, batch_id, notion_id) DO UPDATE
    SET confidence     = EXCLUDED.confidence,
        model          = EXCLUDED.model,
        prompt_version = EXCLUDED.prompt_version,
        rationale      = EXCLUDED.rationale,
        batch_id       = EXCLUDED.batch_id,
        created_at     = now()
WHERE question_notion_suggestions.review_verdict IS NULL;

COMMIT;
SQL

echo "Lot ${LOT} : batch_id = ${BATCH}" >&2
[[ -n "${BATCH_ID:-}" ]] || echo "${BATCH}" >> batches_v4.txt
