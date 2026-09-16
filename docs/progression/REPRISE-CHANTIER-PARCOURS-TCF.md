# Reprise du chantier « parcours TCF piloté par les évaluations »

> **Fichier de passation, tenu à jour pendant le travail de nuit du 2026-09-17.**
> Il existe pour une seule raison : si la session Claude s'arrête (limite d'usage), une nouvelle
> session doit pouvoir reprendre **sans rien redemander au propriétaire**.
>
> Une reprise automatique locale a été programmée pour **02:33 heure de Paris** (tâche one-shot
> `5f2c85fb`). ⚠️ Elle est **en mémoire de session** : si le processus Claude Code meurt
> complètement, elle meurt avec lui — ce fichier-ci est alors le seul point de reprise.

## Comment reprendre, en une ligne

> « Reprends le chantier parcours TCF là où `docs/progression/REPRISE-CHANTIER-PARCOURS-TCF.md`
> s'est arrêté, lot par lot jusqu'à la fin de la spec, sans me demander de validation. »

## À lire, dans cet ordre

1. `docs/progression/spec-plan-tcf-parcours-evaluations-v2.md` — **la spec**, révisée et validée.
2. `docs/decisions/plan-parcours-tcf.md` — les **9 arbitrages du propriétaire** (D-1 → D-9).
3. `docs/decisions-autonomes-parcours-tcf.md` — les décisions prises **en autonomie**, à continuer
   d'alimenter dès qu'un point n'est pas tranché par la spec.
4. `docs/progression/audit-plan-tcf-parcours-evaluations-v2.md` — l'audit de Phase 0 (où vit quoi).

## Contraintes de session

- Branche **`feature/refonte-l1-socle`**, courante. **Ne pas créer de branche.**
- **Backend** : tests dans la même passe (`./mvnw verify`, build vert).
- **Fronts** : 🛑 **aucun nouveau test**. Vérification par `npx tsc --noEmit`, `npm run build`,
  `flutter analyze`, et rien d'autre.
- Pas de validation à demander : avancer, décider, consigner.

## État d'avancement

| Lot | Contenu | État |
|---|---|---|
| **Phase 0** | Audit + spec révisée + journal d'arbitrages | ✅ **fait**, validé par le propriétaire |
| **Phase 1** | DDL `V066`, entités, enums, repositories, managers, config versionnée | 🔄 **en cours** |
| **Phase 2** | Orchestration, filtre R1, bootstrap, branchements, 48 tests | ✅ **fait** — suite complète 1296 tests verts |
| **Phase 3** | `GET /api/me/plan/journey`, DTO, miroirs web + mobile | ✅ **fait** — `tsc` + `flutter analyze` verts |
| **Phase 4** | 6 cartes « À faire maintenant », timeline dans les 2 kits, suppressions front | 🔄 **en cours** — timeline faite, cartes et suppressions à faire |

### Détail du lot en cours

**Phases 1 à 3 — livrées.** Backend `./mvnw -o verify` → **1296 tests, 0 échec**.
**Phase 4a et 4b — livrées** : les primitives de timeline sont dans **les deux kits**
(`JourneyRow`/`JourneyList` ⇄ `SfJourneyRow`/`SfJourneyList`), les phrases dans
`web_sejoufr/lib/journey.ts` ⇄ `mobile_sejourfr/lib/screens/plan/journey_labels.dart`, et
**l'écran Plan des deux fronts affiche la file** — abonné comme compte gratuit. Le parcours de
tâche et le chemin de palier en ont disparu. `npm run build` et `flutter analyze` verts.

**Ce qui reste, dans cet ordre :**

