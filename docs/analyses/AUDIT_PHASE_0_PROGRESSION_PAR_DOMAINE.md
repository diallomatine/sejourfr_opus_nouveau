# PHASE 0 — Audit préalable au brief « progression par épreuve » (v2)

> Répond au **§13** de `BRIEF_CLAUDE_CODE_PROGRESSION_PAR_DOMAINE_v2.md`.
> **Aucun fichier modifié. Aucune migration. Aucun appel LLM.** Question 10 = SQL sur la base locale.
> 🛑 **STOP 1 — j'attends un GO explicite avant toute ligne de code.**

---

## Verdict en trois lignes

1. 🟢 **Le chantier n'est pas bloqué par le contenu** : 100 % des 48 compétences EE/EO ont 15 petits sujets actifs. CO/CE n'utilisent pas ce contenu-là (série QCM tirée par palier, 134–214 questions par palier). Le filtre de faisabilité §8 reste à construire, mais il ne coupera rien aujourd'hui.
2. 🔴 **Le palier par domaine existe déjà dans le dépôt** — c'est `prescriptionLevel` du moteur V4.2, en `SHADOW` et branché **compréhension seulement**. Écrire un `nextTargetLevel` dans `PlanCycleResolver` créerait une **deuxième autorité** sur la même question. C'est l'arbitrage n°1 à rendre.
3. 🟡 **Trois affirmations du brief ne correspondent pas au dépôt** (§2 sur le §93, §11 sur la config livrée, §16 sur les noms de champs). Détail au §C. Je ne les ai pas absorbées silencieusement.

---

## A. Réponses aux 10 questions

### Q1 — Où le palier global est-il calculé, et qui le consomme ?

**Calcul** : `PlanCycleResolver.palierVise(depart, objectif)` — `PlanCycleResolver.java:210`.
`depart = TcfLevelProfile.globalLevel()` = plancher des domaines **évalués** (`TcfProfileService`, autorité unique). Résultat porté par `PlanCycleDto.targetLevel`.

**Consommateurs — backend**

| Lieu | Usage | Impact si le palier devient par domaine |
|---|---|---|
| `PlanAcquisitionSelector.java:126,141,156` | palier des acquisitions **en expression** | 🔴 cœur du correctif |
| `PlanCycleResolver.java:367` (`priorite`) | `niveau < vise ⇒ A_TRAVAILLER` | 🔴 décide `PAS_ENCORE_PRIORITAIRE` |
| `PlanCycleResolver.java:248` (`chemin`) | l'étape `CURRENT` du chemin global | 🟢 reste global (§2) |
| `PlanCycleResolver.java:162-172` | `objectifAtteint`, `gate`, `PlanCycleState` | 🟢 reste global (§2) |

