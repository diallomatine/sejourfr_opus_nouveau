# GUIDE SL — Maîtrise des structures de la langue (A2 / B1 / B2)

> À utiliser avec `GUIDE_00_COMMUN_conventions.md`.
> ⚠️ **SL n'est PAS une épreuve des examens blancs IRN** : usage entraînement
> uniquement. Ne pas l'inclure dans les compositions d'examens blancs.

---

## Structure d'un item SL

Une phrase contenant un **espace à compléter** (le « trou »), 4 options, 1 seule
correcte. La phrase est présentée en deux fragments : avant le trou / après le trou.

Champs de contenu (à mapper sur la table `questions`/`choices` du projet) :
```
difficulty ('A2'|'B1'|'B2'), competence_code, theme_id,
statement        -- la phrase à trous, ex : "Pour s'inscrire, il faut … une pièce d'identité."
explanation      -- pourquoi la bonne option, pourquoi les autres sont fausses
choices (jsonb)  -- 4 options (les mots/formes candidates), 1 correcte
```
Convention d'affichage du trou : `…` (points de suspension) à l'emplacement à
compléter. Indiquer clairement le fragment avant et après.

---

## Calibration par niveau

### A2 — grammaire de base
Points testés : articles (défini/indéfini/partitif), accord simple, prépositions
courantes (à, de, en, chez), présent, passé composé (auxiliaire), futur proche,
pronoms sujets/COD-COI simples, négation, interrogation.
- Distracteurs : formes proches mais clairement fausses pour le contexte.
- Exemple (original) :
  - « Je vais … boulangerie acheter du pain. »
  - A. à la ✅ · B. au · C. en · D. de la
  - explanation : « boulangerie » est féminin → « à la ». « au » = à+le
    (masculin), « en » ne s'emploie pas devant un nom de commerce déterminé, « de
    la » exprime la provenance, pas la destination.

### B1 — grammaire intermédiaire
Points testés : imparfait vs passé composé, pronoms relatifs simples (qui, que, où,
dont), pronoms y/en, subjonctif présent après expressions courantes (il faut que,
pour que), comparatifs/superlatifs, connecteurs logiques courants, accord du
participe passé (cas simples), gérondif.
- Distracteurs : autres formes grammaticalement existantes mais inadaptées au
  contexte.
- Exemple (original) :
  - « C'est le livre … je t'ai parlé hier. »
  - A. que · B. qui · C. dont ✅ · D. où
  - explanation : « parler **de** quelque chose » → relatif « dont » (reprend le
    complément introduit par « de »). « que » = COD, « qui » = sujet, « où » =
    lieu/temps.

### B2 — grammaire fine et lexique nuancé
Points testés : pronoms relatifs composés (lequel, auquel, duquel, à laquelle…),
concordance des temps, subjonctif/indicatif selon la nuance, conditionnel passé,
voix passive, registres, et **distinctions lexicales fines** (verbes de
mouvement/transport : apporter/emporter/emmener/ramener ; connaître/savoir ;
nuances de sens proches).
- Distracteurs : **tous** grammaticalement plausibles ; un seul correct selon une
  règle précise ou une nuance de sens.
- Exemples (originaux) :
  - Relatif composé : « L'entreprise … nous avons signé le contrat est étrangère. »
    A. que · B. dont · C. avec laquelle ✅ · D. lequel
    (« signer un contrat **avec** une entreprise » → « avec laquelle »).
  - Lexique de transport : « N'oublie pas d'… ton parapluie en partant. »
    A. apporter · B. emporter ✅ · C. emmener · D. ramener
    (emporter = prendre avec soi un objet en quittant un lieu ; apporter = amener
    vers l'interlocuteur ; emmener/ramener concernent des personnes/retour).

---

## Règles de rédaction des items SL

- La phrase doit rendre **une seule** option correcte de façon non ambiguë : le
  contexte (sens + grammaire) doit trancher.
- Les 4 options appartiennent à la **même catégorie** (4 prépositions, 4 relatifs,
  4 formes verbales, 4 verbes de la même famille) pour que le choix soit grammatical
  et non par élimination thématique.
- Phrase **originale**, vie courante, niveau de vocabulaire adapté au niveau.
- En B2, exploiter les **pièges classiques** (cause/but, relatif simple vs composé,
  paronymes, registres) — mais toujours une réponse défendable par une règle claire,
  explicitée dans `explanation`.

---

## Compétences (`competence_code` indicatif)

- A2 : `sl_grammaire_base`
- B1 : `sl_grammaire_intermediaire`
- B2 : `sl_grammaire_avancee`
(ou un code plus fin par point grammatical si le projet le prévoit : `sl_relatifs`,
`sl_lexique_transport`, `sl_subjonctif`, etc.)

---

## Checklist spécifique SL

- [ ] Phrase à trous claire (fragment avant `…` / fragment après).
- [ ] 4 options de **même catégorie** grammaticale/lexicale, 1 seule correcte.
- [ ] Point grammatical conforme au niveau (base A2 / intermédiaire B1 / fin B2).
- [ ] `explanation` nomme la règle et démonte chaque distracteur.
- [ ] Phrase originale, contexte de vie courante.
- [ ] + checklist universelle du commun. (Rappel : hors examens blancs IRN.)
