# SejourFR — Brief Claude Code
## Moteur du Plan : progression **par épreuve** vers l'objectif, confirmation **globale** du niveau

> **Version** : 2.0 — 2026-08-26
> **Remplace** : `BRIEF_CLAUDE_CODE_PROGRESSION_PAR_DOMAINE.md` (v1)
> **S'appuie sur** : le rapport d'analyse du compte `1a55f230-…` (diagnostic `fe35354d-…`)
> **Statut** : brief d'exécution — **phase d'audit obligatoire avant toute génération de code**

---

# 0. Comment lire ce brief

Ce document contient :

1. Une **doctrine produit** (§1–§12) — elle amende une doctrine existante, voir §2.
2. Une **phase d'audit obligatoire** (§13) avec un **STOP** avant tout code.
3. Des **contraintes d'implémentation** (§14–§30).
4. Des **critères d'acceptation et tests** (§31–§40).

⚠️ **Tu ne dois pas commencer à écrire du code avant d'avoir rendu l'audit §13 et reçu un GO explicite.**
Si une observation faite pendant l'audit contredit ce brief, **signale-la et arrête-toi** — ne l'absorbe pas silencieusement. Ce brief a été écrit sans lire le code ; toi tu le lis.

---

# 1. Le problème observé

Compte de test, objectif **NAT → B2** :

```text
EE = A2   3 fragilités observées, 6 compétences B1 jamais travaillées
EO = B1   0 fragilité observée, 4 compétences B1 + 6 compétences B2 jamais travaillées
```

Le Plan a servi **2 actions**, toutes en EE. L'EO affiche « rien à travailler ».

Cause : trois règles indépendantes se sont composées.

| Maillon | Mécanisme | Verdict |
|---|---|---|
| 1 | Le correcteur n'a trouvé aucune fragilité EO | ✅ Légitime — à conserver |
| 2 | Le palier du cycle est **global** (`min` des domaines) → B1 imposé à l'EO | ❌ À changer (§2) |
| 3 | `PAS_ENCORE_PRIORITAIRE` ⇒ zéro action | ❌ Conséquence non voulue |
| 4 | `MAX_PRIORITIES = 5` utilisé comme **budget de production**, pas comme plafond d'affichage | ❌ **Trou principal** |
| 5 | La carte d'épreuve lit `nature` = les cartes déjà empilées par le Plan | ❌ Elle a besoin de sa propre vue |

**10 actions pédagogiques réelles existaient. 2 ont été servies.**

---

# 2. ⚠️ Amendement doctrinal explicite

**Ce brief amende les §37 et §93 de la spec de progression** (« un palier à la fois, celui qui bloque »).

Ce qui change :

```text
AVANT : palier d'apprentissage = premier cran au-dessus du niveau GLOBAL
APRÈS : palier d'apprentissage = premier cran au-dessus du niveau DU DOMAINE
```

Ce qui **ne change pas** — le niveau global reste la référence pour :

- le chemin global affiché ;
- l'état du cycle global ;
- la **confirmation** d'un niveau CECRL ;
- le déclenchement et l'interprétation du **gate mock** / examen blanc ;
- le libellé « niveau globalement atteint ».

```text
Progression pédagogique  = PAR DOMAINE
Confirmation du niveau   = GLOBALE
```

Si tu trouves dans le dépôt (`CLAUDE.md`, docs, javadoc, tests) des affirmations contraires,
**tu les listes dans l'audit** et tu proposes leur mise à jour dans le même lot. Tu ne les
supprimes pas de ton propre chef.

---

# 3. Les invariants — non négociables

Trois règles qui doivent survivre à ce correctif :

```text
INVARIANT 1  —  NON OBSERVÉ ≠ FAIBLE
```

Une compétence jamais observée ne devient **jamais** `TO_REINFORCE` pour remplir un écran.
Elle peut en revanche devenir `TO_ACQUIRE` si elle appartient au prochain palier du domaine.

```text
INVARIANT 2  —  AUCUNE FRAGILITÉ ≠ OBJECTIF ATTEINT
```

```text
EO = B1, objectif = B2, fragilités = 0
→ conclusion correcte : commencer les acquisitions B2
→ conclusion actuelle  : « rien à travailler »   ❌
```

```text
INVARIANT 3  —  PLAFOND UI ≠ BUDGET PÉDAGOGIQUE
```

