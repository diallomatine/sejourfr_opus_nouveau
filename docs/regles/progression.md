# Moteur de progression V4.2 — ce qui est en place, ce qui ne l'est pas

Spécification normative complète : `docs/plan/SEJOURFR_PROGRESSION_ENGINE_V4_2.md`.
Ce fichier-ci ne la résume pas — il dit **où en est l'implémentation** et **ce qui casse en
silence si on l'ignore**.

État au **2026-08-23** : **phase 0 livrée, moteur non écrit**. §49 impose un *hard stop* :
rien du moteur ne s'écrit avant validation explicite du propriétaire.

---

## Ce qui existe

| Livrable | Où |
|---|---|
| Configuration figée v1 | `backend_sejourfr/src/main/resources/progression/progression-config-v1.json` |
| Chargeur + validation au démarrage | `com.sejourfr.app.progression.config.ProgressionConfigLoader` |
| Feature flag SHADOW / ACTIVE | `sejourfr.progression.mode` (`application.yaml`) |
| Contrat de domaine (enums, `LearningEvidence`, `ProgressionStateKey`, snapshots) | `com.sejourfr.app.progression.domain` |
| Contrat du moteur (interface pure) | `com.sejourfr.app.progression.engine.ProgressionEngine` |
| Verrou de la config, valeur par valeur | `ProgressionConfigTest` — **vert** |
| T01–T35 | `ProgressionEngineAcceptanceTest` — **écrits, `@Disabled`** |
| T36 (conformité front) | `scripts/verifier-contrat-front-progression.mjs` — **vert** |

## Ce qui n'existe pas

Le moteur. Pas de table `learning_evidence`, pas de `progression_state`, pas de
`progression_prediction_log`, aucune migration Flyway, aucun endpoint. `PhaseZeroEngine`
(test) lève `UnsupportedOperationException` sur chaque appel — 🛑 **ne jamais lui donner
« juste assez » d'implémentation pour faire verdir un test.**

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

## Le passage à ACTIVE

```text
PROGRESSION_ENGINE_MODE=SHADOW   (défaut)
PROGRESSION_ENGINE_MODE=ACTIVE
```

🛑 On ne passe à `ACTIVE` **qu'après** validation produit des métriques shadow : précision
des prédictions `SOLID` ≥ 70 % sur 30 jours (§47.4). Les seuils de la v1 sont des
**hypothèses produit**, pas des mesures. Si la précision est sous 70 %, on ne bricole pas la
config : on analyse, on crée une v2, on rejoue.

---

## Ordre de reprise (§49)

| Phase | Contenu | État |
|---|---|---|
| 0 | config figée, T01–T36 écrits, feature flag, nettoyage front | **livré** |
| 1 | `learning_evidence`, agrégat epoch, `progression_state`, gates, prérequis, shadow | à valider |
| 2 | analyse shadow → `ACTIVE` → Plan branché sur `prescriptionLevel` | — |
| 3 | EE/EO : observations IA, cap micro, `transferGate`, corpus de stabilité | — |
| 4 | calibration contenu : `difficultyBand`, séries 6/10/4, `CONTENT_BANK_TOO_SMALL` | — |

Avant la phase 1, relire §27.2.1 : les accumulateurs epoch se stockent en
`double precision`, **jamais** en `NUMERIC(p,s)` ni en `BigDecimal`. Ils croissent
exponentiellement — `≈ 2.6e24` à J+3650 — et un décimal à précision fixe déborde en
silence, sur une donnée matérialisée que rien ne recalcule dans le chemin nominal.
