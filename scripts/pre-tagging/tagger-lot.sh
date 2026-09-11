#!/usr/bin/env bash
# PRÉ-TAGGING ASSISTÉ — PROMPT_TAG_NOTION_v1.
#
# Propose un rattachement question -> notion civique. Lots mono-thème.
#
# 🛑 LE MODÈLE PROPOSE, IL N'APPLIQUE RIEN. Ce script n'écrit QUE dans
#    question_notion_suggestions ; `questions.civic_notion_id` n'est jamais
#    touché, par aucun chemin. Poser un tag reste un geste humain, dans
#    l'écran d'administration.
# 🛑 IL DÉPENSE DE L'ARGENT. Un lot de 25 coûte ~0,026 $ sur Sonnet 5. Ne le
#    lancer que sur demande explicite du propriétaire (règle du dépôt).
# 🛑 Les réponses brutes sont archivées dans reponse_lot_N.json AVANT tout
#    traitement, et un lot déjà présent n'est JAMAIS rejoué : une erreur de
#    parsing ne doit pas coûter un second appel.
#
# Mesuré au pilote du 2026-09-11 (2 lots × 25, CIV_HISTOIRE_GEO) : 50/50
# propositions alignées, confiance étalée de 0,55 à 0,97, coût total 0,053 $.
#
# Les métriques de relecture se lisent avec ./mesurer.sh, APRÈS passage humain.
set -euo pipefail
cd "$(dirname "$0")"

# Sonnet 5 : la tâche demande de distinguer des notions qui se recouvrent, et
# c'est la CONFIANCE qui trie la file humaine — un modèle qui la calibre mal la
# rend inutile. Opus pense par défaut et facture la réflexion en sortie (x3,3)
# pour un gain nul ici.
THEME="${THEME:-CIV_HISTOIRE_GEO}"
MODEL="claude-sonnet-5"
PROMPT_VERSION="PROMPT_TAG_NOTION_v3"
API_KEY="$(grep "^ANTHROPIC_API_KEY=" /Users/diallomatine/Desktop/Projets/sejourfr_opus_nouveau/backend_sejourfr/.env | cut -d= -f2-)"

# Le référentiel est restreint aux notions DU THÈME : une suggestion pointant
# vers un autre thème serait inapplicable dans l'écran d'administration, dont le
# <select> ne propose que les notions du thème courant.
#
# 🛑 v2 — la DESCRIPTION de la notion est servie au modèle quand elle existe
# (colonne `civic_notions.description`, V055). C'est la même chaîne que lit
# l'écran d'administration et que lit le relecteur : une seule autorité. Le
# pilote v1 a montré qu'un libellé de 40 caractères ne tranche pas entre deux
# notions voisines — `hg_conquetes_droits` ⇄ `hg_dates_republique` hésitait à
# 0,73 de confiance moyenne.
REFERENTIEL="$(psql -d sejourfr_db -U diallomatine -t -A -F '\t' -c \
  "SELECT code, label, coalesce(description,'') FROM civic_notions
    WHERE is_active AND theme_code='$THEME' ORDER BY display_order;" \
  | awk -F'\t' '{ if ($3 == "") printf "- %s : %s\n", $1, $2;
                  else printf "- %s : %s\n    %s\n", $1, $2, $3 }')"

CODES_JSON="$(psql -d sejourfr_db -U diallomatine -t -A -c \
  "SELECT json_agg(code ORDER BY code)::text FROM civic_notions
    WHERE is_active AND theme_code='$THEME';")"
# « AUCUNE » est une valeur de PREMIÈRE CLASSE : sans échappatoire, le modèle est
# forcé de choisir et la confiance perd tout sens. C'est aussi ce qui permet de
# mesurer le « taux sans notion pertinente » demandé.
ENUM_JSON="$(jq -c '. + ["AUCUNE"]' <<<"$CODES_JSON")"

SYSTEM="Tu rattaches des questions d'un examen civique français à une notion d'un référentiel fermé.

RÉFÉRENTIEL du thème traité (une notion par ligne ; la ligne indentée, quand elle existe, est sa FRONTIÈRE — elle fait autorité sur le libellé) :
${REFERENTIEL}