Le moteur calcule **toutes** les actions vraies, puis l'UI en affiche un sous-ensemble.
Jamais l'inverse.

À ajouter dans `CLAUDE.md` à la fin du chantier.

---

# 4. Niveau global vs niveau par domaine

Le niveau global continue d'exister :

```text
globalWorkingLevel = min(CO, CE, EO, EE)     // uniquement si les 4 sont évaluées
```

Mais il **ne détermine plus** le prochain palier d'apprentissage d'un domaine.

Si un domaine n'est pas évalué : `NOT_EVALUATED`. **Ne jamais inventer A2.**
Le global n'est alors pas calculable — le Plan doit proposer « compléter cette épreuve ».

---

# 5. `nextTargetLevel` par domaine

```text
nextTargetLevel(domainLevel, objectiveLevel)

A2 + objectif B2  → B1
B1 + objectif B2  → B2
B2 + objectif B2  → objectif atteint localement

A2 + objectif B1  → B1
B1 + objectif B1  → objectif atteint localement
```

Ne jamais proposer un palier supérieur à l'objectif utilisateur.
Ne jamais faire sauter un palier (A2 → B2 directement est interdit).

Exemple attendu :

```text
EE = A2, EO = B1, CO = A2, CE = B1, objectif = B2

EE → prochain palier B1
EO → prochain palier B2
CO → prochain palier B1
CE → prochain palier B2
```

---

# 6. Trois natures d'action, jamais fusionnées

| Nature | Origine | Wording produit |
|---|---|---|
| `REINFORCEMENT` (issu de `TO_REINFORCE` / `PRIORITY`) | Observation réelle d'une fragilité | « À renforcer » |
| `TO_ACQUIRE` | Compétence du prochain palier du domaine, jamais travaillée | « Prochaine étape vers B2 » |
| `READY_FOR_VALIDATION` | Compétence travaillée, en attente de vérification en situation | « Prête à vérifier » |

`masteryStatus` et `planNature` sont **deux champs distincts**. Combinaison valide :

```text
masteryStatus = NOT_OBSERVED
planNature    = TO_ACQUIRE
```

→ « jamais observée, mais prochaine compétence du parcours ». Pas « faiblesse détectée ».

---

# 7. Éligibilité ≠ priorité

```text
isEligibleForProgression   ← un domaine sous objectif est TOUJOURS éligible
priorityRank               ← l'ordre d'affichage peut favoriser le domaine bloquant
```

Exemple :

```text
EE A2 / objectif B2   eligible = true   priority = HIGH
EO B1 / objectif B2   eligible = true   priority = MEDIUM
```

Les deux ont des actions. `PAS_ENCORE_PRIORITAIRE` (ou son successeur) ne doit plus
signifier « ce domaine ne reçoit rien ».

**Priorité secondaire ≠ domaine gelé.**

---

# 8. 🆕 PATCH 1 — Filtre de faisabilité : une action doit être exécutable

> **C'est l'ajout le plus important de la v2. Le brief v1 ne le mentionnait pas.**

En passant de 2 actions servies à 10–20, le moteur va proposer des compétences pour
lesquelles **aucun contenu n'est peut-être rattaché**. Résultat : le candidat tape sur une
carte et tombe sur un écran vide. C'est pire que l'état actuel.

Règle dure :

```text
Une action n'existe dans le pool que si elle est EXÉCUTABLE.

Exécutable = il existe au moins un item de contenu actif rattaché à cette compétence
             pour le palier visé
             OU un fallback explicite et assumé (tâche complète / série mixte)
```

Placement dans le pipeline : **entre le calcul des candidates et le ranking** (§10, étape 7).

Conséquences à traiter :

- Le compteur affiché sur la carte d'épreuve (`acquireCount`) doit-il compter les
  compétences **non exécutables** ? → **Non.** Sinon le compte promet ce qui n'existe pas.
  Prévoir éventuellement un compteur interne séparé pour le pilotage produit.
- Si un domaine n'a **aucune** action exécutable, appliquer §9 (fallback), pas un écran vide.
- L'audit §13 doit **mesurer** la couverture de contenu par compétence **avant** de coder.
  Si la couverture est faible, ce chantier est bloqué par le tagging du catalogue, pas par le
  moteur — et il faut le dire tout de suite.

---

# 9. Garantie produit + 🆕 PATCH 2 — la vérification doit être ciblée

Règle :

