# SejourFR — Module Examen civique

> Prérequis : `00_SEJOURFR_SPEC_MAITRE.md` et `AUDIT.md`.
> À implémenter **après** le TCF (lots L8 à L11).
> Différence majeure avec le TCF : ici le chantier principal est **éditorial** (créer les notions, re-tagger le catalogue), pas algorithmique.

---

# 1. Cadre

- Examen obligatoire depuis le 1er janvier 2026 pour CSP, CR et naturalisation.
- Format retenu dans l'app : **40 questions / 45 min / seuil 32 sur 40**.
- Composition : **28 questions de connaissances + 12 mises en situation**.
- 5 thèmes officiels, à conserver sans renommage :

1. Principes et valeurs de la République
2. Système institutionnel et politique
3. Droits et devoirs
4. Histoire, géographie et culture
5. Vivre dans la société française

- 3 mentions : **CSP, CR, NAT**.

## 1.1. Hiérarchie cible

```
Mention → Thème → Notion → Questions
                        └→ (mises en situation : Thème → Domaine de situation → Questions)
```

La notion est le niveau qui **n'existe pas encore** en base. Tout le reste s'appuie dessus.

## 1.2. Scoping par mention (arbitrage A9)

Chaque question porte l'ensemble des mentions pour lesquelles elle est pertinente (`mentions` : tableau, pas une clé étrangère unique — une même question sert souvent 2 ou 3 mentions). Chaque notion porte également ses mentions.

Conséquences, non négociables :

- le diagnostic ne tire que dans le périmètre de la mention de l'utilisateur ;
- le plan ne propose que des notions de cette mention ;
- les examens blancs sont déjà scopés par mention : ne pas casser l'existant ;
- si l'utilisateur change de mention, le plan est recalculé, les états de maîtrise par notion sont **conservés** (une notion maîtrisée le reste).

`user.civic_target_mention` doit être demandé une fois, avant le diagnostic, et modifiable dans le profil.

---

# 2. Référentiel de notions (nouveau)

Proposition de départ, **à valider éditorialement** contre le référentiel officiel de l'examen avant intégration. Codes stables, libellés candidats.

## 2.1. Thème 1 — Principes et valeurs de la République

| Code | Libellé |
|---|---|
| `pv_devise` | La devise : Liberté, Égalité, Fraternité |
| `pv_symboles` | Les symboles de la République |
| `pv_laicite` | La laïcité |
| `pv_ddhc` | La Déclaration des droits de l'homme et du citoyen |
| `pv_democratie` | Démocratie et souveraineté nationale |
| `pv_caracteres_republique` | Une République indivisible, laïque, démocratique et sociale |
| `pv_egalite_fh` | L'égalité entre les femmes et les hommes |
| `pv_liberte_expression` | La liberté d'expression et ses limites |
| `pv_non_discrimination` | Le refus des discriminations |
| `pv_fraternite` | Fraternité et solidarité |

## 2.2. Thème 2 — Système institutionnel et politique

| Code | Libellé |
|---|---|
| `inst_constitution` | La Constitution et la Ve République |
| `inst_president` | Le Président de la République |
| `inst_gouvernement` | Le Gouvernement et le Premier ministre |
| `inst_parlement` | Le Parlement |
| `inst_assemblee` | L'Assemblée nationale |
| `inst_senat` | Le Sénat |
| `inst_elections` | Les élections et le droit de vote |
| `inst_commune` | La commune et le maire |
| `inst_departement_region` | Le département et la région |
| `inst_justice` | La justice et les tribunaux |
| `inst_conseil_constitutionnel` | Le Conseil constitutionnel |
| `inst_ue` | L'Union européenne |
| `inst_partis` | Partis politiques et vie démocratique |

## 2.3. Thème 3 — Droits et devoirs

