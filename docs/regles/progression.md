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

### 🛑 EE/EO — un ENTRAÎNEMENT ne définit JAMAIS le niveau global AFFICHÉ ICI (2026-09-16)

Règle du propriétaire. Pour l'expression **orale** et **écrite**, un
entraînement ne définit jamais le palier affiché ici, **même corrigé par l'IA et
même situé sur un niveau CECRL**. Un entraînement sert à pratiquer autant qu'on
veut, à alimenter compétences / priorités / feedbacks, et à porter son **niveau
observé sur la tâche** — sur son propre écran de résultat, ce qui ne change pas.

🛑 **Cette règle s'arrête à l'ACCUEIL. Le PLAN n'est pas concerné** (périmètre
corrigé le jour même par le propriétaire). Le Plan, ses priorités et ses
compétences **continuent** de voir les observations d'entraînement EE/EO : une
production d'entraînement corrigée est une observation pleine et entière, elle
n'est simplement pas une **mesure d'épreuve**. Concrètement, deux lectures de la
même autorité :

| lecture | qui l'appelle | ce que vaut une épreuve | EE/EO viennent de |
|---|---|---|---|
| `TcfProfileService.levelProfile` | `PlanCycleResolver`, priorités, compétences | le **MEILLEUR** résultat de tout l'historique | **toute** évaluation IA valide, entraînement compris |
| `TcfProfileService.levelProfileAccueil` | `ProgressService.tcf()` **et** `UserDashboardService` | la **MOYENNE des 3 derniers examens qualifiants** | **uniquement** les épreuves complètes |

Les deux peuvent donc **diverger**, et c'est voulu : l'affichage dit « à
évaluer », ou annonce un palier en baisse, pendant que le Plan travaille déjà le
domaine sur son meilleur niveau connu. Ce qui serait un défaut, c'est qu'un
écran **recalcule** l'une des deux — ils l'appellent.

🛑 **Toutes les surfaces d'affichage lisent la MÊME lecture** (2026-09-16,
seconde passe). `UserDashboardService` est passé de `levelProfile` à
`levelProfileAccueil` : `DashboardSummaryResponse.estimatedTcfLevel` étant le
seul endroit d'où sort ce niveau pour les fronts, les **cinq** surfaces web
(`/dashboard`, `/profil`, `/statistiques`, `TcfHub`, `/examens-blancs`) et les
deux surfaces mobiles (Accueil, Profil) annoncent maintenant **le même palier
que l'Accueil**, au même instant. Avant, le Profil servait le maximum du Plan
pendant que l'Accueil servait autre chose. **Aucun DTO n'a changé de forme**, et
`TcfDomainProfileDto` publiait déjà les 4 paliers d'épreuve à côté du global.

✅ **RÉVISER a rejoint la liste le 2026-09-16** (troisième passe), et c'était la
**dernière contradiction de niveau connue** du dépôt. L'écran écrivait
« Niveau estimé : X » sur `domain?.niveau ?? stat.level`, c'est-à-dire **deux
autres autorités** : la lecture du **Plan** (`PlanDomainDto.niveau` — le maximum,
entraînements EE/EO compris) puis, en repli, `DashboardCategoryStat.level` — le
dernier niveau CECRL de n'importe quelle soumission, **une troisième autorité,
encore plus large, et qui n'avait aucune raison d'exister ici**. Un candidat dont
la seule trace EO était un entraînement de trois minutes y lisait un palier
pendant que l'Accueil, le Profil, l'écran Progrès et l'écran Diagnostic disaient
tous « à évaluer ».
- Il lit désormais **`tcfDomainProfile`**, par
  `niveauActuelEpreuve(profil, code)` (`web_sejoufr/lib/reviser.ts` ⇄
  `mobile_sejourfr/lib/screens/reviser/reviser_labels.dart`). Le **code de
  catégorie est la valeur de `epreuve`** : aucune table de correspondance n'est
  écrite côté front.
