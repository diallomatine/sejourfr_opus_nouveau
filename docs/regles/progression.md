# Moteur de progression V4.2 — ce qui est en place, ce qui ne l'est pas

Spécification normative complète : `docs/plan/SEJOURFR_PROGRESSION_ENGINE_V4_2.md`.
Ce fichier-ci ne la résume pas — il dit **où en est l'implémentation** et **ce qui casse en
silence si on l'ignore**.

État au **2026-08-23** : **les quatre phases livrées**. Le moteur tourne en **SHADOW**. Le moteur tourne en **SHADOW** : il
enregistre, calcule et prédit — et **ne touche pas au Plan servi**.

---

## Ce qui existe

| Livrable | Où |
|---|---|
| Configuration figée v1 | `backend_sejourfr/src/main/resources/progression/progression-config-v1.json` |
| Chargeur + validation au démarrage | `progression.config.ProgressionConfigLoader` |
| Feature flag SHADOW / ACTIVE | `sejourfr.progression.mode` (`application.yaml`) |
| Domaine (enums, `LearningEvidence`, `ProgressionStateKey`, snapshots) | `progression.domain` |
| **Moteur pur** (agrégat epoch, gates, machine à états, prérequis) | `progression.engine.DefaultProgressionEngine` |
| **Schéma** (`learning_evidence`, `progression_state`, prédictions, signaux) | `db/migration/00_schema/V044__progression_engine.sql` |
| **Ingestion** idempotente + replay | `progression.service.ProgressionIngestionService` |
| **§12 bis** — `contentId` + `independenceClass` serveur | `progression.service.ContentIdentityService` |
| **Adaptateur CO/CE** (correction du hasard, ventilation par palier) | `progression.service.ReceptiveEvidenceAdapter` |
| **Adaptateur EE/EO** (observations IA, micro-sujets, `transferGate`) | `progression.service.ProductiveEvidenceAdapter` |
| **Shadow mode** (prédictions, rattachement, précision) | `progression.service.ProgressionShadowService` |
| **Tirage 6/10/4** + signal de banque insuffisante | `progression.service.ComprehensionSeriesComposer` |
| **`difficulty_band`** + vue de difficulté observée | `db/migration/00_schema/V045__question_difficulty_band.sql` |
| Difficulté empirique (propose, n'impose pas) | `progression.calibration.EmpiricalDifficultyService` |
| **Outillage du tagging** (inventaire, export CSV, réimport) | `progression.calibration.CatalogueCalibrationService` |
| Lecture (`prescriptionLevel`, prérequis dérivés) | `progression.service.ProgressionReadService` |
| **Pont vers le Plan**, éteint en SHADOW | `progression.service.ProgressionPlanBridge` |
| **Rapport de bascule** + états servis | `progression.service.ProgressionReportService` |
| Console admin | `GET/POST /api/admin/progression/*` |
| **Observabilité §46** (codes de raison, trace d'état) | `progression.service.ProgressionExplanationService` |
| Verrou de la config, valeur par valeur | `ProgressionConfigTest` — **vert** |
| **T01–T35** | `ProgressionEngineAcceptanceTest` — **35/35 verts** |
| T36 (conformité front) | `scripts/verifier-contrat-front-progression.mjs` — **vert** |

## Ce qui n'existe pas encore

- **Aucun front ne lit le moteur.** Les DTO existent, l'endpoint admin existe, le pont vers le
  Plan existe — et il rend `empty()` tant qu'on est en SHADOW. Le web et le mobile n'ont rien à
  changer aujourd'hui ; leur travail commencera le jour de la bascule.
- **Le catalogue n'est pas tagué.** La colonne `questions.difficulty_band` existe, le tirage
  6/10/4 existe, mais **aucune question ne porte encore de bande**. Tant que ce n'est pas fait,
  toutes les séries d'entraînement restent `UNCALIBRATED` — cf. ci-dessous.
- **Corpus de stabilité IA (§45)** : *non fait, et volontairement.* Il relève de EE/EO, et
  nous sommes en phase 1/2 sur CO/CE. Arbitré le 2026-08-23 : **on le fera au moment de passer
  EE/EO en shadow, pas avant.** Il exige de toute façon d'appeler un fournisseur payant sur un
  corpus fixe — décision du propriétaire, c'est son argent.

---

## Les trois choses qui cassent en silence

### 1. La config ne s'édite pas

`progression-config-v1.json` est **figé**. Changer une valeur métier, c'est :

```text
nouveau progression-config-v2.json  +  engineVersion 2  +  replay contrôlé
```

`ProgressionConfigTest` verrouille les 40+ valeurs de §4 une par une. Un ajustement discret
« pour faire passer un test » casse là, et c'est l'intention. Un retour arrière est un
changement de `PROGRESSION_ENGINE_VERSION`, pas une migration.

Aucune valeur métier ne vit dans `application.yaml` ni dans un POJO : la doctrine
« défauts dans le POJO ET dans le YAML » des autres `*Properties` **ne s'applique pas ici**,
parce qu'il n'y a rien à dupliquer.

### 2. `null` n'est pas `0` — et un palier sans preuve directe vaut `null`

`visibleProgress = null` pour un palier qui n'a jamais reçu la moindre `LearningEvidence`
(§18.6, invariant I41). Le front n'affiche alors **aucun pourcentage**, seulement l'état
textuel. Afficher `A2 — 0 %` à un candidat dont A2 n'a jamais été mesuré lui ment : il n'a
pas régressé, il n'a jamais été mesuré. C'est la même confusion qui a produit les faux
`A1_NON_ATTEINT` de V040–V042 (`docs/decisions/diagnostic.md`).

### 3. Le front ne calcule aucun état, aucun niveau, aucun seuil

§25 bis, invariants I42–I44. Le serveur sert `status`, `statusLabel`, `visibleProgress`,
`directQualification`, `prerequisiteSatisfied` ; il n'envoie **jamais** `masteryScore`,
`confidence` ni les accumulateurs epoch.

Le vérificateur `scripts/verifier-contrat-front-progression.mjs` échoue si un front :

- rend un niveau CECRL à partir d'un nombre ;
- compare un pourcentage à 40 / 45 / 55 / 60 / 65 / 70 / 80 / 85 puis pose un libellé
  d'état pédagogique ;
- met un pourcentage et un libellé CECRL dans le même bloc visuel ;
- ne déclare pas les six états de §13.

Une exemption s'écrit **sur la ligne**, avec sa raison :

```ts
// t36-ok: niveau du sujet, pas du candidat
```

🛑 **Ce n'est pas un test de front.** Le dépôt n'en accepte aucun (`CLAUDE.md` racine) : c'est
un script Node autonome, sans dépendance. Il se lance à la main, ou en pré-commit si on en
met un un jour.

```bash
node scripts/verifier-contrat-front-progression.mjs
```

---

## Les six états — le seul vocabulaire autorisé

| État | Libellé FR | Ton |
|---|---|---|
| `NOT_EVALUATED` | À évaluer | neutral |
| `FRAGILE` | À renforcer | danger |
| `PROGRESSING` | En progression | primary |
| `READY_FOR_REASSESSMENT` | Prêt à vérifier | accent |
| `SOLID` | Acquis | success |
| `WATCH` | À vérifier | warn |

Une UI qui n'en gère que quatre est **non conforme** : `WATCH` et `READY_FOR_REASSESSMENT`
portent la valeur pédagogique du produit, et ce sont toujours les premiers qu'on perd en
recopiant un ancien vocabulaire.

Miroirs : `web_sejoufr/lib/progression-contract.ts`,
`mobile_sejourfr/lib/core/models/progression_status.dart`. Le ton se dérive de l'**état**,
jamais d'un nombre.

---

## Ce qui a été retiré des fronts le 2026-08-23

| Avant | Après | Pourquoi |
|---|---|---|
| `masteryLabel(num)` (mobile, `app_theme.dart`) | supprimé | classait un % en « Solide / En bonne voie / … » |
| `masteryColor(num)` (mobile, `app_theme.dart`) | supprimé | rampe de ton dérivée d'un nombre |
| `masteryHint(percent)` (web, `lib/dashboard.ts`) | `successHint(percent)` — factuel | rendait « Excellent niveau », « En bonne voie » |
| `categoryStatus(percent)` (web) | `categoryBadge(percent)` — « À découvrir » / « Déjà travaillé » | trois verdicts calculés dans le navigateur |
| `barTone(percent)` (web) | `barTone()` — accent de marque | ton classé par seuils |
| `masteryLabel(state)` (web, `plan-domain.ts`) | `masteryStateLabel(state)` | **traduisait un enum servi** — pas une faute, mais le nom entrait en collision avec la fonction interdite |
| « Tu maîtrises bien le niveau X, tente le suivant » (mobile, résultat de lot) | reformulé | une seule série n'ouvre jamais un palier (§16, T01) |

**Non touché, volontairement** : `SkillMasteryState` (`PRIORITY / TO_REINFORCE /
CONSOLIDATING / SOLID`) et `LearningPlanSkillStatus` restent le vocabulaire du Plan actuel.
Ce sont des enums **servis par le backend** — les remplacer par les six états suppose que le
moteur serve ces états, donc la phase 2. Les remplacer maintenant casserait le produit en
service pour aligner un contrat qui n'a pas d'émetteur.

---

## La notation IA est en config (bloc `aiScoring`)

Ces quatre valeurs **multiplient directement `baseEffectiveWeight`**. Ce sont donc des valeurs
métier au même titre qu'un `sourceWeight`, et elles vivent dans
`progression-config-v1.json`, pas dans une constante Java.

Hors config, les changer ne bumperait pas `engineVersion`, ne déclencherait aucun replay, et
rendrait deux campagnes shadow séparées par une telle édition **non comparables sans que rien
ne le signale** — violation directe de I32, I33 et I34.

| Réglage | Pourquoi il existe |
|---|---|
| `confidenceMapping` | Le tool-schema livré rend un **enum** `LOW / MEDIUM / HIGH`, pas un nombre — contrainte dure, et on ne réécrit pas un contrat livré. La traduction vers `[0,1]` doit donc exister quelque part. `HIGH` ne vaut délibérément pas 1,00 : une évaluation IA n'est jamais une certitude. |
| `microSkillAssistance` | Checklist, amorce et astuce sont la raison d'être pédagogique du micro-sujet — et une assistance réelle. §8.2 veut qu'une preuve assistée pèse moins, sans plancher. Un micro-sujet **non guidé** reste en `NONE`. |
| `microSkillScoringConfidence` | Un critère unique jugé sur une production courte porte moins de matière qu'une tâche complète. On le dit plutôt que de faire comme si. |

🛑 **Aucune de ces valeurs n'apparaît en dur dans le code Java.** `ProgressionConfigTest` les
verrouille une par une, et `ProgressionConfigLoader` fait échouer le démarrage si
`confidenceMapping` ne couvre pas les trois niveaux.

Seule exception, et elle est normative : le mapping `VALIDATED / PARTIAL / NOT_VALIDATED →
1,00 / 0,50 / 0,00` de §6.5, que la spec qualifie d'**obligatoire**. Le mettre en config
laisserait croire qu'il est réglable.

## Deux conséquences à connaître avant de toucher au moteur

### Une série n'est calibrée que si elle l'est *réellement*

La machinerie est en place : `ComprehensionSeriesComposer` tire 6 EASY / 10 MEDIUM / 4 HARD
quand la banque le permet, et `ReceptiveEvidenceAdapter` vérifie la composition **réellement
jouée** — pas l'intention du compositeur.

🛑 **Il n'y a pas de « presque calibré ».** Une seule question sans bande, ou une répartition
6/11/3, et toute la série bascule en `UNCALIBRATED`. Accepter l'approximation reviendrait à
verrouiller des paliers sur des mesures qui ne se valent pas — et il faudrait ensuite les
retirer aux candidats.

Quand une bande ne peut pas être remplie, le compositeur **ne complète pas** avec des questions
non taguées : il rend une série jouable (priver le candidat de son entraînement serait pire),
la marque non calibrée, et écrit `CONTENT_BANK_TOO_SMALL` avec le stock manquant par bande.

**Conséquence aujourd'hui — et c'est bloquant, pas une tâche de fond.** Le catalogue n'ayant
aucune bande :

```text
toutes les séries sont UNCALIBRATED (poids 0,50)
  → qualificationGate toujours false (T05)
  → activeLearningLevel ne bouge jamais par l'entraînement
  → un candidat qui s'entraîne sans examen blanc reste prescrit sur A2 indéfiniment
```

Et donc : **les métriques shadow ne seront alimentées que par des prédictions issues d'examens
blancs** — échantillon minuscule, biaisé, non représentatif de l'usage réel.

🛑 **L'ordre est : taguer, puis mesurer, puis basculer.** La décision de bascule dépend
entièrement de l'avancement du tagging.

### L'outillage du tagging

Le tagging lui-même est un travail humain, fait hors application. Le code l'outille :

| Endpoint | À quoi il sert |
|---|---|
| `GET …/catalogue/inventaire` | **L'indicateur d'avancement** : `seriesConstructibles` par (domaine, palier), et `bandeLimitante`. |
| `GET …/catalogue/export` | CSV de travail, **non taguées d'abord**. |
| `POST …/catalogue/bandes` | Réimport en masse. Lignes indépendantes ; `band: null` dé-tague. |
| `GET …/catalogue/propositions` | Les non taguées avec assez de données. `EASY p > 0,75` · `MEDIUM 0,45 ≤ p ≤ 0,75` · `HARD p < 0,45`, plancher **30 réponses**. |
| `GET …/catalogue/desaccords` | Taguée HARD, réussie à 90 % — fausse toutes les séries qui la contiennent. |

`seriesConstructibles` = `min(easy/6, medium/10, hard/4)`. **Un minimum, pas une moyenne** : la
bande la plus pauvre décide seule, et 200 questions MEDIUM ne servent à rien avec 3 HARD. Une
moyenne dirait « on y est presque » et enverrait produire du contenu au mauvais endroit.

### La difficulté observée propose, elle n'impose jamais

La vue `question_empirical_difficulty` expose le taux de réussite réel par item, et
`EmpiricalDifficultyService` en tire trois listes : la mesure brute, les **désaccords** (taguée
HARD, réussie à 90 %), et les **propositions** pour les questions non taguées.

🛑 **Rien ne repose une bande automatiquement.** §7 dit qu'à terme l'empirique *pourra*
remplacer les tags manuels — « pourra », et c'est une décision produit. Une bande qui changerait
toute seule ferait bouger la calibration des séries, donc le poids des preuves, donc des paliers
déjà acquis : un candidat verrait un acquis disparaître sans avoir rien fait, et personne ne
saurait pourquoi.

Plancher d'échantillon : **30 réponses**. En dessous, un taux est du bruit et rien n'est
proposé. Une question jamais répondue rend `null`, jamais « difficile ».

### Le recalcul relit l'historique d'une clé, pas un delta

§28 décrit une mise à jour O(1). Les **accumulateurs** le sont bel et bien — quatre additions
commutatives, rien à dupliquer et rien qui puisse diverger. Ce qui ne l'est pas, c'est la
machine à états : les hystérésis, le passage `SOLID → WATCH` sur la *première* contradiction et
la monotonie de `visibleProgress` dépendent de l'histoire, pas du total.

`ProgressionIngestionService` relit donc l'historique **de la seule clé touchée** et rejoue le
moteur dessus. À notre volume c'est borné et plus simple. Écart assumé, arbitré le 2026-08-23,
sous trois conditions — toutes tenues :

**a) Le poids stocké ne dépend que d'`occurredAt`.** `EpochWeights.toEpochWeight` applique
`exp(lambda × days(EPOCH, occurredAt))` et ne voit jamais `now()`. `masteryScore` est un
rapport de deux accumulateurs epoch : il ne contient aucun instant de calcul.
🛑 **C'est le seul vrai risque de ce raccourci** : un decay relatif à `now()` rendrait la
maîtrise time-dependent et ferait tomber I10. Verrouillé par
`poidsIndependantDeLInstantDeCalcul` — deux lectures du même historique à 400 jours d'écart
rendent la même maîtrise, et seule la **confiance** décroît.

**b) Les quatre colonnes epoch restent écrites, en `double precision`.** Plus la ventilation
`progression_state_family_aggregate` (§27.3), qui était créée mais **jamais écrite** avant cet
arbitrage — sans elle on lit une masse totale sans savoir ce qui l'a remplie, et le cap micro
de §11.1 n'est pas auditable après coup. Les deux lignes (`MICRO`, `NON_MICRO`) sont écrites à
chaque recalcul, **même celle qui vaut zéro** : une famille absente serait indiscernable d'une
famille jamais calculée.

