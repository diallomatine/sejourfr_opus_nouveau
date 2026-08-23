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
- **Corpus de stabilité IA (§45)** : *non fait, et volontairement.* Mesurer la dérive d'un
  prompt exige d'appeler un fournisseur payant sur un corpus fixe. `CLAUDE.md` l'interdit sans
  demande explicite du propriétaire — c'est son argent, il décide. Le corpus lui-même
  (productions A2/B1/B2 limites, hors sujet, très courtes, très longues) est à constituer avant
  toute campagne.

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

## Trois arbitrages d'implémentation à confirmer

Aucun ne touche à `progression-config-v1.json`, mais tous les trois sont des choix que le
propriétaire peut vouloir trancher autrement. Ils vivent en constantes documentées, pas en
config, précisément pour qu'on les voie.

| Choix | Où | Pourquoi ainsi |
|---|---|---|
| Confiance IA `LOW / MEDIUM / HIGH` → `0,50 / 0,75 / 0,95` | `ProductiveEvidenceAdapter.CONFIANCE_IA` | Le tool-schema livré rend un **enum**, pas un nombre, et on ne réécrit pas un contrat livré. `HIGH` ne vaut pas 1,00 : une évaluation IA n'est jamais une certitude. Candidat pour la config v2. |
| Un micro-sujet guidé pèse `LIGHT` (0,85) | `LearningPlanObservationService.recordSkillAttemptProgression` | Checklist, amorce et astuce sont la raison d'être pédagogique du micro-sujet — et une assistance réelle. §8.2 veut qu'une preuve assistée pèse moins, sans plancher. |
| Un micro-sujet a `scoringConfidence = 0,75` | `ProductiveEvidenceAdapter.ingererMicroSujet` | Un critère unique jugé sur une production courte : moins de matière qu'une tâche complète, donc moins de certitude. On le dit plutôt que de faire comme si. |

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

**Conséquence aujourd'hui** : le catalogue n'ayant aucune bande, toutes les séries
d'entraînement pèsent 0,50 et ne verrouillent aucun palier. Seuls les examens blancs le font —
leurs strates sont garanties à la composition (8 A2 + 9 B1 + 8 B2). **Taguer le catalogue est
le travail de contenu qui reste**, et c'est lui qui débloquera la progression par
l'entraînement.

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

§28 décrit une mise à jour O(1). Les accumulateurs le sont ; **la machine à états ne l'est
pas** — les hystérésis, le passage `SOLID → WATCH` et la monotonie de `visibleProgress`
dépendent de l'histoire, pas du total.

`ProgressionIngestionService` relit donc l'historique **de la seule clé touchée** et rejoue le
moteur dessus. C'est un écart assumé à la lettre de §28, pour tenir une règle qui compte
davantage : *une règle, une autorité*. Dupliquer la machine à états dans un chemin incrémental
garantirait qu'un jour les deux divergent — c'est le défaut le plus cher du dépôt.

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
2. `GET /api/admin/progression/shadow` — lire précision **et base** ;
3. décider.

🛑 On ne passe à `ACTIVE` **qu'après** validation produit : précision des prédictions `SOLID`
≥ 70 % (§47.4), sur une base qui veuille dire quelque chose. Une précision de 100 % sur deux
prédictions n'est pas une mesure — le rapport sert donc toujours le dénominateur à côté du
pourcentage, et refuse de conclure quand il n'y a rien.

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
