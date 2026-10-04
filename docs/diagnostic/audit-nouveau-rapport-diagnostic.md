# Audit — nouveau rapport du diagnostic rapide + écran « Votre plan commence ici »

> Date : 2026-10-04 · branche `feature/nav-v2` · **audit seul** : aucun code, aucun schéma,
> aucun prompt modifié, aucun commit, **aucun appel LLM**. Base locale lue en `SELECT` seulement.
> Maquette auditée : `docs/diagnostic/maquette-rapport-diagnostic-premium.html` (2 écrans).
> Audit antérieur d'une maquette proche : `docs/diagnostic/audit-maquette-rapport-diagnostic.md`
> (2026-09-25) — repris en le revérifiant, écarts au §6.

Légende de classement (demandée) : **A** déjà disponible · **B** disponible mais non exposée ·
**C** facilement dérivable (aucune modif IA) · **D** backend léger · **E** donnée métier
manquante · **F** modification du contrat IA · **G** nouvelle évaluation / coût supplémentaire.

---

## 1. Verdict rapide

- **La maquette a été bâtie sur une vraie session** : `diagnostic_sessions 0fb5e0bc…`
  (`QUICK_TCF` v1, close le 2026-10-04 00:17, compte NAT ⇒ objectif B2). Niveau `B1`, point fort
  `EE2-C5` avec son explication **mot pour mot**, et les trois priorités de l'écran 2
  (`EE3-C3`, `EE3-C2`, `EE2-C7`) sont **exactement le lot du Plan** créé par cette session
  (requêtes au §3.6).
- **Environ 80 % des informations affichées existent déjà** (28 lignes A ou B sur 34 au §2),
  **100 % sont constructibles sans toucher à l'IA**. Aucune ligne n'est en **F** ni en **G** :
  **pas de nouvel appel LLM, pas de coût d'évaluation supplémentaire.**
- **Immédiat (front seul)** : kicker, titre, niveau, objectif, piste de niveau, point fort,
  explications, encart d'honnêteté, les 4 épreuves et leur état (lus sur
  `GET /api/me/plan/journey`), prochaine étape (`journey.current`), CTA.
- **Léger (backend)** : servir **sur le DTO du rapport** les priorités **du Plan** (le lot dont
  `source_assessment_id = session.id`), la phrase « déjà les bases » comme fait servi, et
  l'explication générique (`skills.general_criterion`, déjà en base).
- 🛑 **Le point dur n'est pas une donnée manquante, c'est une DIVERGENCE** : aujourd'hui le
  rapport affiche les priorités du **diagnostic** (`summary_json.priority_skill_codes`, ≤ 2) et
  le Plan celles du **lot** (≤ 3), choisies par **deux règles différentes**. Sur les 7 sessions
  qui ont un lot, **aucune** ne montre les mêmes compétences des deux côtés ; une
  (`bc77e2a5…`) n'en a **aucune en commun**. La cause racine est en partie un **bug** : le
  départage du lot repose sur l'ordre d'insertion des observations à la microseconde (§3.4).
- ⚠️ **Deux contradictions produit** à trancher avant d'implémenter l'écran 2 : au cycle
  d'affinage (D-64), la **vraie** prochaine étape est l'**examen blanc EE**, pas une priorité,
  et les priorités y sont **facultatives** (§3.5, arbitrages AR-1 et AR-2).

---

## 2. Tableau exhaustif — une ligne par information affichée

Abréviations : `DR` = `web_sejoufr/app/_components/diagnostic/DiagnosticReport.tsx` ;
`RL` = `web_sejoufr/app/_components/diagnostic/report-labels.ts` ;
`DRV` = `mobile_sejourfr/lib/screens/diagnostic/widgets/diagnostic_result.dart` ;
`DRL` = `mobile_sejourfr/lib/screens/diagnostic/widgets/diagnostic_report_labels.dart` ;
`DS` = `backend_sejourfr/src/main/java/com/sejourfr/app/service/diagnostic/DiagnosticService.java`.

### Écran 1 — Rapport