**c) T11b — le test qui prouve réellement le design epoch.** T11 (six permutations) ne prouve
rien à lui seul : un recalcul complet retrie les preuves avant de replier, il est
*trivialement* invariant par ordre. T11b compare la valeur recalculée depuis l'historique à
celle obtenue en **accumulant les mêmes preuves une par une, dans un ordre absurde**, à
`1e-12`. C'est la promesse de §10 — quatre additions suffisent, on peut accumuler au fil de
l'eau sans jamais relire le passé — et c'est elle que le test verrouille.

## Le passage à ACTIVE

```text
PROGRESSION_ENGINE_MODE=SHADOW   (défaut)
PROGRESSION_ENGINE_MODE=ACTIVE
```

**C'est un changement de variable d'environnement, pas un déploiement.** C'est la propriété
qui compte : un moteur dont les seuils sont encore des hypothèses doit pouvoir être arrêté en
une minute. Le retour arrière est symétrique.

Ce que la bascule change, concrètement : `ProgressionPlanBridge` cesse de rendre `empty()`, et
`PlanCycleResolver` lit `prescriptionLevel` du moteur au lieu de `suivant(consolide)`. Le Plan
gagne alors une chose qu'il ne sait pas faire aujourd'hui — faire passer une **vérification**
avant l'apprentissage normal quand un acquis vient d'être contredit (§19, §20).