```text
Toute épreuve évaluée dont le niveau est inférieur à l'objectif
doit porter au moins une prochaine action pédagogique VRAIE,
si une telle action existe.
```

Types d'action admissibles :

```text
À renforcer · À acquérir · Prête à vérifier ·
Tâche complète · Série ciblée · Examen blanc / vérification
```

🛑 **Jamais une action inventée.** Cette garantie ne peut piocher que dans des actions réelles
et exécutables. Elle ne transforme **jamais** une compétence `SOLID` ou `NOT_OBSERVED` en
fragilité.

### 🆕 Le patch

Le brief v1 disait : si rien ne reste, proposer « Vérifier le niveau en situation ».
**Problème** : un domaine solide sur les 8 compétences observées mais jamais observé sur les
16 autres recevra cette action **indéfiniment**, sans jamais produire de nouvelle observation.
L'écran se répète et rien n'avance.

Règle corrigée :

```text
Une action de vérification doit être SCOPÉE sur des compétences non observées
du palier visé, de manière à produire de nouvelles observations.

Une vérification qui ne peut rien observer de neuf n'est pas une action valide.
```

Et si tout est vraiment localement solide au palier cible :

```text
→ le domaine devient candidat au gate mock / examen blanc
→ pas une ligne de plus dans Aujourd'hui
```

---

# 10. Architecture attendue

```text
1.  Charger le profil
2.  Charger le référentiel
3.  Déterminer le niveau courant PAR DOMAINE
4.  Déterminer nextTargetLevel PAR DOMAINE                     (§5)
5.  Calculer TOUTES les fragilités observées
6.  Calculer TOUTES les acquisitions possibles du palier du domaine
7.  🆕 Filtrer par faisabilité / disponibilité de contenu       (§8)
8.  Calculer les validations / vérifications possibles         (§9)
9.  Construire la VUE COMPLÈTE par domaine                     (§16)
10. Ranker globalement                                         (§11)
11. Appliquer les règles de composition                        (§12)
12. Sélectionner Aujourd'hui / Mes priorités                   (§14)
13. Appliquer le masque freemium                               (§20)
```

Les étapes 1→9 sont **identiques pour un abonné et un non-abonné**. Le freemium est un
masque d'affichage appliqué en toute fin (§20).

---

# 11. 🆕 PATCH 3 — Le ranking est configurable, pas hardcodé

Ordre de base :

```text
1. Fragilité réellement bloquante
2. Compétence prête à être vérifiée
3. Acquisition du prochain palier du domaine
4. Consolidation utile
5. Maintenance
```

Pondéré par : urgence du domaine · écart à l'objectif · récence · confiance · readiness.

### La contrainte

Le brief v1 laissait ces pondérations à l'appréciation de l'implémentation. **Interdit ici.**
Conformément à la doctrine du dépôt sur les constantes de progression :

```text
Tous les poids, seuils et plafonds de ce chantier vivent dans
progression-config-v1.json (ou son successeur versionné).

Aucune valeur numérique de ranking n'est écrite en dur dans le code Java.
engineVersion doit rester intègre pour permettre le rejeu.
```

Constantes concernées, au minimum :

| Clé | Rôle | Valeur de départ proposée |
|---|---|---|
| `ranking.weights.*` | pondérations du ranking | à proposer, à valider |
| `display.today.maxActions` | plafond Aujourd'hui | 3 |
| `display.priorities.maxActions` | plafond Mes priorités | 5 |
| `display.today.maxSecondaryDomainActions` | 🆕 voir §12 | 1 |

---

# 12. 🆕 PATCH 4 — Règle dure de composition d'Aujourd'hui

Le brief v1 posait une « règle douce de diversité » sans la borner. Avec le palier par domaine,
le pool passe de ~5 à ~20 actions : sans borne, Aujourd'hui devient une liste de courses et on
perd exactement ce que la doctrine « un palier à la fois » protégeait — la **cohérence
pédagogique**.

Règle :

```text
Aujourd'hui : maximum 1 action de domaine SECONDAIRE sur 3.

domaine primaire   = le(s) domaine(s) au priorityRank le plus urgent
domaine secondaire = tout domaine éligible mais moins urgent
```

Exemple attendu sur le compte de test :

```text
1. Expression écrite · Tâche 1 — Relier les informations   [À renforcer]   ← primaire
2. Expression écrite · Tâche 2 — Compétence B1             [À acquérir]    ← primaire
3. Expression orale  · Tâche 3 — Compétence B2             [À acquérir]    ← secondaire
```