RÈGLES
1. Tu PROPOSES un rattachement. Un relecteur humain tranche. N'écris jamais comme si ta proposition était appliquée.
2. Rattache la question à la notion que le candidat doit avoir apprise pour y répondre — pas au mot qui apparaît dans l'énoncé. Une question qui cite « 1789 » en passant mais porte sur la laïcité relève de la laïcité.
3. Utilise l'ÉNONCÉ, les PROPOSITIONS, la BONNE RÉPONSE et l'EXPLICATION. L'explication dit souvent ce que la question vérifie vraiment.
4. Si aucune notion ne convient vraiment, réponds « AUCUNE ». Ne force jamais un rattachement pour éviter de dire non — une question mal rangée coûte plus cher qu'une question non rangée.
5. La confiance doit être HONNÊTE et discriminante. 0.95+ : un seul rattachement est défendable. 0.70–0.89 : tu hésites entre deux notions, donne l'autre en alternative. <0.70 : tu n'es pas sûr. Si tu renvoies la même confiance partout, tu rends le tri humain inutile.
6. « rationale » : une phrase courte qui dit CE QUI dans la question t'a décidé. Elle est lue par le relecteur pour trancher en quelques secondes.
7. Quand deux notions se disputent une question, relis leurs FRONTIÈRES : elles sont écrites pour trancher exactement ces cas, et elles portent sur la SUBSTANCE de la question, jamais sur sa formulation. Si elles tranchent, la confiance doit être haute.
8. Mais NE FORCE PAS une frontière sur un contenu qui relève réellement des deux. Dans ce cas, choisis la notion la plus défendable, baisse la confiance et donne l'autre en alternative : une hésitation honnête se relit en dix secondes, un faux rattachement sûr de lui se propage.
9. Réponds pour CHAQUE question du lot, dans l'ordre, en reprenant le « rang » donné. Le message te dit combien il y en a : ton tableau doit en compter exactement autant. Une réponse partielle, ou une « rationale » de remplissage, rend le lot inutilisable et il faudra le repayer."

lancer_lot() {
  local lot="$1" debut="$2"
  local out="reponse_lot_${lot}.json"
  if [[ -f "$out" ]]; then
    echo "Lot ${lot} : déjà présent ($out), aucun appel — on ne repaie pas." >&2
    return 0
  fi

  local questions
  questions="$(jq -r --argjson d "$debut" '
    .[$d:$d+25] | to_entries | map(
      "### rang \(.value.rang) (\(.value.difficulty))\n" +
      "Question : \(.value.statement)\n" +
      "Propositions :\n" + (.value.choix | map("  - \(.label)\(if .correct then "   ← BONNE RÉPONSE" else "" end)") | join("\n")) +
      "\nExplication : \(.value.explanation // "—")"
    ) | join("\n\n")' pilote_questions.json)"
  local n
  n="$(jq -r --argjson d "$debut" '.[$d:$d+25] | length' pilote_questions.json)"
  # 🛑 Le compte est RÉPÉTÉ en tête et en pied du message. Mesuré au pilote v2 :
  # sans lui, le modèle a rendu 2 propositions sur 25 et écrit « placeholder »
  # dans une rationale — lot perdu, et il faut le repayer.
  questions="Voici ${n} questions à rattacher. Ton tableau « propositions » doit contenir EXACTEMENT ${n} entrées, une par rang.

${questions}

Rappel : ${n} questions, donc ${n} propositions, dans l'ordre des rangs."

  jq -n --arg model "$MODEL" --arg system "$SYSTEM" --arg q "$questions" --argjson enum "$ENUM_JSON" '{
    model: $model,
    max_tokens: 8000,
    system: $system,
    output_config: { effort: "low" },
    tool_choice: { type: "tool", name: "proposer_rattachements" },
    tools: [{
      name: "proposer_rattachements",
      description: "Propose un rattachement notion pour chacune des 25 questions.",
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
  }' > "requete_lot_${lot}.json"

  echo "Lot ${lot} : appel en cours…" >&2
  curl -sS https://api.anthropic.com/v1/messages \
    -H "x-api-key: ${API_KEY}" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d @"requete_lot_${lot}.json" > "$out"

  if jq -e '.type == "error"' "$out" >/dev/null 2>&1; then
    echo "Lot ${lot} : ERREUR API" >&2
    jq -r '.error.message' "$out" >&2
    return 1
  fi
  local rendus
  rendus="$(jq '[.content[] | select(.type=="tool_use") | .input.propositions[]] | length' "$out")"
  jq -r '"Lot '"${lot}"' : \(.usage.input_tokens) in / \(.usage.output_tokens) out · stop=\(.stop_reason)"' "$out" >&2
  if [[ "$rendus" -ne "$n" ]]; then
    # 🛑 On RENOMME au lieu de supprimer : la réponse est déjà payée, elle doit
    # rester consultable. Mais elle ne doit pas être prise pour un lot valide.
    mv "$out" "${out%.json}.incomplet.json"
    echo "Lot ${lot} : INCOMPLET — ${rendus} propositions sur ${n}. Réponse conservée dans ${out%.json}.incomplet.json" >&2
    return 1
  fi
  echo "Lot ${lot} : ${rendus}/${n} propositions." >&2
}

lancer_lot 1 0
lancer_lot 2 25
echo "Terminé. Réponses brutes : reponse_lot_1.json, reponse_lot_2.json" >&2