### La procédure

1. `POST /api/admin/progression/shadow/rattacher` — rattacher les résultats disponibles ;
2. `GET /api/admin/progression/shadow` — lire le `verdict` ;
3. décider.

🛑 **Deux conditions cumulatives, et aucune précision n'est servie tant que la première n'est
pas remplie** : `minOutcomeCount` = **30 issues rattachées**, puis `minSolidPrecision` ≥ 70 %.

Sous 30 issues, `precisionSolid` vaut `null` — **y compris quand la précision serait
calculable et juste**. Une issue rattachée et bonne donnerait 100 % ; ce chiffre serait exact
et serait lu comme une validation. Le seul moyen sûr d'empêcher un go/no-go sur un échantillon
minuscule est de ne pas le rendre calculable.

Le `verdict` distingue quatre situations, jamais confondues :

| `verdict` | Ce que ça veut dire |
|---|---|
| `AUCUNE_DONNEE` | Rien n'a de résultat. Absence de mesure, pas 0 %. |
| `ECHANTILLON_INSUFFISANT` | *N* issues sur 30. Aucune précision servie. |
| `PRECISION_INSUFFISANTE` | Effectif atteint, objectif non tenu. |
| `OBJECTIF_ATTEINT` | Les deux conditions sont remplies. La bascule reste une décision. |