Pas trois épreuves différentes le même jour. Pas quatre.

**Sticky Today conservé** : une action non résolue reste présente le lendemain. Elle ne
disparaît qu'en atteignant son critère de résolution / maîtrise.

---

# 13. 🛑 PHASE 0 — AUDIT OBLIGATOIRE — STOP AVANT TOUT CODE

Tu ne génères **aucun** code tant que cet audit n'est pas rendu et validé.

## Ce que tu dois lire

```text
service/LearningPlanService.java
service/LearningPlanPriorityResolver.java
service/PlanAcquisitionSelector.java
service/PlanCycleResolver.java
service/PlanDomainSkillResolver.java

dto/PlanDomainDto + PlanDomainSkillDto + miroirs frontend
screens/diagnostic/widgets/diagnostic_result.dart
app/_components/diagnostic/*        (web)
Plan screen mobile + web
progression-config-v1.json (ou équivalent existant)
CLAUDE.md + docs de progression
```

## Ce que tu dois répondre — factuellement, sans supposer

| # | Question | Pourquoi |
|---|---|---|
| 1 | Où le palier global est-il calculé, et **qui le consomme** ? Lister tous les appelants. | Mesurer le rayon d'explosion de §2 |
| 2 | **🔴 Combien de compétences actives ont ≥1 item de contenu rattaché ?** Ventiler par section (CO/CE/EE/EO) × palier (A2/B1/B2). | §8 — bloquant potentiel du chantier |
| 3 | `MAX_PRIORITIES` est-il utilisé ailleurs que dans le sélecteur ? | Éviter une régression silencieuse |
| 4 | `READY_FOR_VALIDATION` (ou équivalent) existe-t-il déjà, ou faut-il le créer ? | §6 |
| 5 | `progression-config-v1.json` existe-t-il ? Quelle est sa structure, comment est-il chargé ? | §11 |
| 6 | `PlanDomainDto` est-il consommé à l'identique par mobile **et** web ? Qu'est-ce qui casse si on l'enrichit ? | Coordination des 3 surfaces |
| 7 | Où est implémenté Sticky Today, et sur quoi repose son critère de résolution ? | §12 |
| 8 | Quelles affirmations du dépôt contredisent §2 ? (fichier + ligne) | §2 — mise à jour dans le même lot |
| 9 | Le masque freemium est-il appliqué au calcul ou à l'affichage aujourd'hui ? | §20 |
| 10 | Combien de diagnostics en base présentent `skill.targetLevel > levelEstimate AND status = SOLID AND confidence = HIGH` ? Ventiler EE/EO × A2→B1 / B1→B2. **SQL uniquement, aucun appel LLM.** | §28 |

## Ce que tu ne dois PAS faire pendant l'audit

- Ne modifie aucun fichier.
- Ne fais aucun backfill, aucune migration.
- Ne rejoue aucune production auprès d'un LLM (question 10 = SQL sur les analyses déjà en base).
- Ne suppose pas qu'un champ existe parce que ce brief le nomme. Ce brief a été écrit sans lire
  le code : ses noms de champs sont **conceptuels**.

## 🛑 STOP 1

Rends l'audit. Attends un GO explicite.

Si la question 2 révèle une couverture de contenu faible sur les paliers visés, **dis-le
franchement** : le chantier moteur produira des culs-de-sac et l'ordre des priorités change.

---

# 14. Plafonds d'affichage

```text
MAX_PRIORITIES = 5   →  sémantique : MAXIMUM AFFICHÉ dans « Mes priorités »
                        et non : maximum d'actions connues du moteur

Aujourd'hui    = 3   →  même sémantique, source = pool complet rangé
```

Ne pas forcément remplir 5 si moins de 5 actions vraies existent.

Interdit :

```java
// ❌ ce qui existe aujourd'hui
limit = MAX_PRIORITIES - actionable.size();
acquisitionSelector.select(..., limit);
```

Attendu :

```text
allActions = fragilities + acquisitions + validations     // complet, filtré §8
ranked     = rank(allActions)                             // §11
composed   = applyCompositionRules(ranked)                // §12
displayed  = composed.take(limit)                         // §14
```

---

# 15. Carte d'épreuve ≠ priorités du jour

`Plan → Mon diagnostic` répond à :

