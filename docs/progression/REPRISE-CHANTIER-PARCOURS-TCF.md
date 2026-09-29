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
| **Phase 4** | 6 cartes « À faire maintenant », timeline dans les 2 kits, suppressions, docs | ✅ **fait** |

### Ce qui reste

**La spec est livrée de bout en bout.** Backend `./mvnw verify` → **1300 tests, 0 échec** ;
`npm run build` et `flutter analyze` verts ; **aucun test front ajouté**.

Trois points **ouverts**, tous consignés et aucun bloquant :

1. 🛑 **A23 — `plan_pinned_priorities` n'est pas supprimée**, contrairement à la spec §6. Elle
   est devenue le **repli** pour les candidats sans objectif déclaré (17 sur 34 en dev), qui
   n'ont pas de parcours. La supprimer pour de bon suppose un arbitrage produit :
   **le Plan exige-t-il lui aussi un objectif déclaré ?**
2. ⚠️ **A16 — limite connue côté production** : une épreuve EE/EO **abandonnée** dont la
   dernière évaluation atterrit avant la clôture de la session n'ouvre pas de lot. L'épreuve
   reste **mesurée**, et la prochaine évaluation reprend la main. La fermer proprement
   demanderait un déclencheur à la clôture de session, qui n'existe pas aujourd'hui.
3. ⚠️ **Cosmétique** : `mobile_sejourfr/lib/screens/plan/plan_task_path.dart` ne contient plus
   de « task path ». Renommage non fait — quatre imports pour zéro changement de comportement.

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