Si la précision est sous l'objectif : **ne pas bricoler `progression-config-v1.json`**. On
analyse, on crée `progression-config-v2.json`, on incrémente `engineVersion`, on rejoue
(`POST .../replay`). Un ajustement sur place effacerait la trace de ce qu'on croyait avant.

---

## Contrat de livraison (§52), point par point

| Livrable | État |
|---|---|
| `progression-config-v1.json` figé | ✅ verrouillé valeur par valeur par `ProgressionConfigTest` |
| Migrations DB | ✅ V044 (moteur), V045 (bandes de difficulté) |
| `learning_evidence` + idempotence | ✅ contrainte d'unicité en base, pas un `exists` applicatif |
| Colonnes epoch en `double precision` | ✅ §27.2.1 |
| Normalisation chance-adjusted CO/CE | ✅ dénominateur = `totalQuestions`, toujours |
| `contentId` + `independenceClass` serveur | ✅ jamais fournis par le client |
| INCOMPLETE / ABANDONED / TIME_EXPIRED / SUBMITTED | ✅ |
| Agrégation epoch commutative | ✅ six permutations à 1e-12 (T11) |
| `progression_state` | ✅ |
| `qualificationGate` direct | ✅ Cas A / B / C |
| `prerequisiteSatisfied` dérivé | ✅ jamais persisté, révocable |
| `visibleProgress = null` sans preuve directe | ✅ §18.6, jamais 0 |
| `activeLearningLevel` | ✅ |
| `prescriptionLevel` avec WATCH | ✅ |
| `progression_prediction_log` | ✅ figé à `predictedAt` |
| Mode SHADOW | ✅ défaut, et seule bascule = variable d'env |
| Contrat de rendu front §25 bis | ✅ `cefr`/`masteryLabel`/`masteryTone` supprimés |
| T01–T35 verts | ✅ 35/35 |
| Valeurs T01–T06 à 1e-6 | ✅ |
| Test des 6 permutations | ✅ |
| Test statique front (T36) | ✅ script Node, pas un test de front |
| Logs `recommendationReasonCode` | ✅ trace d'état + `predictionReason` |
| Logs `CONTENT_BANK_TOO_SMALL` | ✅ table + log, par bande |

**Rien n'est marqué fait sans l'être.** Les deux seuls éléments de la spec non livrés sont
énoncés plus haut, avec leur raison : le corpus de stabilité IA (§45, coût LLM) et le tagage du
catalogue (travail de contenu).

## Ordre de reprise (§49)

