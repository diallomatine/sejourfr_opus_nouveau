# AUDIT — Moteur de cycle (Plan) — Phase 0

> Spec auditée : `docs/progression/SPEC_cycle_plan.md` · brief : `docs/progression/BRIEF_cycle_plan_audit.md`
> Maquettes : `docs/progression/plan_cycle.html` (cycle en cours) · `docs/progression/cycle_termine.html`
> Date : **2026-09-18**. Lecture seule : aucun fichier de code, de migration ni de test n'a été créé ou modifié.
> ⚠️ `docs/audits/` n'existait pas ; la convention du dépôt range les audits dans `docs/progression/` ou
> `docs/audit-*.md`. Le dossier est créé parce que le brief l'exige nommément.

---

## 1. Synthèse

1. **Le moteur décrit par la spec existe déjà, livré le 2026-09-17**, sous les noms `journey` /
   `journey_lot` / `journey_step` / `journey_assessment_event` (`00_schema/V066`), avec 11 arbitrages
   écrits (`docs/decisions/plan-parcours-tcf.md`), 52 tests backend et les deux fronts branchés.
2. **Le vocabulaire n'est pas un conflit** : arbitré par le propriétaire le **2026-09-18** — « cycle »
   était un mot de commodité, on garde `journey` / `lot` / `étape`. Seul le **cadre fonctionnel** compte.
3. Trois règles centrales de la spec sont **déjà codées** : R1 (un examen hors plan valide l'étape),
   R3 (l'entraînement n'alimente jamais la file), et le quota de 2 séries en compréhension.
4. **Le seul vrai trou du modèle** : il n'existe **aucune liaison question ↔ compétence**. R2 n'est
   calculable pour aucune épreuve de compréhension autrement qu'au grain du palier (`CO-B1` *est* la
   compétence). `Competence` existe pourtant : c'est `Skill` (48 compétences d'expression + 6 de
   compréhension) — la spec §10.1 se trompe en l'affirmant absente.
5. Manquent ensuite, par ordre de poids : le **cycle borné** (un bloc par épreuve, un état terminé, une
   barre), le **cycle en attente**, l'**historisation** + page Progression, le **civique** (aucun
   parcours persisté), le **verrou de l'examen par les compétences du bloc** (la sémantique actuelle est
   l'inverse), et le **mode module global persisté** (inexistant, 7 mécaniques concurrentes).
