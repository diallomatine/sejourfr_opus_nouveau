# Audit — Phase 0 de `spec-plan-tcf-parcours-evaluations-v2.md`

> Rapport demandé par la spec §0.1 et §20 (« Phase 0 — Audit obligatoire, aucune ligne de code »).
> **Aucun code écrit. Aucune migration créée. En attente du go du propriétaire.**
> Branche : `feature/refonte-l1-socle` (branche courante, pas de nouvelle branche).
> Date : 2026-09-17.

---

## Verdict en trois phrases

1. **Le moteur pédagogique que la spec suppose existe déjà, en entier** : priorités sourcées,
   rang de gravité déterministe, quota d'étape à 5, maîtrise, niveau estimé par épreuve, étapes
   « Évaluer mon niveau », freemium opposable, ordre des épreuves. Il n'y a **rien à recalculer**.
2. **Ce que la spec ajoute réellement, c'est une FILE PERSISTÉE** (`journey` / `journey_cycle` /
   `journey_step`) là où le Plan est aujourd'hui **entièrement dérivé à la lecture**. C'est un
   changement d'architecture, pas un enrichissement : il faut l'assumer comme tel, parce qu'il
   heurte de front l'invariant « dérivé serveur ⇒ jamais persisté » du `CLAUDE.md` racine.
3. **Quatre points de la spec sont inapplicables en l'état** et demandent un arbitrage avant tout
   code : R1 vs les observations de compréhension, R8 vs le plafond freemium de 2 sujets sur 5,
   `TRAIN_SKILL` sur CO/CE (qui n'ont ni tâche ni petit sujet), et la collision du mot « cycle ».

---

# A. Les 12 points de §20

## 1. Types d'`Attempt` et comment distinguer les cinq natures d'évaluation

Tout est déjà discriminable sur la seule ligne `attempts`, **sans requête supplémentaire**.

| Nature (vocabulaire spec) | Discriminant technique | Fichier |
|---|---|---|
| **Diagnostic rapide** | `diagnostic_sessions` (1 tâche EE + 1 tâche EO **facultative**) ; ses productions portent `production_tasks.diagnostic_code`, donc `ProductionSubmission.isDiagnostic()` | `entity/DiagnosticSession.java`, `entity/ProductionSubmission.java` |
| **Diagnostic complet (4 épreuves)** | `tcf_diagnostic_sessions` + `attempts.tcf_diagnostic_id IS NOT NULL` ; parent `epreuve=TCF_COMPLET`, 4 sous-attempts | `entity/TcfDiagnosticSession.java`, `entity/Attempt.java:66-79` |
| **Examen CO/CE isolé** | `type=MOCK_EXAM`, `epreuve=TCF_CO|TCF_CE`, `slot_number NOT NULL`, `parent_attempt_id NULL` | `entity/Attempt.java` |
| **Examen EE/EO isolé** | `epreuve=TCF_EE|TCF_EO`, `slot_number NOT NULL` | idem |
| **Examen blanc complet** | parent `epreuve=TCF_COMPLET`, `tcf_diagnostic_id NULL` ; sous-épreuves via `parent_attempt_id` | `service/FullTcfExamService.java` |
| **Entraînement** | `type=TRAINING` (QCM, série ciblée) ou production sans `slot_number` ni parent | `service/AttemptService.java` |

Trois enums portent tout : `AttemptType` (`TRAINING`/`MOCK_EXAM`/`REVIEW`), `EpreuveType`
(7 valeurs, `TCF_COMPLET` = conteneur), `AttemptMode`. **`TCF_STRUCTURE` est hors périmètre**
comme le veut le `CLAUDE.md` racine.

🛑 **Point de vigilance** : le discriminant « examen » côté **production** n'est pas `AttemptType`
mais `slot_number IS NOT NULL OR parent_attempt_id IS NOT NULL`
(`LearningPlanObservationService.isMockExam`, l.267-271). La spec devra reprendre **ce prédicat**
et non inventer le sien — il vit déjà en deux copies synchronisées par test
(`AttemptRepository.findProductionEpreuvesPassees`, `ProductionAccessService.isExamSession`).

⚠️ **Conséquence à noter** : les EE/EO du **diagnostic complet** sont des sous-attempts d'un parent
`TCF_COMPLET`, donc elles sont vues comme des **productions d'examen** (`MOCK_EXAM_EE/EO`), pas
comme un diagnostic. C'est cohérent avec la définition « épreuve mesurée » de la spec §2 — mais
c'est un fait à connaître, pas une déduction à refaire.

## 2. Où et comment sont produites les priorités, et existe-t-il un rang de gravité ?

**Une priorité n'est pas calculée : elle est LUE dans `learning_plan_observations`.**

- **Producteur expression (EE/EO)** : `LearningPlanObservationService.recordProduction`
  (l.54) — écrit une ligne par compétence renvoyée par le correcteur IA, avec `status`
  (`LearningPlanSkillStatus`), `confidence` (`ObservationConfidence`), `evidence`, `explanation`,
  `source_type`, `source_id` (= `production_submissions.id`), `subject_id` (= tâche).
- **Producteur compréhension (CO/CE)** : `ComprehensionObservationService.record` (l.152) — ventile
  les réponses **par niveau de question** et écrit une observation par (domaine × niveau)
  réellement représenté, vers `CO-A2 … CE-B2`. Plancher de fiabilité → `NOT_OBSERVED`.
- **Sélection et ORDRE** : `LearningPlanPriorityResolver.actionable(...)` — tri
  **déterministe** : `PRIORITY` avant `TO_REINFORCE`, puis **confiance décroissante**, puis
  observation la plus récente ; les compétences dont le transfert est prouvé ou dont la
  vérification a été rendue sortent.
- **Classement transverse** : `PlanActionRanker.classer(...)` — score additif, poids lus dans
  `resources/plan/plan-config-v1.json` (`natureWeights`, `domainPriorityWeights`,
  `confidenceWeights`, `levelGapWeight`).

**Réponse à la question posée** : il existe un **ordre total déterministe**, pas un entier
« severity_rank ». La colonne `journey_step.severity_rank` de la spec §6 est donc un **rang dans le
lot** (0,1,2) à dériver de cet ordre au moment de la création du lot — elle ne peut pas être
« lue » quelque part. C'est exactement ce que la spec dit (« rang dans le lot ») ; il fallait
confirmer qu'aucune valeur métier n'est disponible ailleurs.

🛑 **Il n'y a aucun plafond dans le moteur, et c'est voulu** (incident du 2026-08-25, documenté en
commentaire dans `LearningPlanService`) : `actionable` rend **tout**, l'affichage coupe
(`display.prioritiesMaxActions`). Le `maxPrioritiesPerLot: 3` de la spec est un **plafond de
production de file** — c'est-à-dire exactement l'inverse. Voir §B-5 : ce n'est pas forcément une
régression, mais ça doit être dit et assumé, pas glissé.

## 3. Où est calculé le niveau estimé par épreuve (pour l'écart au niveau cible) ?

**Deux lectures, volontairement différentes, et la spec doit choisir laquelle elle veut.**

| Lecture | Autorité | Règle | Usage actuel |
|---|---|---|---|
| **Plan** | `TcfProfileService.levelProfile(userId)` (l.149) | **meilleur** résultat par épreuve sur tout l'historique ; diagnostic en **repli** seulement | cycle de palier, domaines, `PlanCycleDto` |
| **Affichage** | `NiveauActuelEpreuveResolver` | **moyenne des 3 derniers examens qualifiants** (peut redescendre), arbitrage propriétaire du 2026-09-16 | écran Progrès, « Où vous en êtes » |

Toute la math CECRL est dans `TcfLevelEstimatorService` (score calibré 100-499, poids par strate,
plafond B2, plancher A1). `attempts.cecrl_level` est **persisté à la finalisation** — donc l'écart
au niveau cible est disponible sans recalcul.

➡️ **Recommandation** : R10 bis doit lire la **lecture Plan** (`TcfProfileService`), pas la lecture
d'affichage. Motif : la file est un objet du Plan, et un ordre de lots qui changerait parce qu'un
mauvais examen a fait redescendre une moyenne d'affichage réordonnerait le parcours sans qu'aucune
priorité n'ait bougé. **À faire confirmer** (§D-2).

## 4. API du moteur de maîtrise et événement de fin d'entraînement

- **Moteur** : `SkillMasteryEngine.evaluate(observations, now)` (l.86) → `SkillMastery`
  (`state`, `transferProven()`, `verificationSubmitted()`, `readyForReassessment`).
  Batch : `SkillMasteryResolver.fromObservations(...)` / `bySkillIds(...)`. **Jamais persisté.**
- **Quota d'étape** : `LearningPlanStep.PROMPTS_PAR_ETAPE = 5` (l.37) et
  `LearningPlanStep.Progress.completed()` = « les 5 sujets de l'étape ont été **traités** ».
  ➡️ C'est **déjà** le `trainSkillQuota: 5` de la spec, et `progress { done, quota }` de §16 est
  déjà servi sur `LearningPlanPriorityDto` (`stepAttemptedCount` / `stepPromptCount`).
- **Événement exploitable** :
  - expression → `SkillAttemptService` (écrit `user_skill_attempts`) puis, via l'analyse,
    `LearningPlanObservationService.recordProduction` ;
  - compréhension → `AttemptInteractionService.doFinish` (l.289) → `recordComprehension` (l.466) →
    `ComprehensionObservationService.record`.

🛑 **`doFinish` est LE point d'entrée unique de toute fin de session QCM** — entraînement,
révision, examen blanc, section de diagnostic. C'est une excellente nouvelle pour R7/R14 (un seul
endroit à brancher) et un **problème** pour R1 (voir §B-1).