**Consommateurs — fronts** (tous en lecture d'affichage, aucun recalcul)

| Fichier | Ligne | Ce qu'il affiche |
|---|---|---|
| `plan_evolution_screen.dart` | 138 | `PlanLevelRail(current: cycle.targetLevel)` |
| `plan_progress_screen.dart` | 186 | idem |
| `widgets/plan_priority_hero.dart` | 173 | idem |
| `plan_labels.dart` | 780, 783, 927 | « Votre plan construit d'abord votre **B1** » |
| `plan_groups.dart` | 352 | **repli** du palier d'une compétence sur `cycle.targetLevel` |
| `LearningPlanView.tsx` (web) | 493-496 | « Palier en construction : … » + rail |
| `PlanProgressView.tsx` (web) | 229 | rail |
| `plan-domain.ts` (web) | 137-138 | même phrase que `plan_labels.dart:780` |

⚠️ **`plan_groups.dart:352` est un piège** : il fait `planSkillLevel(plan, skillId) ?? plan.cycle?.targetLevel`. Avec des acquisitions de paliers **différents** selon le domaine, ce repli affichera un palier faux dès qu'une compétence n'est pas retrouvée. À traiter en Phase 3.

**Rayon d'explosion** : 4 points backend, 9 points front. Le libellé « votre plan construit d'abord votre B1 » devient **ambigu** dès qu'EE construit B1 et EO construit B2 — c'est une décision d'écriture, pas seulement de code (§C.4).

---

### Q2 🔴 — Couverture de contenu par compétence

**EE / EO — couverture parfaite, uniforme.**

| Section | Palier | Compétences | Avec ≥1 sujet | Petits sujets | Min/max par compétence |
|---|---|---|---|---|---|
| EE | A2 | 8 | **8** | 120 | 15 / 15 |
| EE | B1 | 11 | **11** | 165 | 15 / 15 |
| EE | B2 | 5 | **5** | 75 | 15 / 15 |
| EO | A2 | 8 | **8** | 120 | 15 / 15 |
| EO | B1 | 8 | **8** | 120 | 15 / 15 |
| EO | B2 | 8 | **8** | 120 | 15 / 15 |

**720 petits sujets actifs, 15 par compétence, aucun trou.**

**CO / CE — autre mécanique, à ne pas confondre.** Les 6 compétences de palier CO/CE ont **0 `skill_prompts`**, et c'est normal : `RecommendedExerciseSelector.targetedQcmSeries` (`:170`) ne choisit aucun contenu — il ouvre une **série ciblée** dont le tirage se fait au démarrage de la session, sur `questions` filtrées par palier.

| Palier | Questions CO actives | Questions CE actives |
|---|---|---|
| A2 | 134 | 206 |
| B1 | 214 | 205 |
| B2 | 212 | 205 |

**Conclusion Q2 : le chantier moteur n'est pas bloqué par le tagging du catalogue.** Le filtre §8 doit quand même exister (une compétence EE/EO dont tous les sujets seraient désactivés doit sortir du pool), mais il ne coupera rien avec les données d'aujourd'hui. ⚠️ Le filtre doit avoir **deux branches** : expression ⇒ « ≥1 `skill_prompt` actif » ; compréhension ⇒ « ≥1 `question` active à ce palier », **jamais** la même requête.

Note : `PlanSeanceBuilder.build` écarte déjà une priorité **sans exercice** (« cas normal, jamais une erreur ») — un embryon du filtre §8, mais placé **après** la sélection et **seulement** pour la séance, pas pour les compteurs.

---

### Q3 — `MAX_PRIORITIES` est-il utilisé ailleurs ?

**Deux usages en production, deux rôles différents** :

| Lieu | Rôle | À changer ? |
|---|---|---|
| `LearningPlanPriorityResolver.java:183` | `.limit(MAX_PRIORITIES)` sur la liste des **fragilités observées** | 🟡 c'est déjà un plafond d'affichage — mais il tronque **avant** le ranking, donc à revoir aussi |
| `LearningPlanService.java:216` | **budget** passé au sélecteur d'acquisitions | 🔴 c'est le trou principal |

Plus 3 tests : `LearningPlanAcquisitionIT:231`, `LearningPlanServiceTest:1594`, `LearningPlanPriorityResolverTest:81` — le second (`= MAX_PRIORITIES - 3`) **gèle explicitement le comportement fautif** et devra être réécrit, pas supprimé.

Aucun autre usage. `DiagnosticAnalysisValidator.MAX_PRIORITIES_PER_PRODUCTION = 2` est **une autre constante**, sans rapport (plafond de priorités par production LLM).

---

### Q4 — `READY_FOR_VALIDATION` existe-t-il ?

**Oui, sous trois noms différents selon le grain — ne rien créer.**

| Concept du brief | Existe sous | Où |
|---|---|---|
| `REINFORCEMENT` | `PlanActionNature.A_RENFORCER` | `enums/PlanActionNature.java:71` |
| `TO_ACQUIRE` | `PlanActionNature.A_ACQUERIR` | `:91` |
| `READY_FOR_VALIDATION` | `PlanActionNature.A_VERIFIER` + le booléen `readyForReassessment` | `:78`, `LearningPlanPriorityDto:116`, `PlanSeanceItemDto:110` |
| `masteryStatus` | `SkillMasteryState` (`PRIORITY`/`TO_REINFORCE`/`CONSOLIDATING`/`SOLID`) | `enums/SkillMasteryState.java` |
| statut d'observation | `LearningPlanSkillStatus` (`NOT_OBSERVED`/`PRIORITY`/`TO_REINFORCE`/`SOLID`) | `enums/LearningPlanSkillStatus.java` |

Le moteur V4.2 a en plus `ProgressionStatus.WATCH` et `RecommendationReasonCode.READY_FOR_REASSESSMENT` (`progression/domain/`). Le sélecteur de vérification existe : `ReassessmentExerciseSelector`.

🛑 `docs/regles/plan.md:568-590` fige la **réconciliation des trois vocabulaires** et `SkillLabelsTest` gèle les libellés. Renommer en `masteryStatus`/`planNature`/`TO_ACQUIRE` coûterait 3 fronts + le test de libellés **pour zéro gain fonctionnel**. Le brief dit lui-même que ses noms sont conceptuels : **je propose de garder les noms existants** (§C.3).

---

### Q5 — `progression-config-v1.json` existe-t-il ?

**Oui.** `backend_sejourfr/src/main/resources/progression/progression-config-v1.json`, chargé par `sejourfr.progression.engine-version` (`application.yaml:1334`, défaut `1`).

Clés actuelles : `engineVersion`, `weightEpoch`, `recencyHalfLifeDays`, `sourceWeights`, `assistanceFactors`, `independenceFactors`, `independence`, `confidenceK`, `thresholds`, `strongEvidence`, `qualificationGates`, `microEvidenceCaps`, `aiScoring`, `visibleProgress`, `receptiveSeriesBlueprint`, `shadowValidation`, `maintenance`.

Mode : `sejourfr.progression.mode` = **`SHADOW`** par défaut (`application.yaml:1329`).

🔴 **Contradiction avec §11 du brief.** Le YAML dit, ligne 1330-1333 : *« Une nouvelle calibration = un nouveau fichier de config + cette version incrémentée + un replay contrôlé (§29). **Jamais une édition d'un fichier déjà livré**. »* Or §11 demande d'ajouter `ranking.weights.*` et `display.*` à `progression-config-v1.json`. Deux options, à arbitrer (§C.2) :
- **v2 du fichier** + `PROGRESSION_ENGINE_VERSION=2` — respecte la règle, mais couple les plafonds d'affichage du Plan au versionnage du moteur de progression, qui n'a rien à voir ;
- **fichier de config distinct** (`plan-config-v1.json`), versionné selon la même doctrine — plus propre sémantiquement, un mécanisme de chargement de plus.

---

### Q6 — `PlanDomainDto` est-il consommé à l'identique par mobile et web ?

**Oui, les deux miroirs sont complets et alignés champ pour champ.**

| Champ | Backend | Mobile | Web |
|---|---|---|---|
| `epreuve`, `evaluated`, `niveau`, `priority` | ✔ | `diagnostic_models.dart:1365+` | `types.ts:1317+` |
| `consolidatedLevel`, `blockingLevel`, `paliers`, `taches` | ✔ | ✔ | ✔ |
| `skills[]` (24 en expression, 3 en compréhension) | ✔ | ✔ | ✔ |
| `fragileSkillCount` / `solidSkillCount` / `notObservedSkillCount` | ✔ | `:1452-1455` | `types.ts:1345-1359` |

**Ce qui casse si on l'enrichit : rien** — l'ajout est additif, les deux fronts replient sur `0` / `[]` un champ absent. Trois précautions :

1. 🔴 **`notObservedSkillCount` est déjà ambigu.** Le serveur compte **tous** les `NOT_OBSERVED` ; le mobile recompte localement en **excluant** les acquisitions (`diagnostic_result.dart:394-397`, `:470`). Les deux nombres divergent dès qu'une acquisition existe. Ajouter `acquireCount` (§16) impose de **trancher la définition** de `notObservedSkillCount` et de la re-geler des deux côtés.
2. Le web n'a **pas** de groupage `notObserved` équivalent visible dans `DiagnosticReport.tsx` — à vérifier en Phase 3 (`DiagnosticReport.tsx:339` mappe bien `A_ACQUERIR → "ACQUIRE"`, donc la parité de nature existe).
3. `admin_sejourfr` ne consomme pas `PlanDomainDto` (vérifié) : deux surfaces à aligner, pas trois.

---

### Q7 — Où est Sticky Today, et sur quoi repose sa résolution ?

**Il n'y a ni table, ni colonne, ni graine — et c'est documenté comme un choix.** `PlanSeanceBuilder.java:52-78` :

> *« Cette stickiness est **acquise par construction** […] la séance ne lit **jamais** l'horloge : aucune méthode ne reçoit de `Clock` ni de `LocalDate`. Deux lectures à deux dates différentes, sans action du candidat, rendent la même séance. »*

Critère de sortie : `SkillMastery.transferProven()` (`SkillMasteryEngine`), pas une date.
Plafond : `PlanSeanceBuilder.MAX_ITEMS = 3` — **constante Java publique**, à déplacer en config si §11 est retenu.

**Conséquence pour §12** : la règle « au plus 1 domaine secondaire sur 3 » s'insère naturellement dans `PlanSeanceBuilder` (qui ordonne et borne déjà), **sans** rien persister. ⚠️ Mais elle introduit un **choix dépendant du rang du domaine** : il faudra vérifier que deux lectures successives sans action rendent toujours la même séance (l'invariant de déterminisme ci-dessus), notamment quand deux domaines sont à égalité d'urgence.

