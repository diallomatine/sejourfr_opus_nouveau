#!/usr/bin/env bash
# CAMPAGNE COMPLÈTE DE PRÉ-TAGGING — Batch API, PROMPT_TAG_NOTION_v4.
#
# 🛑 LE MODÈLE PROPOSE, IL N'APPLIQUE RIEN. Ce script n'écrit que dans
#    `question_notion_suggestions`. Le mot `civic_notion_id` n'apparaît nulle
#    part ici, et c'est vérifiable d'un grep. Aucun seuil de confiance ne pose
#    de tag : même à 0,99, un humain tranche dans l'écran d'administration.
# 🛑 IL DÉPENSE DE L'ARGENT — environ 0,90 $ pour 791 questions. Ne le lancer
#    que sur demande explicite du propriétaire (règle du dépôt).
# 🛑 LE PROMPT NE BOUGE PAS PENDANT LA CAMPAGNE. Il vit dans prompt-v4.sh,
#    partagé avec ./tagger-lot.sh. Le modifier en cours de route rendrait la
#    mesure incomparable d'un lot à l'autre, sans que rien ne le signale.
#
# La Batch API facture MOITIÉ PRIX et rend tout en une fois, sous 24 h. C'est
# le bon outil ici : personne n'attend ces suggestions en direct, et 34 appels
# synchrones coûteraient le double pour arriver au même endroit.
#
# Chaque étape écrit son résultat sur disque et refuse de le refaire :
# une campagne payée ne se repaie pas pour une erreur de parsing.
#
#   ./batch-v4.sh preparer    # gratuit — compose les lots depuis la base
#   ./batch-v4.sh lancer      # PAYANT — soumet le batch
#   ./batch-v4.sh suivre      # gratuit — où en est-il
#   ./batch-v4.sh recuperer   # gratuit — télécharge et persiste les suggestions
set -euo pipefail
cd "$(dirname "$0")"

DB="${DB:-sejourfr_db}"
# Surchargeable : une reprise cible un AUTRE dossier que la campagne
# initiale, sinon `lancer` refuse de repartir — à juste titre, il voit un
# batch déjà payé. Un dossier par campagne, c'est aussi ce qui garde les
# réponses brutes de chacune consultables séparément.
DOSSIER="${DOSSIER:-campagne-v4}"
API_KEY="$(grep "^ANTHROPIC_API_KEY=" \
  /Users/diallomatine/Desktop/Projets/sejourfr_opus_nouveau/backend_sejourfr/.env | cut -d= -f2-)"
source ./prompt-v4.sh

THEMES=(CIV_HISTOIRE_GEO CIV_INSTITUTIONS CIV_DROITS_DEVOIRS CIV_SOCIETE CIV_PRINCIPES)
PAR_LOT=25

