#!/usr/bin/env bash
# PRÉ-TAGGING ASSISTÉ — PROMPT_TAG_NOTION_v4.
#
# Propose un rattachement question -> notion civique. Un lot = un thème.
#
# 🛑 LE MODÈLE PROPOSE, IL N'APPLIQUE RIEN. Ce script n'écrit même pas en base :
#    il produit reponse_lot_N.json. La persistance est un second geste
#    (./persister.sh), et poser un tag en est un troisième, humain, dans
#    l'écran d'administration. `questions.civic_notion_id` n'est touché par
#    aucun de ces chemins.
# 🛑 IL DÉPENSE DE L'ARGENT. Un lot de 25 coûte ~0,03 $ sur Sonnet 5. Ne le
#    lancer que sur demande explicite du propriétaire (règle du dépôt).
# 🛑 Les réponses brutes sont archivées AVANT tout traitement, et un lot déjà
#    présent n'est JAMAIS rejoué : une erreur de parsing ne doit pas coûter un
#    second appel.
#
# v4 (2026-09-11) — le référentiel est passé de 41 notions à 46, validé par le
# propriétaire après l'audit du corpus. Les frontières ont toutes été
# réécrites. v3 est caduc : ses suggestions pointent vers des notions dont
# quatorze sont désormais fusionnées.
#
# Ce que v4 change dans le PROMPT lui-même :
#   * règle 10 — les frontières citent des notions d'AUTRES thèmes. Le modèle
#     ne peut pas les proposer : il doit répondre « AUCUNE » et le dire. C'est
#     le signal qui vérifie le rangement par thème de V059.
#   * règle 11 — une notion peut légitimement n'exister que dans une mention
#     (« Devenir français » n'a aucune question CSP). La mention du candidat
#     n'est donc PAS un indice de rattachement.
#
# LE PIPELINE COMPLET, DANS L'ORDRE. Aucune de ces étapes ne touche
# `questions.civic_notion_id`.
#   ./selectionner-pilote.sh 1 CIV_DROITS_DEVOIRS 25   # gratuit, lit la base
#   ./selectionner-pilote.sh 2 CIV_SOCIETE        25
#   ./tagger-lot.sh          1 CIV_DROITS_DEVOIRS      # ~0,03 $ — PAYANT
#   ./tagger-lot.sh          2 CIV_SOCIETE             # ~0,03 $ — PAYANT
#   ./persister.sh pilote_lot_1.json reponse_lot_1.json CIV_DROITS_DEVOIRS
#   ./persister.sh pilote_lot_2.json reponse_lot_2.json CIV_SOCIETE
#   # relecture humaine dans /notions-civiques, filtre « suggérées »
#   ./mesurer.sh PROMPT_TAG_NOTION_v4 $(cat batches_v4.txt)
#
# Usage : ./tagger-lot.sh <numéro de lot> <THÈME> [BASE]
# `DRY_RUN=1` construit la requête et s'arrête AVANT l'appel : c'est la seule
# façon de relire un prompt sans le payer.
set -euo pipefail
cd "$(dirname "$0")"

LOT="${1:?numéro de lot}"
THEME="${2:?code du thème}"
DB="${3:-sejourfr_db}"

API_KEY="$(grep "^ANTHROPIC_API_KEY=" \
  /Users/diallomatine/Desktop/Projets/sejourfr_opus_nouveau/backend_sejourfr/.env | cut -d= -f2-)"

IN="pilote_lot_${LOT}.json"
OUT="reponse_lot_${LOT}.json"
[[ -f "$IN" ]] || { echo "Manque $IN — lance d'abord ./selectionner-pilote.sh" >&2; exit 1; }
if [[ -f "$OUT" ]]; then
  echo "Lot ${LOT} : déjà présent ($OUT), aucun appel — on ne repaie pas." >&2
  exit 0
fi

# Le prompt, le modèle et la version vivent dans prompt-v4.sh, en un seul
# exemplaire partagé avec ./batch-v4.sh. Deux copies d'un prompt divergent
# toujours, et la mesure ne le dit pas.
source "$(dirname "$0")/prompt-v4.sh"
construire_prompt "$THEME" "$DB"

QUESTIONS="$(jq -r '
  to_entries | map(
    "### rang \(.value.rang) (\(.value.difficulty))\n" +
    "Question : \(.value.statement)\n" +
    "Propositions :\n" + (.value.choix | map("  - \(.label)\(if .correct then "   ← BONNE RÉPONSE" else "" end)") | join("\n")) +
    "\nExplication : \(.value.explanation // "—")"
  ) | join("\n\n")' "$IN")"
N="$(jq length "$IN")"

# 🛑 Le compte est RÉPÉTÉ en tête et en pied du message. Mesuré au pilote v2 :
# sans lui, le modèle a rendu 2 propositions sur 25 et écrit « placeholder »
# dans une rationale — lot perdu, et il faut le repayer.
QUESTIONS="Voici ${N} questions à rattacher. Ton tableau « propositions » doit contenir EXACTEMENT ${N} entrées, une par rang.

${QUESTIONS}

Rappel : ${N} questions, donc ${N} propositions, dans l'ordre des rangs."

jq -n --arg model "$MODEL" --arg system "$SYSTEM" --arg q "$QUESTIONS" \
      --argjson enum "$ENUM_JSON" --argjson n "$N" '{
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
      type: "object",
      additionalProperties: false,
      required: ["propositions"],
      properties: {
        propositions: {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            required: ["rang", "notion", "confiance", "rationale"],
            properties: {
              rang: { type: "integer" },
              notion: { type: "string", enum: $enum },
              confiance: { type: "number" },
              rationale: { type: "string" },
              alternative: { type: "string", enum: $enum },
              alternative_confiance: { type: "number" }
            }
          }
        }
      }
    }
  }],
  messages: [{ role: "user", content: $q }]
}' > "requete_lot_${LOT}.json"

if [[ "${DRY_RUN:-0}" == "1" ]]; then
  echo "Lot ${LOT} (${THEME}) : requete_lot_${LOT}.json construite, AUCUN appel (DRY_RUN)." >&2
  exit 0
fi

echo "Lot ${LOT} (${THEME}, ${PROMPT_VERSION}) : appel en cours…" >&2
curl -sS https://api.anthropic.com/v1/messages \
  -H "x-api-key: ${API_KEY}" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d @"requete_lot_${LOT}.json" > "$OUT"

if jq -e '.type == "error"' "$OUT" >/dev/null 2>&1; then
  echo "Lot ${LOT} : ERREUR API" >&2
  jq -r '.error.message' "$OUT" >&2
  mv "$OUT" "${OUT%.json}.erreur.json"
  exit 1
fi

RENDUS="$(jq '[.content[] | select(.type=="tool_use") | .input.propositions[]] | length' "$OUT")"
jq -r '"Lot '"${LOT}"' : \(.usage.input_tokens) in / \(.usage.output_tokens) out · stop=\(.stop_reason)"' "$OUT" >&2
if [[ "$RENDUS" -ne "$N" ]]; then
  # 🛑 On RENOMME au lieu de supprimer : la réponse est déjà payée, elle doit
  # rester consultable. Mais elle ne doit pas être prise pour un lot valide.
  mv "$OUT" "${OUT%.json}.incomplet.json"
  echo "Lot ${LOT} : INCOMPLET — ${RENDUS} propositions sur ${N}. Conservée dans ${OUT%.json}.incomplet.json" >&2
  exit 1
fi
echo "Lot ${LOT} : ${RENDUS}/${N} propositions. Persiste avec ./persister.sh ${IN} ${OUT} ${THEME}" >&2