> **Qu'est-ce qui me reste à faire dans cette épreuve ?**

Elle ne doit **pas** dériver des cartes sélectionnées pour Aujourd'hui / Mes priorités.

Aujourd'hui, `PlanDomainSkillResolver` fait `natures.get(skill.getId())` — c'est-à-dire
exactement les cartes que le Plan vient d'empiler. C'est la source du bug.

---

# 16. Vue complète par domaine

Le serveur expose par domaine :

```text
domain
evaluationStatus            // EVALUATED | NOT_EVALUATED | NOT_EVALUABLE
estimatedLevel
objectiveLevel
nextTargetLevel

skills[]                    // liste unique avec masteryStatus + planNature

fragileCount
acquireCount                // 🆕 compte les seules compétences EXÉCUTABLES (§8)
readyForValidationCount
solidCount
notObservedCount
```

Ces compteurs sont **propres au domaine** et ne dépendent d'aucune troncature d'affichage.

`PlanDomainSkillDto`, conceptuellement :

```text
skillId · skillCode · name · task · targetLevel
masteryStatus · planNature
progress · confidence
isActionable · isPremiumLocked
```

Réutiliser les structures existantes dès que possible — l'audit §13 Q6 tranche.

---

# 17. Domaine avancé : ne pas rétrograder

```text
EO = B2, EE = A2, objectif = B2
```

L'EO ne refait **pas** massivement du B1 parce que le global est A2.
Elle reçoit : maintenance · validation · simulation.

Si un domaine est **à l'objectif** avec des preuves fiables : plus d'acquisitions systématiques
→ stabilisation, mixed practice, candidature au mock.

---

# 18. Cas dégradés

| Situation | Comportement attendu |
|---|---|
| `CO`/`CE` non évaluées | `NOT_EVALUATED`. Ne pas inventer A2. Proposer « compléter cette épreuve » en parallèle de la progression EE/EO connue. |
| Production `NOT_EVALUABLE` | Ne pas proposer d'acquisitions comme si le niveau était connu. Action prioritaire = refaire l'évaluation. |
| Aucune action exécutable dans un domaine | §9 — fallback ciblé, jamais un écran vide muet. |

---

# 19. Confirmation globale et gate mock

La progression locale n'est **pas** une confirmation CECRL.

```text
EE = B1, EO = B2, CO = B1, CE = B1
→ niveau global confirmé = B1
```

Confirmation d'un niveau N :

```text
CO >= N AND CE >= N AND EE >= N AND EO >= N
```

vérifié par **examen blanc complet** réévaluant les 4 domaines.

⚠️ Règle interne SejourFR — ne jamais la présenter à l'utilisateur comme une formule officielle
du TCF.

Rappel doctrine : **le CECRL ne s'affiche jamais sur un drill isolé**, uniquement sur une épreuve
complète calculée côté serveur.

---

# 20. Freemium

```text
Le moteur calcule TOUT, y compris pour un non-abonné.
Le masque de visibilité est appliqué en dernier (§10 étape 13).
```

Les compteurs affichés doivent être **exacts** :

```text
+ 3 autres priorités
+ 4 à acquérir
+ 5 déjà solides
```

### 🆕 À instrumenter

Ce correctif fait passer le rideau freemium de « 1 sur 5 » à « 1 sur 9 ou 12 » sur le compte de
test. Signal de valeur plus fort — mais l'effet inverse (découragement) est plausible.

Poser les événements avant le déploiement :

```text
plan_curtain_shown       { visibleCount, totalCount, domain }
plan_curtain_expanded
plan_paywall_view        { source = plan_curtain }
```

Ne pas trancher sur l'intuition. Mesurer.

---

# 21. Contexte d'affichage

Toujours afficher l'épreuve **et** la tâche avant la compétence :

```text
✅  Expression écrite · Tâche 3
    Développer un argument
    À renforcer

❌  Développer un argument
```

Aujourd'hui peut regrouper par épreuve + tâche :

```text
Expression écrite · Tâche 2    2 entraînements
Expression orale  · Tâche 3    1 entraînement
```

Conserver les encarts rétractables prévus.

---

# 22. EE / EO — règles conservées

```text
5 petits sujets + validation contextualisée en tâche complète
```

Une compétence productive n'est **pas** `SOLID` uniquement parce que des micro-sujets ont été
réussis.

`improvedVersion` :