# ----------------------------------------------------------------------------
# QUELLES QUESTIONS RESTENT À PROPOSER. Trois conditions, et chacune a coûté un
# essai raté :
#
#   1. Pas de TAG posé. Une question déjà taguée par un humain est finie ; lui
#      redemander une suggestion la ferait remonter dans la file de revue
#      comme si la décision n'avait pas été prise.
#   2. Aucune suggestion v4 ENCORE APPLICABLE, c'est-à-dire produite alors que
#      la question était déjà dans son thème actuel (`source_theme_code`, V061).
#      Une suggestion n'a de sens que dans le thème où elle a été faite : le
#      modèle ne reçoit que les notions de ce thème-là. C'est ce qui exclut les
#      50 du pilote, et ce qui rend éligibles les questions déplacées.
#
# 🛑 LA CONDITION 2 S'APPUIE SUR `source_theme_code`, PAS SUR LA NOTION
#    PROPOSÉE. La première version déduisait le thème depuis la notion — ce qui
#    marche pour une suggestion nommée, mais pas pour « aucune notion », qui ne
#    pointe vers rien. Résultat mesuré le 2026-09-11 : 34 questions éligibles
#    là où 20 l'étaient réellement, les 14 orphelines étant reprises pour rien.
#    V061 met le thème d'origine en base ; la règle tient maintenant en une
#    égalité, et elle vaut aussi pour les « aucune notion ».
#
#    Corollaire : une orpheline n'a plus besoin d'un verdict humain pour cesser
#    d'être reproposée. Confirmer un trou reste une affirmation éditoriale
#    utile, ce n'est plus une condition technique.
# ----------------------------------------------------------------------------
preparer() {
  mkdir -p "$DOSSIER"
  local total=0 lots=0
  for theme in "${THEMES[@]}"; do
    local ids
    ids="$(psql -d "$DB" -U diallomatine -t -A -c "
      SELECT q.id FROM questions q JOIN themes t ON t.id = q.theme_id
      WHERE q.module = 'CIVIQUE' AND q.is_active
        AND q.question_type = 'CONNAISSANCE'
        AND t.code = '${theme}'
        AND q.civic_notion_id IS NULL
        AND NOT EXISTS (
          SELECT 1 FROM question_notion_suggestions s
           WHERE s.question_id = q.id
             AND s.prompt_version = '${PROMPT_VERSION}'
             AND s.source_theme_code = t.code)
      ORDER BY q.created_at, q.id;")"
    [[ -z "$ids" ]] && continue

    local n=0 lot=0
    local paquet=()
    while read -r id; do
      paquet+=("$id"); n=$((n+1))
      if [[ ${#paquet[@]} -eq $PAR_LOT ]]; then
        lot=$((lot+1)); ecrire_lot "$theme" "$lot" "${paquet[@]}"; paquet=()
      fi
    done <<<"$ids"
    if [[ ${#paquet[@]} -gt 0 ]]; then
      lot=$((lot+1)); ecrire_lot "$theme" "$lot" "${paquet[@]}"
    fi
    echo "  ${theme} : ${n} questions, ${lot} lots" >&2
    total=$((total+n)); lots=$((lots+lot))
  done
  echo "Total : ${total} questions, ${lots} lots -> ${DOSSIER}/" >&2
}

ecrire_lot() {
  local theme="$1" lot="$2"; shift 2
  local liste
  liste="$(printf "'%s'," "$@")"; liste="${liste%,}"
  psql -d "$DB" -U diallomatine -t -A -c "
    WITH tirees AS (
      SELECT q.id, q.statement, q.explanation, q.difficulty,
             row_number() OVER (ORDER BY q.created_at, q.id) AS rang
      FROM questions q WHERE q.id IN (${liste}))
    SELECT coalesce(json_agg(json_build_object(
             'rang', rang, 'id', id, 'statement', statement,
             'explanation', explanation, 'difficulty', difficulty,
             'choix', (SELECT coalesce(json_agg(json_build_object(
                                'label', c.label, 'correct', c.is_correct)
                              ORDER BY c.display_order, c.id), '[]'::json)
                         FROM choices c WHERE c.question_id = tirees.id)
           ) ORDER BY rang), '[]'::json)::text
    FROM tirees;" > "${DOSSIER}/${theme}__${lot}.questions.json"
}

# ----------------------------------------------------------------------------
lancer() {
  local requete="${DOSSIER}/batch.request.json" idfile="${DOSSIER}/batch.id"
  if [[ -f "$idfile" ]]; then
    echo "Campagne déjà lancée (batch $(cat "$idfile")) — on ne repaie pas." >&2
    return 0
  fi
  local theme_courant="" entrees=()
  for f in "${DOSSIER}"/*.questions.json; do
    local base theme lot
    base="$(basename "$f" .questions.json)"
    theme="${base%%__*}"; lot="${base##*__}"
    # Le prompt ne se reconstruit qu'au CHANGEMENT de thème : il coûte deux
    # requêtes SQL, et les lots d'un même thème le partagent à l'identique.
    if [[ "$theme" != "$theme_courant" ]]; then
      construire_prompt "$theme" "$DB"; theme_courant="$theme"
    fi
    entrees+=("$(construire_entree "$base" "$f")")
  done
  printf '%s\n' "${entrees[@]}" | jq -s '{requests: .}' > "$requete"
  echo "Batch : $(jq '.requests | length' "$requete") requêtes, $(wc -c <"$requete") octets." >&2

  curl -sS https://api.anthropic.com/v1/messages/batches \
    -H "x-api-key: ${API_KEY}" -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" -d @"$requete" > "${DOSSIER}/batch.created.json"

  if ! jq -e '.id' "${DOSSIER}/batch.created.json" >/dev/null 2>&1; then
    echo "ERREUR API :" >&2; jq -r '.error.message // .' "${DOSSIER}/batch.created.json" >&2
    return 1
  fi
  jq -r '.id' "${DOSSIER}/batch.created.json" > "$idfile"
  echo "Batch lancé : $(cat "$idfile")" >&2
}

construire_entree() {
  local base="$1" fichier="$2" n questions
  n="$(jq length "$fichier")"
  questions="$(jq -r '
    to_entries | map(
      "### rang \(.value.rang) (\(.value.difficulty))\n" +
      "Question : \(.value.statement)\n" +
      "Propositions :\n" + (.value.choix | map("  - \(.label)\(if .correct then "   ← BONNE RÉPONSE" else "" end)") | join("\n")) +
      "\nExplication : \(.value.explanation // "—")"
    ) | join("\n\n")' "$fichier")"
  # Le compte est RÉPÉTÉ en tête et en pied : sans lui, le pilote v2 avait rendu
  # 2 propositions sur 25 et écrit « placeholder » dans une rationale.
  questions="Voici ${n} questions à rattacher. Ton tableau « propositions » doit contenir EXACTEMENT ${n} entrées, une par rang.

${questions}

Rappel : ${n} questions, donc ${n} propositions, dans l'ordre des rangs."

  jq -n --arg id "$base" --arg model "$MODEL" --arg system "$SYSTEM" \
        --arg q "$questions" --argjson enum "$ENUM_JSON" --argjson n "$n" '{
    custom_id: $id,
    params: {
      model: $model,
      max_tokens: 8000,
      system: $system,
      output_config: { effort: "low" },
      tool_choice: { type: "tool", name: "proposer_rattachements" },
      tools: [{
        name: "proposer_rattachements",
        description: "Propose un rattachement notion pour chacune des \($n) questions.",
        strict: true,
        input_schema: {
          type: "object", additionalProperties: false, required: ["propositions"],
          properties: { propositions: { type: "array", items: {
            type: "object", additionalProperties: false,
            required: ["rang", "notion", "confiance", "rationale"],
            properties: {
              rang: { type: "integer" },
              notion: { type: "string", enum: $enum },
              confiance: { type: "number" },
              rationale: { type: "string" },
              alternative: { type: "string", enum: $enum },
              alternative_confiance: { type: "number" }
            } } } }
        }
      }],
      messages: [{ role: "user", content: $q }]
    }
  }'
}

# ----------------------------------------------------------------------------
suivre() {
  local id; id="$(cat "${DOSSIER}/batch.id")"
  curl -sS "https://api.anthropic.com/v1/messages/batches/${id}" \
    -H "x-api-key: ${API_KEY}" -H "anthropic-version: 2023-06-01" \
  | jq -r '"statut=\(.processing_status) · \(.request_counts | "traitees=\(.succeeded) erreurs=\(.errored) en_cours=\(.processing) annulees=\(.canceled) expirees=\(.expired)")"'
}

recuperer() {
  local id resultats="${DOSSIER}/resultats.jsonl"
  id="$(cat "${DOSSIER}/batch.id")"
  if [[ ! -f "$resultats" ]]; then
    local url
    url="$(curl -sS "https://api.anthropic.com/v1/messages/batches/${id}" \
      -H "x-api-key: ${API_KEY}" -H "anthropic-version: 2023-06-01" | jq -r '.results_url // empty')"
    [[ -n "$url" ]] || { echo "Batch pas encore terminé — ./batch-v4.sh suivre" >&2; return 1; }
    curl -sS "$url" -H "x-api-key: ${API_KEY}" -H "anthropic-version: 2023-06-01" > "$resultats"
  fi
  echo "$(wc -l <"$resultats") résultats." >&2

  # Un batch_id UNIQUE pour toute la campagne : c'est ce qui permettra à
  # ./mesurer.sh de la mesurer sans la mélanger au pilote.
  local batch; batch="$(uuidgen | tr 'A-Z' 'a-z')"
  echo "$batch" > "${DOSSIER}/batch_id_campagne.txt"

  local ok=0 ko=0
  while read -r ligne; do
    local base theme statut n rendus
    base="$(jq -r '.custom_id' <<<"$ligne")"
    theme="${base%%__*}"
    statut="$(jq -r '.result.type' <<<"$ligne")"
    if [[ "$statut" != "succeeded" ]]; then
      echo "  ${base} : ${statut} — ignoré" >&2; ko=$((ko+1)); continue
    fi
    jq '.result.message' <<<"$ligne" > "${DOSSIER}/${base}.reponse.json"
    n="$(jq length "${DOSSIER}/${base}.questions.json")"
    rendus="$(jq '[.content[] | select(.type=="tool_use") | .input.propositions[]] | length' \
             "${DOSSIER}/${base}.reponse.json")"
    if [[ "$rendus" -ne "$n" ]]; then
      # Réponse INCOMPLÈTE : déjà payée, donc conservée, mais jamais persistée.
      mv "${DOSSIER}/${base}.reponse.json" "${DOSSIER}/${base}.incomplet.json"
      echo "  ${base} : INCOMPLET ${rendus}/${n}" >&2; ko=$((ko+1)); continue
    fi
    BATCH_ID="$batch" ./persister.sh \
      "${DOSSIER}/${base}.questions.json" "${DOSSIER}/${base}.reponse.json" "$theme" "$DB" \
      >/dev/null
    ok=$((ok+1))
  done < "$resultats"
  echo "Lots persistés : ${ok} · en échec : ${ko}" >&2
  echo "batch_id de la campagne : ${batch}" >&2
  echo "Mesure : ./mesurer.sh ${PROMPT_VERSION} ${batch}" >&2
}

case "${1:-}" in
  preparer)  preparer ;;
  lancer)    lancer ;;
  suivre)    suivre ;;
  recuperer) recuperer ;;
  *) echo "Usage : $0 {preparer|lancer|suivre|recuperer}" >&2; exit 1 ;;
esac
