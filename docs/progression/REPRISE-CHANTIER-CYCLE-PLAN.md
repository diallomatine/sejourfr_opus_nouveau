# Reprise — chantier du CYCLE BORNÉ (Plan)

> ✅ **CHANTIER LIVRÉ le 2026-09-19.** Ce fichier reste comme trace de reprise ; il n'y a
> plus rien à reprendre. 7 commits sur `feature/refonte-l1-socle`, arbre de travail propre :
> `d1cfa93f` kit · `53e0036a` écran Plan · `d0229a41` bug mobile hors ligne · `6a97e532`
> docs d'arbitrage · `06b84003` schéma + moteur + freemium · `70690c6a` écran
> « Ma progression » · `b0b101a9` règles et `CLAUDE.md`.
>
> **Vérification finale** : backend `./mvnw verify` → **3 048 + 1 345, 0 échec** ;
> web `tsc` 0 erreur, build **114 routes**, **270** tests ; mobile `flutter analyze` 0 issue,
> **296** tests.
>
> **Ce qui reste ouvert** est en bas de ce fichier (§ « Les points laissés au propriétaire »),
> plus deux dettes nommées dans les décisions : l'endpoint `analysis-quota` à retirer avec ses
> lecteurs front, et la carte « À faire maintenant » de l'Accueil qui ne nomme jamais une
> étape verrouillée (A46).

## Où lire la vérité

| Quoi | Où |
|---|---|
| Le cadre fonctionnel | `docs/progression/SPEC_cycle_plan.md` (conformée en P1) |
| L'audit de Phase 0 + l'**Annexe P1** (périmètre de fichiers) | `docs/audits/AUDIT_cycle_plan.md` |
| Les réponses du propriétaire | `docs/audits/REPONSES_AUDIT_cycle_plan.md` |
| **Les arbitrages** (autorité) | `docs/decisions/plan-parcours-tcf.md` — **D-12 → D-24 et D-17 bis**, 2026-09-18 |
| Les décisions prises en autonomie | `docs/decisions-autonomes-parcours-tcf.md` — **A27 → A40** |
| Les maquettes | `docs/progression/plan_cycle.html` · `cycle_termine.html` · `histo_cycle.html` |

## Fait, et vérifié

| Phase | Contenu | Vérification |
|---|---|---|
| **P1** | arbitrages consignés (D-12 → D-24, D-17 bis), spec conformée, périmètre P2 listé | — |
| **P2** | `V067__schema_cycle_journey_et_freebie.sql` : `journey.module/status/entry_level/exit_level/historise_at`, `uq_journey_en_cours` + `uq_journey_en_attente` (index **partiels**), ledger `free_entitlement_usage`. Miroirs JPA. 5 documents périmés corrigés. **Garde de réconciliation** déterministe avant l'index (A28) | `./mvnw verify` vert |
| **P3** | moteur : blocs par épreuve, état terminé, verrou de l'examen par son bloc (D-15), cycle `EN_ATTENTE`, transitions `refresh` / `measurement-cycle`, **4 points de branchement** (D-24). `JourneyDto` += `cycle`/`blocs`/`nextStep` | 3 031 + 1 333, BUILD SUCCESS |
| **P5** | kits : `CycleProgress`, `BlocAccordion`, `ExamStepBox`, `NextStepCard` (+ `Pill` web), miroirs brique pour brique. `AppColors.blueMid` ajouté | tsc 0, build 115 routes, 270 TS, analyze 0, 296 Dart |
| **P6** | écran Plan refait **à partir de « Votre parcours vers le B2 »** (blocs dépliables, état cycle terminé, 2 actions). File plate supprimée | idem, verts |
| **P6 bis** | bloc « Vos priorités » **supprimé** (arbitrage du propriétaire) ; le tap d'une étape verrouillée ouvre le paywall, décidé dans `planNowCard` ⇄ `plan_now_card.dart` | idem, verts |
| **P4** | quota d'étape « **2 réussies ou 4 terminées** » (D-16, le verdict est **lu** sur `learning_plan_observations.status = SOLID`) ; freemium refondu : **1 examen blanc gratuit par épreuve de production**, ledger branché à la **remise de l'analyse**, rejeu sans **aucun** appel payant, paywall EO au démarrage ; `free-analyses: 3` supprimé ; `SkillAccessService` fermé (D-18). `tcf-journey-config-v2.json` | 3 048 + 1 336, BUILD SUCCESS |
| **bug à part** | `mobile_sejourfr/lib/core/auth/auth_controller.dart` : une coupure réseau au démarrage à froid **ne déconnecte plus** (`ApiException.isNetwork`), et `readUser()` retrouve un lecteur | analyze 0, 296 Dart |

