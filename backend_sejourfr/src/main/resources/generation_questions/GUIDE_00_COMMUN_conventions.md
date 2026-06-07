# 00 — Conventions communes de génération (TCF IRN — SejourFR)

> À fournir **systématiquement** avec le guide du module concerné. Ce fichier
> rassemble tout ce qui est partagé : palette, SVG, SSML, JSON, règles
> d'originalité, format de sortie, principes de progression A2 → B2.

---

## 0. Cadre TCF IRN (rappels indispensables)

- Le TCF IRN plafonne au niveau **B2**. Niveaux à produire : **A2, B1, B2**.
- L'examen **n'étiquette jamais** un sujet par niveau : le `niveau_cible` est
  indicatif, interne, jamais montré au candidat ni utilisé comme filtre.
- 1 mot = **tout ensemble de signes entre deux espaces** (« C'est-à-dire » = 1 mot,
  « Un bon sujet » = 3 mots). Définition officielle, à respecter pour tout comptage.
- Une production peut obtenir « A1 non atteint » si : illisible, hors-sujet, nombre
  de mots non respecté, ou tâche non réalisée.
- **Structure de la langue (SL)** n'est PAS une épreuve des examens blancs IRN :
  elle sert uniquement à l'entraînement. La générer reste utile, mais ne pas
  l'inclure dans les compositions d'examens blancs IRN.

---

## 1. Principe de progression A2 → B1 → B2

Règle d'or : **plus le niveau monte, plus les textes sont longs, plus le sens est
implicite, plus les distracteurs sont plausibles.**

| Critère | A2 | B1 | B2 |
|---|---|---|---|
| Longueur des documents | très court | moyen | long |
| Lexique | quotidien, fréquent | courant + quelques termes abstraits | riche, nuancé, parfois spécialisé |
| Grammaire | présent, passé composé, futur proche | + imparfait, subjonctif présent courant, relatifs simples | + conditionnel, concordance, relatifs composés, registres |
| Type de compréhension | **explicite** (info littérale) | explicite + **inférence simple** (relier 2 infos) | **implicite** (intention, ton, sous-entendu) |
| Distracteurs | clairement différents | thématiquement proches | tous plausibles, piège fin |
| Sujets | vie quotidienne concrète | vie sociale, expériences | sujets de société, abstraits, argumentatifs |

---

## 2. Originalité (anti-plagiat) — OBLIGATOIRE

- **Ne jamais recopier** un texte existant (TCF officiel, presse, web, manuels).
  Les exemples officiels servent uniquement de **modèle de format**, jamais de
  contenu à reproduire.
- Inventer des situations, noms, lieux, chiffres **originaux**. Varier les prénoms
  (refléter la diversité du public : Amadou, Lucia, Wei, Rachid, Olena, Diego,
  Priya, Fatou…), les villes, les métiers.
- Pas de marque réelle sauf usage générique neutre. Pas de personnalité réelle.
- Chaque item doit être **autonome** et compréhensible sans contexte externe.

---

## 3. Palette graphique (charte SejourFR) — pour TOUS les SVG

| Usage | Couleur | Hex |
|---|---|---|
| Bleu France (principal) | navy | `#1E3A8C` |
| Bleu foncé / encre | encre | `#0F1839` |
| Bleu profond (variante) | | `#15296B` |
| Rouge (CTA/urgence UNIQUEMENT) | rouge | `#E1372F` |
| Vert succès | vert | `#168F5B` |
| Vert foncé | | `#0F6E45` |
| Ambre / accent | ambre | `#E8A317` |
| Fond clair | | `#E8ECF8` |
| Fond rosé clair | | `#FDECEB` |
| Blanc | | `#FFFFFF` |