| Code | Libellé |
|---|---|
| `dd_droits_fondamentaux` | Les droits fondamentaux |
| `dd_devoirs_citoyen` | Les devoirs : respect des lois, impôts, jury |
| `dd_egalite_loi` | L'égalité devant la loi |
| `dd_travail` | Droits et devoirs au travail |
| `dd_protection_sociale` | La protection sociale et l'assurance maladie |
| `dd_ecole_obligatoire` | L'école obligatoire et les droits de l'enfant |
| `dd_logement` | Droits et obligations liés au logement |
| `dd_liberte_culte` | La liberté de culte et ses limites |
| `dd_protection_femmes` | La protection contre les violences |
| `dd_services_publics` | Les services publics et l'accès aux droits |

## 2.4. Thème 4 — Histoire, géographie et culture

| Code | Libellé |
|---|---|
| `hg_revolution` | La Révolution française et 1789 |
| `hg_dates_republique` | Les grandes dates de la République |
| `hg_loi_1905` | La séparation des Églises et de l'État |
| `hg_guerres_resistance` | Les guerres mondiales et la Résistance |
| `hg_vote_femmes` | Le droit de vote des femmes |
| `hg_construction_europeenne` | La construction européenne |
| `hg_geographie` | Géographie de la France, régions et outre-mer |
| `hg_villes` | Paris et les grandes villes |
| `hg_patrimoine` | Patrimoine et monuments |
| `hg_langue_francophonie` | La langue française et la francophonie |
| `hg_culture` | Culture, arts et personnalités marquantes |

## 2.5. Thème 5 — Vivre dans la société française

| Code | Libellé |
|---|---|
| `vs_demarches` | Les démarches administratives courantes |
| `vs_sante` | Se soigner au quotidien |
| `vs_ecole_parents` | L'école et le rôle des parents |
| `vs_logement_pratique` | Se loger : bail, aides, voisinage |
| `vs_emploi` | Travailler et chercher un emploi |
| `vs_transports` | Transports et sécurité routière |
| `vs_urgences` | Numéros d'urgence et sécurité |
| `vs_budget_impots` | Budget, banque et impôts |
| `vs_vie_collective` | Vivre ensemble et respect des règles |
| `vs_laicite_quotidien` | La laïcité dans la vie quotidienne |

Total : **54 notions**. Volume cible de questions : **minimum 6 questions actives par notion et par mention concernée** pour qu'un entraînement ciblé ait du sens. En dessous de 4, la notion est marquée `insufficient_content` et n'est pas proposée comme priorité.

## 2.6. Domaines de situation (mises en situation, arbitrage A10)

Les mises en situation ne se rattachent **pas** à une notion factuelle. Elles portent un `situation_domain` :

| Code | Libellé |
|---|---|
| `sit_voisinage` | Vie quotidienne et voisinage |
| `sit_travail` | Situations au travail |
| `sit_ecole` | École et parentalité |
| `sit_demarches` | Services publics et démarches |
| `sit_sante` | Santé |
| `sit_laicite` | Laïcité et vivre-ensemble |
| `sit_droits` | Faire valoir ses droits |

Une mise en situation peut en outre référencer une notion « éclairante » (`related_notion_id`, nullable) pour permettre au plan de proposer un rappel utile.

---

# 3. Tagging du catalogue existant

## 3.1. Réalité de départ

Aujourd'hui les questions ne portent qu'un `theme_id`. Il faut : créer les notions, puis rattacher chaque question. C'est le chemin critique du module civique.

## 3.2. Pipeline en 3 étapes

**Étape 1 — Import du référentiel**
Migration Flyway insérant les 54 notions avec leur thème, leur ordre et leurs mentions. Codes stables, jamais réutilisés après suppression.

**Étape 2 — Pré-tagging assisté**
Job admin qui, par lots de 50 questions, appelle `PROMPT_TAG_NOTION_v1` (§9.1) et écrit une **suggestion** :

```
civic_question_notion_suggestion(question_id, notion_id, confidence, rationale, model, created_at)
```