## En cours au moment d'écrire (deux agents)

1. **P7 backend** — retrait de `JourneyDto.steps` et `hiddenUpcomingCount` (plus aucun lecteur front) + `filtrer()` ; `TcfJourneyConfig.display` **conservé** (sinon le retour arrière v1/v2 casse) ; endpoint `GET /api/me/plan/journey/history`.
2. **P7 front** — écran « Ma progression » sur `histo_cycle.html`, à la place du contenu actuel de `/plan/progression` ⇄ `AppRoutes.planProgress` ; **suppression de `/plan/evolution`** et recâblage des liens.

**Si l'un des deux n'a pas fini** : son périmètre est décrit ci-dessus ; vérifier `git status`, relancer la vérification (`./mvnw verify` d'un côté, `npx tsc --noEmit && npm run build && npm test` puis `flutter analyze && flutter test` de l'autre) et finir ce qui manque.

## Le contrat servi de l'historique (arrêté, les deux côtés codent dessus)

```
GET /api/me/plan/journey/history
{ stats: { competencesTravaillees, examensPasses, cyclesTermines },
  cycles: [ { numero, debut, fin, competences, examens, entryLevel, exitLevel,
              blocs: [ { examType, skillTitles[], examens } ] } ] }   // récent → ancien
```

## Ce qui reste après P7

1. **P9 — documentation** : `docs/regles/plan.md` (R2 et §7.2 sont contredits par D-13/D-15 ; P4 a déjà mis à jour R8, le tableau « exécutable » et son § freemium), les sections « kit » de `CLAUDE.md` racine + des deux fronts (les 4 primitives neuves et la fin de la file plate), et **préciser D-21** : le vocabulaire interdit à l'écran est `lot`/`step`/`journey` — « cycle » est le mot du propriétaire dans ses maquettes, il reste.
2. **Consigner les décisions autonomes de P4, P6, P6 bis et P7** à la suite de A40.
3. **`./mvnw verify` + les 4 commandes front**, une dernière fois, d'un seul tenant.
4. **Rien n'est commité** : proposer le découpage des commits au propriétaire (schéma / moteur / freemium / kits / écrans / docs), il décide.

## Les points laissés au propriétaire

- **`GET /api/skills/analysis-quota`** ne dit plus rien depuis la suppression des 3 analyses à vie (`total = 0`, `remaining = 0` ou `-1`). Conservé parce qu'il a des lecteurs front ; **à retirer avec eux**, dans une passe dédiée.
- **La carte « À faire maintenant » de l'Accueil** ne nomme jamais une étape verrouillée (règle antérieure) : avec le Plan gratuit entièrement fermé (D-18), un compte gratuit y voit une carte générique **sans geste**. L'Accueil est hors périmètre (D-22) — à rouvrir ou non.
- **La barre d'avancement du cycle** garde le dégradé bleu → rouge de la maquette, contre la lettre de « rouge = CTAs critiques seulement » (A40-1).
- **Dette antérieure signalée, non touchée** : `planSeanceGroups`, `planSeanceGroupSummary`, `PlanSeanceGroup`, `planGroupContextLine` (web) sont exportés sans lecteur ; `kPlanMilestonePill` (mobile) n'en a plus qu'un miroir.