⚠️ Le **rouge `#E1372F` est réservé** aux éléments critiques (un feu rouge, une
croix médicale, un signal d'urgence). Jamais en fond décoratif gratuit.

---

## 4. Règles SVG (qualité « impeccable »)

Objectif : des illustrations **plates, lisibles, immédiatement reconnaissables**,
style pictogramme épuré (pas de dégradés complexes, pas de réalisme photographique).

**Contraintes techniques :**
- `viewBox="0 0 320 200"` (ratio 16:10, format paysage standard).
- Formes géométriques simples : `rect`, `circle`, `ellipse`, `polygon`, `path`,
  `line`. Couleurs **pleines** issues de la palette.
- Un fond (`<rect width="320" height="200" fill="..."/>`), puis un sol/horizon si
  pertinent, puis les éléments de la scène, du fond vers le premier plan.
- **Reconnaissable en < 2 secondes** : la scène doit être identifiable sans légende.
- Pas de texte dans le SVG, **sauf** si l'information textuelle fait partie de la
  scène (ex. « BUS » sur un panneau, un chiffre sur un feu). Police `Arial`.
- Personnages stylisés : tête = `circle`, corps = `rect` arrondi. Couleurs de
  vêtements dans la palette.
- Équilibre visuel : occuper l'espace, centrer le sujet principal.

**Template de base :**
```svg
<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg">
  <rect width="320" height="200" fill="#E8ECF8"/>          <!-- fond -->
  <rect x="0" y="160" width="320" height="40" fill="#15296B"/> <!-- sol -->
  <!-- éléments de la scène, du fond vers le premier plan -->
</svg>
```

**À FAIRE / À ÉVITER :**
- ✅ Une scène = un message clair (ex. « personne à un arrêt de bus »).
- ✅ Contrastes nets, palette charte.
- ❌ Surcharge d'éléments, détails illisibles à petite taille.
- ❌ Dégradés, ombres complexes, `filter`, images bitmap encodées.
- ❌ Rouge décoratif.

Chaque SVG s'accompagne **toujours** d'un `image_alt_text` décrivant la scène
(accessibilité + repli).

---

## 5. Règles SSML (Azure Neural TTS)

Format `<speak version="1.0" xml:lang="fr-FR">…</speak>`. Voix :

| Rôle | Voix Azure |
|---|---|
| Narratrice / consigne / propositions | `fr-FR-DeniseNeural` (rate `0.95`) |
| Locuteur masculin (dialogue) | `fr-FR-HenriNeural` (rate `1.0`) |
| Locutrice féminine (dialogue) | `fr-FR-VivienneNeural` (rate `1.0`) |

**Règles :**
- Échapper les caractères XML ; en SQL, apostrophes doublées `''`.
- La **narratrice (Denise)** dit l'intro et lit les propositions A/B/C/D.
- Les voix de dialogue (Henri/Vivienne) ne servent qu'**à l'intérieur** d'un
  document parlé.
- Pauses : `<break time="1500ms"/>` après l'intro, `<break time="1000ms"/>` après
  le document, `<break time="700ms"/>` entre propositions, `<break time="300ms"/>`
  après la lettre (« A. <break time="300ms"/> texte »).
- Équilibre obligatoire : autant de `</voice>` que de `<voice>`, autant de
  `</prosody>` que de `<prosody>`.

**Format de lecture des 4 propositions (commun CO/CO_IMAGE) :**
```
A.<break time="300ms"/>{texte A}<break time="700ms"/>
B.<break time="300ms"/>{texte B}<break time="700ms"/>
C.<break time="300ms"/>{texte C}<break time="700ms"/>
D.<break time="300ms"/>{texte D}
```

---

## 6. Format des réponses (JSONB `choices`)

Toujours **4 propositions, exactement 1 correcte** :
```json
[{"label": "A", "is_correct": false, "display_order": 1},
 {"label": "B", "is_correct": true,  "display_order": 2},
 {"label": "C", "is_correct": false, "display_order": 3},
 {"label": "D", "is_correct": false, "display_order": 4}]
```

**Distribution des bonnes réponses :** sur un lot de 10, viser un équilibre proche
de A=2-3, B=2-3, C=2-3, D=2-3. Ne jamais laisser une lettre dominer (ex. 6×A).

---

## 7. Champ `explanation` (correction pédagogique)

- Expliquer **pourquoi la bonne réponse est correcte** ET **pourquoi chaque
  distracteur est faux** (à quelle autre question il répondrait).
- Ton pédagogique, clair, en français.
- Mettre en gras (`**…**`) le point clé (la nature de la question, le mot piège).
- Pour les niveaux B1/B2, nommer le mécanisme linguistique (cause vs but, moment
  vs fréquence, gérondif de moyen, inférence d'intention, etc.).

---

## 8. UUID & déterminisme

- UUID **déterministes** et lisibles, par plages cohérentes avec le module et le
  lot (ex. `66666666-00XX-Y000-0000-0000000000NN`). Rejouables en dev et recette.
- 10 items par lot par défaut, sauf indication contraire.

---

## 9. Format de sortie attendu de l'IA

- **Un fichier `.sql`** prêt à jouer (migration Flyway), en-tête commenté
  (module, niveau, lot, sémantique).
- Apostrophes SQL doublées (`''`), JSONB valide, SVG/SSML équilibrés.
- **Aucun README, aucune image de rendu**, juste le SQL + un court commentaire
  d'en-tête. (Préférence projet : sortie directe, prête à l'emploi.)
- Terminer par un bloc commentaire « checklist » rappelant les contrôles passés
  (nombre d'items, distribution des réponses, SVG/SSML équilibrés).

---

## 10. Checklist qualité universelle (avant livraison)

- [ ] N items demandés, UUID uniques et déterministes.
- [ ] 4 propositions / 1 correcte par item ; distribution des bonnes réponses équilibrée.
- [ ] `explanation` justifie la bonne réponse ET les 3 distracteurs.
- [ ] Contenu **original** (aucune copie de texte existant).
- [ ] Longueur/complexité conformes au niveau visé (cf. §1).
- [ ] SVG : viewBox 320×200, palette charte, reconnaissable, `alt_text` présent.
- [ ] SSML : balises équilibrées, voix correctes, pauses conformes.
- [ ] SQL valide (apostrophes doublées, JSONB parseable).
