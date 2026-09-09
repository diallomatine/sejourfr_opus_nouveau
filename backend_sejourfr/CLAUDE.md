# SejourFR Backend — index et invariants

API REST unique (Spring Boot 4 / Java 21 / PostgreSQL / Flyway / JWT) des 3 fronts. Elle est la
**source de vérité** des DTO, des règles métier et du freemium.

🛑 **Ce fichier est un index, pas une référence.** Il est rechargé à chaque requête dès qu'on
travaille dans ce dossier, donc il ne contient que **la façon d'écrire du code serveur ici** et
**de quoi savoir quel fichier ouvrir**. **Aucune règle métier n'y vit** — elles sont toutes dans
`docs/regles/*.md`, en lecture à la demande. Lire aussi le `CLAUDE.md` racine.

## Convention de couches — `Controller → Service → Manager → Repository`, strict

- **Controllers** : ultra-fins. Ils délèguent tout au service. Pas de logique, pas de mapping
  inline, pas d'accès repo.
- **Services** : orchestrent **un** cas d'usage (validations, règles métier, transactions,
  mapping DTO). Ils **n'accèdent jamais à un `*Repository`** — ils passent par les managers. Un
  service peut appeler plusieurs managers et d'autres services.
- **Managers** (`manager/`) : **seule couche autorisée** à appeler les `*Repository`. Un manager
  par agrégat, même pour du CRUD trivial. `int limit` plutôt que `Pageable` quand ça suffit ;
  `Specification + Pageable` quand la recherche est dynamique.
- **Mappers** : `@Component`, **purs**. Ils reçoivent l'entité + les compléments en paramètres et
  rendent un DTO. Ils ne touchent ni repo ni manager. Si un mapping a besoin d'une lookup, c'est
  le service qui la fait avant.
- **Lombok** : `@RequiredArgsConstructor` sur controllers/services/managers/mappers, `@Slf4j` au
  lieu de `LoggerFactory`. Sur les entités JPA : `@Getter`/`@Setter` OK, **jamais `@Data`** ni
  `@EqualsAndHashCode` automatique (toString/equals + lazy loading = bugs).
- **Seule exception** : `audioquestion/`, sous-module isolé non migré (refacto reportée). Ses
  services peuvent encore appeler `MediaRepository` directement. Ne pas étendre l'exception.

Arborescence : `entity/`, `repository/`, `manager/`, `service/`, `controller/`, `dto/`,
`mapper/`, `specification/`, `security/`, `config/`, `exception/`, `enums/` (+ `audioquestion/`).

## Comment on écrit une règle ici

- **Un dérivé se relit, il ne se persiste pas.** Statuts, situations, niveaux, natures d'action,
  achèvements : un `*Resolver` calcule à la lecture. Recalibrer un poids relit alors tout
  l'historique au prochain appel, **sans migration ni job**. Patrons de référence :
  `SkillStatusResolver`, `SituationDansNiveau`, `SkillMasteryResolver`, `PlanCycleResolver`.
- **Une règle = une autorité, et on l'appelle.** Jamais une copie. À la 2ᵉ occurrence, on
  **extrait** dans `util/` ou un resolver dédié (`TexteNormalise`, `CoutAppelLlm`,
  `FenetreMesure`, `ProductionValidityService`, `EvaluationProductionSegments`). Le défaut le
  plus cher du dépôt est la duplication : table des paliers en 6 copies, `estimateCostCents` en
  11 copies.
- **`null` = inconnu, jamais mauvais.** Une absence de mesure ne devient jamais le verdict le
  plus bas. Ne pas remplacer un `null` par un plancher « pour simplifier le front ».
- **Un garde-fou ne peut qu'abaisser** (`applyCouplage`, `applyPlafonds`, `applyConfiance`,
  `CoherenceBilan`, `CompetenceLevelEvidenceGuard`). L'unique exception voulue est le plancher A1
  des QCM, et elle est bornée à un cran. Ne pas créer de garde-fou qui relève.