1. 🛑 **Les 6 cartes « À faire maintenant »** — *lire d'abord la décision **A18** dans
   `docs/decisions-autonomes-parcours-tcf.md`* : la spec §16 a un trou, `JourneyStepDto` ne
   porte **aucune action à lancer**. La résolution proposée (et non encore implémentée) est
   `planNowCard(plan, {free, journey})` : l'**identité** vient de `journey.current`,
   l'**action** se résout en rapprochant l'étape des données du Plan
   (`recommendedExercise` pour `TRAIN_SKILL`, `domainesAEvaluer` pour `SECTION_EXAM`,
   `/diagnostic` pour `DIAGNOSTIC`), et sans parcours servi le comportement d'aujourd'hui est
   **inchangé**.
   ⚠️ Six sites d'appel : Plan (`LearningPlanView.tsx` ⇄ `plan_tcf_view.dart`), Accueil
   (`dashboard/page.tsx` ⇄ `home_screen.dart`), Réviser (`lib/reviser.ts` ⇄
   `reviser_labels.dart`). **N'en migrer que quelques-uns rouvrirait la contradiction corrigée
   le 2026-09-16.** Accueil et Réviser devront donc lire le parcours eux aussi
   (`journeyApi.getCached()` ⇄ `journeyProvider`, déjà en place).
2. **Les états `NEEDS_OBJECTIVE` / `LOCKED` / `UP_TO_DATE`** à l'écran : les libellés existent
   déjà des deux côtés (`JOURNEY_NEEDS_OBJECTIVE_*`, `JOURNEY_UP_TO_DATE_*`,
   `JOURNEY_LOCKED_CAPTION`, `JOURNEY_SUGGESTION_MOCK_EXAM` et leurs jumeaux Dart) mais
   **aucun écran ne les rend encore**. « Choisir mon objectif » ouvre `/parcours` (web) /
   `target_path_screen` (mobile).
3. **Les suppressions §11 encore à faire** — le bloc « Votre parcours — Tâche X » a disparu du
   **Plan**, mais ses dérivations vivent toujours et servent l'**Accueil** :
   `parcoursDeLaTache` / `planTaskPath`, `plan_task_path.dart`, `plan_task_row.dart`. Les
   supprimer suppose d'avoir traité le point 1 (l'Accueil lit le parcours).
   Et le **chemin vers l'objectif** côté serveur n'est pas encore retiré :
   `PlanCycleDto.path`, `PlanCycleResolver.chemin` (l.235), `PlanPathStepDto`,
   `PlanPathStepKind`, `PlanPathStepStatus`, les `PLAN_PATH_*` du web, `plan_path_section.dart`,
   plus les tests `LearningPlanCycleIT` / `PlanCycleResolverTest` (à **mettre à jour**).
   🛑 **`PlanCycleDto` survit** : seul son champ `path` disparaît.
4. **`plan_pinned_priorities` + `PlanFocusResolver.epingler`** — ⚠️ **décision A13** : deux
   blocages à résoudre d'abord (candidats **sans objectif déclaré**, et la première place du
   Plan existant).
5. **Documentation** : `docs/regles/plan.md` (R1, R2 et son budget assumé **avec sa raison**,
   R8, la notion d'étape exécutable), le `CLAUDE.md` de chaque front, et le `CLAUDE.md`
   backend — qui cite encore V065 comme « seule exception assumée » à « un dérivé se relit ».

## Pièges relevés par l'audit — à ne pas réapprendre

- `AttemptInteractionService.doFinish` est **le** point de fin de toute session QCM (entraînement
  compris) : c'est là que se branche R7, **après** `recordComprehension`, et c'est aussi pourquoi le
  filtre R1 est indispensable.
- La compétence CO/CE est **dérivée du contenu des questions**, jamais connue de l'appelant : lire
  les observations **réellement écrites**.
- `SkillAccessService` doit recevoir la **première étape non clôturée** (verrous ignorés), pas
  `CURRENT` — sinon circularité, et l'exemption freemium du 2026-08-21 tombe.
- `plan_pinned_priorities` est **supprimée** (V065) : penser au `CLAUDE.md` du backend, qui la cite
  comme « seule exception assumée » à « un dérivé se relit ».
- `PlanCycleDto` **survit**, seul son champ `path` disparaît (D-4).
- Ordre des épreuves : `TcfDomainProfileDto.ORDRE` = `CO, CE, EO, EE` (D-9).
- Prochain numéro de migration : **V066** dans `00_schema/` (⚠️ `100_reference/` est à V114).