```text
niveau courant A2  → improvedVersion vise B1
niveau courant B1  → improvedVersion vise B2
niveau courant B2 avec objectif B2  → reste B2
```

Cette logique utilise désormais le niveau **du domaine**, pas le global.

Rappel : **conduite et notation restent strictement séparées** en session EO temps réel.

---

# 23. CO / CE — compétences MVP conservées

```text
CO-A2  Repérer une information explicite à l'oral
CO-B1  Comprendre le sens global et l'intention à l'oral
CO-B2  Comprendre l'implicite et les nuances à l'oral

CE-A2  Repérer une information explicite dans un texte
CE-B1  Comprendre l'idée principale et l'intention d'un texte
CE-B2  Comprendre l'implicite et les nuances d'un texte
```

Même doctrine que EE/EO : `CE = B1` + objectif B2 → travailler CE-B2, même si le global est A2.

---

# 24. Ordre de correction

```text
PHASE 0  Audit                                    🛑 STOP 1
PHASE 1  Moteur
         1. Découpler calcul complet / plafond d'affichage
         2. nextTargetLevel par domaine
         3. Acquisitions au palier propre du domaine
         4. Filtre de faisabilité (§8)
         5. Ranking configurable (§11) + composition (§12)
         6. Tests backend                         🛑 STOP 2
PHASE 2  DTO / API — vue complète par domaine, compteurs exacts
PHASE 3  Frontend mobile + web
PHASE 4  Instrumentation freemium (§20)
PHASE 5  Audit notation (§28) — indépendant, SQL only
PHASE 6  Mise à jour CLAUDE.md + docs (§3, §2)
```

## 🛑 STOP 2

Après la Phase 1, avant de toucher aux DTO et au front : montre le résultat du moteur sur le
compte de test (§25) sous forme de sortie brute ou de test. Attends un GO.

Raison : si le moteur est faux, propager l'erreur sur 3 surfaces coûte trois fois plus cher à
défaire.

---

# 25. Scénario d'acceptation principal

```text
objectif = B2
EE = A2   3 fragilités, plusieurs B1 jamais travaillées
EO = B1   0 fragilité, plusieurs B2 jamais travaillées
```

Attendu après correction :

```text
Mon diagnostic
  EE → A2, next B1 — priorités + acquisitions B1, compteurs exacts
  EO → B1, next B2 — « À renforcer : 0 · À acquérir vers B2 : N · Solides : 8 »

Aujourd'hui
  au plus 3 actions, dont au plus 1 de domaine secondaire (§12)

Mes priorités
  au plus 5, mix cohérent, non tronqué en amont

EO ne doit plus jamais afficher « rien à travailler »
```

---

# 26–27. Scénarios secondaires

| Cas | Attendu | Interdit |
|---|---|---|
| `EE=A2, EO=B2, objectif=B2` | EE → B1 ; EO → maintenance / validation | EO redescend vers B1 |
| `EE=A2, EO=B1, objectif=B1` | EE → B1 ; EO → stabilisation | acquisitions B2 |
| `CO`/`CE` non évaluées | « compléter l'épreuve » en parallèle | inventer A2 |
| EO `NOT_EVALUABLE` | « refaire l'évaluation orale » | acquisitions B1/B2 |
| 🆕 Domaine sans contenu taggé | fallback §9 ou compteur honnête | promettre N acquisitions vides |

---

# 28. Audit notation (indépendant du reste)

Le rapport signale deux compétences **B2** notées `SOLID` / `HIGH` chez un candidat estimé
**B1**, sur un monologue d'environ 100 secondes, dans le même appel.

Une compétence B2 solide chez un candidat B1 **n'est pas impossible** — ne pas l'interdire par
principe. Mais mesurer d'abord (§13 Q10, SQL seulement).

Si l'audit montre une incohérence **systématique**, proposer un guard **déterministe** côté
serveur, dans l'esprit du `CompetenceLevelEvidenceGuard` existant :

```text
skill.targetLevel > levelEstimate AND status = SOLID AND confidence = HIGH
→ réduire la confiance, ou requalifier en preuve insuffisante
```

🛑 Jamais une consigne de prompt supplémentaire. Jamais un backfill destructif des analyses
existantes sans mesure préalable et validation humaine.

---

# 29. Migration / compatibilité

- Aucune suppression de champ sans miroir frontend mis à jour dans le même lot.
- `engineVersion` préservé — les plans existants doivent rester rejouables.
- Toute nouvelle constante passe par le fichier de config versionné (§11).
- Les trois surfaces (mobile / web / admin) restent cohérentes en fin de chantier.