| Phase | Contenu | État |
|---|---|---|
| 0 | config figée, T01–T36 écrits, feature flag, nettoyage front | **livré** |
| 1 | `learning_evidence`, agrégat epoch, `progression_state`, gates, prérequis, shadow | **livré** |
| 2 | pont Plan flag-gated, rapport de bascule, console admin | **livré** — reste la décision, qui exige des données réelles |
| 3 | EE/EO : observations IA, cap micro, `transferGate` | **livré** (corpus de stabilité exclu, cf. ci-dessus) |
| 4 | calibration contenu : `difficultyBand`, séries 6/10/4, `CONTENT_BANK_TOO_SMALL` | **livré** (reste à taguer le catalogue) |

Avant la phase 1, relire §27.2.1 : les accumulateurs epoch se stockent en
`double precision`, **jamais** en `NUMERIC(p,s)` ni en `BigDecimal`. Ils croissent
exponentiellement — `≈ 2.6e24` à J+3650 — et un décimal à précision fixe déborde en
silence, sur une donnée matérialisée que rien ne recalcule dans le chemin nominal.


---

## Écran Progrès (T28, 2026-09-10) — le MOUVEMENT, pas l'état

🛑 **À distinguer de `/api/me/dashboard`**, qui sert la **maîtrise** par
catégorie. Le dashboard répond à « où j'en suis » ; `GET /api/me/progress`
répond à « **qu'est-ce qui a bougé** » (`30_` §7). Les deux coexistent, et
l'écran de progression des deux fronts les affiche l'un sous l'autre plutôt que
d'ouvrir une troisième page « progression » — le dépôt en avait déjà deux.

🛑 **Ce service n'invente aucune mesure.** Il assemble ce que d'autres autorités
servent déjà :

| Ce qu'il affiche | D'où ça vient |
|---|---|
| niveau TCF actuel, par épreuve | `TcfProfileService` — « le SEUL endroit d'où sort ce niveau » |
| objectif | `TcfDiagnosticService.cible(user)` → `TargetProcedure.niveauVise` |
| sens d'une évolution | `TcfDiagnosticProgressionResolver.evolution` (L7, écrit pour cet écran) |
| **statut d'une épreuve face à l'objectif** | `StatutObjectifResolver` (2026-09-16) |
| compétences tenues | moteur de maîtrise (`SkillMasteryResolver`) |
| compteurs civiques | moteur du plan civique (L10) |
| **détail civique par thème** | `CivicPlanService.themeLignes()` (L10, le même que Plan / Réviser) |
| jours travaillés | `AttemptRepository.findDistinctActivityDates` (celui du streak) |

Aucun niveau, aucun palier, aucun état n'est recalculé ici.

### Les règles que cet écran fait respecter

- 🛑 **Aucun pourcentage de progression vers un palier** (`30_` §7, règle
  explicite). Un palier CECRL n'est pas une barre : « 68 % vers le B2 » n'a aucun
  sens mesurable et se lit pourtant comme une promesse. On nomme deux paliers.
- 🛑 **Aucune gamification.** Pas de flamme, pas de record, pas d'objectif
  hebdomadaire. L'activité se dit en **jours travaillés** et en semaines. Le
  streak existe déjà sur le tableau de bord, où il est une information ; le
  ramener ici en ferait un enjeu — et un compteur qu'on peut **casser**
  transforme une mesure en dette.
- 🛑 **`INCONNUE` n'est pas `STABLE`.** Une épreuve non évaluée d'un côté n'a ni
  progressé ni tenu : le front ne rend **aucun** marqueur, surtout pas « = ».
  `BAISSE` existe et se sert — la masquer rendrait la réévaluation invendable.
- 🛑 **Les 4 épreuves sont toujours servies**, évaluées ou non. Une épreuve
  absente de la liste disparaîtrait de l'écran au lieu de se dire « non
  évaluée ».
- 🛑 **Le statut d'une épreuve face à l'objectif est SERVI** (`Epreuve.status`,
  **2026-09-16**) : `TARGET_REACHED` / `CLOSE_TO_TARGET` / `TO_REINFORCE`,
  dérivés par `StatutObjectifResolver` d'`actuel` **vs** `objectif`, deux
  paliers que le DTO servait déjà. Aucun front ne compare deux niveaux CECRL :
  la règle vit à un seul endroit, et l'ordre CECRL vient de
  `TcfDiagnosticLevelResolver.rang`, la même autorité qu'`evolution`.
  - 🛑 **`null` quand aucune démarche n'est déclarée.** Sans palier exigé il n'y
    a rien vers quoi renforcer : on ne range personne dans le verdict le plus
    bas faute d'objectif.
  - 🛑 **`TO_REINFORCE` recouvre DEUX cas** — « mesuré, et loin » et « jamais
    mesuré ». Le statut produit les confond (table de la spec V2 §2), **les
    écrans non** : `niveau` vaut `null` dans le second cas, et les deux fronts
    affichent alors « **À évaluer** », jamais « À renforcer »
    (`progresStatutLabel` ⇄ `progresStatutLabel`). C'est l'incident
    V040/V041/V042 sous un autre déguisement — ne jamais fondre les deux.
- 🛑 **Le détail civique par thème est SERVI** (`Civique.themes`, **2026-09-16**)
  et c'est **le même record que le Plan** (`CivicPlanDto.ThemeLigne`) : le
  serveur réexpose ce que son moteur produit déjà, dans le **même**
  `CivicPlanService.compteurs(userId)` — aucune requête de plus, aucun second
  calcul de maîtrise. L'état arrive en `CivicThemeState` **brut** ; les fronts
  posent le libellé (`CIVIC_THEME_STATE_LABEL` ⇄ `CivicThemeState.label`) et le
  ton (`kitTone` ⇄ `civicThemeTone`), les autorités déjà en place. 🛑
  `NON_EVALUE` reste **neutre**, jamais ambre : le serveur n'a pas mesuré ce
  thème, il ne dit pas qu'il est fragile.