⚠️ **Il n'existe aucun event Spring, aucun listener, aucune file** : tout est appelé en direct,
best-effort, `REQUIRES_NEW`. `onAssessmentCompleted` de la spec §7.2 devra suivre la même doctrine
(propre transaction, échec avalé, jamais bloquant pour la correction ni la réponse HTTP) — sinon un
bug d'orchestration fera échouer une soumission payante.

## 5. File de priorités existante, et ce qu'elle devient

**Il n'y a aucune file persistée. Le Plan est recalculé intégralement à chaque `GET /api/me/plan`.**

`LearningPlanService.get(userId)` (l.140) produit en une passe : `completedSteps` (5 max),
`currentPriority`, `nextPriorities`, `observedSkills`, `milestone`, `domaines`, `cycle`,
`domainesAEvaluer`, `seance`, `recentChanges`.

**Une seule chose est persistée**, et c'est instructif : `plan_pinned_priorities`
(`entity/PlanPinnedPriority.java`, une ligne `user × skill × pinned_at`), introduite le 2026-09-13
parce que la première place, recalculée, sautait d'une compétence à l'autre au milieu d'un cycle
(cas réel documenté : « EE3 à 0/5 remplacée par EO1 dès la première production orale »).
`PlanFocusResolver.epingler` (l.181) ne réécrit la ligne que lorsque la première place **change**.