---

### Q8 — Ce que le dépôt affirme et qui contredit §2

| Fichier | Ligne | Affirmation | Statut |
|---|---|---|---|
| `PlanCycleDto.java` | 19-22 | « `targetLevel` est le cran AU-DESSUS de `startingLevel` » (= plancher global) | 🔴 à amender |
| `PlanCycleResolver.java` | 55-57 | « Le palier visé est le cran au-dessus, jamais l'objectif directement (brief §37) » | 🔴 à amender |
| `PlanCycleResolver.java` | 202-210 | javadoc de `palierVise` : « premier cran strictement au-dessus du **niveau mesuré** » | 🔴 à amender |
| `PlanCycleResolver.java` | 353-359 | javadoc de `priorite` : « le Plan cible le domaine qui bloque le palier **courant** (brief §93), pas celui qui est déjà devant » | 🔴 à amender |
| `PlanAcquisitionSelector.java` | 56-60 | « elle appartient au **palier que le cycle construit** en expression » | 🔴 à amender |
| `docs/regles/plan.md` | 594-599 | même règle, + « le palier **global** du cycle peut dépasser » celui de la compréhension | 🔴 à amender |
| `docs/plan/BRIEF…TCF_V2.md` | 1255-1271 (§37) | « niveau actuel A2 → premier cycle cible B1 » | 🟡 amendé indirectement : « niveau actuel » devient celui du domaine |
| `docs/plan/BRIEF…TCF_V2.md` | 1315-1325 (§39) | `globalLevel = min(CO, CE, EO, EE)` sert « au Plan » | 🟡 reste vrai pour la confirmation, plus pour l'apprentissage |
| `plan_labels.dart` 780 · `plan-domain.ts` 137 | | « Votre plan construit d'abord votre {palier} » | 🟡 libellé à réécrire (§C.4) |

