#!/usr/bin/env bash
# LE PROMPT PROMPT_TAG_NOTION_v4, EN UN SEUL EXEMPLAIRE.
#
# 🛑 UNE RÈGLE = UNE AUTORITÉ. Deux copies d'un prompt divergent toujours, et
#    on ne s'en aperçoit qu'à la mesure : le pilote et le batch complet
#    rendraient alors des chiffres incomparables sans que rien ne le signale.
#    Ce fichier est donc `source`-é par ./tagger-lot.sh (appel unitaire) ET par
#    ./batch-v4.sh (campagne Batch API), jamais recopié.
#
# 🛑 NE PAS MODIFIER PENDANT UNE CAMPAGNE. Le propriétaire a figé v4 le
#    2026-09-11 pour que la mesure reste cohérente d'un bout à l'autre du
#    corpus. Une retouche, même bénigne, oblige à changer PROMPT_VERSION —
#    sinon deux textes différents se cachent derrière une même étiquette.
#
# Usage :  source prompt-v4.sh ; construire_prompt CIV_SOCIETE sejourfr_db
# Définit alors : REFERENTIEL, ENUM_JSON, SYSTEM.
set -euo pipefail

PROMPT_VERSION="PROMPT_TAG_NOTION_v4"
# Sonnet 5 : la tâche demande de distinguer des notions qui se recouvrent, et
# c'est la CONFIANCE qui trie la file humaine — un modèle qui la calibre mal la
# rend inutile. Opus pense par défaut et facture la réflexion en sortie (x3,3)
# pour un gain nul ici. Mesuré au pilote v4 : 97,6 % de justesse au-dessus de
# 0,90, 44,4 % en dessous — la confiance prédit vraiment la justesse.
MODEL="claude-sonnet-5"

construire_prompt() {
  local THEME="$1" DB="${2:-sejourfr_db}"

  # Le référentiel est restreint aux notions DU THÈME : une suggestion pointant
  # vers un autre thème serait inapplicable dans l'écran d'administration, dont le
  # <select> ne propose que les notions du thème courant.
  #
  # 🛑 La DESCRIPTION est servie au modèle. C'est la même chaîne que lit l'écran
  # d'administration et que lit le relecteur : une seule autorité. Le pilote v1 a
  # montré qu'un libellé de 40 caractères ne tranche pas entre deux notions
  # voisines. Et v1 a montré pire : une frontière qui décrit la FORME de la
  # question (« quand un événement a eu lieu ») fait ranger « l'école gratuite »
  # dans les dates. Les descriptions de V058 décrivent toutes la SUBSTANCE.
  REFERENTIEL="$(psql -d "$DB" -U diallomatine -t -A -F $'\t' -c \
    "SELECT code, label, coalesce(description,'') FROM civic_notions
      WHERE is_active AND theme_code='${THEME}' ORDER BY display_order;" \
    | awk -F'\t' '{ if ($3 == "") printf "- %s : %s\n", $1, $2;
                    else printf "- %s : %s\n    %s\n", $1, $2, $3 }')"
  [[ -n "$REFERENTIEL" ]] || { echo "Référentiel vide pour ${THEME} dans ${DB}." >&2; return 1; }

  CODES_JSON="$(psql -d "$DB" -U diallomatine -t -A -c \
    "SELECT json_agg(code ORDER BY code)::text FROM civic_notions
      WHERE is_active AND theme_code='${THEME}';")"
  # « AUCUNE » est une valeur de PREMIÈRE CLASSE : sans échappatoire, le modèle est
  # forcé de choisir et la confiance perd tout sens. C'est aussi ce qui permet de
  # mesurer le « taux sans notion pertinente » demandé, et — depuis V058 — de
  # vérifier que le rangement par thème tient.
  ENUM_JSON="$(jq -c '. + ["AUCUNE"]' <<<"$CODES_JSON")"

  SYSTEM="Tu rattaches des questions d'un examen civique français à une notion d'un référentiel fermé.

  RÉFÉRENTIEL du thème traité (une notion par ligne ; la ligne indentée est sa FRONTIÈRE — elle fait autorité sur le libellé) :
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
  9. Réponds pour CHAQUE question du lot, dans l'ordre, en reprenant le « rang » donné. Le message te dit combien il y en a : ton tableau doit en compter exactement autant. Une réponse partielle, ou une « rationale » de remplissage, rend le lot inutilisable et il faudra le repayer.
  10. Les frontières renvoient parfois vers une notion d'un AUTRE thème (« → thème CIV_SOCIETE », « → pv_laicite »). Ces notions ne sont PAS dans ton référentiel et tu ne peux pas les proposer. Si la frontière envoie la question hors du thème, réponds « AUCUNE » et dis dans la rationale vers quel thème elle devrait aller. C'est un signal utile, pas un échec : il sert à vérifier le rangement du corpus.
  11. Une notion peut n'exister que pour une mention : « Devenir français » n'a aucune question de carte de séjour, « Les numéros d'urgence » aucune question de naturalisation. La mention indiquée (CSP, CR, NAT) t'aide à comprendre le niveau attendu, mais elle n'est JAMAIS un indice de rattachement. Ne te dis pas « c'est du NAT donc c'est cette notion-là »."
}