6. Côté freemium, deux exigences de la spec n'ont **aucun support** : le quota « 1 analyse IA / jour »
   (l'existant est « 3 analyses à vie ») et le « 1er examen EE **ou** EO gratuit une seule fois »
   (l'existant est 2 sessions, EE+EO confondues).
7. **Risque principal** : appliquer la spec à la lettre rouvre cinq arbitrages datés et crée une seconde
   autorité sur « cette compétence est-elle acquise ? », face à `SkillMasteryEngine`.

---

## 2. Inventaire

### 2.1 Modèle de données (brief §1)

| élément attendu | existe | chemin | remarque |
|---|---|---|---|
| `Question` / `Choice` / `Theme` / `Passage` | oui | `00_schema/V003`, `V004` · `entity/{Question,Choice,Theme,Passage}.java` | 1 thème **obligatoire** par question. Un thème TCF = une épreuve, pas un sujet. |
| tag plus fin qu'un thème (TCF) | **non, et un faux ami** | `questions.tcf_sub_theme`, `questions.competence_code` (V004) | `competence_code` est un `varchar(64)` **libre, sans FK ni CHECK**, écrit seulement par `audioquestion/service/AudioQuestionPersistenceService.java:97` et les seeds `structure_langue`, **lu par personne**. Ne pas le détourner. |
| tag fin (civique) | **oui** | `00_schema/V051` : `civic_notions` (40 notions) + `questions.civic_notion_id` nullable | Le patron `Question → unité fine` existe, en **1..1**, civique seulement, et **0 question taguée** au lancement. `question_notion_suggestions` (pré-tagging LLM) est créée **vide** par décision de coût. |
| axe fin exploité en CO/CE | oui | `questions.difficulty_band` (V045) `EASY/MEDIUM/HARD` | Seul axe réellement utilisé pour composer une série calibrée. |
| entité `Competence` | **oui, nommée `Skill`** | `skills` (`V025`, `V039`) · `entity/Skill.java` | `section ∈ {EE,EO,CO,CE}`, `task_code` nullable depuis V039, `target_level`, `is_active`, `learning_points` (V063). **Ni `module` ni `theme_id`** ⇒ TCF pur. |
| taxonomie V3 | **en base** | `300_tcf/competences/V319` (48 rangs actifs) + `V320` (144 points, 285 sujets, 855 références) | Générée (`tools/competences/*.py`), UUID `uuid5` déterministes. Concerne l'**expression** seule. |
| compétences CO/CE | oui, **6** | `300_tcf/competences/V318` | `CO-A2/B1/B2`, `CE-A2/B1/B2`. Choix écrit : « une compétence par NIVEAU et par DOMAINE, pas un référentiel fin ». |
| `QuestionCompetence` | **NON** | — | Aucune table de liaison ; 58 tables vérifiées. Seule voie pour du 1..n : une table neuve. |
| `UserCompetenceStatus` | **NON, 4 tables s'en partagent le rôle** | `learning_plan_observations` (V029) · `progression_state` (V044) · `plan_pinned_priorities` (V065) · `user_skill_attempts` (V025) | Aucun état d'étape persisté : doctrine D-7, tout état pédagogique est **dérivé à la lecture**. |
| `UserQuestionStatus` | oui, mais **inerte** | `V007` · `entity/UserQuestionStatus.java` | `wrong_count` / `correct_count` / `last_seen_at` : **code mort en écriture** (seuls écrivains : favoris et suppression de compte). Compteurs cumulatifs **par question**, sans notion de série ⇒ **ne peut pas** servir de base à R2. |
| agrégat « une ligne par série » | **oui, et c'est le bon précédent** | `learning_evidence` (V044) : `result`, `content_id` (sha256 des `questionIds`), `calibration_status`, `natural_key` | 🛑 `learning_evidence_cle_coherente` **interdit** à une preuve CO/CE de porter un `skill_id`. |
| `Attempt` porte un type | oui | `attempts.type` ⇒ `AttemptType {TRAINING, MOCK_EXAM, REVIEW}` | « examen d'épreuve / complet / diagnostic » se lit sur une **combinaison** : `type` + `module_exam_question_type` + `epreuve='TCF_COMPLET'` + `tcf_diagnostic_id` / `civic_diagnostic_id` + `lot_numero`. |
| `Attempt` porte l'épreuve | **oui** | `attempts.epreuve` NOT NULL (V006) | Un attempt ≠ `TCF_COMPLET` couvre **exactement une** épreuve ; le conteneur en couvre 4 par ses enfants. |
| `parent_attempt_id` | oui | V006 (+ index partiel, `ON DELETE CASCADE`) | **`ExamComplet` passable épreuve par épreuve est déjà le modèle en place.** |
| `ExamTemplate` / `ExamTemplateRule` | oui, mais **hors du chemin TCF** | V005 · `100_reference/V110`, `V111` | Les examens TCF par épreuve sont composés **dynamiquement** (`AttemptCompositionService`, `exam_template_id` reste NULL). Les templates civiques sont utilisés (40 q / seuil 32) ; **aucun template « thème en 10 questions »**. |
| parcours persisté existant | **oui** | `V066` · `entity/{Journey,JourneyLot,JourneyStep,JourneyAssessmentEvent}.java` | `journey` : `UNIQUE (user_id, target_level)`, **pas de `module`, pas de `status`**. `journey_lot` : un lot = les ≤3 priorités d'**une** évaluation pour **une** épreuve, `UNIQUE … WHERE status='OPEN'`. `journey_step` : `type ∈ {DIAGNOSTIC, TRAIN_SKILL, SECTION_EXAM}`, `closed_at` + `resolution`, **aucune colonne `status`**. |
| objets de la spec sans aucun équivalent | — | — | cycle **borné** par module avec `EN_COURS`/`EN_ATTENTE`/`HISTORISE` · statut d'étape **persisté** · `QuestionCompetence` · compétence rattachée à un thème civique · `ExamBloc` civique 10 questions · agrégat « N séries réussies par compétence ». |

### 2.2 Flyway et conventions (brief §2)

| élément | valeur | remarque |
|---|---|---|
| prochain numéro de schéma | **`V067`** (`00_schema/` s'arrête à `V066__schema_journey_tcf.sql`) | `V059` n'existe pas (trou assumé). |
| plages thématiques | `00_schema V001-V099` · `100_reference` (max **V114**) · `200_civique` · `300_tcf` (sous-plages par domaine) · `db/migration-dev V900+` | ⚠️ **`docs/migrations-flyway.md` est périmé** : il annonce « max V057 » et « 100_reference max V113 ». |
| nommage | `V<n>__<snake_case>.sql`, double underscore, sans accents dans les fichiers récents | `R__`/`U__` non utilisés. |
| config | `baseline-on-migrate: true`, **`out-of-order: true`**, scan récursif | `application.yaml:20-32`. |
| UUID | **générés par le code** : `uuid PRIMARY KEY` sans DEFAULT + `@UuidGenerator` | `gen_random_uuid()` dans 5 fichiers seulement (V001, V011, V038, V051, V052) ; V066 ne l'utilise pas. Contenu seedé : `uuid5` déterministe. |
| `is_active = FALSE` | **doctrine** | `questions.is_active` + `status`, `skills.is_active`, `skill_prompts.is_active`, `civic_notions.is_active` + `merged_into_id`, `exam_templates.is_published`. « Aucune suppression, le geste est la DÉSACTIVATION » — et un rang désactivé **n'est pas libéré**. |
| contrainte qui **gêne** « un EN_COURS + un EN_ATTENTE par (user, module) » | `uq_journey_user_target UNIQUE (user_id, target_level)` + `chk_journey_target_level IN ('A2','B1','B2')` + `journey_lot.exam_type IN (TCF_*)` | Bloquant si on réutilise `journey` tel quel : la clé est le **niveau cible**, pas le module, et le civique est exclu par CHECK. |
| patron à copier | `uq_journey_lot_open_par_epreuve … WHERE status='OPEN'` | Index unique **partiel sur statut** : exactement la forme d'un « un seul EN_COURS / un seul EN_ATTENTE ». |
| dette ouverte | `plan_pinned_priorities` (V065) | V066 annonce la remplacer ; **la suppression n'a pas eu lieu** — et D-10 (2026-09-17) l'a finalement **conservée** comme repli des candidats sans objectif. |

### 2.3 Couche métier (brief §3)

| élément attendu | existe | chemin | ce que le code fait réellement |
|---|---|---|---|
| moteur de parcours (écriture) | oui | `service/journey/JourneyService.java` | `lire()`, `getOrCreate()` + bootstrap depuis les observations passées (sans LLM), `onAssessmentCompleted()`, `onTrainingProgress()`. `REQUIRES_NEW`, exceptions avalées, verrou pessimiste. Ne mesure ni ne note rien. |
| lecture dérivée | oui | `service/journey/JourneyReadService.java` | Dérive `CURRENT` (première étape ouverte **et exécutable**), `locked` (3 autorités), `SKIPPED`, la progression servie, `JourneyState ∈ {NEEDS_OBJECTIVE, IN_PROGRESS, LOCKED, UP_TO_DATE}`. |
| sélection des priorités | oui | `service/journey/JourneyLotBuilder.java` | `maxPrioritiesPerLot = 3`, tri `PRIORITY` puis `TO_REINFORCE`, confiance ↓, récence ; dédup par compétence ; lots ordonnés par écart au niveau cible. |
| filtre « qu'est-ce qu'une évaluation » (R3) | **oui, déjà codé** | `service/journey/JourneyEvaluationFilter.java` | `DIAGNOSTIC_EE/EO` + `MOCK_EXAM_EE/EO` + (`TCF_CO/CE` **si** l'attempt source est un `MOCK_EXAM`). |
| Plan servi | oui, **dérivé** | `service/LearningPlanService.java` (+ `PlanActionRanker`, `PlanSeanceBuilder`, `PlanFocusResolver`, `PlanAcquisitionSelector`, `PlanMilestoneSelector`, `PlanContentAvailability`…) | `GET /api/me/plan`. Seule écriture : l'épingle. |
| « par quoi mesurer cette épreuve » | oui | `service/PlanDomainAssessmentResolver.pour(epreuve)` | 6 appelants, zéro requête. **C'est l'`EXAM_BLOC` de la spec**, déjà relayé dans `JourneyStepDto.assessment`. |
| niveau par épreuve | oui, **dérivé** | `service/NiveauActuelEpreuveResolver.java` (autorité d'affichage : moyenne des 3 derniers qualifiants) et `service/TcfProfileService.levelProfile` (meilleur historique, **lecture Plan**, D-2) | Deux lectures **volontairement** distinctes. Niveau global = **plancher** des 4 épreuves, `null` ignorés. |
| moteur de maîtrise | oui | `service/SkillMasteryEngine.java` (pur, rien persisté) | `state`, `readyForReassessment`, **`transferProven`** = « l'étape est franchie ». Seuils dans `application.yaml:1267-1344`. |
| moteur de progression V4.2 | oui, **SHADOW** | `progression/` + `progression/progression-config-v1.json` | Contient littéralement le « N séries ≥ X % » cherché (`mockStrongResult: 0.80`, ≥ 2 séries calibrées). **Ne pilote rien** aujourd'hui. |
| matière première | oui | `learning_plan_observations` (`skill_id` **FK réelle**, `status`, `confidence`, `source_type`, `source_id`, idempotent) | Écrite par 4 voies ; un générateur d'étapes n'a besoin de rien d'autre. |
| diagnostic rapide | oui | `entity/DiagnosticSession.java` + `service/diagnostic/*` | Crée un `Attempt(TCF_EE)` mais **`type = TRAINING`**, `is_diagnostic = true` ⇒ **aucune `AiEvaluation`**, donc aucune mesure EE de plein droit. Priorités **persistées** dans `summary_json.priority_skill_codes` (≤3). |
| diagnostic complet | oui, enveloppe seule | `entity/TcfDiagnosticSession.java` + `service/diagnostictcf/*` | 4 sections créées à l'ouverture (CO/CE = 25 items `MOCK_EXAM`), priorités **recalculées** à chaque lecture, sur des **tâches** (pas des compétences). |
| diagnostic civique | oui | `entity/CivicDiagnosticSession.java` + `service/diagnosticcivique/*` | Tunnel invité (`user_id` nullable), aucun coût LLM. |
| plan civique | oui, **100 % dérivé** | `service/plancivique/*` (13 fichiers, Leitner 5 boîtes) | **Aucune table de plan, aucune file, aucune étape** : tout se recalcule sur `answers`. |
| analyse IA — correcteur /20 | oui | `service/AiEvaluationService.java` + `EvaluationPromptBuilder`, clients, validateurs ; verdict dans `ai_evaluations.feedback_json` | `points_a_ameliorer` est du **texte libre sans `skill_code`** ⇒ inexploitable pour créer une étape. |
| analyse IA — priorités exploitables | **oui, une seule voie** | `service/diagnostic/DiagnosticProductionAnalysisService.analyseDiagnostic` / `observeStandardProduction` → `service/LearningPlanObservationService.recordProduction` | Tool-schema `prompts/diagnostic-analysis-tool-schema-v1.json`, champ requis `skills[]` avec `skill_code` + `status`. Allowlist stricte. C'est un **second appel LLM** sur le même texte. |
| examinateur vocal EO | oui | `controller/RealtimeEoController` + `service/realtime/*` | Le backend ne voit jamais l'audio ; `finish` réinjecte le transcript dans la voie du correcteur. |
| examens | oui | `AttemptService.startModuleExam` / `startProductionAttempt` · `FullTcfExamService` (parent + 4 sous-attempts, clôture paresseuse à la lecture) | — |
| **hook post-attempt** | **aucun événement Spring dans tout le backend** | `service/attempt/AttemptInteractionService.doFinish` | Pattern en place : appel direct best-effort. 🛑 **4 points de branchement, pas 1** : (1) `doFinish` après `recordProgression` ; (2) la sortie anticipée EE/EO (l.300-306) ; (3) `FullTcfExamService.buildAndPersistCecrlIfReady` (le parent `TCF_COMPLET` ne passe **jamais** par `doFinish`) ; (4) `lockProductionSubAttempts` **à exclure** (pose `TERMINE` sans examen passé). |
| notion de « série » | 3 réalités | `LotService` (lot = fenêtre déterministe de 20, non persistée) · attempt `TRAINING` portant `lot_numero` · `AttemptService.startComprehensionSeries` (série ciblée, attempt **nu**, compétence re-dérivée du contenu) | `LotDto` : `lastScore` du **dernier essai seulement**. `seriesCount` compte les séries **terminées**, sans seuil. |
| comptage du quota d'étape | oui | `JourneyReadService.seriesTermineesDepuisLaCreation` | `trainSeriesQuota = 2`, **les `NOT_OBSERVED` comptent** : « le quota mesure le travail fourni, pas la réussite ». |
| endpoints | — | `GET /api/me/plan` · `GET /api/me/plan/journey?expand=all` · `GET /api/me/civic-plan` · `GET /api/me/preparation` · `GET /api/me/dashboard` · `GET /api/me/progress[/tcf/{epreuve}/historique]` · `/api/attempts*` · `/api/full-tcf-exams*` · `/api/diagnostics*`, `/api/tcf-diagnostics*`, `/api/civic-diagnostics*` · `/api/lots`, `/api/skills*`, `/api/skill-attempts*`, `/api/production-submissions*`, `/api/realtime/eo/*` | **aucun n'expose une notion de cycle** |

### 2.4 Quotas et abonnement (brief §4)

| élément attendu | existe | chemin | remarque |
|---|---|---|---|
| quota « analyses IA / **jour** » | **NON** | — | `grep dailyQuota\|parJour` = 0. L'existant est **« 3 analyses à vie »** : `SkillAnalysisAccessService` + `sejourfr.competences.analysis.free-analyses: 3`. Le seul « daily » est un **rate-limit anti-abus** (`InMemoryRateLimiter`, Caffeine, **non persistant**) — inapte à porter un quota métier. |
| quotas EE/EO | oui | `service/ProductionAccessService.java` | `FREE_TRAINING_PER_EPREUVE = 1` (entraînement) ; examen blanc de production : **seuil 2, EE+EO confondues**. |
| slots d'examen QCM | oui | `AttemptService.enforceMockExamSlotAccess` | Slot 1 **offert et rejouable à volonté** ; 2..20 abonnés. |
| compétences / sujets ouverts au gratuit | oui | `service/SkillAccessService.java` (`FREE_PROMPTS_PER_SKILL = 2`) | Ouvre 1 compétence par `SkillTaskCode` + le 1ᵉʳ rang CO et CE + **la compétence du focus Plan**. |
| mécanisme de comptage | **calcul à la lecture** sur l'historique | `attempts`, `production_submissions`, `user_skill_attempts` | Aucune table `quotas`. Seul vrai ledger : `user_subscriptions.realtime_eo_sessions_remaining`. |
| production du 403 | oui | `AccessDeniedException` → `exception/GlobalExceptionHandler.handleForbidden` | `message` affichable tel quel. |
| `locked` servi | oui, **12 DTO** | `JourneyStepDto.locked`, `PlanSeanceItemDto`, `LearningPlanPriorityDto`, `PlanDomainSkillDto`, `SkillDto`/`SkillPromptDto`, `FullTcfExamResponse.SubAttempt`, `CivicPlanDto…` | Jamais déduit d'un rang par un front. |
| « première fois gratuite » réutilisable | **non, 4 implémentations ad hoc** | `ProductionAccessService`, `ProductionSubmissionManager.hasFullExamProductionSubmission`, `attempts.production_locked`, slot ≤ 1 | Le plus proche d'un booléen « une fois à vie » : le freebie EE/EO **de l'examen complet**. |
| abonnement servi | oui | `SubscriptionService.currentAccess()` → `GET /api/billing/subscription-status` (`SubscriptionStatusResponse`) + `AuthenticatedUser.hasCivique/hasTcf` | Granularité **module** (`NONE < CIVIQUE < INTEGRAL`) + durée. **Aucune granularité sous le module.** |

### 2.5 Configuration externalisée (brief §5)

| fichier versionné | loader | version pilotée par |
|---|---|---|
| `plan/plan-config-v1.json` | `service/plan/PlanConfigLoader` + `PlanConfigProvider` | `sejourfr.plan.config-version` |
| `plan/tcf-journey-config-v1.json` | `service/journey/TcfJourneyConfigLoader` + `TcfJourneyConfigProvider` | `sejourfr.tcf-journey.config-version` |
| `progression/progression-config-v1.json` | `progression/config/ProgressionConfigLoader` | `sejourfr.progression.engine-version` |
| `prompts/*` (rubriques, tool-schemas, personas, diagnostic, version ciblée) | ~10 providers `@PostConstruct` / `ClassPathResource` | `sejourfr.<domaine>.*` |

Doctrine commune : `FAIL_ON_UNKNOWN_PROPERTIES` + `FAIL_ON_NULL_FOR_PRIMITIVES`, refus si la version du
fichier ≠ version demandée, **aucun défaut en Java**, aucune écriture, aucun rechargement à chaud.

**Où devrait vivre le bloc `cycle.json`** — `src/main/resources/plan/cycle-config-v1.json` + son **propre
loader validant** (`service/plan/CycleConfigLoader`) + `config/CycleProperties` (`sejourfr.cycle.config-version`),
**distinct de `plan-config`** (dont `PlanProperties` interdit explicitement d'influencer le calcul de
maîtrise). 🛑 **Trois clés de la spec §9 ne doivent pas y entrer** : `nb_series_reussies` **est déjà**
`trainSeriesQuota: 2`, `nb_max_competences_par_bloc` **est déjà** `maxPrioritiesPerLot: 3`, et
`ordre_blocs_cycle_initial` **est déjà** `TcfDomainProfileDto.ORDRE` (non configurable par décision D-9).
Et `civique.{seuil_examen, nb_questions_examen}` se heurte à `enums/CivicExamFormat` : *« C'est du code,
pas un réglage. 40 questions et un seuil de 32 ne sont pas des paramètres produit. »*

### 2.6 Fronts — web Next.js et mobile Flutter (brief §6)

| élément attendu | existe | chemin | remarque |
|---|---|---|---|
| Accueil | oui, complet | `web_sejoufr/app/(app)/dashboard/page.tsx` ⇄ `mobile_sejourfr/lib/screens/home/home_screen.dart` (+ `widgets/home_blocks.dart`, `home_labels.dart`) | **7 blocs** aujourd'hui contre **2** dans la spec. À supprimer : « Votre Plan » (aperçu), « Votre progression », « Vos parcours ». À dégraisser : « Où vous en êtes » (sous-titre, `GoalBanner`, `LadderLegend`, `MicroNote`, **4 CTA par épreuve**). |
| Plan | oui, complet | `web_sejoufr/app/(app)/plan/page.tsx` → `app/_components/plan/{PlanModules,LearningPlanView,CivicPlanPanel,PlanGate,PlanMilestoneCard}.tsx` ⇄ `mobile_sejourfr/lib/screens/plan/{plan_screen.dart,widgets/plan_tcf_view.dart,civic_plan_view.dart}` | 10 blocs, **miroirs brique pour brique**. Le parcours est rendu en **file plate** ordonnée par `position` — jamais regroupée par épreuve. |
| « À faire maintenant » | **conforme, autorité unique** | `planNowCard` (web) ⇄ `plan_now_card.dart` (mobile), 6 surfaces | Le seul bloc déjà à la cible. |
| blocs dépliables | **partiel** | `Prio`/`SfPrio` (état **interne**), `HistoryRow`/`SfHistoryRow` (état **externe**) | Aucune brique ne fait un **en-tête de bloc d'épreuve** (initiale + titre + méta + pastille de statut + corps replié). |
| barre d'avancement de cycle | **non** | `ProgressMini` (ratio **sans chiffre**), `PathCard` (barre **segmentée**), `GoalBanner` | Ni le total d'étapes ni un numéro de cycle ne sont **servis**. |
| toggle module | oui | kit `ModuleToggle` ⇄ `SegmentedTabs` + `parcoursSegments` | 🛑 **zéro persistance** : web = `?module=` dans l'URL (`lib/module-switch.ts`), perdu par la sidebar et sur `/examens-blancs` ; mobile = `StateProvider` **en mémoire**, perdu au cold start. **7 mécaniques concurrentes** (dont `ModuleSwitch.tsx`, code mort). Aucun champ serveur. |
| page Progression (cycles historisés) | **NON, aucune forme** | — | Voisins : `/plan/progression` (les 4 domaines), `/plan/evolution`, `/historique`, et surtout `historique/epreuve/[domaine]` ⇄ `epreuve_historique_screen.dart` — **entièrement kit** (`ResultHero`, `LevelChart`, `FilterChips`, `HistoryRow`, `InfoNote`), scopé à **une** épreuve. |
| primitives de kit couvrant les maquettes | **4 sur 6** | `web_sejoufr/app/_components/sejour/SejourKit.tsx` (1792 l.) ⇄ `mobile_sejourfr/lib/core/widgets/sejour/sejour_kit.dart` (4022 l.) | Couverts : carte « À faire maintenant », ligne d'étape avec cadenas (`JourneyRow`/`SfJourneyRow`), barre en substance, badge d'état (mobile a `SfPill`/`SfBadge` autonomes, **le web non**). |
| primitives **manquantes dans les deux kits** | — | — | `BlocAccordion` (la brique centrale de la maquette) · `NextStepCard` (carte de fin de cycle à **deux** actions — aucune primitive n'a deux slots) · `CycleProgress` (barre **continue** + « 3 étapes sur 8 ») · `ExamStepBox` (encart d'examen imbriqué) · `HistoryList` + séparateur de date. |
| écarts de kit unilatéraux | — | — | **Web** : 13 manquantes (`Pill`, `Badge`, `Score`, `UnlockHero`, `SectionTitle`, `StatGrid`, primitives de texte). **Mobile** : 6, dont 2 volontaires (`SejourApp` desktop, `ModuleToggle`). |
| stockage local mobile | 🛑 **Drift est ABSENT** | `flutter_secure_storage` (tokens) + `SharedPreferences` (onboarding, brouillons EE, diagnostic invité, analytics) + fichiers WAV temporaires | Ni drift, ni sqflite, ni hive, ni isar : **zéro occurrence** dans `pubspec.yaml` et `.lock`. Plan/diagnostic/progression = `FutureProvider.autoDispose` + `keepAlive()`, **mémoire seule** ⇒ cold start sans réseau = écran vide. ⚠️ `auth_controller.dart:81-124` : un `GET /me` en échec réseau **efface les tokens et déconnecte**. ⚠️ `SubmissionKeys` est une `Map` d'instance ⇒ un renvoi après kill de l'app **perd la clé d'idempotence**. |

**Avis sur l'offline (demandé, non tranché)** — trois niveaux :
**N1, lecture offline** : persister la *dernière réponse servie* de `/api/me/plan/journey`, `/api/me/plan`,
`/api/me/progress` avec son horodatage, l'afficher « dernière mise à jour le … » et **désactiver toute
action**. Aucune règle dupliquée, aucun verrou déduit ; c'est le pendant disque de `lib/data-cache.ts`
côté web, et ça corrige au passage la déconnexion hors ligne. **N2, écriture offline bornée aux QCM** :
file de réponses + `finish`, rejouée au retour, `clientSubmissionId` **persistée**, l'avancement d'étape
restant **décidé serveur** au rejeu. **N3, cycle rejoué localement** : à déconseiller — ce serait une
seconde autorité sur la règle la plus complexe du produit, dans le langage où le dépôt s'interdit
d'ajouter des tests, et il faudrait répliquer le freemium côté client (donc le rendre contournable).

### 2.7 Tests (brief §7)

| élément attendu | état | chemins |
|---|---|---|
| volumétrie backend | **414 fichiers** (257 `*Test` + 138 `*IT`), **3 838 `@Test`** | ⚠️ `docs/plan-tests-backend.md` annonce « 929 tests verts » : **périmé**. |
| Attempt / scoring | couvert | `AttemptServiceTrainingIT` (10), `AttemptServiceMockExamIT` (27), `AttemptServiceProductionIT` (14), `AttemptServiceReadIT` (13, dont idempotence de `finish`), `AttemptExpirationIT`, `attempt/AttemptChronoTest`, `TcfLevelEstimatorServiceTest` (20), `NiveauActuelEpreuveResolverTest` (14), `TcfProfileServiceTest` (35) |
| examen complet | couvert | `FullTcfExamServiceTest` (16), `FullTcfExamResponseBuilderTest` (21), `FullTcfExamTempsEtContinuiteTest` (9), `FullTcfExamDureesIT`, `FullTcfExamScoreCalibreIT` |
| quotas / freemium | couvert | `SkillAccessServiceTest` (18), `SkillAnalysisAccessServiceTest` (8), `ProductionAccessServiceTest` (23), `FullTcfExamServiceFreemiumTest` (6), `RealtimeQuotaServiceTest`, `SubscriptionServiceTest`, `billing/*` (96) |
| parcours existant | couvert | `service/journey/{JourneyServiceIT (16), JourneySchemaIT (16), JourneyLotBuilderTest (9), JourneyProgressionIT (6), JourneyReadServiceTest, TcfJourneyConfigLoaderTest}` + `JourneyControllerIT` |
| idempotence | couvert | `IdempotenceSoumissionIT` (6) |
| fixtures réutilisables | **oui, riches** | `support/AbstractIntegrationTest` (Zonky + `@Transactional` rollback), `EmbeddedPostgresHolder`, `TestSupportConfig`, `AuthTestSupport.bearer(User)`, **`support/TestData` (1205 l., ~90 fabriques)** dont `epreuveProductionPassee`, `troisTachesEvaluees`, `learningPlanObservation(...)`, `comprehensionSkill(...)`, `paidSubscription(...)` |
| IT « parcours utilisateur complet » | **n'existe pas**, mais faisable sans nouvelle infra | fragments : `LearningPlanProfilProgressifIT`, `TcfDiagnosticEpreuveMesureeIT`, `JourneyProgressionIT` |
| fabriques manquantes | — | `userPremium()` (dupliqué en privé ×2), `candidat(TargetProcedure)` (×9), `examenQcmTermine(...)` (×4), examen complet TCF (parent + 4 enfants), session diagnostic TCF 4 sections, `clientSubmissionId`. ⚠️ Le `@Transactional` de la classe de base bloque `@Async` ⇒ `NOT_SUPPORTED` (4 précédents). |
| tests front | **39 fichiers existants** (16 TS + 23 Dart), **aucun nouveau** (règle du dépôt) | ⚠️ `CLAUDE.md` annonce 41 (16 + 25) : **2 fichiers Dart de moins** qu'au décompte du 2026-09-10. Deux fichiers tomberont si la navigation du Plan change : `web_sejoufr/lib/parcours-tcf-navigation.test.ts` et `mobile_sejourfr/test/plan_navigation_test.dart` — à **mettre à jour ou supprimer**, jamais à contourner. |

---

## 3. Écarts bloquants, par gravité

### B1 — Aucune liaison question ↔ compétence : **R2 n'est pas calculable en CO/CE**
`question_skills` n'existe pas. En compréhension, la compétence est **dérivée du contenu** par
`ComprehensionObservationService` (couple `QuestionType` × `Difficulty`) vers **6** compétences
(`CO-A2/B1/B2`, `CE-A2/B1/B2`) : une série CO-B1 *est* la compétence CO-B1. Par ailleurs
`learning_evidence_cle_coherente` **interdit** à une preuve CO/CE de porter un `skill_id`.
⇒ « 2 séries réussies sur des questions taguées de cette compétence » n'a aujourd'hui de sens qu'au
grain du **palier**. C'est le préalable technique réel, et il n'est pas celui que la spec §10.1 annonce.

### B2 — Le cycle **borné** et le cycle **en attente** n'ont aucun support, et la règle en vigueur dit l'inverse
`journey` n'a ni `module` ni `status` ; sa clé est `(user_id, target_level)`. Les lots sont **par
évaluation** ⇒ plusieurs lots CO possibles, aucun « bloc CO du cycle », aucun état « tout est terminé »,
aucune barre d'avancement, aucune historisation. Et R2 de `docs/regles/plan.md` (2026-09-17) écrit
noir sur blanc : « les priorités au-delà **ne sont ni stockées ni mises en attente** ».
⇒ Le cycle en attente n'est pas un oubli à combler, c'est une **révocation à demander**.

### B3 — `EXAM_BLOC` verrouillé par les compétences du bloc : la sémantique actuelle est **inverse**
`estVerrouillee` ne verrouille un `SECTION_EXAM` que sur le quota d'examen de production EE/EO, jamais
sur l'état des compétences du lot ; et R7 fait qu'un examen passé **avec des entraînements restants**
rend le lot `SUPERSEDED` — là où la spec R1 veut « étape non validée, l'examen compte comme
entraînement ». Deux comportements opposés sur le même geste.

### B4 — Le civique n'a **aucun parcours persisté**
`skills` est TCF-only (`chk_skills_section`), `journey.target_level` est CECRL, `journey_lot.exam_type`
est CHECK sur les 4 épreuves TCF. Le plan civique est **intégralement recalculé** (Leitner, sans état).
Et l'« examen de thème » existant fait **20 questions / seuil 16**, pas 10. Étendre le moteur au civique
est un chantier de schéma entier, pas un paramètre.

### B5 — Freemium : deux exigences sans support, une qui révoque un arbitrage
(a) « 1 analyse IA / jour » : **aucune fenêtre journalière** en base ; l'existant est « 3 à vie ».
(b) « 1er examen EE **ou** EO gratuit une seule fois » : l'existant est **2 sessions, EE+EO confondues**,
plus 1 essai d'entraînement par épreuve, et aucun marqueur « le freebie a été pris en EE ».
(c) « travailler une compétence depuis le Plan = premium » **contredit** l'arbitrage du 2026-08-21
(« un candidat non abonné pourra travailler sa priorité 1 ») et **casse la circularité** que D-1 a
résolue : `SkillAccessService` ouvre la première étape non clôturée pour que `CURRENT` existe. Tout
verrouiller rendrait le parcours d'un gratuit `LOCKED` en permanence — ce qui est peut-être l'effet
voulu, mais c'est une décision produit, pas un réglage.

### B6 — « Le diagnostic rapide **est** l'`EXAM_BLOC` EE gratuit » n'est pas gratuit techniquement
Le diagnostic crée bien un `Attempt(TCF_EE)`, mais `type = TRAINING` et `is_diagnostic = true` ⇒ **pas
de `AiEvaluation`**, donc pas de niveau EE pour le profil (`TcfProfileService.bestProduction` ne lit que
`ai_evaluations`). Les assimiler exige **soit** de faire produire une `AiEvaluation` au diagnostic
(nouveau coût LLM + nouveau contrat), **soit** de faire compter `diagnostic_production_analyses` comme
mesure de plein droit — ce qui change `NiveauActuelEpreuveResolver`, donc « épreuve mesurée », donc R12.

### B7 — Statut d'étape persisté vs D-7
La spec persiste `A_FAIRE`/`EN_COURS`/`REUSSI` sur l'étape. `enums/JourneyStepStatus.java` dit
« DÉRIVÉ À LA LECTURE, JAMAIS PERSISTÉ », et l'invariant racine dit la même chose. Le statut du **cycle**
(EN_COURS / EN_ATTENTE / HISTORISE) est un autre sujet : c'est une **mémoire d'ordonnancement**, du même
type que `resolution`, donc compatible avec D-7 si on l'argumente comme tel.

### B8 — Le « mode global persisté » du toggle n'existe pas
Zéro persistance des deux côtés, 7 mécaniques concurrentes, aucun champ serveur. C'est un chantier à part
entière (choisir l'autorité, réduire les 7 à 1), pas une ligne dans l'écran Plan.

### B9 — Le hook post-évaluation a **4 points**, pas 1
Voir §2.3. Le parent `TCF_COMPLET` ne passe jamais par `doFinish` ; `lockProductionSubAttempts` pose
`TERMINE` sans examen passé et doit être exclu explicitement. Un branchement naïf sur `doFinish` rate
l'examen complet et invente des mesures.

### B10 — Deux moteurs, deux jeux de seuils
`SkillMasteryEngine` (actif, seuils `application.yaml`) et `progression/` (V4.2, **SHADOW**, seuils
`progression-config-v1.json`, 38 tests normatifs) répondent tous deux à « où en est le candidat », avec
des valeurs volontairement séparées. Le moteur de cycle doit **choisir lequel il lit** — et ce choix
change les résultats affichés.

---

## 4. Conflits, avec l'option de résolution recommandée (non appliquée)

| # | Ce que dit la spec | Ce que dit l'existant (autorité, date) | Option recommandée |
|---|---|---|---|
| C0 | `Cycle` / `CycleBloc` / `CycleEtape` | `journey` / `journey_lot` / `journey_step` ; D-8 a refusé le mot « cycle » (déjà pris par `PlanCycleDto`, palier CECRL) | ✅ **Clos le 2026-09-18** par le propriétaire : « cycle » était un nom de commodité, on garde le vocabulaire existant. Le reste du tableau ne parle que de fonctionnel. |
| C1 | ordre des blocs = `EE, CO, EO, CE`, **configurable** | `TcfDomainProfileDto.ORDRE = CO, CE, EO, EE`, autorité unique, **explicitement non configurable** (D-9, « un second ordre ferait diverger la file et Compléter mon profil ») | Garder l'ordre existant. Le besoin réel de la spec (« EE d'abord parce que le diagnostic est un écrit ») est déjà obtenu autrement : le diagnostic rapide **crée** les lots EE/EO, donc ils sont en tête par construction. |
| C2 | `nb_max_competences_par_bloc: 4` | `maxPrioritiesPerLot: 3`, documenté comme **budget pédagogique assumé** (B-5) | Changer la **valeur** dans `tcf-journey-config` si le propriétaire le veut ; ne pas ouvrir une 2ᵉ clé. |
| C3 | une seule constante « 2 séries **réussies** (≥ 0.80) » | **deux** quotas assumés : CO/CE `trainSeriesQuota: 2` séries **terminées** ; EE/EO `PROMPTS_PAR_ETAPE = 5` sujets. D-5 refuse de mettre le second en config (2ᵉ copie d'un chiffre déjà servi dans `progress.quota`) | Garder les deux unités (`progress.unit` est déjà servi). Si « réussies » est voulu, c'est un **changement de sémantique** à consigner : ajouter un seuil lu chez l'autorité qui existe déjà (`learning-plan.comprehension.solid-ratio: 0.80`), pas une 8ᵉ déclaration de 0.80. |
| C4 | `cycle.json` porte `civique.{seuil_examen: 32, nb_questions_examen: 40}` | `enums/CivicExamFormat` : « **c'est du code, pas un réglage** », même traitement que `DureeEpreuve` et `TargetProcedure` | Ne pas externaliser. `cycle-config-v1.json` ne reçoit que les valeurs **neuves** (`seuil_reussite_competence`, `exam_bloc_gratuit`, `analyses_ia_par_jour_gratuit`). |
| C5 | les priorités non retenues partent dans le cycle **EN_ATTENTE** | R2 (`docs/regles/plan.md`, 2026-09-17) : « ni stockées ni mises en attente ; si elles persistent, le prochain examen les redésignera » | Demander la **révocation explicite** de cette phrase avant d'écrire la table. C'est le cœur fonctionnel de la spec §5-§6, donc à trancher en premier. |
| C6 | compte gratuit : cycle visible, **aucune étape cliquable** | Exemption du 2026-08-21 + D-1 : la première étape non clôturée est **déverrouillée** pour que `CURRENT` existe ; contradiction #1 tranchée « on floute l'ACTION, jamais le RÉSULTAT » | Si le propriétaire confirme, l'implémentation est **petite** (`JourneyReadService.estVerrouillee` + `elire`) mais il faut retirer l'exemption dans la même passe et accepter `JourneyState.LOCKED` permanent pour un gratuit. À consigner comme révocation datée. |
| C7 | amorce A : bloc EE = compétences, blocs CO/EO/CE = `EXAM_BLOC` seul | Le diagnostic rapide produit des priorités **EE et EO** (deux productions) ⇒ deux lots peuplés | Accepter l'existant (il est plus riche) **ou** filtrer l'oral à la création du premier cycle. Recommandation : accepter. |
| C8 | Progression = liste des cycles historisés | `/plan/progression` (les 4 domaines), `/plan/evolution`, `/historique`, `historique/epreuve/[domaine]` | **Refondre `/plan/progression`** plutôt que créer une 7ᵉ page, et supprimer `/plan/evolution` dans la même passe (règle « refonte = suppression immédiate »). Les briques de kit du détail par épreuve sont réutilisables telles quelles. |
| C9 | Accueil : supprimer les CTA secondaires par épreuve | `accueilEpreuveOuvreLExercice` fait de certains `LevelRow` un **lanceur d'examen** (`assessments.start`) | Les supprimer **après** avoir décidé par où repasse le lancement : « À faire maintenant » seul, ou le bloc d'épreuve du Plan. Sinon on retire un chemin d'accès sans remplaçant. |
| C10 | — | Documents périmés croisés en chemin | `docs/migrations-flyway.md` (dit V057, réel V066) · `docs/plan-tests-backend.md` (929 tests, réel 3 838) · `dto/LotDto` javadoc (15/20/25, réel 20 partout) · `CLAUDE.md` racine (41 tests front, réel 39) · `docs/regles/diagnostic-tcf-4-epreuves.md` (`config-version` 2 vs 3, le YAML dit 3). À corriger en Phase 2, pas maintenant. |

---

## 5. Questions ouvertes (fermées)

**Modèle**
1. Crée-t-on une table de liaison `question_skills` (1..n) pour les questions CO/CE — **oui / non** ? Si non, accepte-t-on que « compétence de compréhension » reste le **palier** (`CO-B1`), et donc que R2 se lise « 2 séries sur le palier » ?
2. Le cycle borné se **superpose** aux lots existants (un cycle = l'ensemble des lots ouverts à un instant + un `EXAM_BLOC` par épreuve non mesurée) — **oui** — ou **remplace-t-il** `journey_lot` — **non** ?
3. Révoque-t-on la phrase de R2 « les priorités au-delà ne sont ni stockées ni mises en attente », pour permettre le cycle en attente persisté — **oui / non** ?
4. Le statut de l'**étape** reste-t-il dérivé (D-7) — **oui / non** ? (Le statut du **cycle** est persisté dans les deux cas.)

**Règles**
5. Accepte-t-on que `EXAM_BLOC` soit verrouillé tant qu'une compétence du bloc n'est pas clôturée, et donc qu'un examen passé hors plan avec des compétences restantes **ne valide rien** (abandon de `SUPERSEDED` dans ce cas) — **oui / non** ?
6. Le quota d'étape devient-il « 2 séries **réussies** » (seuil 0.80) au lieu de « 2 séries terminées » — **oui / non** ?
7. `nb_max_competences_par_bloc` : on passe de **3 à 4** — **oui / non** ?
8. L'ordre initial des blocs reste-t-il `CO, CE, EO, EE` (D-9) — **oui / non** ?

**Freemium**
9. Travailler une compétence depuis le Plan devient-il **premium sans exception**, ce qui révoque l'exemption du 2026-08-21 — **oui / non** ?
10. Le quota « 1 analyse IA / jour » **remplace-t-il** les « 3 analyses à vie » du module Compétences — **oui** — ou s'y **ajoute-t-il** — **non** ?
11. Le freebie devient-il « **1 seule** session d'examen EE **ou** EO, à vie », en remplacement du budget actuel de 2 sessions EE+EO confondues — **oui / non** ?
12. Le diagnostic rapide devient-il l'`EXAM_BLOC` EE gratuit, ce qui implique qu'il produise une **mesure EE de plein droit** (donc un appel de correcteur en plus, ou `diagnostic_production_analyses` promu en mesure) — **oui / non** ?

**Périmètre**
13. Le civique entre-t-il dans ce chantier — **oui** — ou fait-on le TCF d'abord — **non** ?
14. Si oui : l'`EXAM_BLOC` d'un thème civique fait-il **20** questions (l'existant) plutôt que 10 (la spec) — **oui / non** ?
15. Le mode module global **persisté** fait-il partie de ce chantier — **oui / non** ? Si oui, l'autorité est-elle un champ serveur sur `users` — **oui** — ou locale à chaque front — **non** ?
16. Sur l'Accueil, retire-t-on le `GoalBanner` et les 4 CTA par épreuve, le lancement d'examen ne passant plus que par « À faire maintenant » — **oui / non** ?
17. Le niveau **en sortie** d'un cycle (page Progression) est-il **persisté** à l'historisation — **oui** — ou recalculé à la lecture — **non** ? (Aujourd'hui il n'existe nulle part.)
18. Le niveau **N1** d'offline mobile (cache de lecture + correction de la déconnexion hors ligne) entre-t-il dans ce chantier — **oui / non** ?

---

## 6. Découpage proposé (proposition seule)

| Phase | Contenu | 🛑 STOP |
|---|---|---|
| **P0** | Cet audit. | **Validation + réponses aux 18 questions.** |
| **P1** | Écrire les arbitrages dans `docs/decisions/plan-parcours-tcf.md` (suite de D-11) et mettre la spec en conformité. **Aucun code.** | STOP relecture. |
| **P2** | Schéma : `V067` en DDL seul — cycle borné (`module`, `status`, index uniques **partiels** sur le patron `uq_journey_lot_open_par_epreuve`), historisation, et `question_skills` si Q1 = oui. **Création paresseuse, aucune migration de données.** | STOP relecture du schéma. |
| **P3** | Moteur : bornage par épreuve, état terminé, verrou de l'examen par le bloc, cycle en attente, transitions de fin de cycle (examen complet / actualiser), endpoint(s). **Tests backend dans la même passe** (le gabarit `JourneyProgressionIT` + les fabriques manquantes de `TestData`). Brancher les **4** points post-évaluation. | STOP : revue des tests avant l'écran. |
| **P4** | Freemium + configuration : `plan/cycle-config-v1.json` + loader validant, quota journalier d'analyse, freebie EE/EO « une seule fois ». Tests. | STOP. |
| **P5** | Kit : les **5 primitives manquantes dans les deux kits** (`BlocAccordion`, `NextStepCard`, `CycleProgress`, `ExamStepBox`, `HistoryList`), miroirs brique pour brique. Rien d'autre. | STOP : comparaison visuelle web ⇄ mobile. |
| **P6** | Écrans Accueil (dégraissage à 2 sections) et Plan (regroupement par bloc + écran « cycle terminé »), **web et mobile dans la même passe**. Vérif : `npx tsc --noEmit` / `npm run build` / `flutter analyze`. Mettre à jour ou supprimer `parcours-tcf-navigation.test.ts` et `plan_navigation_test.dart` s'ils rougissent. | STOP. |
| **P7** | Page Progression : endpoint d'agrégation + refonte de `/plan/progression`, suppression de `/plan/evolution`. | STOP. |
| **P8** | Civique, si Q13 = oui (schéma + moteur + écrans). | STOP. |
| **P9** | Chantiers à part, à ne pas mélanger : mode module global persisté (Q15), offline N1 (Q18), et la mise à jour de `docs/regles/plan.md` + des `CLAUDE.md` locaux + des 5 documents périmés (C10). | — |

---

# Annexe P1 (2026-09-18) — le périmètre de fichiers de P2

> Livrable 3 de P1 : **la liste, sans toucher aux fichiers.** Arbitrages :
> `docs/decisions/plan-parcours-tcf.md` D-12 → D-24. Spec conformée :
> `docs/progression/SPEC_cycle_plan.md`.
> P2 = **schéma + miroirs JPA + correction des documents périmés**. Toute logique (orchestration,
> verrous, transitions, lecture) est **P3 ou plus tard** et ne s'écrit pas en P2.

## 1. Migration — DDL seul

| Fichier | Contenu attendu |
|---|---|
| `backend_sejourfr/src/main/resources/db/migration/00_schema/V067__*.sql` *(prochain numéro libre ; `00_schema` s'arrête à V066)* | `journey` : + `module`, + `status`, + niveau d'entrée, + niveau de sortie, + `historise_at`. Remplacement de `uq_journey_user_target` par **deux index uniques partiels** `(user_id, module) WHERE status = 'EN_COURS'` et `… WHERE status = 'EN_ATTENTE'`, sur le patron `uq_journey_lot_open_par_epreuve`. CHECK de cohérence `status` ⇄ `historise_at` ⇄ niveau de sortie, sur le patron `chk_journey_step_closure`. Table **`free_entitlement_usage`** (`user_id`, `code`, `consumed_at`, `source_attempt_id`, `UNIQUE (user_id, code)`). ⚠️ **Aucune migration de données** (création paresseuse) ; UUID générés par le code, pas de `gen_random_uuid()`. |

🛑 **Pas de `question_skills`** (D-19). 🛑 **Rien de civique** (D-23).

## 2. Miroirs JPA et accès (P2, sans logique)

| Fichier | Nature |
|---|---|
| `backend_sejourfr/src/main/java/com/sejourfr/app/entity/Journey.java` | colonnes neuves |
| `…/enums/JourneyStatus.java` *(nom à fixer)* | **nouveau** — `EN_COURS` / `EN_ATTENTE` / `HISTORISE`, avec le javadoc qui dit **pourquoi** il est persisté alors que `JourneyStepStatus` ne l'est pas (mémoire d'ordonnancement, D-14) |
| `…/enums/JourneyStepStatus.java` | **inchangé** — le javadoc « dérivé à la lecture, jamais persisté » reste vrai (D-14) |
| `…/repository/JourneyRepository.java` · `…/manager/JourneyManager.java` | lectures par `(user, module, status)` |
| `…/entity/FreeEntitlementUsage.java` · `…/enums/FreeEntitlementCode.java` · `…/repository/FreeEntitlementUsageRepository.java` · `…/manager/FreeEntitlementUsageManager.java` | **nouveaux** — le ledger unique (D-17). ⚠️ Les 4 implémentations ad hoc y sont ramenées en **P4**, pas en P2. |

## 3. Tests backend de P2

| Fichier | Nature |
|---|---|
| `backend_sejourfr/src/test/java/com/sejourfr/app/service/journey/JourneySchemaIT.java` | **étendu** : les deux index partiels refusent un second `EN_COURS` / `EN_ATTENTE` du même `(user, module)`, et acceptent un `EN_COURS` + un `EN_ATTENTE` |
| `…/support/TestData.java` | fabriques : `journey(user, module, status)`, `freeEntitlementUsage(...)`. ⚠️ En profiter pour remonter les 3 helpers dupliqués en privé relevés par l'audit (`userPremium`, `candidat(TargetProcedure)`, `examenQcmTermine`) est **autorisé mais optionnel** |
| `…/support/TestDataFactoryIT.java` | une assertion par fabrique ajoutée |
| nouveau `…/entitlement/FreeEntitlementUsageIT.java` | l'unicité `(user_id, code)` est refusée **par la base** ; même code chez deux comptes = OK (patron `IdempotenceSoumissionIT`) |

## 4. Documents périmés à corriger en P2 (C10)

| Fichier | Correction |
|---|---|
| `docs/migrations-flyway.md` | dit « max V057 / prochain V058 » et « 100_reference max V113 » ⇒ **V066** et **V114** |
| `docs/plan-tests-backend.md` | dit « 929 tests verts » ⇒ **414 fichiers, 3 838 `@Test`** |
| `backend_sejourfr/src/main/java/com/sejourfr/app/dto/LotDto.java` (+ `service/LotService.listCivique`) | javadoc « A2=15, B1=20, B2=25 » et « 15 » ⇒ **20 partout** |
| `CLAUDE.md` (racine) | « 41 fichiers de test front (16 + 25) » ⇒ **39 (16 TS + 23 Dart)** |
| `docs/regles/diagnostic-tcf-4-epreuves.md` | `config-version` 2 vs 3 ⇒ **3**, comme `application.yaml:1150` |

## 5. Ce que P2 ne touche pas, et où ça vivra

| Sujet | Phase |
|---|---|
| Orchestration (bornage par bloc, état terminé, verrou de l'examen, cycle en attente, transitions de fin de cycle), **4 points de branchement** (D-24) | **P3** |
| `plan/cycle-config-v1.json` + loader, quota/freebie, bascule des 4 implémentations sur le ledger, révocations `SkillAccessService` / `ProductionAccessService` / `free-analyses` | **P4** |
| Les 5 primitives de kit, dans les **deux** kits | **P5** |
| Écran Plan **à partir de « Votre parcours vers le B2 »** (D-22) — Accueil **hors périmètre** | **P6** |
| Endpoint d'agrégation de l'historique, puis écran Progression **à la réception du template** | **P7, bloquée** |
| Mode module global persisté · offline mobile N1 · `docs/regles/plan.md` et les `CLAUDE.md` locaux | **P9** |
| Bug à sortir en ticket séparé : `mobile_sejourfr/lib/core/auth/auth_controller.dart:81-124` (un `GET /me` en échec réseau déconnecte) | hors chantier, **immédiat** |