🔴 **Le §93 ne dit PAS ce que le brief lui fait dire.** Texte exact (`BRIEF…TCF_V2.md:2714-2732`) :

> *« objectif cycle B1 / CE montre B2 / EO montre A2 → **Ne pas forcer CE à travailler B1**. Le domaine CE peut être en entretien / pas prioritaire. Le Plan cible le domaine qui bloque le palier global. »*

Le §93 interdit de faire **redescendre** un domaine avancé — c'est exactement le §17 du brief v2. Il ne dit nulle part qu'un domaine avancé ne reçoit **rien**. **C'est l'implémentation qui a durci « pas prioritaire » en « zéro action »**, pas la doctrine. L'amendement §2 est donc **beaucoup moins lourd que le brief ne le suppose** : il porte sur §37/§39 (le palier se lit sur le niveau global), pas sur §93.

Autre point à consigner : `docs/decisions/contradictions-ouvertes.md` **#3 (non tranchée)** porte sur le **coût du Plan** (20 requêtes / +1 / 19), verrouillé par deux tests qui exigent une **égalité** de statements. Ce chantier touchera ce compte — la contradiction devra être tranchée dans le même lot, sinon les tests de coût deviennent inarbitrables.

---

### Q9 — Le freemium est-il appliqué au calcul ou à l'affichage ?