- 🛑 **« Maîtrisée » se lit sur `SkillMastery.transferProven`, PAS sur
  `state() == SOLID`** (correctif du **2026-09-16**). C'est la **même** autorité
  que « acquis » sur le Plan (`PlanStepStateResolver`, `completedSteps` — voir
  `docs/regles/plan.md`), et ce service ne la recopie pas, il l'appelle. L'écart
  n'était pas théorique : le parcours **normal** (cinq micro-entraînements puis
  une vérification réussie) plafonne sous `solid-score`, donc la carte « Votre
  progression » annonçait « 0 compétence maîtrisée » pendant que le Plan de la
  même app cochait les mêmes compétences. Verrouillé par
  `ProgressServiceTest.leTransfertProuveCompteMemeSansSolid`.
- 🛑 **Freemium : les compteurs de compétences restent, le DÉTAIL part**
  (`30_` §7 : « blocs 1 et 2 visibles, 3 et 5 verrouillés »). Cacher le nombre
  reviendrait à cacher au candidat ce qu'il a lui-même produit.
- 🛑 **Aucune seconde liste d'historique.** Le bloc 5 de la spec est déjà servi
  par les écrans d'historique existants ; on sert un **lien**.
- 🛑 **Aucune métrique CECRL côté civique** (`20_` §12) : le civique se mesure en
  points sur 40 et en cibles tenues.

### Deux écarts avec `30_` §7, assumés

- **La fenêtre d'activité vaut 28 jours, pas 30.** 30 ne fait pas un nombre
  entier de semaines, et une frise de quatre semaines dont la somme **ne vaut
  pas** le compteur affiché au-dessus est un défaut bien pire qu'un ordre de
  grandeur arrondi. La fenêtre est **servie** (`fenetreJours`) : aucun écran ne
  l'écrit en dur, donc aucun ne peut mentir sur ce qu'il compte.
- **L'activité est transverse**, pas ventilée par module : les jours de travail
  ne se répartissent pas — une séance civique et une production TCF sont le même
  effort du même jour.

Routes : `docs/api-endpoints.md`, section « Progrès (T28) ». Journal :
`docs/review_all/60_DECISIONS_IMPLEMENTATION.md`, section « T28 ».

---

## Écran ACCUEIL — « Où vous en êtes » (2026-09-16)

🛑 **À distinguer de l'écran Progrès**, qui reste inchangé. Une section
**ajoutée** à l'Accueil, entre « À faire maintenant » et « Votre Plan » : une
carte compacte par épreuve TCF — palier, jauge, état en un mot, action — puis
le bandeau « Objectif actuel · Atteindre B1 partout ». Maquette du
propriétaire, seule référence (aucune capture validée n'existe dans
`~/Desktop/sejourfr_ecrans` ni `~/Desktop/grok_ecran` pour cette section).

🛑 **Les cartes d'épreuve se posent en GRILLE À DEUX COLONNES, dès 360 px**
(maquette du propriétaire, 2026-09-16) — jamais une file de cartes pleine
largeur. `HomeSituationGrid` (mobile) ⇄ `.home-situation-grid` (web, qui reprend
son auto-fit au palier desktop de 960 px, où la colonne pose les 4 épreuves de
front). Sur une demi-largeur de téléphone, la pastille de palier passe **sous**
le titre plutôt que de le casser au milieu d'un mot. Le bandeau d'objectif, lui,
reste **pleine largeur sous la grille** : il porte l'objectif de toutes les
épreuves, pas d'une carte.

🛑 **Elle ne remplace PAS « Votre progression »**, qui garde ses deux compteurs
de compétences juste en dessous. L'une dit *où en est chaque épreuve*, l'autre
*combien de compétences ont bougé*. Les fondre aurait fait disparaître un
compteur servi pour les deux parcours.

🛑 **Aucun appel de plus.** `GET /api/me/progress` est déjà lu par l'Accueil
(`progressProvider` ⇄ le lot parallèle du dashboard) et porte déjà les
4 épreuves : la section ne coûte rien au réseau.

### 🛑 La section s'affiche TOUJOURS (correctif du 2026-09-16)

⚠️ **Révoque « une liste vide veut dire aucun diagnostic clos, le bloc se
tait ».** `ProgressService.tcf()` coupait toute la réponse TCF sous
`clos.isEmpty()` — aucune session `TcfDiagnosticSession` en `COMPLETED`, donc
`epreuves = []`, donc **section entière masquée**. Chez un candidat dont la CO
et la CE étaient déjà mesurées par un examen blanc de module, l'Accueil ne
montrait rien de ce qu'il avait pourtant mesuré.

La cause était un raccourci, pas une règle : **le palier d'une épreuve ne vient
pas du diagnostic**, il vient de `TcfProfileService.levelProfile()` — « le
meilleur résultat, toutes sources confondues », l'unique autorité du dépôt sur
ce niveau. Une section de diagnostic close isolément y entre déjà (correctif de
`AttemptRepository.findQcmEpreuvesPassees`), un examen de module aussi.

Ce qui dépend encore du diagnostic 4 épreuves, et **seulement cela** :