| # | Information affichée | Dyn./stat. | Cat. | Source actuelle | Backend | API | Front | Effort | Recommandation |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Kicker « Diagnostic rapide terminé » | statique | **A** | `RL:25` ⇄ `DRL` | — | — | déjà rendu (`Top kicker`, `DR:183-187`) | 0 | garder |
| 2 | Titre « Votre estimation » | statique | **A** | `RL:27` | — | — | déjà rendu | 0 | garder |
| 3 | « Niveau estimé sur cet exercice » | statique | **A** | `RL:35` (wording imposé) | — | — | déjà rendu (`DR:97`) | 0 | garder tel quel |
| 4 | « B1 » | dynamique | **A** | `diagnostic_production_analyses.level_estimate` (rendu par le LLM, enum `A1_NON_ATTEINT…B2`, `diagnostic-analysis-tool-schema-v1.json:14-18`) → `DiagnosticProductionResultDto.levelEstimate` (`DS:425-428`) | — | `GET /api/diagnostics/{id}` · `/current` → `result.written.levelEstimate` | rendu `DR:98` ⇄ `DRV:136` | 0 | garder ; `null` (`NON_EVALUABLE`) déjà nommé, jamais A1 |
| 5 | « Votre objectif B2 » | dynamique | **A** | `GET /api/auth/me` → `AuthenticatedUser.targetLevel` = `TargetProcedure.niveauVise(...)` (`dto/AuthenticatedUser.java:66`) | — | existant | rendu `DR:99-101` ⇄ `DRV:140-145` | 0 | ⚠️ parité : objectif `null` ⇒ web « à définir », mobile ligne masquée (§4.5) |
| 6 | « Vous avez déjà les bases pour viser le niveau B2. » | dynamique | **C** | rien de servi ; règle existante côté serveur `TcfDomaine.ecartAuNiveauCible` (`util/TcfDomaine.java:96-100`) ; analogue front `demarcheRappel` (`web_sejoufr/lib/production-feedback.ts:422-436`) | servir un écart/une situation (D léger, recommandé) | champ sur `DiagnosticResultDto` | table enum → phrase par front | 0,25 j | servir `situationObjectif` (`ATTEINT` / `UN_PALIER` / `PLUSIEURS_PALIERS` / `null`) ; ⚠️ la phrase est **fausse** pour A1 → B2 ou au-dessus de l'objectif (§4.2) |
| 7 | Piste A2 — B1·Vous — B2 (objectif) | dynamique | **A** (+ correctif de parité) | `LevelTrack` + `levelTrackPosition` (`web_sejoufr/lib/tcf-diagnostic.ts:49-58`) ⇄ `SfLevelTrack` + `cecrlTrack` (`mobile_sejourfr/lib/core/utils/cecrl_track.dart:21-35`) | — | — | déjà rendu (`DR:104-110` ⇄ `DRV:146-151`) | 0,25 j (parité) | ⚠️ les deux « miroirs » n'ont **pas** le même algorithme (§4.5) ; aucun % (règle `docs/regles/progression.md:404-406`) |
| 8 | Légende « Votre progression vers l'objectif » | statique | **A** | nouveau libellé | — | — | à ajouter (2 fronts) | ε | libellé ; jamais de pourcentage |
| 9 | Synthèse, phrase 1 « Votre production est claire et bien organisée. » | dynamique | **A** (texte LLM) / **C** (forme courte) | `written.summary` (LLM, ≤ 280 c., **6 analyses QUICK_TCF sur 11 tronquées** avec « … », mesure §3.6) ; `communicationStatus` `EFFECTIVE/PARTIAL/INEFFECTIVE` servi mais **jamais affiché** (`DiagnosticProductionResultDto`) | — | existant | aujourd'hui `summary` brut (`DR:111`) | 0,25 j | phrase courte indexée sur `communicationStatus` (table de libellés front, légitime) ; garder `summary` en dépliant ou le retirer (AR-4) |
| 10 | Synthèse, phrase 2 « Ce qui vous sépare principalement du B2 est … » | dynamique | **C/D** | objectif (#5) + titre de la priorité n°1 **du lot** (#15) ; `summary_json.main_priority_explanation` existe (LLM) mais porte sur la priorité n°1 **du diagnostic**, pas du Plan | dépend de #15 | — | composition front d'un gabarit + 2 faits servis | 0,25 j | « Ce qui vous sépare principalement du {objectif} : {titre priorité 1} » ; la prose exacte de la maquette serait du **F** — **déconseillé** |
| 11 | Section « Ce que nous avons observé » | statique | **A** | `RL:51` | — | — | déjà rendu | 0 | garder |
| 12 | Kickers « POINT FORT » / « PRIORITÉ » | statique | **A** | aujourd'hui « Positive » / « À améliorer » (`RL:52-53`) | — | — | libellés | ε | changer les libellés (2 fronts, miroirs) |
| 13 | Point fort : « Raconter les actions dans l'ordre » | dynamique | **A** | 1ʳᵉ observation `SOLID` de `written.skills[]` (ordre d'allowlist) → `skillTitle` (`DS:412-424`) ; sélection `observationLines` (`RL:77-93`) ⇄ `diagnosticObservations` (`DRL:89-113`) | — | existant | déjà rendu | 0 | garder |
| 14 | Justification du point fort | dynamique | **A** | `written.skills[].explanation` (LLM, ≤ 220 c.) ; ici **identique mot pour mot** à la maquette (§3.6) | — | existant | déjà rendu | 0 | garder |
| 15 | 3 cartes PRIORITÉ (titres) | dynamique | **D** | **aujourd'hui** : `result.priorities` = `summary_json.priority_skill_codes` (≤ 2 par production, `DiagnosticAnalysisValidator.java:41`), affichées ≤ 2 (`RL:56`). **Les 3 de la maquette** = `journey_step` `TRAIN_SKILL` du lot `source_assessment_id = session.id` (§3) | lire le lot dans `DiagnosticService.result` | nouveau champ `planPriorities` sur `DiagnosticResultDto` | remplacer la source de `observationLines` | 0,5 j back + 0,25 j fronts | **la seule vraie rupture** — §3 et §5 |
| 16 | Explication propre à la production de chaque priorité | dynamique | **A** | `written.skills[].explanation` existe pour **les 8** compétences de l'allowlist, jointure par `skillCode` (ex. `EE3-C2` : « Une raison pertinente est donnée (fatigue, manque de temps), mais elle reste générale. ») | joindre dans le champ #15 | idem | idem | inclus | ton réel = constat neutre à la 3ᵉ personne, plus sec que la maquette (AR-6) |
| 17 | Encart « Une première estimation, pas encore votre niveau TCF complet » + « dépend également de CO, CE et EO » | statique | **A** | existe sous une autre forme : « Ce n'est qu'une première estimation » (`RL:114-120` ⇄ `DRL`) | — | — | `NoteCard` ⇄ `SfNoteCard` | ε | changement de copie (miroirs) |
| 18 | CTA « Découvrir mon plan → » | statique | **A** | aujourd'hui « Voir mon plan » → Plan (`RL:155`, `DR:170` ⇄ `DRV:92-96`) | — | — | cible = écran 2 | ε | — |
| 19 | Lien « Revoir ma réponse » | dynamique | **B** | texte **stocké** : `production_submissions.texte_soumis` (770 c. pour la session de la maquette) ; `DiagnosticResponse.written.submissionId` est servi ; `GET /api/production-submissions/{id}` rend `texteSoumis` au propriétaire, diagnostic compris (`controller/ProductionSubmissionController.java:64-67`, `service/ProductionSubmissionService.java:137-147`) ; consigne servie (`DiagnosticExerciseDto.instruction`) | — | existant | **aucun écran** ne relit une production de diagnostic | 0,5 j (2 fronts) | feuille / page « Votre réponse » (consigne + texte) ; bonus possible : `exempleCible` (servi, jamais affiché) |