➡️ **Lecture d'audit** : le dépôt a déjà rencontré le problème que la spec veut résoudre, et l'a
résolu par **le plus petit état persisté possible** (une épingle), pas par une file. La spec propose
le **grand** état persisté. C'est un choix légitime — la spec apporte en plus l'ordre, les
checkpoints et la mémoire des cycles, qu'une épingle ne donne pas — mais il faut savoir que
`plan_pinned_priorities` devient alors **redondant** et doit être **supprimé dans la même passe**
(règle « refonte = suppression immédiate de l'ancien » du `CLAUDE.md` racine).

Ce que la file **ne doit pas** absorber, sous peine de doublon :
`SkillMasteryEngine`, `TcfProfileService`, `PlanCycleResolver`, `PlanDomainAssessmentResolver`,
`PlanActionRanker`, `PlanContentAvailability`. La spec §0.4 le dit déjà ; ce point d'audit confirme
que la frontière est nette et tenable.

## 6. Composants actuels de l'écran Plan, et source de la carte « À faire maintenant »

**Web** (`web_sejoufr/`)
- `app/(app)/plan/page.tsx` + `app/_components/plan/LearningPlanView.tsx` (795 l.) — l'écran.
- `app/_components/plan/PlanBits.tsx`, `PlanLayout.tsx`, `PlanMilestoneCard.tsx`,
  `PlanDomainsSummary.tsx`, `PlanPaywallCard.tsx`, `AffinerPlanCard.tsx`, `plan.module.css`.
- Sous-écrans : `/plan/domaine/[domaine]`, `/plan/competences`, `/plan/progression`, `/plan/evolution`.
- Libellés et règles d'affichage : `web_sejoufr/lib/plan-domain.ts`.

**Mobile** (`mobile_sejourfr/`)
- `lib/screens/plan/plan_screen.dart` + `widgets/plan_tcf_view.dart` (657 l.).
- `plan_labels.dart` (859 l.), `plan_step_labels.dart`, `plan_groups.dart`, `plan_task_path.dart`,
  `widgets/plan_path_section.dart`, `widgets/plan_task_row.dart`, `widgets/plan_tokens.dart`.

**La carte « À faire maintenant » a une seule autorité, partagée, et elle est CÔTÉ FRONT** :
`planNowCard(plan)` — `web_sejoufr/lib/plan-domain.ts:639` ⇄
`mobile_sejourfr/lib/screens/plan/plan_now_card.dart:129`, miroirs mot pour mot.

🛑 **Elle a SIX sites d'appel** (arbitrage du 2026-09-16, documenté en tête de `plan_now_card.dart`) :

| Écran | Web | Mobile |
|---|---|---|
| Plan | `LearningPlanView.tsx:505` | `plan_tcf_view.dart:292` |
| Accueil | `app/(app)/dashboard/page.tsx:549` | `home_screen.dart:328` |
| Réviser | `lib/reviser.ts:135` | `reviser_labels.dart:118` |

➡️ **Conséquence directe sur la spec §10 et §15** : faire de `current` un champ servi ne suffit pas.
Il faut migrer **les six** sites dans la même passe, sinon l'Accueil et Réviser continueront de
composer leur propre « à faire maintenant » — précisément la contradiction que le 2026-09-16 a
corrigée. Le plan d'implémentation §24 (« Phase 4 — Web puis mobile ») sous-estime ce périmètre :
ce sont **trois écrans × deux fronts**, pas un écran.

**Timeline déjà existante** : un « chemin vers l'objectif » est déjà servi et affiché
(`PlanPathStepDto`, `PlanPathStepKind` = `COMPLETE_PROFILE`/`BUILD_LEVEL`/`STABILIZE`,
`PlanPathStepStatus` = `DONE`/`CURRENT`/`UPCOMING`, rendu par `plan_path_section.dart` et
`planPathStepTitle` côté web). Ce n'est **pas** la timeline de la spec §12 (il s'agit de paliers
CECRL, pas d'étapes), mais le vocabulaire, les statuts et le rendu sont déjà là et **réutilisables
brique pour brique**. La spec devra dire si les deux timelines cohabitent ou si l'une remplace
l'autre (§D-4).

**Le bloc à supprimer (§11)** existe bien : « Votre parcours — Tâche X » =
`parcoursDeLaTache(plan, plan.currentPriority)` côté web (`LearningPlanView.tsx:288` et `:395`) et
`plan_task_path.dart` + `plan_task_row.dart` côté mobile.

**Kit obligatoire** : le `CLAUDE.md` racine impose que les écrans de plan passent par
`SejourKit.tsx` ⇄ `sejour_kit.dart`. Toute primitive manquante pour la timeline §12-13 (rail,
marqueur double-cercle, badge `EXAMEN`) doit être ajoutée **dans les deux kits dans la même passe**.

## 7. Mécanisme de gating Premium existant

Trois autorités, aucune duplication, toutes opposables serveur :

| Objet | Autorité | Règle |
|---|---|---|
| Compétence / petit sujet | `SkillAccessService` (`resolve`, `assertCanProduce`, `assertCanTrain`) | gratuit : 1ʳᵉ compétence de chaque tâche + **la priorité n°1 du Plan** + `CO-A2`/`CE-A2` ; **2 sujets sur 5** par compétence (`FREE_PROMPTS_PER_SKILL = 2`, l.108) |
| Examen blanc QCM | `AttemptService.enforceMockExamSlotAccess` (l.484) | **slot 1 offert et rejouable à volonté** ; slots 2+ → abonnés du module |
| Production EE/EO | `ProductionAccessService` | gratuit : 1 essai d'entraînement **à vie** par épreuve + 1 examen blanc production offert |
| Réévaluation (diagnostic) | `TcfReassessmentService.eligibilite` (l.98) | `PREMIUM_REQUIRED` (commerciale) / `INTERVAL_NOT_ELAPSED` (temporelle, 14 j, ouverte par une étape franchie) |

Les DTO portent un simple `locked`, **calculé à la lecture**. C'est exactement ce que demande R16 :
rien à construire.

⚠️ **Deux faits qui cassent la spec** (voir §B-2 et §B-3) :
- un compte gratuit plafonne à **2/5** sujets, donc `Progress.completed()` est **structurellement
  faux** pour lui — c'est un arbitrage produit explicite (« la vérification est premium »), pas un
  bug. Une file avec un seul `CURRENT` le bloque donc **définitivement** sur l'étape 1.
- le tirage d'un examen module est **aléatoire** pour un compte inscrit
  (`composeModuleExam(..., deterministic=false)`, `AttemptService.java:916`) et déterministe
  seulement pour les invités (l.708). Donc les checkpoints CO/CE répétés mesurent bien quelque
  chose de neuf à chaque fois, gratuitement. **Bonne nouvelle**, et elle n'était pas acquise.

## 8. Gestion actuelle du niveau cible

- `users.target_procedure` (`CSP`/`CR`/`NAT`) et `users.target_level` (`A2`/`B1`/`B2`).
- **Autorité unique** : `TargetProcedure.getRequiredTcfLevel()` et
  `TargetProcedure.niveauVise(procedure, declare)` — **la démarche fait plancher, jamais plafond**.
  Miroirs gelés par test sur les 3 fronts. Ne jamais réécrire cette table.
- Lecture métier : `TcfDiagnosticService.cible(User)` (l.192), `PlanCycleDto.objectiveLevel`,
  `PlanDomainTargetLevelResolver.parSection(...)` (palier **par domaine**, pas global).
- Les deux champs sont remis à `null` par l'anonymisation de compte (`User.java:121-122`).

🛑 **Un niveau cible peut être `null`** (ni démarche ni niveau déclarés). La clé
`(userId, targetLevel)` de R18 est donc **incomplète** : il faut décider du repli. Voir §D-3.

⚠️ **R18 dit « le parcours est identifié par `(userId, targetLevel)` »**, mais le niveau visé est
**dérivé** de deux colonnes, dont l'une fait plancher. Un candidat CSP qui déclare B2 puis retire sa
déclaration passe de B2 à A2 : le parcours B2 est conservé, l'A2 est bootstrappé. Comportement
correct au regard de R18, mais il faut qu'il soit voulu.

## 9. Historique disponible : peut-on lister toutes les évaluations exploitables ?

**Oui, et les deux requêtes existent déjà**, par épreuve, triées `finished_at DESC`, paginables :

- **CO/CE** : `AttemptRepository.findQcmEpreuvesPassees(userId, epreuve, pageable)` —
  `type=MOCK_EXAM AND finished_at IS NOT NULL AND civic_diagnostic IS NULL AND EXISTS(answers)`.
  🛑 Les sous-épreuves du **diagnostic complet** y comptent depuis le 2026-09-16 (révocation
  explicite de l'exclusion V049 : même tirage, mêmes 25 items, même durée).
- **EE/EO** : `AttemptRepository.findProductionEpreuvesPassees(...)` —
  `finished_at IS NOT NULL AND (slot_number IS NOT NULL OR parent_attempt_id IS NOT NULL) AND
  EXISTS(production_submissions)`. **L'entraînement libre est exclu, volontairement.**
- **Diagnostic rapide** : à part, `diagnostic_production_analyses` (ses attempts n'ont ni slot ni
  parent).
- **Priorités de n'importe quelle évaluation passée** : `learning_plan_observations`, indexée
  `(user_id, observed_at DESC)` et `(user_id, skill_id, observed_at DESC)`, avec `source_type` +
  `source_id` sur chaque ligne. **C'est la table qui rend R19 réalisable** : on retrouve, pour
  chaque évaluation, exactement les compétences qu'elle a désignées.

**Évaluations inexploitables, et pourquoi** (à écarter du bootstrap) :
1. `ai_evaluations.evaluabilite = NON_EVALUABLE` (V041/V042 : production vide, quasi vide, langue
   non française, recopiage de consigne) — **aucun niveau, aucune priorité**.
2. Sessions QCM terminées **sans aucune réponse** — déjà écartées par l'`EXISTS(answers)`.
3. Observations `NOT_OBSERVED` — 🛑 `null = inconnu, jamais mauvais` : ne **jamais** les
   transformer en priorité.
4. Attempts invités (`user_id IS NULL`) — personne à qui attribuer.
5. Diagnostics complets `IN_PROGRESS` : leurs sections **terminées** comptent, le parent non.

## 10. Les priorités dépendent-elles du niveau cible ? Recalculables pour un autre niveau ?

**Réponse nuancée, et c'est la réponse dont R18/R19 ont besoin.**

- **Les priorités observées ne dépendent PAS du niveau cible.** Une ligne
  `learning_plan_observations` porte une compétence et un verdict ; le niveau cible n'entre pas dans
  sa production. Elle reste donc **valable telle quelle** pour n'importe quel parcours.
- **Ce qui dépend du niveau cible, c'est la SÉLECTION** :
  - `skills.target_level` porte le palier **pédagogique interne** de chaque compétence
    (🛑 non officiel, cf. `CLAUDE.md` racine) ;
  - `PlanDomainTargetLevelResolver.parSection(...)` résout le palier **en construction par
    domaine** ;
  - `PlanAcquisitionSelector` ne propose que des compétences du palier en construction jamais
    travaillées ;
  - `PlanActionRanker` pondère par `levelGapWeight` (écart domaine ↔ objectif).

➡️ **Donc oui, c'est recalculable pour un autre niveau, sans aucun appel LLM et sans migration.**
Les fragilités mesurées sont conservées ; seul le palier en construction et le classement changent.
R19 point 3 (« extraire les priorités pour le niveau cible du parcours ») est réalisable **en
réutilisant les sélecteurs existants**, à condition de ne pas réécrire la table des paliers.

⚠️ **Une nuance qui compte** : en **compréhension**, la compétence **est** le palier (`CO-A2`,
`CO-B1`, `CO-B2`). Un changement B1 → B2 change donc littéralement l'ensemble des compétences
candidates. En **expression**, les 6 tâches existent à tous les paliers et les fragilités se
transposent. Les deux familles ne se comportent pas pareil au changement d'objectif : à tester
explicitement (test §18-23).

## 11. Volume à bootstrapper : création paresseuse ou migration batch ?

Mesure faite en **SQL sur la base locale de dev** (aucune requête payante, aucun LLM) :

| Mesure | Base `sejourfr_db` (dev) |
|---|---|
| Utilisateurs | 34 (33 non supprimés) |
| dont `target_level` renseigné | 17 |
| `attempts` | 674 |
| `attempts` TCF `MOCK_EXAM` terminés | 105 |
| `diagnostic_sessions` (rapide) | 18 |
| `tcf_diagnostic_sessions` (complet) | 6 |
| `learning_plan_observations` | 455 |
| Utilisateurs avec ≥ 1 observation | 18 |

🛑 **Ce sont des chiffres de DEV, pas de prod** : je n'ai pas accès à la base de production depuis
cette session. À l'échelle observée, et compte tenu du fait que le produit n'est pas encore lancé
(examens obligatoires au 1ᵉʳ janvier 2026), **la création paresseuse à la première ouverture du Plan
est la seule option raisonnable** :

- une migration batch devrait rejouer `TcfProfileService` + `SkillMasteryEngine` par utilisateur,
  donc embarquer de la logique applicative dans une migration Flyway — ce que le dépôt n'a jamais
  fait et que `docs/migrations-flyway.md` décourage ;
- le bootstrap est **idempotent par construction** (`journey_assessment_event` unique sur
  `(journey_id, source_assessment_id)`), donc rien n'oblige à le faire d'avance ;
- un utilisateur qui n'ouvre jamais le Plan n'a pas besoin de parcours.

➡️ **Recommandation : création paresseuse, sans migration de données.** Les migrations Flyway se
limitent au DDL des 3 tables. Prochain numéro libre : **V066** dans `00_schema/` (dernier utilisé :
V065 ; `100_reference/` est à V114 — ne pas s'y tromper, les plages sont thématiques).

## 12. Écarts entre la spec et l'existant

Développé en §B. Résumé : **4 bloquants**, **5 arbitrages**, **6 ajustements de forme**.

---

# B. Écarts et conflits

## B-1. 🛑 BLOQUANT — R1 est faux aujourd'hui : un entraînement CO/CE crée des priorités

**R1** : « Micro-entraînement / petit sujet ciblé / exercice de révision **ne peuvent jamais
ajouter d'étapes** ».

**Réalité** : `AttemptInteractionService.doFinish` appelle `recordComprehension` pour **toute**
session TCF terminée — `TRAINING`, `REVIEW`, `MOCK_EXAM`, section de diagnostic confondues. Une
série ciblée de 20 questions CO-B1 écrit donc de vraies observations `TCF_CO`, qui deviennent de
vraies priorités. Et c'est **documenté comme voulu** (`ComprehensionObservationService`, javadoc) :
« en compréhension, une bonne réponse est une bonne réponse — il n'y a ni assistance ni filet dont
l'absence rendrait l'examen plus probant ».

En expression, R1 est en revanche **déjà respecté** : `SKILL_TRAINING` n'est jamais `isContextual()`
et ne peut pas confirmer une maîtrise.

**Trois issues possibles, toutes à arbitrer :**

| Option | Effet | Coût |
|---|---|---|
| **(a)** La file ne consomme que les observations dont `source_type` est une évaluation (`DIAGNOSTIC_*`, `MOCK_EXAM_*`) et, en compréhension, uniquement celles issues d'un attempt `MOCK_EXAM` | R1 respecté à la lettre ; le profil de niveau continue d'apprendre des entraînements | faible, filtre à un seul endroit ; **mais** un candidat qui ne passe que des séries ciblées n'aura jamais de file |
| **(b)** On garde le comportement actuel et on amende R1 pour la compréhension | aucun code ; cohérent avec la doctrine déjà écrite | la spec perd son invariant central |
| **(c)** On cesse d'écrire des observations sur les sessions `TRAINING` | R1 respecté partout | 🛑 **régression** : révoque une décision explicite et appauvrit le profil CO/CE |

➡️ **Ma recommandation : (a)**, avec R1 reformulé en « seules les évaluations **alimentent la
file** » (le profil, lui, continue d'apprendre de tout). C'est la seule option qui tient les deux
doctrines sans rien révoquer.

## B-2. 🛑 BLOQUANT — R8 + file à un seul `CURRENT` = compte gratuit bloqué à vie

- `LearningPlanStep.PROMPTS_PAR_ETAPE = 5`, `SkillAccessService.FREE_PROMPTS_PER_SKILL = 2`.
- `Progress.completed()` exige `attemptedCount >= 5` sur le périmètre **éditorial**, pas sur ce que
  l'accès ouvre. La javadoc est explicite : « un compte gratuit plafonne donc à 2/5 et ne bascule
  jamais : c'est un **arbitrage produit** (la vérification est premium), **ne pas le réparer** ».

**Conséquence sous la spec** : R8 ne résout une étape que par `MASTERED` ou `QUOTA_REACHED`. Un
compte gratuit n'atteindra ni l'un ni l'autre sur une étape d'expression. Avec **une seule étape
`CURRENT` par parcours** (§5) et **aucun ajout devant** (R4), son Plan se figera **définitivement**
sur l'étape 1 — alors qu'aujourd'hui il voit un Plan entier, cadenas compris, et que la
contradiction #1 du dépôt a été tranchée en ce sens (2026-08-21 : « le Plan reste intégralement
visible »).

**Options** :
- **(a)** `QUOTA_REACHED` se calcule sur le périmètre **ouvert au candidat** (2 pour un gratuit).
  🛑 Contredit frontalement l'arbitrage produit ci-dessus.
- **(b)** Une étape `CURRENT` **verrouillée** ne bloque pas la promotion : la file promeut la
  première étape `UPCOMING` **exécutable**, et l'étape verrouillée reste affichée avec son cadenas
  et son CTA paywall. La carte « À faire maintenant » montre alors l'étape verrouillée (R16 : « le
  Plan affiche toujours la vraie prochaine étape ») mais le parcours n'est pas mort.
- **(c)** `CURRENT` reste unique et bloquant, et on assume que le parcours d'un gratuit s'arrête à
  l'étape 1 — c'est-à-dire qu'on en fait un mur de paywall.

➡️ **Ma recommandation : (b)**, à condition que le propriétaire confirme que « bloqué » est bien
l'effet **non** souhaité. C'est un arbitrage produit, pas technique (§D-1).

## B-3. 🛑 BLOQUANT — `TRAIN_SKILL` n'a pas de sens tel quel sur CO/CE

Les compétences de compréhension **n'ont ni tâche ni petit sujet** (`SkillSection`, javadoc ;
`skills.task_code` nullable depuis V039). Leur entraînement est une **série ciblée de 20 QCM**
(`AttemptService.startComprehensionSeries`, l.298). Donc, pour une étape `TRAIN_SKILL` CO/CE :

- `task_code` est `null` → le sous-titre « Expression écrite · Tâche 1 » de §10 n'a pas d'équivalent ;
- il n'y a **aucun** compteur « x/5 petits sujets » → `progress { done, quota }` est indéfini ;
- `trainSkillQuota` ne peut pas se compter en « sujets » : l'unité naturelle est **la série**.

Et la carte §10 (« {trainSkillQuota} petits sujets · ~2 min chacun ») est **littéralement fausse**
pour la moitié du référentiel.

➡️ **À trancher** : soit le quota CO/CE se compte en **séries terminées** (valeur distincte à
configurer, ex. 2), soit la file ne porte pas de `TRAIN_SKILL` sur CO/CE et la compréhension
n'entre dans la file que par ses **checkpoints** (ce qui appauvrit beaucoup le parcours). Voir §D-5.

## B-4. 🛑 BLOQUANT — collision du mot « cycle », et de « étape »

Le dépôt utilise déjà, servis aux fronts et affichés :

| Nom existant | Sens existant | Sens dans la spec |
|---|---|---|
| `PlanCycleDto` / `PlanCycleResolver` / `PlanCycleState` | **cycle de palier CECRL** (d'où part le candidat, quel palier se construit, gate par examen blanc complet) | `journey_cycle` = **lot + son checkpoint** |
| « étape » (`LearningPlanStep`, `PlanSkillStepState`, `completedSteps`) | les **5 petits sujets** d'une compétence | `journey_step` = une ligne de la file |
| `PlanPathStepDto` / `PlanPathStepKind` | étape du **chemin vers l'objectif** (paliers) | — |

Trois sens de « cycle » et trois de « étape » dans le même écran : c'est exactement le type de
collision qui a produit les 6 copies de la table des paliers. **À renommer avant d'écrire la
première migration.** Proposition : `journey_cycle` → `journey_lot` (« lot » est déjà le mot de la
spec §2) ; `journey_step` garde son nom mais le DTO servi ne doit pas s'appeler `step` tout court.

## B-5. ⚖️ ARBITRAGE — un plafond de production de file vs l'incident du 2026-08-25

Le `CLAUDE.md` racine porte cet invariant, en rouge :

> 🛑 Un plafond d'AFFICHAGE n'est jamais un budget PÉDAGOGIQUE. Le moteur calcule **toutes** les
> actions vraies, l'écran en montre un sous-ensemble — jamais l'inverse.

`maxPrioritiesPerLot: 3` **est** un budget pédagogique : R2 dit explicitement que les priorités
au-delà de 3 « ne sont pas stockées ni mises en attente ». Ce n'est pas la même erreur que le
2026-08-25 (où un plafond de 5 était **partagé entre 4 domaines**, d'où 3 domaines à zéro action :
ici c'est 3 **par épreuve**, donc jusqu'à 12), mais c'est le même geste.

➡️ **Ce n'est pas un blocage**, c'est un choix produit conscient que la spec assume déjà (« si elles
persistent, le prochain examen les fera remonter »). Il doit être **écrit noir sur blanc** dans
`docs/regles/plan.md` avec sa raison, sinon la prochaine lecture du `CLAUDE.md` le prendra pour une
régression. Et la limite connue de `TOP_SEVERITY` (spec R2, note) est réelle : avec 3 compétences
très faibles, une 4ᵉ n'apparaîtra **jamais**.

## B-6. ⚖️ ARBITRAGE — la file persistée contre « dérivé serveur ⇒ jamais persisté »

L'invariant du `CLAUDE.md` racine :

> **Dérivé serveur ⇒ jamais persisté, jamais recalculé par un front.** Statuts, situations,
> niveaux, natures d'action, achèvements d'étape : le serveur calcule à la lecture.

La spec §6 persiste `status`, `resolution`, `severity_rank`, `position`. Formellement, ce n'est pas
un dérivé : c'est la **mémoire d'une décision d'ordonnancement**, qu'aucun recalcul ne peut
reconstituer (l'ordre dépend de l'ordre d'arrivée des évaluations). Le dépôt a d'ailleurs déjà
accepté exactement cet argument pour `plan_pinned_priorities`.

Mais deux colonnes sont, elles, **bien des dérivés** :
- `journey_step.status` pour un `TRAIN_SKILL` : `MASTERED`/`QUOTA_REACHED` se relisent à tout
  instant depuis `SkillMasteryEngine` et `Progress.completed()`. Les persister crée une seconde
  autorité sur « cette compétence est-elle acquise ? » — le défaut le plus cher du dépôt.
- `journey_step.severity_rank` : dérivable de l'ordre de `actionable`.

➡️ **Recommandation** : persister **la structure** (quelle étape, dans quel lot, à quelle position,
issue de quelle évaluation) et **relire l'achèvement** au lieu de le figer ; ne persister une
résolution que lorsqu'elle est **historique et non recalculable** (`SUPERSEDED`,
`SATISFIED_BY_ASSESSMENT`, qui dépendent d'un événement daté). À confirmer (§D-6) — cela allège
significativement le modèle et supprime le risque de divergence.

## B-7. ⚖️ ARBITRAGE — le checkpoint EE/EO se heurte au paywall dès le 2ᵉ cycle

- CO/CE : slot 1 offert et **rejouable à volonté**, tirage **aléatoire** pour un compte inscrit →
  les checkpoints CO/CE fonctionnent, gratuitement, indéfiniment. ✅
- EE/EO : **1 examen blanc production offert** par épreuve, puis premium. Le checkpoint du cycle 2
  d'une épreuve d'expression est donc verrouillé pour un gratuit. Compatible avec R16 (« le CTA
  ouvre le paywall »), mais combiné à B-2 cela signifie qu'un compte gratuit voit un parcours qui
  ne peut **structurellement** pas avancer.
- Et `TcfReassessmentService` impose en plus **14 jours** entre deux **diagnostics complets** — sans
  rapport avec un examen d'épreuve, mais à ne pas confondre : si le checkpoint d'un cycle est un
  jour implémenté comme un diagnostic, la porte temporelle s'appliquera.

## B-8. ⚖️ ARBITRAGE — R12 existe déjà, sous un autre nom, et son action a été tranchée

R12 (« ajouter “{Épreuve} — Évaluer mon niveau” pour chaque épreuve non mesurée ») est
**exactement** `PlanDomainAssessmentResolver.resolve(domaines)` (l.92), servi sur
`LearningPlanDto.domainesAEvaluer`, ordonné par `TcfDomainProfileDto.ORDRE` (= `examTypeOrder` de la
spec, `[CO, CE, EO, EE]`).

⚠️ **Attention à l'ordre** : `ORDRE` vaut `TCF_CO, TCF_CE, TCF_EO, TCF_EE` ; la spec §17 propose
`["TCF_CO","TCF_CE","TCF_EE","TCF_EO"]`. **EE et EO sont inversés.** Deux ordres = deux écrans qui
divergent. Il faut un seul ordre, et ce doit être celui qui existe.

⚠️ Et l'**action** a été tranchée le 2026-09-16 : « mesurer un domaine, c'est passer un EXAMEN
BLANC — les quatre épreuves, sans exception ». Les natures `DIAGNOSTIC` et `PRODUCTION` de
`PlanDomainAssessmentKind` ont été **supprimées** pour cette raison. La spec doit reprendre
`MODULE_MOCK_EXAM` / `PRODUCTION_MOCK_EXAM` et le `SLOT_OFFERT = 1`, pas réinventer une action.

## B-9. ⚙️ FORME — le fichier de config doit suivre la convention du dépôt

Spec §17 : `config/tcf-journey.json`. Convention en vigueur :
`src/main/resources/plan/plan-config-v1.json`, chargé et **validé au démarrage** par
`PlanConfigLoader` (refus sur clé inconnue, entrée d'enum manquante, plafond ≤ 0, version
discordante), sans aucune valeur de repli en Java. Idem `progression-config-vN.json`.

➡️ Soit `resources/plan/tcf-journey-config-v1.json` avec son propre loader, soit — plus simple — une
**section `journey` dans `plan-config-v2.json`**. `maxPrioritiesPerLot` et `trainSkillQuota` sont de
la **sélection**, ce que `PlanConfig` porte déjà ; mais 🛑 `PlanConfig` a l'interdiction explicite
d'influencer le calcul de maîtrise (arbitrage du 2026-08-26), donc `trainSkillQuota` ne peut pas
y vivre s'il change ce que `Progress.completed()` décide. À trancher avec B-2.

## B-10. ⚙️ FORME — l'endpoint doit suivre la convention `/api/me/*`

Spec §16 : `GET /api/tcf/journey?targetLevel=B2`. Le dépôt sert le Plan sur `/api/me/plan`, la
progression sur `/api/me/progress`. Et `targetLevel` en query param est redondant : le serveur
connaît le niveau visé du candidat (`TargetProcedure.niveauVise`) et ne doit pas accepter qu'un
client en impose un autre.

➡️ `GET /api/me/plan/journey`, sans query param. Un `?targetLevel=` ouvrirait la porte à un front
qui demande un parcours qui n'est pas le sien.

## B-11. ⚙️ FORME — `title`/`subtitle` calculés à la lecture : d'accord, mais où ?

Spec §6 : « `title` et `subtitle` ne sont pas persistés ». ✅ Conforme au dépôt. Mais le `CLAUDE.md`
racine et tout l'existant disent l'inverse de §16 : **le serveur expose des faits, la phrase
appartient aux fronts** (`PlanPathStepKind`, `PlanDomainAssessmentKind`, `PlanChangeDto`,
`PreparationEtape` : tous documentés ainsi). `title: "Identifier clairement le destinataire"` est le
`skills.title` du référentiel, donc un fait — d'accord. Mais `subtitle: "Expression écrite ·
Tâche 1"` et « Vérifier mes progrès » sont des **phrases**, qui vivent aujourd'hui dans
`plan-domain.ts` ⇄ `plan_labels.dart`.

➡️ Servir `section` + `taskCode` + `purpose`, et laisser les deux fronts composer le sous-titre via
leurs libellés miroirs. Sinon on ouvre une 7ᵉ copie de libellés.

## B-12. ⚙️ FORME — §19 « Tests UI minimum » est retiré par le `CLAUDE.md` racine

> 🛑 **Aucun NOUVEAU test sur les fronts.** Cette règle **prime** sur toute consigne de test écrite
> ailleurs. Vérification d'un changement front : `npx tsc --noEmit` / `npm run build` /
> `flutter analyze`, rien de plus.

Les 8 points de §19 sont donc **annulés** en tant que tests. Ils restent une **checklist de
vérification manuelle** utile. Les 16 tests TS et 24 tests Dart existants doivent rester verts ;
ceux que ce chantier rendrait rouges se mettent à jour ou se suppriment un par un.

En revanche §18 (30 tests métier backend) est **obligatoire et non négociable** (« Backend : tests
dans la même passe »). Conventions : `*Test` (unitaire, surefire) / `*IT` (intégration, failsafe,
Postgres embarqué Zonky) — `docs/plan-tests-backend.md`. Gabarit disponible : les 28 tests Plan
existants (`LearningPlanServiceTest`, `LearningPlanCycleIT`, `PlanActionRankerTest`, …).

## B-13. ⚙️ FORME — deux trous dans les algorithmes §7

1. **§7.2 ne dit pas quoi faire des étapes `DIAGNOSTIC` quand un diagnostic rapide arrive après un
   examen.** R11 dit que le diagnostic rapide « n'est proposé comme étape que si aucune évaluation
   exploitable n'existe », et §7.2 résout l'étape `DIAGNOSTIC` active — mais rien n'interdit à un
   candidat de lancer un diagnostic rapide alors qu'il a déjà 3 examens. Cas réel : `/diagnostic`
   est une page publique accessible en permanence.
2. **§7.3 `onTrainingProgress` ne dit pas d'où vient `skillCode`.** L'appelant naturel est
   `SkillAttemptService` (expression) et `doFinish` (compréhension) — mais en compréhension la
   compétence est **dérivée du contenu des questions** par `ComprehensionObservationService`, pas
   connue de l'appelant. Le branchement doit donc se faire **après** l'écriture des observations,
   sur les compétences réellement écrites.

## B-14. ⚙️ FORME — `plan_pinned_priorities` devient mort

Si la file existe, l'épingle n'a plus d'objet : la position d'une étape **est** l'épingle. Règle du
dépôt : refonte = suppression immédiate de l'ancien (entité, manager, repository, migration de
suppression, `PlanFocusResolver.epingler`, et la dépendance de `SkillAccessService` à la première
place). ⚠️ `SkillAccessService.resolve(userId, focusSkillId)` ouvre la compétence de la priorité
n°1 à un compte gratuit : cette règle doit alors lire l'étape `CURRENT` de la file. À ne pas
oublier, sinon l'étape 1 d'un gratuit redevient cadenassée (le bug de 2026-08-21).

---

# C. Table de correspondance spec → existant

| Ce que demande la spec | Ce qui existe déjà | Verdict |
|---|---|---|
| Priorités d'une évaluation | `learning_plan_observations` + `LearningPlanPriorityResolver.actionable` | **réutiliser tel quel** |
| Rang de gravité | ordre total déterministe (status → confiance → récence) | **réutiliser**, dériver le rang |
| `trainSkillQuota` | `LearningPlanStep.PROMPTS_PAR_ETAPE = 5` | **réutiliser tel quel** |
| `progress { done, quota }` | `LearningPlanStep.Progress` + `stepAttemptedCount`/`stepPromptCount` | **déjà servi** |
| Résolution `MASTERED` | `SkillMastery.transferProven()` | **réutiliser tel quel** |
| Écart au niveau cible | `TcfProfileService.levelProfile` + `TargetProcedure.niveauVise` | **réutiliser tel quel** |
| `examTypeOrder` | `TcfDomainProfileDto.ORDRE` | **réutiliser** ⚠️ EE/EO inversés dans la spec |
| R12 « Évaluer mon niveau » | `PlanDomainAssessmentResolver` + `PlanDomainAssessmentKind` | **réutiliser tel quel** |
| `locked` | `SkillAccessService` / `enforceMockExamSlotAccess` / `ProductionAccessService` | **réutiliser tel quel** |
| Statuts d'étape §5 | `PlanSkillStepState` (`MAINTENANT`/`A_VENIR`/`ACQUIS`/`SERIE_TERMINEE`/…) | **très proche, à réconcilier** |
| Timeline §12 | `PlanPathStepDto` + `plan_path_section.dart` + `planPathStepTitle` | **motifs réutilisables**, sémantique différente |
| Config versionnée | `plan-config-v1.json` + `PlanConfigLoader` | **réutiliser la convention** |
| Sérialisation §R14 | ❌ rien | **à créer** (verrou pessimiste sur `journey`) |
| Idempotence par évaluation | ❌ rien (idempotence existe **par observation**, clé `(user, skill, source, attempt)`) | **à créer** (`journey_assessment_event`) |
| File ordonnée + positions | ❌ rien (seule `plan_pinned_priorities`) | **à créer** |
| Cycles / checkpoints | ❌ rien | **à créer** |
| Bootstrap R19 | ❌ rien | **à créer** |

**Ce qui reste réellement à écrire** : 3 tables, un verrou, un journal d'évaluations, un
ordonnanceur, un bootstrap, un endpoint de lecture, et la migration des 6 cartes « À faire
maintenant ». **Tout le reste se branche.**

---

# D. Arbitrages demandés au propriétaire

Aucun code ne part avant ces réponses. Les six premiers sont bloquants.

1. **Compte gratuit et étape verrouillée** (B-2) — un compte gratuit ne peut pas terminer une étape
   d'expression (2 sujets sur 5, arbitrage produit assumé). Sous une file à un seul `CURRENT`, son
   parcours se figerait définitivement. **La promotion doit-elle sauter une étape verrouillée**
   (option b, ma recommandation), ou assume-t-on que le parcours d'un gratuit s'arrête à l'étape 1 ?
2. **Quelle lecture de niveau pour R10 bis** (§A-3) — la lecture **Plan** (meilleur résultat,
   `TcfProfileService`, ma recommandation) ou la lecture **affichage** (moyenne des 3 derniers, qui
   peut faire redescendre et donc **réordonner la file** sans qu'aucune priorité n'ait bougé) ?
3. **Niveau cible `null`** (§A-8) — 17 utilisateurs sur 34 en dev n'ont pas de `target_level`. Quel
   repli pour la clé `(userId, targetLevel)` : `A2` (le plus étroit, cohérent avec
   `mentionCivique(null) → CSP`), ou pas de parcours du tout tant que l'objectif n'est pas déclaré ?
4. **Deux timelines ou une** (§A-6) — le « chemin vers l'objectif » (paliers CECRL,
   `PlanPathStepDto`) est déjà affiché. La timeline §12 s'ajoute-t-elle à côté, ou la remplace-t-elle ?
5. **`TRAIN_SKILL` en compréhension** (B-3) — quota en **séries terminées** (avec sa propre valeur
   de config), ou la compréhension n'entre dans la file que par ses checkpoints ?
6. **R1 en compréhension** (B-1) — filtrer la file aux seules évaluations (option a, ma
   recommandation) ou amender R1 ?
7. **Périmètre de persistance** (B-6) — persister la structure et **relire** l'achèvement, ou figer
   `status`/`resolution` comme l'écrit §6 ?
8. **Renommage** (B-4) — `journey_cycle` → `journey_lot` ? Trois sens de « cycle » dans le même
   écran est un risque documenté du dépôt.
9. **Ordre des épreuves** (B-8) — l'ordre existant est `CO, CE, EO, EE`, la spec dit
   `CO, CE, EE, EO`. Lequel fait foi ? (Ma recommandation : l'existant, il est déjà à l'écran.)

---

# E. Plan d'implémentation révisé (pour validation, pas pour exécution)

Les phases de la spec §21-24 tiennent, avec trois corrections de périmètre.

| Phase | Contenu | Correction par rapport à la spec |
|---|---|---|
| **0** | Ce rapport | **STOP — en cours** |
| **1** | DDL `V066__schema_journey_tcf.sql` (`00_schema/`), entités, managers, repositories, config | 🛑 pas de migration de **données** (§A-11) ; config dans `resources/plan/`, loader validant (B-9) |
| **2** | Ordonnanceur (§7), bootstrap R19, branchements `doFinish` + `recordProduction` + `SkillAttemptService`, **suppression de `plan_pinned_priorities`** et report de son rôle sur `CURRENT`, tests §18 | + suppression de l'ancien (B-14) ; + le filtre R1 arbitré (B-1) |
| **3** | `GET /api/me/plan/journey` (B-10), `locked` à la lecture, filtrage §14 ; `title`/`section`/`taskCode`/`purpose` servis, **phrases côté fronts** (B-11) | endpoint et contrat corrigés |
| **4** | **6 cartes** « À faire maintenant » (Plan / Accueil / Réviser × web / mobile), timeline §12-14 dans les **deux kits**, suppression de « Votre parcours — Tâche X ». Vérif : `npx tsc --noEmit`, `npm run build`, `flutter analyze` | 🛑 §19 retiré comme tests (B-12) ; périmètre front ×3 écrans, pas ×1 (§A-6) |

**Mise à jour documentaire dans la même passe** (règle du `CLAUDE.md` racine) : `docs/regles/plan.md`
(la règle), `docs/decisions/` (les arbitrages de §D, verbatim et datés), le `CLAUDE.md` local de
chaque front si une convention change, `docs/api-endpoints.md` pour le nouvel endpoint. Le
`CLAUDE.md` racine seulement si un invariant transverse naît — ce sera le cas si §D-7 tranche pour
la persistance d'un dérivé.