Rien n'est appliqué automatiquement. Le LLM propose, il ne décide pas.

**Étape 3 — Validation humaine dans l'admin**
Écran de tagging en lot :

- filtre par thème et par état (`non taggée`, `suggérée`, `validée`) ;
- la suggestion est présélectionnée avec son niveau de confiance ;
- validation au clavier, 1 question par seconde visée ;
- action « marquer comme mise en situation » avec choix du domaine ;
- compteur de couverture par notion, pour repérer les notions vides.

Règle : `confidence < 0.7` → la suggestion est affichée mais **non présélectionnée**.

## 3.3. Migration progressive

`civic_questions.notion_id` est **nullable**. Deux phases :

- **Phase 1** : l'application fonctionne avec des questions non taguées. Le plan travaille alors au niveau **thème** et l'affiche comme tel (« Renforcer : Système institutionnel »).
- **Phase 2** : à mesure que le tagging avance, le plan bascule automatiquement au niveau notion, thème par thème.

Bascule contrôlée par un seuil : un thème passe en mode notion quand **≥ 80 %** de ses questions actives sont taguées. Valeur configurable, calculée quotidiennement.

## 3.4. Mode dégradé

| Situation | Comportement |
|---|---|
| Thème sous le seuil de tagging | Plan et diagnostic au niveau thème pour ce thème uniquement |
| Notion avec < 4 questions | `insufficient_content` : jamais proposée comme priorité, utilisable en examen blanc |
| Question sans explication | Correction affichée sans explication, signalée à l'admin ; **ne jamais générer d'explication factuelle non validée** |

---

# 4. Diagnostic civique

## 4.1. Principe

Le diagnostic n'est **pas** un examen blanc. Il sert à identifier quoi travailler, pas à vérifier si on est prêt.

| | Diagnostic | Examen blanc |
|---|---|---|
| But | identifier les faiblesses | vérifier la préparation |
| Format | 24 questions, ~15 min | 40 questions / 45 min / seuil 32 |
| Couverture | équilibrée sur les 5 thèmes | représentative de l'examen |
| Effet | crée le plan | met à jour le plan |

## 4.2. Composition

24 questions, configurable :

- **17 questions de connaissances** : minimum 3 par thème, réparties sur des notions différentes ;
- **7 mises en situation** (~29 %, cohérent avec 12/40), réparties sur au moins 4 domaines ;
- difficulté représentative du catalogue ;
- aucune notion évaluée plus de 2 fois ;
- uniquement des questions de la mention de l'utilisateur.

Contrainte explicite : **ne jamais évaluer un thème sur une seule question**.

## 4.3. Accès

- **1 diagnostic civique gratuit** par compte, quota distinct du TCF et des quotas IA (le civique est du QCM déterministe, aucun coût LLM).
- Résultat consultable à vie.
- Nouvelle passation : Premium, ou déclenchée par le plan après un parcours terminé, au plus une fois tous les 14 jours.

## 4.4. Calcul

**Par thème**

```
taux_theme = bonnes réponses / questions posées sur ce thème

état_theme =
  SOLIDE     si taux ≥ 0.80
  A_RENFORCER si 0.55 ≤ taux < 0.80
  FAIBLE     si taux < 0.55
```

**Par notion** — une ou deux questions ne suffisent pas à conclure. Le diagnostic ne fixe donc pas un état définitif : il **initialise** la boîte Leitner.

```
réponse correcte   → boîte 2
réponse incorrecte → boîte 1, marquée priority_seed = true
notion non évaluée → NON_EVALUEE
```

**Score global** : nombre de bonnes réponses sur 24, converti en projection lisible.

```
projection_40 = arrondi( bonnes_reponses / questions_posees × 40 )
```

Exemple : 18 / 24 → 0,75 → **30 / 40**.

