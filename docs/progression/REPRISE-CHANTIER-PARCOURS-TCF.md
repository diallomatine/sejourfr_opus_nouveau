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
| **Phase 4** | 6 cartes « À faire maintenant », timeline dans les 2 kits, suppressions front | 🔄 **en cours** |

### Détail du lot en cours

**Phases 1 à 3 — livrées et commitées** (4 commits sur `feature/refonte-l1-socle`).
Backend : `./mvnw -o verify` → **1296 tests, 0 échec**. Fronts : `npx tsc --noEmit` et
`flutter analyze` verts, **aucun test front ajouté**.

**Phase 4 — à faire**, dans cet ordre :

1. **Les 6 cartes « À faire maintenant »** branchées sur `journey.current` :
   `planNowCard` (`web_sejoufr/lib/plan-domain.ts:639`) ⇄ `planNowCard`
   (`mobile_sejourfr/lib/screens/plan/plan_now_card.dart:129`) deviennent une **projection**
   de `current`, plus un décideur. Sites : Plan (`LearningPlanView.tsx:505` ⇄
   `plan_tcf_view.dart:292`), Accueil (`dashboard/page.tsx:549` ⇄ `home_screen.dart:328`),
   Réviser (`lib/reviser.ts:135` ⇄ `reviser_labels.dart:118`).
   🛑 N'en migrer que quelques-uns rouvrirait la contradiction corrigée le 2026-09-16.
2. **La timeline §12-14** dans **les deux kits** (`SejourKit.tsx` ⇄ `sejour_kit.dart`) :
   rail, marqueur double-cercle, badge `EXAMEN`, cadenas d'étape. Un motif s'ajoute des deux
   côtés dans la même passe. ⚠️ Une media query n'est pas une primitive : le palier desktop
   du kit web n'a pas de miroir Flutter.
3. **Les suppressions §11**, dans la même passe :
   - « Votre parcours — Tâche X » : `parcoursDeLaTache` (`LearningPlanView.tsx:288` et `:395`),
     `plan_task_path.dart`, `plan_task_row.dart` ;
   - le « chemin vers l'objectif » (D-4) : `PlanCycleDto.path`, `PlanCycleResolver.chemin`
     (l.235), `PlanPathStepDto`, `PlanPathStepKind`, `PlanPathStepStatus`, `PLAN_PATH_*` et
     `planPathStep*` (`lib/plan-domain.ts`), `widgets/plan_path_section.dart`, les tests
     backend `LearningPlanCycleIT` / `PlanCycleResolverTest` (mis à jour, pas contournés).
     🛑 **`PlanCycleDto` survit** : seul son champ `path` disparaît.
   - `plan_pinned_priorities` + `PlanFocusResolver.epingler` — ⚠️ **avec les deux blocages de
     la décision A13** à résoudre d'abord (candidats sans objectif déclaré, première place du
     Plan existant).
4. Mise à jour de `docs/regles/plan.md` (R1, R2 et son budget assumé, R8, étape exécutable),
   du `CLAUDE.md` de chaque front si une convention change, et du `CLAUDE.md` backend (qui
   cite V065 comme « seule exception assumée » à « un dérivé se relit »).

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