- **Les nombres vivent en configuration, pas dans le Java** — `application.yaml` + un POJO
  `@ConfigurationProperties` **aux mêmes valeurs par défaut** (ils ne doivent jamais diverger).
  Exception assumée : une **donnée officielle** (table des paliers TCF, durées d'épreuve, tâches
  du référentiel) est du code, pas un réglage.
- **Deux configurations versionnées, et elles ne se mélangent pas.**
  `progression/progression-config-v{n}.json` porte l'intégrité d'`engineVersion` et le **rejeu**
  de la maîtrise ; `plan/plan-config-v{n}.json` ne porte que **sélection et affichage** du Plan
  (plafonds d'écran, poids de classement) et bougera souvent.
  🛑 **`plan-config` ne peut RIEN influencer du calcul de maîtrise** — les mélanger
  invaliderait le rejeu à chaque réglage d'écran. Une doctrine pédagogique déterministe
  (le mapping `nextTargetLevel`) n'y va pas non plus : ce n'est pas un réglage.
- **Un contrat de prompt se versionne, il ne se réécrit jamais.** Une version livrée reste
  chargeable ; un retour arrière est un changement de variable d'environnement, pas une
  migration. Une version inconnue **échoue au boot** — jamais de repli muet.
- **Ce qui tient la qualité d'une sortie LLM, ce sont les contraintes dures** : (1) le
  tool-schema — un champ absent ne *peut pas* être produit ; (2) une longueur plafonnée ; (3) un
  contrôle serveur déterministe ; (4) **en dernier** une consigne de prompt, qui n'est qu'un vœu.
- **Un verrou d'accès est opposable serveur** (403/422), et sa **jumelle en lecture** sert le
  `locked` des DTO — jamais une seconde implémentation de la règle.
- **Best-effort veut dire best-effort** : un enrichissement (observation de Plan, second appel
  LLM, funnel, analytics) tourne **hors transaction**, avale ses exceptions, et **ne dégrade
  jamais** l'opération principale. Ne pas ajouter de transaction englobante autour d'un runner
  async : une exception d'un service `REQUIRED` la marquerait rollback-only.
- **Le coût d'un endroit se verrouille par une ÉGALITÉ**, pas par un `<=` : c'est la seule façon
  d'attraper un N+1. Corollaire : un chargement doit être **inconditionnel** là où on veut
  vérifier le coût, et un **retour anticipé** là où l'appel est massif.

## Migrations Flyway

- Convention de numérotation et arbo `db/migration/` : `docs/migrations-flyway.md`.
- ⚠️ **Flyway ordonne par NUMÉRO, pas par dossier.** Un backfill de contenu seedé se numérote
  **après ses lots**, jamais dans `00_schema` — sinon l'`UPDATE` passe avant les `INSERT` et
  touche zéro ligne.
- **Additif par défaut.** Une colonne legacy cesse d'être écrite et mappée, elle ne se supprime
  pas : les valeurs déjà en base sont de la donnée réelle. **Aucun recalcul rétroactif** d'un
  prix, d'un coût ou d'un verdict.
- **Une migration de données ne se teste pas en place** (elle tourne avant tout jeu d'essai) : le
  test **relit le fichier**, le coupe sur sa sentinelle (`@@…@@`) et rejoue le SQL réel. Patrons :
  `LegacyPassCompensationIT`, `RejugementProductionsInexploitablesIT`. Ne jamais recopier la
  requête dans le test, ne jamais supprimer la sentinelle.

## Tests — dans la même passe, toujours

Tout code ajouté ou modifié ici est couvert **dans la même passe**. Une feature, un bugfix, une
règle métier, un endpoint, une migration à impact logique ne se ferment pas sans test(s) qui
verrouillent le comportement. Avant un refactor d'un bloc non couvert : écrire le filet d'abord.

- `./mvnw verify` — unitaires `*Test` (surefire) + intégration `*IT` (failsafe). Build **vert**.
- `*Test` (Mockito) pour la logique, les branches, les validations, le mapping, les clients
  externes (**toujours mockés**). `*IT extends AbstractIntegrationTest` quand le cas traverse
  vraiment la base — Postgres **embarqué** (Zonky, pas de Docker) avec les **vraies migrations**,
  donc toute contrainte est vérifiée et `ddl-auto: validate` valide le mapping.
- Un nouvel endpoint admin s'ajoute à la **matrice de droits**
  (`AdminRoutes`/`AuthenticatedRoutes`/`PublicRoutesSecurityIT`).
- Détail, gabarits par couche et pièges (seed Flyway, `save()` qui ne flushe pas, ordre `id ASC`
  Postgres ≠ `Comparator<UUID>`, `UnfinishedStubbing`) : `docs/plan-tests-backend.md`.

🛑 **Aucun test ni aucune mesure qui appelle un LLM payant sans demande explicite du
propriétaire.** Vaut pour `CalibrationBenchTest`, `CompetenceCalibrationBenchTest` et tout script
qui interroge un fournisseur. On propose la mesure et son coût, il décide. Avant toute analyse,
se demander d'abord si une **requête SQL sur la base locale** répond à la question — c'est
gratuit, immédiat, et c'est le plus souvent le cas.

## Parité — ce qui part d'ici touche 3 fronts

Une modif de **surface partagée** (endpoint : chemin, query params, méthode, param devenu
requis ; DTO ; enum ; règle métier) se propage et se **vérifie des trois côtés dans la même
passe** : `admin_sejourfr/src/types/api.ts`, `web_sejoufr/lib/types.ts`,
`mobile_sejourfr/lib/core/models/*.dart`. Les fronts **n'ont pas de tests** : le filet, c'est le
test backend + la relecture croisée.

**Aucun libellé métier ne se recopie sans être gelé** : les chaînes FR des enums exposés sont
figées par `SkillLabelsTest` côté serveur, et les 3 fronts en tiennent une copie écrite à la
main. Un libellé qui bouge, ce sont quatre fichiers dans la même passe.

---

# Où lire quoi

**Les règles métier ne sont pas dans ce fichier.** Ouvrir celle du sujet **avant** de coder.

| Si tu touches à… | Ouvre |
|---|---|
| un cadenas, un quota, un slot, un `locked` de DTO | `docs/regles/freemium.md` |
| le Plan, une priorité, la séance, un jalon, le moteur de maîtrise | `docs/regles/plan.md` |
| le diagnostic initial et son analyse | `docs/regles/diagnostic.md` |
| une rubrique, un tool-schema, un filet/purge, un coût LLM, le banc | `docs/regles/notation-ia.md` |
| le module Compétences (micro-entraînement EE/EO) | `docs/regles/competences.md` |
| un score QCM, un niveau dérivé, l'ordre des propositions | `docs/regles/qcm.md` |
| un chrono, `DureeEpreuve`, `deadlineAt`, la clôture d'une épreuve | `docs/regles/examens-temps.md` |
| une soumission orale, Whisper, R2 | `docs/regles/audio-productions.md` |
| l'analytics, le funnel, un rate-limit par IP | `docs/regles/mesure-audience.md` |
| `user_subscriptions`, un webhook store, un plan | `docs/regles/paiements.md` |
| la sémantique fine d'un enum métier | `docs/regles/domaine.md` |

**Avant de changer une règle** : `docs/decisions/<même sujet>.md` (journal daté de ce qui a été
essayé, mesuré et révoqué), plus `docs/decisions/contradictions-ouvertes.md` et
`docs/decisions/suspects-perimes.md`.

**Référence** : `docs/api-endpoints.md` · `docs/migrations-flyway.md` ·
`docs/plan-tests-backend.md` · `docs/pipeline-evaluation-eo-ee.md` · `docs/audio-pipeline/` ·
`docs/notation-ia-eo-ee.md` (grand public, **à tenir exhaustive et à jour dans la même passe**
que tout changement de règle de notation).