| ce qui est servi | dépend du diagnostic 4 épreuves ? |
|---|---|
| `tcf.disponible` | **oui** — c'est son sens : « un diagnostic 4 épreuves est clos » |
| `tcf.historique` (la courbe) | **oui** — une courbe se trace sur des diagnostics clos |
| `epreuve.niveauInitial` (le palier au **premier** diagnostic) | **oui** — sans premier diagnostic, `null`, donc `evolution == INCONNUE` |
| `tcf.epreuves` (les 4 cartes) | **non** |
| `epreuve.niveau` | **non** — profil TCF |
| `tcf.niveauActuel` | **non** — `profil.globalLevel()` |

🛑 **`disponible` garde exactement son sens** et sa valeur : il commande le
palier global et la frise de l'**écran Progrès**, plus la liste des épreuves.
Ne pas le rebrancher sur « y a-t-il quelque chose à montrer ». Corollaire côté
front : l'état vide de Progrès se lit par `progresEcranVide` ⇄
`progresEcranVide` (`lib/progres.ts` ⇄ `screens/progres/progres_labels.dart`),
qui ajoute « et aucune épreuve mesurée » — sans quoi l'écran annonçait
« votre progression s'affichera après votre premier diagnostic » juste au-dessus
de la progression déjà mesurée.

### La dérivation, et pourquoi elle tient en un seul endroit

`accueilEpreuveEtat` (`lib/progres.ts` ⇄ `screens/progres/progres_labels.dart`)
vit **dans le fichier des libellés de Progrès**, pas à côté : c'est le même
statut servi, et deux tables auraient fini par le nommer autrement sur deux
écrans que le candidat voit dans la même minute.

Elle ne lit que **deux faits servis** — `status` (`StatutObjectifResolver`) et
`evolution` (`TcfDiagnosticProgressionResolver`) — et **aucun nombre**. Ordre :

| # | condition | état | statut | jauge | ton | CTA |
|---|---|---|---|---|---|---|
| 1 | `niveau == null` | `A_EVALUER` | Pas encore évaluée | 0 | neutre | Faire un exercice |
| 2 | `evolution == HAUSSE` | `EN_PROGRESSION` | En progression | 0,55 | bleu | Continuer |
| 3 | `status == TARGET_REACHED` | `SOLIDE` | Solide · à maintenir | 1 | vert | Voir mes résultats |
| 4 | `status == CLOSE_TO_TARGET` | `PROCHE` | Proche de l'objectif | 0,75 | ambre | Voir mes résultats |
| 5 | `status == TO_REINFORCE` | `A_RENFORCER` | À renforcer | 0,35 | rouge | Voir mes résultats |
| 6 | `status == null` | `SANS_OBJECTIF` | *(rien)* | 0 | neutre | Voir mes résultats |

🛑 **L'ordre 1 puis 2 puis le statut est normatif.** Le cas 1 rejoue
V040/V041/V042 s'il passe après : le serveur range bien une épreuve jamais
mesurée dans `TO_REINFORCE`, et l'écrire « à renforcer » transformerait une
absence de mesure en verdict. Le cas 2 passe avant le statut parce que dire
« à renforcer » à quelqu'un qui vient de monter d'un palier lui cache la seule
bonne nouvelle qu'il a.

### 🛑 « Faire un exercice » LANCE la mesure (2026-09-16)

⚠️ **Révoque « deux destinations : la fiche du domaine, ou la page des
résultats ».** Sur une épreuve jamais évaluée, la carte renvoyait vers la fiche
du domaine — **une étape intermédiaire** : le candidat devait y retrouver, puis
appuyer, le bouton qui lance réellement la mesure. Arbitrage du propriétaire :
un clic sur la carte **lance directement l'évaluation de cette épreuve**.

🛑 **Aucun mécanisme nouveau, aucune 5ᵉ porte.** Le descripteur est celui qui
existe déjà — `PlanDomainAssessmentResolver.pour(epreuve, diagnosticTermine)`,
la table des trois natures qui sert déjà « Compléter mon profil », la fiche d'un
domaine et la ligne `A_EVALUER` de la séance :

| épreuve | ce qui est lancé |
|---|---|
| `TCF_CO` / `TCF_CE` | `MODULE_MOCK_EXAM` — examen blanc de module, **slot 1**, le slot offert à tout compte |
| `TCF_EE` / `TCF_EO`, diagnostic **non** terminé | `DIAGNOSTIC` |
| `TCF_EE` / `TCF_EO`, diagnostic terminé | `PRODUCTION` — le catalogue standard (le diagnostic ne se rejoue pas) |

🛑 **Ce qui a été explicitement ÉCARTÉ** : lancer `/api/tcf-diagnostics` ciblé
sur une seule section. Ce serait une 5ᵉ porte vers un mécanisme qui n'est routé
nulle part ailleurs depuis l'Accueil ou le Plan, et elle entrerait en conflit
avec la réévaluation payante espacée (`TcfReassessmentService`) une fois le
diagnostic `COMPLETED`.

**Contrat servi** : `ProgressDto.Epreuve.evaluation`, un `PlanDomainAssessmentDto`
— renseigné **quand et seulement quand** `niveau == null`, `null` dès qu'un
palier existe (rien à mesurer, on ne propose pas de refaire une mesure qui
existe). `diagnosticTermine` vient de **`PlanFoundationResolver`**, la même
autorité que le Plan et que `PreparationDto.planDisponible` : la carte de
l'Accueil et la carte du Plan ne peuvent donc pas désigner deux parcours
différents pour le même domaine.

🛑 **Le lanceur est celui du Plan, jamais un second** : `usePlanAssessment`
(web) ⇄ `openPlanAssessment` (mobile). Les fronts passent le descripteur reçu et
n'écrivent aucune route de démarrage. Un `evaluation` absent (client servi par
un backend antérieur) **replie sur le comportement d'avant**, la fiche du
domaine.