- 🛑 **Aucun appel de plus** : les deux Réviser chargeaient déjà
  `GET /api/me/dashboard` — ils y lisent `CategoryStat` pour les séries. Le
  profil par domaine voyageait dans la même réponse, inutilisé.
- 🛑 **Le repli `stat.level` est SUPPRIMÉ de cette phrase.** Le champ **reste au
  DTO** : il a d'autres lecteurs (`/statistiques` et `ReinforceRow` côté web,
  `progres_screen` et `reco_screen` côté mobile).
- **Épreuve non mesurée ⇒ aucun palier inventé** : la ligne retombe sur ce que
  Réviser sait **compter** (séries terminées, compétences observées), et à
  défaut sur son propre « **Pas encore travaillé** » — le vocabulaire du
  catalogue, pas le « À évaluer » d'un constat. `null` = inconnu, jamais un
  plancher.
- **La dérivation n'est PAS partagée avec l'Accueil** (`accueilEpreuveEtat`),
  et c'est voulu : celle-ci rend un **état pédagogique servi** (statut +
  evolution → ton, jauge, CTA), Réviser rend une **ligne de catalogue** (étape en
  cours, compétences acquises, séries faites). Seule la **source du niveau** leur
  est commune, et c'est elle qu'on a unifiée.
- ⚠️ **La fiche de domaine du Plan (`/plan/domaine/[x]`) n'est PAS concernée** :
  elle affiche la lecture du Plan parce qu'elle *est* le Plan. → journal :
  `docs/decisions/diagnostic.md`.

Le niveau global d'une épreuve de production ne bouge que sur un **examen
complet de l'épreuve**. **Trois provenances, et seulement trois** :

1. l'épreuve EO/EE du **diagnostic complet** (4 épreuves) ;
2. un **examen blanc isolé** de l'épreuve ;
3. l'épreuve EO/EE d'un **examen blanc TCF complet**.

Dans les trois cas, le niveau retenu est celui de l'**épreuve entière** —
l'agrégat pondéré de ses 3 tâches (`ProductionBilanService.niveauEpreuve`),
jamais une tâche isolée. Sans aucun examen complet : `niveau = null`, et l'écran
dit « **Expression orale — À évaluer** ». Le contrat ne change pas de forme :
`niveau` était déjà nullable, aucun front n'est touché.

🛑 **`attempts.type` ne distingue RIEN ici** — piège coûteux :
`AttemptService.startProduction` pose `TRAINING` sur **toutes** les sessions de
production, examen blanc isolé compris. Le prédicat réel est celui de
`ProductionAccessService.isExamSession`, porté en JPQL par
`AttemptRepository.findProductionEpreuvesPassees` : `slot_number IS NOT NULL`
(cas 2) **ou** `parent_attempt_id IS NOT NULL` (cas 3 **et** cas 1, le
diagnostic complet accrochant ses sections au même conteneur), plus
`finished_at IS NOT NULL` et au moins une soumission.

**Une règle, une autorité** : `EpreuvesProductionQualifiantesResolver` (extrait
le 2026-09-16 à sa 2ᵉ occurrence), appelé par
`TcfProfileService.levelProfileAccueil` **et** par `EpreuveHistoriqueService` —
jamais par la lecture du Plan. L'entraînement libre — sessions temps réel de
l'examinateur vocal comprises — n'a ni slot ni parent : il est dehors, quel que
soit le nombre de tâches soumises.

🛑 **Le niveau GLOBAL de l'Accueil suit la même règle** : c'est le plancher des
**quatre paliers affichés**, pas celui du profil du Plan. Sinon l'écran
annoncerait un niveau global tiré d'une EO qu'il présente deux lignes plus bas
comme non évaluée.

