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
| **Phase 2** | Orchestration, filtre R1, bootstrap, branchements, suppression de l'ancien, 45 tests | 🔄 **en cours** |
| **Phase 3** | `GET /api/me/plan/journey`, DTO, miroirs web + mobile | ⬜ à faire |
| **Phase 4** | 6 cartes « À faire maintenant », timeline dans les 2 kits, suppressions front | ⬜ à faire |

### Détail du lot en cours

**Phase 1 — livrée.** `V066__schema_journey_tcf.sql` (4 tables), 9 enums `Journey*`, 4 entités,
4 repositories, 3 managers, `TcfJourneyProperties` + `TcfJourneyConfig` / `Loader` / `Provider`,
`resources/plan/tcf-journey-config-v1.json`, bloc `sejourfr.tcf-journey` dans `application.yaml`.
Tests : `TcfJourneyConfigLoaderTest` (3) + `JourneySchemaIT` (16). **Verts.**
⚠️ La spec §6 a été corrigée en cours de route : `journey_assessment_event` porte l'épreuve mesurée
(décision **A11**, sinon R14 est faux dès que R9 s'applique).

**Phase 2 — à écrire**, dans cet ordre :

1. `service/journey/JourneyEvaluationFilter` — le filtre R1 (D-6), **une seule** classe, partagée
   par l'orchestration et le bootstrap (décision A10).
2. `service/journey/JourneyLotBuilder` — R2 (top N) + R10 bis (écart au niveau cible **lecture
   Plan** via `TcfProfileService.levelProfile`, puis `TcfDomainProfileDto.ORDRE`).
3. `service/journey/JourneyReadService` — `locked` par étape (§5 bis), élection de `CURRENT`,
   statuts de rendu, filtrage §14. 🛑 L'ordre de la promotion est normatif : `SkillAccessService`
   reçoit la **première étape non clôturée**, verrous ignorés, jamais `CURRENT`.
4. `service/journey/JourneyService` — `getOrCreate` (R18/D-3), `onAssessmentCompleted` (§7.2),
   `onTrainingProgress` (§7.3), bootstrap R19.
5. Branchements : `AttemptInteractionService.doFinish` (après `recordComprehension`),
   le pipeline de production (⚠️ **par attempt d'épreuve, pas par soumission** — cf. A11),
   clôture du diagnostic rapide, finalisation de l'examen blanc complet.
6. Suppressions : `plan_pinned_priorities` + `PlanFocusResolver.epingler` + rebranchement de
   `SkillAccessService` sur la première étape non clôturée ; `AccountDeletionService` efface le
   parcours (A07) ; paragraphe de `backend_sejourfr/CLAUDE.md` qui cite V065 comme « seule
   exception assumée ».
7. Les 45 tests métier de la spec §18.

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