Cette valeur est **toujours calculée côté backend** et transmise au client. Elle ne doit jamais être écrite en dur dans une maquette ni recalculée par le front. Elle est présentée comme une estimation, jamais comme un pronostic de réussite :

> « Sur un examen de 40 questions, votre résultat actuel correspondrait à environ **30 / 40**. Le seuil de réussite est de 32. »

## 4.5. Écran de résultat

```
[Header]     « Mon diagnostic — Examen civique » + badge mention (CSP / CR / NAT)

[1. Résultat]
   « Votre résultat »
   18 / 24                                  ← grand
   « Soit environ 30 / 40 à l'examen. Le seuil de réussite est de 32. »
   ⚠ valeur calculée par le backend, jamais en dur
   barre de progression avec le seuil marqué visuellement
   ⚠ aucune promesse de réussite

[2. Vos thèmes]                5 lignes, état + libellé, jamais 5 « urgents »
   ✅ Principes et valeurs de la République        Solide
   🟠 Droits et devoirs                            À renforcer
   🔴 Système institutionnel et politique          Faible
   🟠 Histoire, géographie et culture              À renforcer
   ✅ Vivre dans la société française              Solide

[3. Mises en situation]        bloc distinct, car c'est une compétence différente
   « 4 sur 7 réussies »
   « Les mises en situation demandent d'appliquer les règles à un cas concret.
     C'est souvent ce qui fait la différence à l'examen. »

[4. Ce qui vous coûte le plus de points]
   titre volontairement concret
   🔴 Le Parlement                    Système institutionnel
   🟠 Le Gouvernement                 Système institutionnel
   🟠 Les collectivités territoriales Système institutionnel
   (au niveau thème si le tagging n'est pas suffisant)

[5. Rassurance]
   « Vous n'avez pas besoin de tout réviser »
   « 2 thèmes sont déjà solides. Votre plan se concentrera sur les notions
     qui vous font perdre le plus de points. »

[6. Teaser du plan]
   « Votre plan de révision est prêt »
   1. Le Parlement                 10 questions ciblées
   2. Le Gouvernement              8 questions ciblées
   3. Les collectivités            8 questions ciblées
   🔒 + 6 autres notions à consolider
   [CTA] Découvrir mon plan

[Pied]  [Revoir mes réponses]      ← gratuit, avec explications
```

Comme pour le TCF : **le constat est intégralement gratuit**, le paywall porte sur l'accompagnement.

---

# 5. Moteur de progression

## 5.1. Répétition espacée (arbitrage A11)

Leitner à 5 boîtes, par couple (utilisateur, notion) :

| Boîte | Intervalle avant nouvelle présentation |
|---|---|
| 1 | immédiat (même session ou lendemain) |
| 2 | 1 jour |
| 3 | 3 jours |
| 4 | 7 jours |
| 5 | 21 jours |

Transitions :

```
réponse correcte    → boîte + 1 (max 5)
réponse incorrecte  → retour boîte 1
```

Sur une mise en situation, la boîte concernée est celle du `situation_domain`, pas d'une notion.

## 5.2. État de maîtrise (arbitrage A12)

```
NON_EVALUEE     < 2 réponses enregistrées
A_TRAVAILLER    boîte 1 ou 2
EN_PROGRESSION  boîte 3
MAITRISEE       boîte 4 ou 5 ET dernière réponse correcte
```

Une notion `MAITRISEE` dont l'échéance Leitner est dépassée redevient éligible au plan en tant que **révision d'entretien**, jamais en tant que priorité rouge.

## 5.3. Score de priorité d'une notion

```
score =
    3 × (1 si erreur dans les 7 derniers jours sinon 0)
  + 2 × min(nb_erreurs_30j, 3)
  + 2 × (1 si priority_seed du diagnostic sinon 0)
  + 2 × (1 si échéance Leitner dépassée sinon 0)
  + 1 × (poids du thème : 2 si FAIBLE, 1 si A_RENFORCER, 0 si SOLIDE)
  − 3 × (1 si MAITRISEE sinon 0)
  − 10 × (1 si insufficient_content sinon 0)
```