---

# 30. Ce qu'il ne faut surtout pas faire

- ❌ Transformer un `NOT_OBSERVED` en `TO_REINFORCE`.
- ❌ Inventer une compétence ou une action pour remplir un écran.
- ❌ Laisser un domaine B1 sans action alors que l'objectif est B2 et que des acquisitions B2
  exécutables existent.
- ❌ Bloquer l'EO parce que l'EE est plus faible.
- ❌ Utiliser `MAX_PRIORITIES` pour tronquer le moteur.
- ❌ Confondre carte d'épreuve et liste Aujourd'hui.
- ❌ Recalculer des compteurs sur une liste déjà tronquée.
- ❌ 🆕 Proposer une compétence sans contenu rattaché.
- ❌ 🆕 Hardcoder un poids de ranking.
- ❌ 🆕 Servir une action de vérification qui ne peut produire aucune observation nouvelle.
- ❌ Prétendre que toutes les compétences ont été observées au diagnostic.
- ❌ Confirmer un niveau global sans preuve sur les quatre domaines.
- ❌ Faire monter un candidat de A2 à B2 sans palier intermédiaire.
- ❌ Afficher un niveau CECRL sur un drill isolé.

---

# 31–39. Tests attendus

| # | Test | Attendu |
|---|---|---|
| 1 | `EE=A2, EO=B1, obj=B2` | EE cible B1, EO cible B2 |
| 2 | Niveau global | reste `min(...)`, ne pilote plus les paliers |
| 3 | Aucune fragilité EO | EO reçoit quand même des acquisitions B2 |
| 4 | `NOT_OBSERVED` | ne devient jamais `TO_REINFORCE` ; peut devenir `TO_ACQUIRE` |
| 5 | Domaine sous objectif | porte ≥1 action vraie **si elle existe** |
| 6 | Domaine à l'objectif | pas d'acquisitions systématiques ; maintenance / mock |
| 7 | Plafond UI | 12 actions connues, 5 affichées, compteurs = 12 |
| 8 | Aujourd'hui | ≤3 actions, ≤1 domaine secondaire (§12) |
| 9 | Carte d'épreuve | indépendante des cartes sélectionnées |
| 10 | Sticky | action non résolue conservée J+1 |
| 11 | Gate mock | déclenché sur la règle globale uniquement |
| 12 | 🆕 Compétence sans contenu | absente du pool ; non comptée dans `acquireCount` |
| 13 | 🆕 Vérification non observante | rejetée par le sélecteur |
| 14 | 🆕 Constantes | aucune valeur de ranking en dur — test de non-régression sur la config |
| 15 | Non-abonné | même pool calculé, masque appliqué en fin de chaîne |

---

# 40. Definition of Done

**Moteur**
- [ ] `nextTargetLevel` par domaine
- [ ] acquisitions calculées par domaine, au palier du domaine
- [ ] filtre de faisabilité appliqué avant ranking
- [ ] toutes les actions calculées avant toute troncature
- [ ] ranking + composition pilotés par config versionnée
- [ ] limites UI appliquées après ranking

**Backend**
- [ ] `PlanDomainDto` expose la vue complète et des compteurs exacts
- [ ] fragilité / acquisition / validation distinguées
- [ ] tests §31–39 verts

**Frontend**
- [ ] Mon diagnostic affiche les vraies compétences par épreuve
- [ ] contexte épreuve · tâche systématique
- [ ] Aujourd'hui / Mes priorités branchés sur le nouveau pool
- [ ] mobile et web cohérents
- [ ] compteurs freemium exacts + événements posés

**Documentation**
- [ ] `CLAUDE.md` porte les trois invariants (§3)
- [ ] l'amendement §2 est écrit et les affirmations contraires corrigées

---

# 41. Principe final

Le Plan doit répondre en permanence à :

> **Quelle est la prochaine action la plus utile — et réellement disponible — pour faire
> progresser ce candidat vers son objectif ?**

et non uniquement :

> Quelle faiblesse avons-nous détectée au diagnostic ?

```text
Observer
→ Réparer les fragilités observées
→ Enseigner le palier suivant du domaine
→ Vérifier en situation
→ Confirmer par domaine
→ Confirmer globalement par examen blanc
→ Continuer vers l'objectif
```