**`niveauInitial`, `evolution` et `status` ne changent pas de source** :
`niveauInitial` vient des sections du premier diagnostic 4 épreuves clos, et une
section EE/EO de diagnostic complet est justement l'une des trois provenances
qualifiantes — les deux paliers se lisent sur la même famille de mesures.
⚠️ **Ce qui a changé le 2026-09-16 : `actuel` PEUT désormais passer sous
`initial`**, la moyenne ayant remplacé le maximum. `evolution` rend alors
`BAISSE`, et c'est le comportement voulu — un candidat qui a régressé doit le
lire. `status` en dérive sans rien à changer.

**Ce qui a motivé la règle** : un compte dont la seule trace EO était un
entraînement de trois minutes, noté A2, affichait « expression orale : A2 » sans
avoir jamais passé d'épreuve d'EO. → `docs/decisions/diagnostic.md`.

🛑 **Le repli sur la baseline du diagnostic RAPIDE est inchangé** : quand aucune
des trois provenances n'existe, `diagnostic_production_analyses` renseigne encore
le domaine. Une baseline n'est jamais **concurrente** d'une preuve réelle, elle
n'est qu'un **repli** — cette règle-là n'a pas bougé.

### 🛑 Le niveau AFFICHÉ = la MOYENNE des 3 derniers examens qualifiants (2026-09-16)

⚠️ **Cette règle RÉVOQUE le « maximum monotone » et la protection « le niveau ne
redescend jamais »** de la lecture d'affichage, posées le matin même. Décision du
propriétaire, verbatim :

> Je confirme : **moyenne des 3 derniers examens qualifiants**. Le niveau affiché
> doit représenter le **niveau actuel estimé**, donc il peut monter comme
> descendre. 1 examen qualifiant → niveau de cet examen ; 2 examens → moyenne des
> 2 ; 3 examens ou plus → moyenne des **3 derniers uniquement**. […] Si on dispose
> d'un **score numérique interne**, moyenne d'abord les **scores** puis transforme
> le résultat en niveau CECRL. Évite de faire une moyenne directe des labels
> A2/B1/B2. On retire donc la règle du **maximum monotone** et la protection « le
> niveau ne redescend jamais ». Le meilleur niveau atteint peut rester visible
> plus tard dans l'historique, mais il ne doit pas être confondu avec le niveau
> actuel affiché.

**Où vit le calcul** : `NiveauActuelEpreuveResolver`, une seule fois pour les
4 épreuves. `TcfProfileService.levelProfileAccueil` l'appelle ; **personne
d'autre**.

**Ce qui compte comme examen qualifiant** — aucune définition nouvelle, les deux
qui existent sont appelées, et ce sont celles de « Voir mes résultats » :

| épreuve | source | ce qui est exclu |
|---|---|---|
| CO / CE | `AttemptRepository.findQcmEpreuvesPassees` | les sessions **sans aucune réponse** |
| EE / EO | `EpreuvesProductionQualifiantesResolver` | **l'entraînement libre**, examinateur vocal compris |

Les trois provenances (diagnostic complet · examen blanc isolé · examen blanc TCF
complet) comptent **à égalité** : aucun traitement selon la provenance.

**On moyenne des SCORES, jamais des labels.** Un niveau CECRL est une *bande* :
« la moyenne d'un A2 et d'un B2 » n'a pas de sens arithmétique, et la calculer
sur les ordinaux d'un enum ferait dépendre le résultat de l'ordre de déclaration.

| épreuve | score moyenné | table de conversion (existante, **jamais recopiée**) |
|---|---|---|
| CO / CE | le **score calibré 100-499** (`TcfLevelEstimatorService.calibratedScore`) | `TcfLevelEstimatorService.niveauDepuisScoreCalibre` — ≥400 B2, ≥300 B1, ≥200 A2, ≥101 A1 |
| EE / EO | la **compétence /20 de l'épreuve** (`ProductionBilanService.NiveauEpreuve.competence`, l'agrégat pondéré des 3 tâches) | `ProductionBilanService.niveauDepuisCompetence` — les seuils de la grille active |