Ordre de sélection quand les scores sont proches :

1. notions vues et faibles ;
2. notions à erreurs répétées ;
3. notions en progression non consolidées ;
4. notions jamais évaluées ;
5. notions maîtrisées en révision d'entretien.

**3 priorités visibles maximum.** Les autres sont comptées : « + 6 autres notions à consolider ».

## 5.4. Recalcul

Déclencheurs : fin du diagnostic, fin d'une mini-série ciblée, fin d'un examen blanc, franchissement d'une échéance Leitner (job quotidien), changement de mention.

Comme pour le TCF, la priorité n°1 reste stable tant que sa mini-série n'est pas terminée.

---

# 6. Page Plan civique

Même écran que le Plan TCF, sélectionné par le segmented control. **Aucune métrique CECRL ne doit apparaître** quand l'onglet civique est actif.

```
[Segmented control]   TCF IRN | Examen civique
[Header]              « Mon plan »
                      « Votre préparation personnalisée à l'Examen civique »
                      « 3 thèmes à renforcer »

[1. Objectif]         Résultat estimé aujourd'hui  30 / 40
                      Seuil de réussite            32 / 40
                      « Estimation à partir de vos dernières réponses. »

[2. À faire maintenant]         bloc dominant
                      Système institutionnel et politique
                      Le Parlement                         [PRIORITÉ N°1]
                      « Comprendre le rôle de l'Assemblée nationale et du Sénat. »
                      10 questions ciblées · ~6 min
                      [Commencer]

[3. Votre semaine]    « 2 séries sur 4 terminées »
                      ✓ Le Président de la République
                      ✓ Les symboles de la République
                      ○ Le Parlement
                      ○ Mises en situation — Démarches

[4. Vos priorités]    3 cartes
                      🔴 Le Parlement — Système institutionnel
                         À travailler · 3 erreurs récentes
                      🟠 Le Gouvernement
                      🟡 Les collectivités territoriales
                      « + 6 autres notions à consolider »

[5. À revoir bientôt] révision d'entretien, secondaire
                      Les symboles de la République — à revoir dans 2 jours

[6. Déjà solide]      ✅ Principes et valeurs   ✅ Vivre dans la société française

[7. Progression]      « Progression détectée — Le Président de la République
                        est maintenant maîtrisé. Prochaine priorité : Le Parlement. »
```

**Variante non abonné** : mêmes blocs 1, 2 (titre de la notion et objectif visibles, série verrouillée), 4 (3 priorités entièrement visibles), puis teaser :

```
Votre série ciblée sur Le Parlement            🔒 10 questions
Fiche de rappel                                🔒
Explications de vos erreurs                    🔒
Révision automatique aux bons moments          🔒
Réévaluation de votre niveau                   🔒

[CTA] Débloquer mon plan — Premium · 14,99 €/mois
```

Argument Premium propre au civique, à utiliser dans le paywall quand le contexte est civique :

> « Réviser des centaines de questions au hasard prend des semaines. SejourFR vous fait travailler les notions qui vous coûtent réellement des points, et vous les represente au bon moment jusqu'à ce qu'elles soient acquises. »

Si un chiffre est affiché (nombre de questions du catalogue, nombre de notions faibles), il est **calculé et transmis par le backend**. Aucune valeur numérique en dur dans un texte marketing : elle deviendrait fausse à la première évolution du catalogue.

---

# 7. Réviser › Examen civique

Reprend la logique du TCF : la bibliothèque reste ouverte, le plan guide.

## 7.1. Niveau 1 — Les thèmes