### Écran 2 — Transition « Votre plan commence ici »

| # | Information affichée | Dyn./stat. | Cat. | Source actuelle | Backend | API | Front | Effort | Recommandation |
|---|---|---|---|---|---|---|---|---|---|
| 20 | Coche + « Votre diagnostic est analysé » | statique | **A** | `DiagnosticResponse.status == COMPLETED` | — | existant | nouvel écran | (écran) | — |
| 21 | « Votre plan commence ici » | statique | **A** | — | — | — | libellé | ε | — |
| 22 | « … pour vous rapprocher de votre objectif B2 » | dynamique | **A** | #5 | — | — | — | 0 | objectif `null` ⇒ phrase sans palier |
| 23 | Carte « Vos 3 premières priorités » | dynamique | **D** | même donnée que #15 ; le **nombre** est celui du lot (1 à 3 ; 0 si aucune fragilité, R9) | #15 | #15 | `Prio` ⇄ `SfPrio` | inclus #15 | jamais « 3 » en dur ; ⚠️ AR-2 (« facultatives » au Plan) |
| 24 | Pastille « Expression écrite » | dynamique | **A** | `section` / `bloc` de l'étape (`JourneyStepDto.section`, `JourneyStepDto.java:59`) ; libellés `web_sejoufr/lib/tcf-epreuves.ts` ⇄ `tcf_epreuves.dart` | — | — | — | 0 | lue, jamais écrite en dur (un ancien `INITIAL_TCF` a aussi des priorités EO) |
| 25 | Numéros 1 / 2 / 3 | dynamique | **A** | `journey_step.severity_rank` (0..2) / `position` | — | — | — | 0 | — |
| 26 | Titre de chaque compétence | dynamique | **A** | `skills.title` (= `JourneyStepDto.skillTitle`, `JourneyStepDto.java:68-69`) | — | `GET /api/me/plan/journey` ou #15 | — | 0 | lire le même champ que #15 |
| 27 | Explication pédagogique générique (« Aller au-delà d'une idée simple… ») | statique par compétence | **B** | `skills.general_criterion` (NOT NULL, 59–132 c. en EE, infinitif, ex. `EE3-C3` : « Expliquer comment ou pourquoi l'argument soutient la position, au lieu de simplement l'énumérer. ») ; servi par `SkillDto.generalCriterion` (`GET /api/skills`, `dto/SkillDto.java:36`) mais **ni** par `JourneyStepDto` **ni** par le DTO du diagnostic. Alternatives : `skills.description` (2 phrases, trop long), `learning_points[3]` | ajouter au champ #15 | idem | — | inclus | `general_criterion` convient en longueur et en ton ; **E** seulement si le propriétaire veut une ligne éditoriale dédiée (48 lignes, contenu, 0 LLM) |
| 28 | « Et pour connaître votre niveau réel au TCF ? » + « un examen blanc dans chaque épreuve encore à mesurer » | statique | **A** | proche de `DIAGNOSTIC_SUITE_TITLE/PROMISE` (`RL:129-146`) ; vrai par construction (D-69 : `SECTION_EXAM INITIAL_ASSESSMENT` CO/CE/EO posés, §3.6) | — | — | — | ε | — |
| 29 | 4 tuiles CO / CE / EE / EO (libellés) | statique | **A** | `DIAGNOSTIC_SUITE_EPREUVES` (`RL:133-138`) ⇄ `kDiagnosticSuiteEpreuves` (`DRL:156-161`) ; jamais `TCF_STRUCTURE` | — | — | `ExamRow` ⇄ `SfExamRow` | 0 | — |
| 30 | État de chaque épreuve | dynamique | **A** (autre endpoint) | `JourneyDto.blocs[].status` (`TERMINE / EN_COURS / A_EVALUER / A_VENIR / INACHEVE`, `enums/JourneyBlocStatus.java`) + `blocs[].meta` (phrase servie) ; aussi `PlanDomainDto.evaluated` (`GET /api/me/plan`) | — | `GET /api/me/plan/journey?module=TCF` (déjà consommé : `web_sejoufr/lib/api.ts:1141` ⇄ `mobile_sejourfr/lib/core/api/learning_plan_repository.dart:33`) | table enum → libellé par front | 0,25 j | lire `blocs`, ne rien recalculer ; après le rapide : EE `EN_COURS` (porte `current`, A159), CO/CE/EO `A_EVALUER` |
| 31 | Bloc « VOTRE PROCHAINE ÉTAPE » | dynamique | **A** (donnée) · ⚠️ copie | `JourneyDto.current` ; au cycle d'affinage = **l'examen blanc EE** (A159, `docs/decisions-autonomes-parcours-tcf.md:3038-3046`), sinon CO si l'examen EE offert est consommé | — | idem #30 | `NextStepCard` ⇄ `SfNextStepCard` / `planNowCard` | 0,25 j | afficher la **vraie** étape ; « Commencer par ce qui vous limite aujourd'hui » est **faux** à ce moment (AR-1) |
| 32 | « Vos priorités sont déjà intégrées à votre plan… » | statique conditionnelle | **C** | vrai si le lot est dans le cycle `EN_COURS` ; **faux** si le diagnostic arrive après un examen du cycle d'examens (priorités → cycle `EN_ATTENTE`, D-69 tableau ligne 4, `docs/regles/plan.md:2287`) | servir `dansLeCycleCourant` avec #15 | #15 | phrase conditionnelle | inclus | ne jamais l'afficher sans le fait servi |
| 33 | CTA « Voir mon plan → » | statique | **A** | `planHref("TCF")` ⇄ `AppRoutes.tcfPlan` | — | — | — | 0 | — |
| 34 | « ← Revenir au rapport » | statique | **A** | `/diagnostic/rapport/{sessionId}` existe (web) ⇄ `diagnostic_rapport_screen.dart` | — | — | navigation | ε | — |

**Décompte** : A = 26, B = 2, C = 4, D = 2 (une seule évolution backend, #15/#23), E = 0, F = 0,
G = 0. **A + B = 28 / 34 ≈ 82 %** ; avec C : 94 % ; avec D : 100 %.

---

## 3. Audit diagnostic → Plan

### 3.1 Le pipeline, transformation par transformation

| Étape | Ce qui est produit | Où (code) | Où (base) |
|---|---|---|---|
| 1. Analyse IA de l'écrit | `level_estimate`, `task_completion`, `communication_status`, `summary`, `strengths[≤3]`, `weaknesses[≤3]`, `skills[]` = **les 8 compétences de l'allowlist**, chacune `status` / `confidence` / `explanation` / `evidence` | contrat `diagnostic-analysis-tool-schema-v1.json` ; réconciliateur (troncatures) | `diagnostic_production_analyses.analysis_json` + colonnes |
| 2. Observations | une ligne par compétence, **`observed_at = Instant.now()` à chaque tour de boucle** | `service/LearningPlanObservationService.java:64-87` (l. 86) | `learning_plan_observations` (`source_type = DIAGNOSTIC_EE`, `source_id` = la soumission) |
| 3. Priorités **du diagnostic** | `priority_skill_codes` (≤ 2 par production, désignées puis dérivées des `TO_REINFORCE`, départage **confiance puis rang d'allowlist**) + `main_priority_explanation` | `DiagnosticSessionCoordinator.java:226-233` (résumé), `:258-283` (sélection) ; règle `DiagnosticPriorityRanking.java:39-42` | `diagnostic_sessions.summary_json` |
| 4. DTO du rapport | `result.priorities` (≤ 3, en pratique ≤ 2), `written.skills[]` | `DS:235-262` | — |
| 5. Parcours | `journeyService.onAssessmentCompleted` **après commit**, best-effort (échec avalé, rattrapé à la lecture) | `DiagnosticSessionCoordinator.java:180-193` | `journey_assessment_event (QUICK_DIAGNOSTIC)` |
| 6. Lot du Plan | ≤ 3 fragilités par épreuve, départage **statut, confiance, puis `observed_at` décroissant, puis code** | `JourneyService.java:1094-1131` → `JourneyLotBuilder.depuisEvaluation` (`:96-107`), `lotsParEpreuve` (`:226-256`), `PAR_GRAVITE` (`:274-279`) | `journey_lot` + `journey_step (TRAIN_SKILL, skill_id, severity_rank, source_assessment_id = session.id)` |
| 7. Cycle | cycle d'**affinage** (D-64) : lot EE + `SECTION_EXAM REASSESS` EE + `INITIAL_ASSESSMENT` CO/CE/EO | `JourneyService.amorcer`, `JourneyCycleAffinage` | `journey` (`EN_COURS`) |
| 8. Affichage Plan | blocs CO/CE/EO/EE ; étapes avec `skillCode`, `skillTitle` ; `current` = examen EE (A159) ; compétences **facultatives** | `GET /api/me/plan/journey` → `JourneyDto` | — |

**Identifiant commun** : `skills.id` (`journey_step.skill_id`, `learning_plan_observations.skill_id`,
`DiagnosticSkillObservationDto.skillId`) et `skills.code`. Le lien rapport → lot existe en base
(`journey_step.source_assessment_id = diagnostic_sessions.id`), mais **aucun DTO ne le sert**.

### 3.2 Combien de compétences, combien de priorités

- Le diagnostic rapide observe **toujours 8 compétences** (allowlist `diagnostic_task_skills`,
  `EE1-C7, EE2-C5, EE2-C3, EE2-C7, EE3-C1, EE3-C2, EE3-C3, EE1-C8`, ordre éditorial 1→8).
- Il en désigne **≤ 2 priorités** (plafond par production, `DiagnosticAnalysisValidator.java:41`).
- Le lot en retient **≤ 3** (`maxPrioritiesPerLot`, R2 / D-67).
- Notions explicites de rang : `journey_step.severity_rank` (lot) ; ordre de
  `priority_skill_codes` (diagnostic) ; `fragileSkillCount` / `solidSkillCount` (compteurs servis,
  non affichés). Pas de `priorityRank` sur `DiagnosticSkillObservationDto`.

### 3.3 Le rapport et le Plan désignent-ils les mêmes compétences ? — Non (mesuré)

```sql
SELECT ds.id, ds.summary_json->'priority_skill_codes' AS diag,
       (SELECT string_agg(s.code, ',' ORDER BY js.position) FROM journey_step js
          JOIN skills s ON s.id = js.skill_id WHERE js.source_assessment_id = ds.id) AS lot
FROM diagnostic_sessions ds
WHERE ds.diagnostic_code = 'QUICK_TCF' AND ds.status = 'COMPLETED' ORDER BY ds.completed_at DESC;
```

| Session | Fragilités observées (ordre d'allowlist) | Rapport (diagnostic) | Plan (lot) |
|---|---|---|---|
| `0fb5e0bc` (maquette) | EE1-C7 M, EE2-C7 M, EE3-C2 M, **EE3-C3 PRIORITY H** | EE3-C3, **EE1-C7** | EE3-C3, **EE3-C2, EE2-C7** |
| `bc77e2a5` | EE1-C7, EE2-C5, EE2-C3, EE2-C7, EE3-C2, EE1-C8 (toutes TO_REINFORCE M) | **EE1-C7, EE2-C5** | **EE1-C8, EE3-C2, EE2-C7** — *aucune en commun* |
| `4675936e` | 6 TO_REINFORCE M + EE3-C3 PRIORITY H | EE3-C3, EE1-C7 | EE3-C3, EE1-C8, EE3-C2 |
| `6474e75a` | … EE2-C3 H, EE3-C3 PRIORITY H | EE3-C3, EE2-C3 | EE3-C3, EE2-C3, EE3-C2 |
| `c6a79fa6` | EE2-C3 H + 4 M | EE2-C3, EE1-C7 | EE2-C3, EE1-C8, EE3-C3 |
| `f241e217` | EE2-C3 P H, EE3-C3 P H, 2 M | EE2-C3, EE3-C3 | EE3-C3, EE2-C3, EE3-C2 (ordre inversé) |
| `f14e39f6` | EE3-C2 M, EE3-C3 M | EE3-C2, EE3-C3 | EE3-C3, EE3-C2 (ordre inversé) |
| 4 sessions antérieures (`5015db09`, `0004f8be`, `1f701d8b`, `cf76683d`) | — | 2 codes | **aucun parcours TCF** (aucune ligne `journey`) |

Constat : à égalité de confiance, **le rapport prend la compétence la plus haute de l'allowlist,
le Plan la plus basse**. `EE1-C8` (rang 8) entre dans 4 lots sur 7, `EE1-C7` (rang 1) dans 0.
Même le **n°1** diffère (`bc77e2a5`), ce que `docs/regles/diagnostic.md:383-389` affirme
impossible.

### 3.4 Pourquoi — structurel ET accidentel

1. **Structurel (voulu)** : deux règles et deux plafonds. Le diagnostic coupe à **2** (contrat),
   départage par **rang d'allowlist** ; le lot coupe à **3**, départage par **récence**.
   `JourneyLotBuilder` le documente (« le critère de tri est le même [que le Plan], et c'est tout
   ce qui doit l'être », `:39-44`). Même avec un départage identique, le 3ᵉ du lot n'existe pas
   dans le rapport.
2. **Accidentel (bug)** : la récence n'est **pas** neutre. `JourneyLotBuilder.java:34-37` affirme
   « les deux productions d'un diagnostic sont observées au même instant, donc la récence n'y trie
   rien ». Faux : `LearningPlanObservationService.java:86` pose `Instant.now()` **par ligne**,
   dans l'ordre des `skills[]` rendus par le LLM (= ordre d'allowlist). Les 8 observations de
   `0fb5e0bc` s'étalent de `00:17:12.213287` à `.234624`. Le tri « plus récent d'abord »
   (`PAR_GRAVITE`, `:278`) inverse donc l'ordre éditorial : **la dernière compétence écrite
   gagne**. Le même comparateur vit dans `LearningPlanPriorityResolver.java:172-177` (vue
   `/api/me/plan`), et le même artefact touche **tout** lot d'examen blanc (les 3 tâches sont
   écrites en boucle).
3. **Autres sources de divergence possibles** (non observées sur ces données) : compétence
   « maîtrisée ce jour » exclue du lot (`maitriseesCeJour`) ; diagnostic arrivé **après** un examen
   du cycle d'examens ⇒ lot dans le cycle **`EN_ATTENTE`**, invisible (D-69, D-13) ; hook parcours
   en échec (best-effort, rattrapé à la lecture suivante, `DiagnosticSessionCoordinator.java:176-178`).
   Le palier du domaine et D-70 ne jouent pas : ils ne concernent que CO/CE (`JourneyLotBuilder:175-200`).

**Verdict** : la divergence **n'est pas voulue** — les deux docs disent viser le même ordre
(`docs/regles/diagnostic.md:383-389`, `JourneyLotBuilder.java:32-44`) ; elle est **structurelle**
(deux règles, deux plafonds) et **aggravée par un bug** (horodatage par ligne).

### 3.5 Ce que le Plan fait réellement de ces 3 compétences (D-64)

Session de la maquette, cycle `ee634908…` (créé 13 ms après la clôture) :

| pos | type | épreuve | compétence | état |
|---|---|---|---|---|
| 1-3 | `TRAIN_SKILL` | EE | EE3-C3, EE3-C2, EE2-C7 (`severity_rank` 0-2) | ouvertes, **facultatives** (D-64) |
| 4 | `SECTION_EXAM REASSESS` | EE | — | close `SATISFIED_BY_ASSESSMENT` (examen passé 16 min plus tard) |
| 5-7 | `SECTION_EXAM INITIAL_ASSESSMENT` | CO, CE, EO | — | ouvertes |

- `journey.current` au sortir du diagnostic = **l'examen blanc EE** (A159), pas une compétence.
- Les compétences sont **facultatives** et, pour un compte gratuit, **verrouillées** (`ACCESS`,
  D-18, `docs/regles/freemium.md:127`).
- L'examen EE a ensuite produit un lot `EE2-C5, EE1-C3, EE3-C7` versé au cycle `EN_ATTENTE`
  (`df8aa4a4…`) — dont **`EE2-C5`, le « point fort » du rapport**, désormais `TO_REINFORCE HIGH`.
  Normal (l'examen fait autorité, A161), mais le rapport relu plus tard paraîtra contredit par
  le cycle suivant.

### 3.6 Données réelles de la session de la maquette

```sql
SELECT level_estimate, task_completion, communication_status, evaluabilite, schema_version,
       cost_micro_usd, jsonb_pretty(analysis_json)
FROM diagnostic_production_analyses WHERE submission_id = '7d238820-b0d0-4e3e-a2fc-c3b748023bd2';
-- B1 | COMPLETED | EFFECTIVE | EVALUABLE | v1/v1 | 498 µ$
```

Extrait (structure exacte d'une observation, `analysis_json.skills[]`) :

```json
{"skill_code": "EE2-C5", "observed": true, "status": "SOLID", "confidence": "HIGH",
 "priority": false, "evidence_segment": 4,
 "evidence": "Récemment, j'ai vécu une expérience qui m'a marqué.",
 "explanation": "Les événements sont ordonnés naturellement avec des marqueurs temporels simples et clairs."}
```

Servi par `DiagnosticSkillObservationDto` : `skillId, skillCode, skillTitle, section, observed,
status, evidence, explanation, confidence, priority` — **pas** de `taskCode` (déductible du code,
mais non servi), **pas** de rang. `summary` réel : « Production claire et bien organisée qui
répond aux trois parties demandées […] Le développement des arguments reste toutefois simple,
ce… » (tronqué). Sur les 11 analyses `QUICK_TCF` : longueur moyenne 266 c., **6 tronquées**,
10 avec `exemple_cible`, 0 `NON_EVALUABLE`.

---

## 4. Les vrais manques

### 4.1 Les priorités du Plan ne sont pas servies au rapport (D) — le seul manque structurant

- **Pourquoi** : le rapport lit `summary_json.priority_skill_codes`, le Plan lit `journey_step`.
- **Solution minimale** : `DiagnosticResultDto.planPriorities` (nullable) lu sur les étapes
  `TRAIN_SKILL` dont `source_assessment_id = session.id`, triées par `severity_rank`, avec
  `skillId`, `skillCode`, `skillTitle`, `section`, `taskCode`, `rang`, `explanation` (observation
  du diagnostic, jointure par `skillId`), `generalCriterion`, et un booléen `dansLeCycleCourant`.
- **Coût** : ~0,5 j backend (une lecture via `journey_lot` → index `idx_journey_lot_journey`,
  test IT Zonky qui verrouille « rapport = lot »), miroirs `web_sejoufr/lib/types.ts` ⇄
  `mobile_sejourfr/lib/core/models/diagnostic_models.dart`. **Impact IA : aucun.**

### 4.2 La phrase « Vous avez déjà les bases pour viser B2 » (C → D)

Aucune donnée ; règle triviale, mais elle **classe** un écart. Elle est fausse pour
`A1`/`A1_NON_ATTEINT` → B2 (« les bases » ?), pour un niveau égal ou supérieur à l'objectif, et
indéfinie si l'un des deux est `null`. Solution : un enum servi calculé par
`TcfDomaine.ecartAuNiveauCible` (autorité existante), phrases déclarées une fois par front.
~0,25 j. Impact IA : aucun.

### 4.3 Le bug de départage du lot (correctif recommandé, hors maquette)

`observed_at` horodaté par ligne ⇒ départage par ordre d'écriture inversé. Correctif minimal :
un horodatage **unique par soumission** dans `LearningPlanObservationService.recordProduction`
**et** un départage final éditorial (rang d'allowlist pour un diagnostic) plutôt que le code.
⚠️ Ce changement modifie les **futurs** lots (et l'ordre de `/api/me/plan`) : décision du
propriétaire (AR-3). Les lots existants sont persistés et ne bougent pas. Impact IA : aucun.

### 4.4 L'explication générique de l'écran 2 (B, ou E au choix)

`skills.general_criterion` existe pour les 54 compétences, longueur adaptée. Il suffit de le
servir (#15). Si le propriétaire veut le ton exact de la maquette : 48 lignes éditoriales
(migration de contenu), **0 LLM**.

### 4.5 Défauts de parité relevés (préexistants)

| # | Écart | Web | Mobile |
|---|---|---|---|
| P1 | Piste de niveau | `levelTrackPosition` : échelle fixe A2/B1/B2, **aucune piste** si A1/A1_NON_ATTEINT ou objectif `null` (`tcf-diagnostic.ts:49-58`) | `cecrlTrack` : fenêtre glissante sur 5 paliers, **dessine** A1 non atteint/A1 ; objectif `null` ⇒ piste arrêtée au niveau ; B2/B2 ⇒ `[B1, B2]` au lieu de `[A2, B1, B2]` (`cecrl_track.dart:21-35`) |
| P2 | Objectif `null` | « Votre objectif : à définir » (`DR:100`, `RL:39`) | ligne masquée (`DRV:140`) |
| P3 | Production inexploitable | teste `evaluabilite === "NON_EVALUABLE"`, affiche « — » (`DR:86-98`) | teste `niveau == null`, affiche la pastille « Évaluation incomplète » (`DRV:123-139`) |

### 4.6 Pas un manque : la synthèse

Une synthèse existe (`summary`), mais longue et tronquée dans 55 % des cas. La maquette se
construit **sans IA** : phrase 1 depuis `communicationStatus`, phrase 2 depuis objectif +
priorité n°1 du lot. Demander à l'IA une phrase « ce qui vous sépare de l'objectif » serait du
**F** (contrat `diagnostic-analysis-*-v2`, banc payant, risque mesuré sur l'accord v10/v11) :
**inutile**.

---

## 5. Proposition d'intégration minimale (non implémentée)

**Principe** : le **lot du Plan est l'autorité** des priorités ; le rapport, la transition et le
Plan le lisent, par `skill_id`. Aucune règle de sélection n'est recopiée, aucun front ne trie.

1. **Backend (≈ 1 j, tests IT dans la même passe)**
   - `DiagnosticResultDto` gagne `planPriorities` (§4.1) et `situationObjectif` (§4.2). Les
     anciennes `priorities` cessent d'être lues par les fronts ; suppression dans la foulée si
     aucun autre lecteur (aujourd'hui : `nextAction` seulement, `DS:255`).
   - Cas servis, jamais devinés : lot dans le cycle courant ⇒ `dansLeCycleCourant: true` ; lot en
     cycle `EN_ATTENTE` ⇒ `false` (mêmes 3 compétences, phrase adaptée) ; aucun lot (zéro
     fragilité, hook en échec pas encore rattrapé, session antérieure sans parcours) ⇒ liste vide,
     **aucun** repli sur `priority_skill_codes` (une seconde source recréerait la divergence).
   - Optionnel, décision AR-3 : correctif d'horodatage (§4.3).
   - Docs : `docs/regles/diagnostic.md` (corriger l. 383-389), `docs/api-endpoints.md`.
2. **Écran 1 (web ⇄ mobile, ≈ 0,75 j)** : `DiagnosticReport` ⇄ `DiagnosticResultView` restent ;
   « Ce que nous avons observé » = 1 `SOLID` + **les `planPriorities`** (toutes, pas
   `slice(0, 2)`), explication = `explanation` servie ; phrase d'objectif ; nouvelles copies ;
   lien « Revoir ma réponse » ; correction P1–P3.
3. **Écran 2 (web ⇄ mobile, ≈ 1 j)** : nouvel écran **dans le kit** (`Prio`/`SfPrio`,
   `ExamRow`/`SfExamRow`, `NextStepCard`/`SfNextStepCard`, `NoteCard`/`SfNoteCard`, `Cta`/`SfButton`
   — aucune primitive nouvelle identifiée). Données : `planPriorities` (DTO du diagnostic) +
   `GET /api/me/plan/journey` (`blocs[].status`/`meta`, `current`). Routes : web
   `/diagnostic/rapport/[sessionId]/plan` (ou équivalent), mobile route miroir.
4. **Parité** : `npx tsc --noEmit` / `flutter analyze`, aucun nouveau test front.

**Total estimé** : ≈ 3 j hors arbitrages, **0 appel LLM, 0 migration de schéma** (une migration
de contenu seulement si E retenu au §4.4).

### Arbitrages à demander au propriétaire

| # | Question | Recommandation |
|---|---|---|
| AR-1 | « Prochaine étape » : la maquette dit « commencer par ce qui vous limite » ; le serveur sert l'**examen blanc EE** (A159) | afficher `journey.current` tel quel ; réécrire la copie (« Votre prochaine étape : examen blanc d'expression écrite ») |
| AR-2 | « Vos 3 premières priorités » alors que le Plan les sert **facultatives** au cycle d'affinage | garder le titre, ajouter « à travailler pendant votre cycle » ; ou revoir D-64 |
| AR-3 | Corriger le départage par horodatage (change l'ordre des futurs lots et de `/api/me/plan`) | oui, dans la même passe que §4.1 |
| AR-4 | Synthèse : `summary` LLM (tronqué) ou phrase composée | phrase composée ; `summary` retiré ou replié |
| AR-5 | Phrases de `situationObjectif` (A1 → B2, au-dessus de l'objectif, objectif `null`) | 3 phrases + silence si `null` |
| AR-6 | Ton des explications de priorité (constat LLM vs ligne générique) | écran 1 : constat LLM ; écran 2 : `general_criterion` |

---

## 6. Écarts avec l'audit du 2026-09-25

| Point de l'audit du 2026-09-25 | Aujourd'hui |
|---|---|
| Bloc « Ce qui a été évalué » (vocabulaire / grammaire), seul **F** de l'époque | **absent** de la nouvelle maquette : plus aucun besoin de contrat IA |
| CTA « Faire le diagnostic complet », 4 épreuves sans statut | complet retiré des fronts (2026-09-26) ; CTA actuel « Voir mon plan » (`RL:155`) ; le statut des épreuves est désormais servi par `journey.blocs` |
| Rapport encastré dans `PlanGate.tsx:76` ⇄ `plan_screen.dart:498` (C12) | `PlanGate` supprimé (D-69) ; le rapport vit à `/diagnostic` et `/diagnostic/rapport/[sessionId]` ⇄ `diagnostic_rapport_screen.dart` |
| §4.4 « diagnostic ≠ parcours » (4 sessions) | **confirmé sur 7**, et **cause identifiée** : départage par horodatage par ligne (§3.4) ; une session sans aucune compétence commune |
| 4 sessions sans lot « faute d'objectif déclaré » | ces comptes n'ont **aucun** parcours TCF en base ; la démarche est désormais exigée à l'entrée (2026-09-26) et le Plan existe pour tout compte (D-69) |
| « Votre Plan a choisi 3 priorités » lu sur le parcours, révoquant A133 | la nouvelle maquette **sépare** rapport et transition, mais garde 3 priorités sur le rapport : la règle « une seule source par écran » impose que ce soit le lot (§5) |
| Pas de cycle d'affinage | D-64 : compétences facultatives, `current` = examen EE (AR-1, AR-2) |
| Dette `critereBandeFromNote` ⇄ `TcfNoteScale.bandeFor` (B1) | hors périmètre de cette maquette, non revérifiée |
| — | **nouveaux** : défauts de parité P1–P3 ; `summary` tronqué dans 6 analyses sur 11 ; production relisible via un endpoint existant mais sans écran |

---

## 7. Ce qui n'a pas pu être vérifié

- Le JSON réellement servi par `GET /api/me/plan/journey` pour le compte de la maquette (pas de
  jeton pour ce compte ; analyse faite sur le code et la base).
- Le délai réel entre `COMPLETED` et l'écriture du lot sur un serveur chargé (13 ms en local) :
  l'écran 2 étant atteint par un clic, le risque de lire un parcours pas encore écrit est faible
  mais non nul (hook après commit).
- Le rendu visuel des deux fronts (aucune exécution d'app, conformément aux consignes).