La moyenne est arithmétique et **non pondérée** : les trois examens retenus
mesurent la même épreuve dans les mêmes conditions.

🛑 **Règle de bande : une moyenne qui tombe ENTRE deux bandes reste dans la bande
BASSE.** C'est la convention déjà en vigueur pour les notes de critère, et elle
est gratuite ici : les deux tables sont des **bornes basses** (`>=`). Côté QCM la
moyenne est ramenée à l'entier **inférieur** avant conversion, ce qui est la même
décision — 399,5 reste B1, 400,0 devient B2.

**Ce qui survit à la moyenne** : le **plancher produit** « au moins une bonne
réponse ⇒ au moins A1 » (réappliqué par son autorité, non recodé), le **plafond
B2**, et le **garde-fou de cohérence T3** (il abaissait déjà le niveau d'une
session ; la compétence publiée est ramenée sous la bande plafonnée par
`sousPlafond`, sinon le plafond se perdrait dans la moyenne).

**Aucun examen qualifiant ⇒ `null`** (« À évaluer »), jamais un plancher
fabriqué. Une session qui porte un palier mais **aucun score moyennable** (repli
sur les niveaux persistés, attempt legacy sans score pondéré) ne casse rien : si
aucune des sessions retenues n'a de score, le palier de la **plus récente** fait
foi — « 1 examen → le niveau de cet examen ».

**Le niveau global affiché reste le MIN des 4 épreuves**, chacune valant sa
propre moyenne — `TcfLevelEstimatorService.floor`, la règle du plancher n'étant
pas dupliquée.

### 🛑 Niveau ACTUEL affiché ≠ MEILLEUR niveau atteint

Deux faits différents, et depuis le 2026-09-16 **deux écrans différents** :

| | ce que c'est | où le candidat le lit |
|---|---|---|
| **niveau actuel estimé** | moyenne des ≤3 derniers examens qualifiants | Accueil, Profil, `/dashboard`, `/statistiques`, `TcfHub`, `/examens-blancs`, **écran Diagnostic TCF**, **Réviser** |
| **meilleur niveau atteint** | le plus haut palier jamais obtenu | « Voir mes résultats » (`EpreuveHistoriqueService`), qui liste les 3 dernières mesures avec leur date et leur provenance |

Ne jamais présenter l'un comme l'autre : un candidat dont la moyenne redescend
garde son meilleur jour lisible, mais ce n'est plus son niveau.

⚠️ **Le PLAN, lui, garde le maximum** (`levelProfile`) : un Plan n'a pas à
désapprendre ce qu'un candidat a démontré, et l'anti-yoyo de la spec V2 §5.3 y
tient toujours par construction. La section « anti-yoyo » de
`TcfProfileServiceTest` ne vaut donc **que pour la lecture du Plan**.

### 🛑 « Mesurée » n'a qu'une définition, et c'est celle-ci (2026-09-16)

`NiveauActuelEpreuveResolver` **est** la réponse à « cette épreuve est-elle
mesurée ? » : `null` ⇒ non, non-`null` ⇒ oui. Il n'en existe pas d'autre, et il
ne faut pas en écrire une seconde.

C'est ce qui a permis de fermer le dernier écran qui s'en écartait :
**l'écran Diagnostic TCF 4 épreuves**, qui ne lisait que les sous-attempts de sa
propre session et annonçait « Terminée · Non évaluée » sur une CO qu'un examen
blanc isolé avait pourtant mesurée. Il lit désormais la même autorité, par
`TcfDiagnosticReadService.sectionsMesurees` — une épreuve mesurée y est une
section **faite**, avec le niveau du produit.
→ `docs/regles/diagnostic-tcf-4-epreuves.md`, § « Une épreuve MESURÉE est une
section FAITE ».