```
Examen civique — Mention : Naturalisation
5 cartes de thème, chacune avec :
   libellé · nombre de notions · état (Solide / À renforcer / Faible / Non évalué)
   badge 🔴 « Prioritaire dans votre plan » le cas échéant
   barre de maîtrise : 6 notions maîtrisées sur 13
```

## 7.2. Niveau 2 — À l'intérieur d'un thème

Toggle : **`S'entraîner | Travailler une notion`** (même logique que EE/EO).

**Onglet S'entraîner** : séries libres existantes (aléatoire, par difficulté, erreurs, favoris). Ne rien casser de l'existant.

**Onglet Travailler une notion** :

```
[À travailler en priorité]        si diagnostic disponible
   🔴 Le Parlement                     3 erreurs · 12 questions
   🟠 Le Gouvernement                  2 erreurs · 9 questions
   🟡 Les collectivités territoriales  8 questions

[À revoir]                        échéances Leitner
   Le Président de la République — à revoir aujourd'hui

[Toutes les notions]              repliée, avec état par notion
   ✅ Les symboles   ✅ La devise   ○ Le Conseil constitutionnel …
```

Si le thème est sous le seuil de tagging : afficher uniquement l'onglet « S'entraîner » avec un encart « Les révisions ciblées arrivent bientôt sur ce thème ».

## 7.3. Niveau 3 — Page d'une notion

```
[Titre]     Le Parlement                       Système institutionnel

[Pourquoi cette notion ?]        si diagnostic disponible
   « Lors de votre diagnostic, vous avez répondu incorrectement à 2 questions
     sur le rôle de l'Assemblée nationale et du Sénat. »

[Fiche de rappel]                courte, 5 à 8 lignes maximum, éditoriale
   Contenu validé humainement. Jamais généré à la volée.
   [Premium] verrouillée pour les non-abonnés

[Série ciblée]
   10 questions sur cette notion
   [Commencer]

[Mettre en pratique]
   « Faire une série mixte incluant cette notion »
```

## 7.4. Mises en situation

Entrée dédiée au même niveau que les thèmes, car ce n'est pas une connaissance mais une application :

```
Mises en situation                    « 12 questions sur 40 à l'examen »
   sit_demarches   À renforcer   14 questions
   sit_laicite     Faible        11 questions
   sit_travail     Solide         9 questions
```

## 7.5. Correction d'une question

Après chaque réponse, dans cet ordre :

```
Verdict (correct / incorrect)
La bonne réponse
L'explication éditoriale existante
Pourquoi les autres réponses sont fausses   (si disponible)
[Rattachement] Cette question porte sur : Le Parlement
[Action] Réviser cette notion →   ou   Question suivante →
```

Jamais de correction qui se termine sans action suivante.

---

# 8. Examens blancs et boucle de réévaluation

## 8.1. Menu Examens

```
Segmented control : TCF IRN | Examen civique

Diagnostic initial          [À faire] ou [Terminé — Voir mon diagnostic]
                            ne jamais proposer de le refaire gratuitement
Examens blancs              conditions existantes conservées
                            40 questions / 45 min / seuil 32
Réévaluation                Premium, proposée par le plan
```

## 8.2. Après un examen blanc

```
[Résultat]        31 / 40 — seuil 32
                  « Vous êtes à 1 point du seuil. »
[Par thème]       score et évolution depuis le dernier examen
[Mises en situation]   8 / 12
[Vos erreurs]     regroupées par notion, pas par ordre d'apparition
[Nouvelles priorités]  ce qui a changé dans le plan
[CTA]             « Votre plan a été mis à jour »  →  Continuer mon plan
```

La mise à jour est automatique, avec confirmation visuelle. Chaque réponse d'examen blanc alimente les boîtes Leitner exactement comme une série ciblée.

## 8.3. Progrès

Onglet civique de l'écran Progrès :