**À l'affichage, et c'est déjà exactement ce que §20 demande.**

- `LearningPlanService.java:54` : *« rien n'est masqué. Seul un `locked` est posé, décidé par `SkillAccessService` »*.
- Aucun `filter` sur `locked` dans les sélecteurs : le flag est **posé** sur chaque priorité (`:289`), acquisition (`:300`), compétence observée (`:312`), compétence de domaine (`PlanDomainSkillResolver:120`) et exercice (`RecommendedExerciseSelector:181`).
- `PlanFocusResolver.focus(actionable, acquisitions)` désigne **la compétence ouverte d'office** au compte gratuit — donc le freemium **lit** le pool, il ne le tronque pas.
- Doctrine en vigueur : `docs/decisions/contradictions-ouvertes.md` **#1 ✅ TRANCHÉE**, formulation B — *« on floute l'ACTION pas encore accessible, jamais le RÉSULTAT mesuré »*.

**Rien à refactorer pour §20.** En revanche l'instrumentation demandée (`plan_curtain_shown`, etc.) n'existe pas : à créer en Phase 4, en respectant `docs/regles/mesure-audience.md`.

---

### Q10 — Combien de diagnostics ont `targetLevel > levelEstimate AND SOLID AND HIGH` ?

SQL sur les 22 analyses en base (20 portent un niveau). **Échantillon petit — à lire comme un signal, pas comme une mesure.**

| Section | Niveau estimé | Palier compétence | `SOLID`+`HIGH` | Observations | Taux |
|---|---|---|---|---|---|
| EE | A2 | B1 | 28 | 50 | 56 % |
| EE | A2 | B2 | 0 | 10 | 0 % |
| EE | B1 | B2 | 0 | 1 | 0 % |
| EO | A2 | B1 | 2 | 7 | 29 % |
| EO | A2 | B2 | 4 | 6 | 67 % |
| **EO** | **B1** | **B2** | **12** | **12** | **100 %** |

Distribution globale des statuts observés :

| Section | `PRIORITY` | `TO_REINFORCE` | `SOLID` |
|---|---|---|---|
| EE | 2 | 34 | 51 |
| EO | **0** | 10 | 57 |

**Deux signaux nets, à ne pas confondre.**
1. **EO `B1 → B2` : 12/12 en `SOLID`/`HIGH`.** Aucune compétence B2 n'a jamais été jugée fragile chez un candidat estimé B1 à l'oral. Sur 12 observations, ce n'est pas une preuve — mais le taux de 100 % justifie de continuer à mesurer avant d'ouvrir massivement les acquisitions B2 en EO (§28).
2. **L'EO ne produit jamais de `PRIORITY` et très peu de `TO_REINFORCE`** (10 contre 57). Le déséquilibre EE/EO est structurel, pas propre au compte de test — il explique pourquoi c'est *toujours* l'EO qui se retrouve sans action.

🛑 Aucune conclusion actionnable à ce stade : trop peu de lignes. Le guard §28 ne doit pas être écrit sur cet échantillon.

---

## B. Ce que l'audit change dans le plan d'exécution

| Point du brief | Ce que l'audit établit | Conséquence |
|---|---|---|
| §8 filtre de faisabilité | couverture 100 % EE/EO | **Non bloquant**. À construire quand même, en 2 branches (prompts / questions) |
| §11 config | `progression-config-v1.json` est **livré**, non éditable | Arbitrage §C.2 avant de coder |
| §5 `nextTargetLevel` | `prescriptionLevel` V4.2 fait déjà ça | Arbitrage §C.1 — **le plus important** |
| §16 renommages | 3 enums existants, libellés gelés | Garder les noms actuels (§C.3) |
| §12 composition | `PlanSeanceBuilder` ordonne et borne déjà | Insertion naturelle, vérifier le déterminisme |
| §20 freemium | déjà conforme | Rien à faire, sauf l'instrumentation |
| §2 amendement | §93 mal cité | Amendement **plus étroit** que prévu |
| Coût | contradiction #3 non tranchée | À trancher dans le même lot |

---

## C. Les quatre arbitrages à rendre avant le GO

### C.1 🔴 Qui est l'autorité du palier par domaine ?