⚠️ **Le resolver rend aussi l'attempt source** (`Mesure(niveau, attemptId)`,
le plus récent des examens retenus) : c'est la destination d'un « Voir le
rapport ». Ça ne change **rien** au niveau servi.

⚠️ **Ce que la lecture HISTORIQUE d'un diagnostic ne doit pas faire** :
`TcfDiagnosticReadService.sections` reste ce que **cette session-là** a mesuré.
C'est elle qui porte `niveauInitial` et la courbe de l'écran Progrès. L'enrichir
rendrait toute `evolution` `STABLE`.

**Tests** : `NiveauActuelEpreuveResolverTest` (1 / 2 / 4 examens, la baisse sur
un mauvais examen récent, la bande basse, le plancher A1, le repli sans score),
`TcfProfileServiceTest` section « lecture d'AFFICHAGE » (le câblage, le min des
4, l'affichage plus bas que le Plan), `TcfProfileServiceIT` (les 3 provenances à
égalité, la moyenne en base, la fenêtre de 3, l'entraînement dehors, le min des
4 sur les 4 vraies épreuves).

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
existe déjà — `PlanDomainAssessmentResolver.pour(epreuve)`, la table des natures
qui sert déjà « Compléter mon profil », la fiche d'un domaine, l'écran Progrès,
Réviser et la ligne `A_EVALUER` de la séance :

| épreuve | ce qui est lancé |
|---|---|
| `TCF_CO` / `TCF_CE` | `MODULE_MOCK_EXAM` — examen blanc de module, **slot 1**, le slot offert à tout compte |
| `TCF_EE` / `TCF_EO` | `PRODUCTION_MOCK_EXAM` — examen blanc de production (les 3 tâches), **slot 1** |

🛑 **Mesurer une épreuve, c'est passer un EXAMEN BLANC — les quatre, sans
exception** (arbitrage du propriétaire, **2026-09-16**). ⚠️ **Révoque les deux
lignes d'expression qui vivaient ici** : `DIAGNOSTIC` (l'ancien diagnostic
1 EE + 1 EO) tant qu'il n'était pas terminé, `PRODUCTION` (les 3 tâches en
entraînement libre) ensuite. **Aucun des deux ne lançait un examen blanc** :
« Évaluer mon niveau » ne voulait donc pas dire la même chose en CO/CE et en
EE/EO, et le candidat retombait sur un parcours d'entraînement là où la carte
promettait une mesure. Les deux natures sont **supprimées** de
`PlanDomainAssessmentKind`, avec leurs factories et leurs cas front.

⚠️ **C'est l'ACTION qui change, pas l'AFFICHAGE.** Le niveau qu'un ancien
diagnostic a déjà produit continue de s'afficher — `TcfProfileService` le lit en
repli, et ce repli n'a pas bougé.

🛑 **Le paramètre `diagnosticTermine` a disparu de `pour()`, de `resolve()` et
d'`indispensable()`**, et de tous leurs appelants : il n'aiguillait que
l'expression. `ProgressService` ne lit donc plus `PlanFoundationResolver` — une
requête de moins par lecture de `/api/me/progress`.

🛑 **Ce qui a été explicitement ÉCARTÉ** : lancer `/api/tcf-diagnostics` ciblé
sur une seule section. Ce serait une 5ᵉ porte vers un mécanisme qui n'est routé
nulle part ailleurs depuis l'Accueil ou le Plan, et elle entrerait en conflit
avec la réévaluation payante espacée (`TcfReassessmentService`) une fois le
diagnostic `COMPLETED`.

**Contrat servi** : `ProgressDto.Epreuve.evaluation`, un `PlanDomainAssessmentDto`
— renseigné **quand et seulement quand** `niveau == null`, `null` dès qu'un
palier existe (rien à mesurer, on ne propose pas de refaire une mesure qui
existe). `slotNumber` vaut **1** sur les quatre épreuves (le slot offert et
rejouable : mesurer un domaine ne bute jamais sur le paywall), et c'est **lui**
qui pilote le lancement — aucun front n'écrit `1` en dur.
`estimatedMinutes` suit `DureeEpreuve` : 20 (CO), 35 (CE), 30 (EE) et **`null`
en EO**, qui se chronomètre tâche par tâche — on n'annonce alors aucune minute.