- courbe des scores d'examens blancs avec la ligne du seuil à 32 ;
- notions maîtrisées sur notions totales de la mention ;
- état par thème ;
- mises en situation ;
- régularité (jours d'entraînement sur 30).

Pas plus. Éviter le tableau de bord statistique.

---

# 9. Prompts LLM

Le civique est du QCM déterministe : **aucun appel LLM en runtime utilisateur**. Les prompts ci-dessous sont réservés à l'admin, en production de contenu, avec validation humaine obligatoire.

## 9.1. `PROMPT_TAG_NOTION_v1` (admin, batch)

**System**

```
Tu es assistant éditorial. Tu rattaches des questions d'examen civique français
à une notion d'un référentiel fermé. Tu réponds uniquement par un JSON valide.
Tu ne crées jamais de notion nouvelle. Si aucune notion ne convient, tu renvoies
notion_code: null. Tu ne corriges pas la question, tu ne juges pas son exactitude.
```

**User**

```
Thème de la question : {theme_label}
Notions disponibles pour ce thème :
{liste : code — libellé}

Question : {statement}
Réponses proposées : {choices}
Bonne réponse : {correct_choice}
Explication existante : {explanation ou "aucune"}

Renvoie :
{
  "notion_code": "code | null",
  "confidence": 0.0,
  "rationale": "1 phrase",
  "is_situation": false,
  "situation_domain": "code | null"
}
Mets is_situation à true si la question décrit un cas concret auquel le candidat
doit réagir, plutôt qu'une connaissance factuelle à restituer.
```

Sortie écrite en **suggestion uniquement** (§3.2).

## 9.2. `PROMPT_GEN_NOTION_SHEET_v1` (admin, brouillon)

Génère une fiche de rappel de 5 à 8 lignes pour une notion, à partir des questions et explications **déjà validées** de cette notion.

Contraintes imposées dans le prompt :

```
- Tu n'ajoutes AUCUN fait qui ne figure pas dans les explications fournies.
- Tu n'inventes ni date, ni chiffre, ni nom propre absent des sources.
- Si les sources sont insuffisantes, tu renvoies {"insufficient_sources": true}.
- Sortie en français simple, phrases courtes, 2e personne du pluriel proscrite
  (c'est une fiche, pas un message).
```

Statut de sortie : `DRAFT`. **Aucune fiche ne peut être publiée sans validation humaine.** L'exactitude factuelle du contenu civique prime sur la vitesse de production : c'est une règle produit, pas une préférence.

## 9.3. Ce qui est interdit

- Générer une explication de question civique sans source validée.
- Générer une question civique et la publier automatiquement.
- Faire commenter une réponse d'utilisateur par un LLM en runtime dans le module civique.

---

# 10. Modèle de données

```
civic_notion
  id, theme_id, code, title, short_description, mentions(text[]), order,
  active, content_status(OK|INSUFFICIENT_CONTENT)

civic_situation_domain
  id, code, title, order, active

civic_questions                      -- table existante, à étendre
  + notion_id            (nullable, FK civic_notion)
  + question_kind        (KNOWLEDGE | SITUATION)
  + situation_domain_id  (nullable)
  + related_notion_id    (nullable, pour les situations)
  + mentions             (text[])   -- si non déjà présent
  (theme_id, difficulty, explanation, is_active conservés)

civic_question_notion_suggestion
  question_id, notion_id, confidence, rationale, is_situation,
  situation_domain_id, model, created_at, applied_at, applied_by

user_civic_notion_progress
  user_id, notion_id, mention, leitner_box, status,
  attempts_count, correct_count, incorrect_count, consecutive_correct,
  priority_seed, last_seen_at, last_error_at, next_review_at, updated_at

user_civic_situation_progress
  user_id, situation_domain_id, leitner_box, status, ... (mêmes colonnes)

civic_diagnostic
  id, user_id, mention, status, score_raw, score_total,
  projected_score_40, started_at, completed_at

civic_diagnostic_theme_result
  diagnostic_id, theme_id, asked, correct, state(SOLIDE|A_RENFORCER|FAIBLE)

civic_plan
  id, user_id, mention, plan_version, computed_at, next_item_id

civic_plan_item
  id, plan_id, rank, kind(NOTION|SITUATION|MAINTENANCE),
  notion_id, situation_domain_id, reason_text, priority_score, status

civic_theme_tagging_stats           -- job quotidien
  theme_id, total_active, tagged, ratio, notion_mode_enabled, computed_at
```

Extension des contextes d'`Attempt` existants plutôt que création d'un système parallèle :

```
CIVIC_DIAGNOSTIC | CIVIC_TARGETED_PRACTICE | CIVIC_SERIES | CIVIC_MOCK_EXAM
```

---

# 11. API

```
GET    /api/v1/civic/onboarding/mention              → mention actuelle, options
PUT    /api/v1/civic/onboarding/mention              { mention }

POST   /api/v1/civic/diagnostics                     → { diagnostic_id, questions[] }
POST   /api/v1/civic/diagnostics/{id}/answers        { answers[], client_submission_id }
POST   /api/v1/civic/diagnostics/{id}/complete
GET    /api/v1/civic/diagnostics/{id}/result/view    → écran §4.5

GET    /api/v1/civic/plan/view                       → écran §6, selon droits
GET    /api/v1/civic/plan/items/{id}/view
POST   /api/v1/civic/plan/recompute                  (interne)

GET    /api/v1/civic/revise/themes                   → §7.1
GET    /api/v1/civic/revise/themes/{id}/view         → §7.2, onglets et mode notion/thème
GET    /api/v1/civic/revise/notions/{id}/view        → §7.3
GET    /api/v1/civic/revise/situations               → §7.4
POST   /api/v1/civic/practice/targeted               { notion_id | situation_domain_id }

POST   /api/v1/civic/exams/{id}/complete             → résultat + plan mis à jour
GET    /api/v1/civic/progress/view

-- admin
GET    /api/v1/admin/civic/tagging/queue
POST   /api/v1/admin/civic/tagging/suggest           { question_ids[] }
POST   /api/v1/admin/civic/tagging/apply             { question_id, notion_id | situation }
GET    /api/v1/admin/civic/coverage                  → couverture par notion et mention
```

---

# 12. Tests attendus

**Référentiel et tagging**

- [ ] migration des 54 notions idempotente, codes stables ;
- [ ] question sans `notion_id` : tous les écrans fonctionnent en mode thème ;
- [ ] bascule automatique en mode notion au franchissement du seuil de 80 % ;
- [ ] une suggestion LLM n'est jamais appliquée sans validation.

**Diagnostic**

- [ ] couverture des 5 thèmes, minimum 3 questions par thème ;
- [ ] proportion de mises en situation respectée à ±1 ;
- [ ] aucune question hors mention de l'utilisateur ;
- [ ] 2e diagnostic refusé en gratuit ;
- [ ] projection sur 40 : `round(correct / asked × 40)`, vérifiée sur 18/24 → 30 ;
- [ ] aucune valeur numérique de projection ou de volumétrie en dur côté client.

**Moteur**

- [ ] transitions Leitner correctes dans les deux sens ;
- [ ] `next_review_at` calculé selon la boîte ;
- [ ] notion `insufficient_content` jamais proposée en priorité ;
- [ ] priorité n°1 stable jusqu'à fin de sa série ;
- [ ] changement de mention : plan recalculé, états de maîtrise conservés ;
- [ ] examen blanc alimente les boîtes Leitner comme une série ciblée.

**Séparation des modules**

- [ ] aucun libellé CECRL affiché dans l'onglet civique ;
- [ ] plan TCF et plan civique indépendants, aucun effet croisé ;
- [ ] accueil agrège les deux prochaines actions sans fusionner les plans.

**Parité**

- [ ] chaque écran §4 à §8 rendu à l'identique en Angular et Flutter.