`ProgressionPlanBridge.prescriptionLevel(userId, section, objectif)` rend déjà **le seul niveau que le Plan a le droit de proposer** pour un domaine (`ProgressionPlanBridge.java:46-69`), en s'appuyant sur `DomainProjection` du moteur V4.2. Deux limites aujourd'hui : il rend `Optional.empty()` en **SHADOW**, et il refuse tout ce qui n'est **pas de la compréhension**.

Trois voies :

| Voie | Description | Risque |
|---|---|---|
| **A** — étendre le pont | lever le `!section.isComprehension()` et passer le moteur en `ACTIVE` pour l'expression | Le YAML exige des métriques shadow validées (précision `SOLID` ≥ 70 %) avant `ACTIVE`. On ne les a pas. |
| **B** — règle simple dans `PlanCycleResolver` | `nextTargetLevel(domainLevel, objectif)` en dur, le moteur reste en shadow | 🔴 **deuxième autorité** sur la même question — exactement le défaut le plus cher du dépôt (table des paliers en 6 copies) |
| **C** — hybride explicite | une seule méthode `palierDuDomaine(section)` qui **appelle** le pont, et retombe sur la règle simple quand il rend `empty()` — le patron **déjà utilisé** à `PlanCycleResolver.java:317-326` pour la compréhension | Le patron existe et est documenté. Une seule porte d'entrée, deux implémentations derrière, la bascule reste une variable d'environnement. |

**Ma recommandation : C.** C'est le seul chemin qui n'invente pas une autorité concurrente et qui laisse la bascule `SHADOW → ACTIVE` faire son travail plus tard.

### C.2 🟡 Où vivent les nouvelles constantes ?

`progression-config-v1.json` est **livré** et le YAML interdit de l'éditer. Choisir :
- **v2 du fichier moteur** + `PROGRESSION_ENGINE_VERSION=2` (couple les plafonds d'UI au versionnage du moteur) ;
- **`plan-config-v1.json` distinct**, même doctrine de versionnage (recommandé — `MAX_PRIORITIES`, `MAX_ITEMS` et les poids de ranking ne sont pas des paramètres du moteur de preuves).

### C.3 🟡 Renommer les champs, ou garder les noms du dépôt ?

Le brief nomme `masteryStatus` / `planNature` / `TO_ACQUIRE` / `REINFORCEMENT` / `READY_FOR_VALIDATION`. Le dépôt a `masteryState` / `nature` / `A_ACQUERIR` / `A_RENFORCER` / `A_VERIFIER`, mirrorés sur 2 fronts et **gelés par `SkillLabelsTest`**. Renommer = 3 surfaces + tests, gain fonctionnel nul.
**Recommandation : garder les noms existants**, le brief indiquant lui-même que les siens sont conceptuels.

### C.4 🟡 Que dit le Plan quand deux domaines construisent deux paliers différents ?

« Votre plan construit d'abord votre **B1** » (mobile `plan_labels.dart:780`, web `plan-domain.ts:137`) devient faux dès qu'EE construit B1 et EO construit B2. Trois options : garder la phrase sur le palier **global** (et l'expliciter), la passer **par épreuve** sur la carte de domaine, ou la supprimer du héros. **Décision d'écriture produit** — je ne la prends pas seul.

---

## D. Ce qui n'a pas pu être vérifié

- Le comportement réel du Plan sur le compte de test n'a **pas** été exécuté (pas de backend lancé) : les chiffres du §1 du brief sont dérivés de la base + de la lecture du code, et confirmés par la capture d'écran (« 1 sur 5 »).
- La parité web du groupage « non observée » sur la carte d'épreuve (`DiagnosticReport.tsx`) n'a été vérifiée que sur `A_ACQUERIR`.
- Aucune mesure de performance : l'impact du calcul complet par domaine sur les 20 requêtes du Plan reste à établir en Phase 1 (contradiction #3).

---

## 🛑 STOP 1

Audit rendu. **Aucun fichier du dépôt n'a été modifié.**
J'attends un **GO explicite**, et les réponses aux arbitrages **C.1** (bloquant) et **C.2** (bloquant pour §11). C.3 et C.4 peuvent être tranchés plus tard, mais avant la Phase 3.