🛑 **Le lanceur est celui du Plan, jamais un second** : `usePlanAssessment`
(web) ⇄ `openPlanAssessment` (mobile). Les fronts passent le descripteur reçu et
n'écrivent aucune route de démarrage. Un `evaluation` absent (client servi par
un backend antérieur) **replie sur le comportement d'avant**, la fiche du
domaine.

**Et le démarrage d'un examen de production est le MÊME que celui du jalon du
Plan** (`PlanExerciseKind.EPREUVE_MOCK_EXAM`), extrait pour ne pas être recopié :
`startProductionMockExam` (`use-plan-exercise.ts`) ⇄ `startProductionExam`
(`screens/tcf_production/production_exam_launcher.dart`, qui sert aussi la
grille d'examens de l'épreuve). Un 403 y ouvre l'offre, jamais une erreur
technique.

⚠️ **Le sas suit l'épreuve, et il suit le front.** Sur mobile, les quatre
épreuves ouvrent leur briefing avant de démarrer — `ModuleExamBriefingSheet` en
CO/CE, `ProductionExamBriefingSheet` en EE/EO. Sur le web, les quatre démarrent
**directement**, comme le faisait déjà CO/CE depuis ce point d'entrée. L'écart
est **de forme et antérieur** à cette passe ; ce qui compte est qu'à l'intérieur
d'un front les quatre épreuves se comportent pareil.

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

#### ✅ Arbitrage CLOS le 2026-09-16 — cette page et l'ACCUEIL lisent la même chose

Le propriétaire a tranché la **sortie 1**, puis en a **borné le périmètre le jour
même** : c'est le niveau **affiché sur l'Accueil** qui se restreint aux examens
complets, pas la lecture du Plan. → journal : `docs/decisions/diagnostic.md`.

🛑 **CO/CE : aucun écart**, et il n'y en a jamais eu. Même requête
(`findQcmEpreuvesPassees`) et même autorité de niveau (`niveauEpreuveQcm`) que
`TcfProfileService` : ce que la page montre explique exactement le palier servi.

🛑 **EE/EO : plus d'écart avec l'Accueil.** Les deux lisent
`EpreuvesProductionQualifiantesResolver.qualifiantes(...)` — même liste de
sessions, même niveau par session (`ProductionBilanService.niveauEpreuve`,
l'agrégat des 3 tâches). Le seul écart restant est l'**usage** : l'affichage en
prend la **moyenne des 3 dernières** (`NiveauActuelEpreuveResolver`, appelé par
`TcfProfileService.levelProfileAccueil`), la page en garde la **chronologie**.
Un candidat ne peut donc plus voir un palier d'Accueil que cette page ne sait
pas expliquer — et c'est ici, et ici seulement, qu'il retrouve son **meilleur
niveau atteint**, que le palier affiché ne prétend plus être.
⚠️ C'était un **maximum** jusqu'au 2026-09-16 ; le propriétaire l'a révoqué le
jour même.

⚠️ **Le PLAN, lui, reste plus large, et c'est voulu** :
`TcfProfileService.levelProfile` voit toujours les entraînements EE/EO évalués.
Un domaine peut donc être travaillé par le Plan pendant que cette page et
l'Accueil disent « à évaluer » — ce n'est pas une contradiction, ce sont deux
questions différentes : « qu'ai-je observé de vous ? » contre « quelle épreuve
avez-vous passée ? ».

Ce que la page ajoute, et c'est voulu : la **baseline du diagnostic rapide** y
apparaît toujours en 4ᵉ provenance, alors que les deux lectures du profil ne s'en
servent qu'**en repli** (cf. plus bas).