**Les trois issues d'une carte**, dans l'ordre où elles se décident :

| # | condition | ce qui se passe |
|---|---|---|
| 1 | `niveau == null` **et** `evaluation != null` | la mesure est **lancée** (`usePlanAssessment` / `openPlanAssessment`) |
| 2 | il y a quelque chose à faire, rien à lancer (`EN_PROGRESSION`, ou descripteur absent) | la **fiche du domaine** (`planDomainHref` / `openPlanDomain`) |
| 3 | rien à faire | la page **« Voir mes résultats »** |

Le choix se lit sur l'**état servi**, jamais sur le texte du bouton.

### La jauge n'est pas un pourcentage — arbitrage

La règle « **aucun pourcentage de progression vers un palier** » (`30_` §7)
**tient**, et la maquette montre pourtant une barre. Les deux se concilient
ainsi : la barre est le **codage visuel d'un enum servi**, à cinq positions
fixes (tableau ci-dessus), et **aucun chiffre n'est rendu** — elle dit
exactement ce que dit le mot écrit juste en dessous, rien de plus. Ce qui reste
interdit, et qui n'est fait nulle part : dériver un remplissage d'un rang CECRL
(`rang(niveau) / rang(objectif)`), afficher un « % vers le B1 », ou mettre un
pourcentage et un palier dans le même bloc visuel.

Le ton passe par **`ProgressMini` / `SfProgressMini`**, la primitive existante,
qui gagne un `tone` (`BarTone` ⇄ `SfBarTone`) **dans les deux kits dans la même
passe** — vert / bleu / ambre / rouge / neutre, la palette des segments de
parcours, pas une nouvelle.

### La variante CIVIQUE

Même carte, autres données : `ProgressCivique.themes` (`CivicPlanDto.ThemeLigne`,
le même record que le Plan). 🛑 **Aucune métrique CECRL** (`20_` §12) — l'état
arrive servi, son libellé vient de `CIVIC_THEME_STATE_LABEL` ⇄
`CivicThemeState.label` et son ton de `civicBarTone` ⇄ `civicThemeBarTone`, qui
**dérivent** de `kitTone` ⇄ `civicThemeTone` au lieu de reclasser l'état.
🛑 `NON_EVALUE` reste **neutre**, badge « À évaluer », jauge 0 — jamais ambre.
🛑 Le **bandeau d'objectif est omis** côté civique : rien ne sert d'objectif
civique, et on ne fabrique pas une mesure qui n'existe pas.

### La page « Voir mes résultats »

`/historique/epreuve/{co|ce|ee|eo}` (web) ⇄ `/historiques/epreuve/:domainKey`
(mobile) — les **évaluations qualifiantes** d'une épreuve, servies par
`GET /api/me/progress/tcf/{epreuve}/historique`.

🛑 **Ce n'est pas la seconde liste d'historique que le dépôt refuse.**
`/historique` liste **toutes** les sessions, entraînements compris ;
`/statistiques` répond à « où j'en suis » et `/plan/progression` à « ce qu'il
reste ». Aucune des trois ne répond à « **pourquoi ce niveau ?** », et c'est la
seule question à laquelle celle-ci répond — d'où sa place **sous**
`/historique`, la surface des résultats, et non dans une quatrième page de
progression.

🛑 **Cas vide** : « Aucune évaluation qualifiante pour l'instant. » — jamais une
erreur. Et un **échec de chargement** se dit autrement : on ne range pas une
panne réseau dans le verdict le plus bas.

#### ⚠️ Arbitrage OUVERT — EE/EO : la page est plus étroite que le profil

🛑 **CO/CE : aucun écart.** Même requête (`findQcmEpreuvesPassees`) et même
autorité de niveau (`niveauEpreuveQcm`) que `TcfProfileService` : ce que la
page montre explique exactement le palier servi.

**EE/EO : deux écarts**, et ils viennent d'une prémisse fausse de l'énoncé
(« exactement la même définition qui alimente déjà `niveau` ») :

| | profil (`bestProduction`) | cette page |
|---|---|---|
| unité | le **maximum par TÂCHE** | l'**agrégat par SESSION** (`niveauEpreuve`) |
| périmètre | **toute** tâche évaluée — `AiEvaluationRepository.findByUserAndEpreuve` ne filtre ni la session d'examen ni l'entraînement libre | **sessions d'examen** + baseline du diagnostic rapide |

🛑 **Conséquence à connaître** : un candidat qui n'a fait que de l'entraînement
libre en EE/EO a un `niveau` servi — donc une carte d'Accueil qui propose
« Voir mes résultats » — et cette page lui répond « aucune évaluation
qualifiante ». Les deux énoncés sont vrais séparément : le palier vient bien de
quelque part, mais pas d'une épreuve.

Ce qui a été fait en attendant l'arbitrage : **le libellé de la page ne promet
plus d'expliquer le niveau**, il dit ce que la liste *contient* (« Vos épreuves
complètes et vos diagnostics… »), donc il reste vrai même vide.

Deux sorties, **toutes deux des décisions produit** :

1. **restreindre le profil EE/EO** aux sessions d'examen — il **baisserait** des
   niveaux déjà affichés à des candidats, ce que le dépôt n'autorise qu'à un
   garde-fou explicite ;
2. **accueillir l'entraînement libre** ici sous une 5ᵉ provenance — ce qui
   contredirait l'énumération du propriétaire (« pas les petites séries /
   petits sujets d'entraînement »).
