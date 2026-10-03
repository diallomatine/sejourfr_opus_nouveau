# Audit — Admin · Productions & corrections IA (PHASE 0 du brief)

> Emplacement : ce rapport est rangé dans `docs/admin/productions_corrections/` (et non dans
> `docs/diagnostic/` comme l'écrit le brief §2.5), à la demande du propriétaire.
>
> Date : 2026-10-03 · Branche : `develop` · **Lecture seule** : aucun fichier de code, aucune
> migration, aucune donnée modifiés ; aucun appel LLM, aucun banc.
> SQL : `SELECT` uniquement sur la base **locale de dev** (`sejourfr_db`) — **aucun chiffre de
> production n'a été mesuré**.
> Légende des statuts : ✅ disponible et vérifié · ❓ à confirmer / partiel · ❌ absent.
> Abréviations de chemins : `BE/` = `backend_sejourfr/src/main/java/com/sejourfr/app/` ·
> `RES/` = `backend_sejourfr/src/main/resources/` · `MIG/` = `RES/db/migration/00_schema/` ·
> `FE/` = `admin_sejourfr/src/`.

---

## 0. Ce qu'il faut retenir (1 minute)

1. **Une seule famille de productions entre naturellement dans l'écran** : les productions TCF
   EE/EO **complètes** (`production_submissions` + `ai_evaluations`), qu'elles viennent d'un
   entraînement, d'un examen blanc d'épreuve, d'un examen complet, ou de l'**EO temps réel**
   (l'examinateur Gemini ne note pas : sa transcription repasse dans le même correcteur). Le
   diagnostic et les petits sujets « Compétences » ont **d'autres contrats** (pas de note /20,
   pas de 4 critères) — cf. §F-2.
2. **Presque tout ce que demande le brief existe**, sauf : l'**audio** (supprimé par décision
   du propriétaire — ❌ définitif), la **sortie brute de l'IA** (non stockée : ce qui est en base
   est le JSON **après** filets serveur), le **provider**, la **durée d'appel**, le **nombre de
   tentatives LLM**, le **coût d'un appel en échec**, et le **signalement** (à créer).
3. **Un écran admin couvre déjà la moitié du besoin** : la console **Calibration**
   (`FE/features/calibration/`, `/api/admin/calibration/*`) liste les productions évaluées et en
   affiche le détail (`EvaluationReport`, `ProductionView`). Le brief interdit l'architecture
   parallèle et le dépôt impose « refonte = suppression de l'ancien » : l'articulation des deux
   écrans est la **première décision** à prendre (§F-1).
4. **Le niveau d'une tâche est persisté** (`ai_evaluations.niveau_cecrl`), calculé **serveur** à
   partir des 4 notes de critère : moyenne pondérée (0,25 chacun) arrondie au dixième, puis
   table officielle TCF `0 / ]0;2[ / [2;6[ / [6;10[ / ≥10` (v6+), puis plafonds. Le niveau
   renvoyé par l'IA est gardé à part (`niveau_cecrl_ia`). Les 2 traces réelles (§C.4) se
   recalculent à la main.
5. **Conflits majeurs brief ⇄ dépôt** : lecteur audio + URL signée (interdit), « scores bruts »
   (inexistants en base), « config tarifs/seuils en JSON » (déjà en YAML/grille, une 2ᵉ source
   ferait deux autorités), « niveau final » (le niveau qui fait foi pour le candidat est celui de
   l'**épreuve**, pas de la tâche), tests front (interdits), coût affiché en € (il est en USD).

---

## A. Disponible

### A.1 Admin existant (stack, conventions à réutiliser)

| Sujet | Constat | Source |
|---|---|---|
| Stack | React 19 + TS strict + Vite + React Router 7 + TanStack Query 5 + React Hook Form ; CSS Modules vanilla, pas d'UI kit ni clsx ni lib d'icônes | `admin_sejourfr/package.json`, `admin_sejourfr/CLAUDE.md:5-15` |
| Routes | `FE/App.tsx:39-96` : `/login` hors layout, tout le reste sous `<ProtectedRoute><AppLayout/>` | `FE/App.tsx:41-47` |
| Navigation | **Source unique** `FE/components/layout/navigation.ts:21-64` (sections Pilotage, Support, Contenu, Génération IA, Commerce, Échanges). « Calibration notation » et « Coût de l'IA » sont sous **Génération IA** (l.48-49) | `navigation.ts:48-49` ; ajouter un écran = route + entrée nav (`admin_sejourfr/CLAUDE.md:473-474`) |
| Tableau | Pas de composant React : module CSS partagé `FE/components/ui/DataTable.module.css` (`.tableWrap`, `.cardTable` → fiche < 720 px, `data-label` obligatoire). Référence : `FE/features/users/UsersPage.tsx:143-226` (ligne cliquable via `navigate`, tableau estompé pendant le changement de page) | `admin_sejourfr/CLAUDE.md:480-488` |
| Pagination | **Serveur**, composant `FE/components/ui/Pagination.tsx` (page indexée 0). Type `PageResponse<T>` `{content,page,size,totalElements,totalPages,first,last}` : `FE/types/api.ts:67-75` ⇄ `BE/dto/PageResponse.java:6-25` (jamais un `Page` Spring sérialisé) | — |
| État dans l'URL | Hook partagé `FE/hooks/useUrlListState.ts:20-132` : page 1-based dans l'URL / 0-based vers l'API, filtre ⇒ retour page 1 dans la même écriture, recherche debouncée 300 ms en `replace`, recalage de page hors bornes. `DEFAULT_PAGE_SIZE = 25`, options `[10,25,50,100]` (l.4-5). Utilisé par `/users` (`features/users/useUserListParams.ts:24-52`) et `/subscriptions` | `admin_sejourfr/CLAUDE.md:520-534` |
| Filtres | Puces exclusives `FE/components/ui/Chips.tsx` (users) ; selects ailleurs | `UsersPage.tsx:104-109` |
| Garde front | `FE/routes/ProtectedRoute.tsx:12` : non connecté ou `role !== "ADMIN"` ⇒ `/login` (la vraie barrière est le backend, commentaire l.9-11) | — |
| Client HTTP | `fetch` natif, `FE/api/http.ts` : base `VITE_API_BASE_URL ?? http://localhost:8080` (l.4), `HttpError` (l.6-15), refresh JWT unique partagé sur 401 puis rejeu (l.28-63, 139-150) ; un fichier `FE/api/*Api.ts` par domaine | — |
| TanStack Query | Clés `["resource", params]` / `["resource","sub",id]` ; ex. `["adminUsers","list",filters]` + `keepPreviousData` (`UsersPage.tsx:44-46`) ; client `FE/lib/queryClient.ts:3-16` (pas de retry sur 401/403/404) | `admin_sejourfr/CLAUDE.md:445-449` |
| Primitives UI | `Modal` (`FE/components/ui/Modal.tsx:7-47`), `Tag` (tons info/success/danger/warning/neutral, `dot`), `Button`, `Panel`, `PageHeader`, `Toast`, `Chips`, `Avatar`, `Icon`. **Aucun repliable/accordéon** n'existe | `admin_sejourfr/CLAUDE.md:475-479` |
| Dates | `FE/lib/dates.ts` : `formatParisDate` / `formatParisDateTime` (Europe/Paris, `—` si nul) | — |
| Écrans voisins réutilisables | **Calibration** `FE/features/calibration/` : `ProductionView` (sujet + réponse), `EvaluationReport` (491 lignes : critères, accomplissement, avertissements, confiance, retour rédigé, badge legacy v3, bandeau NON_EVALUABLE), `SubmissionDetailModal`, `HumanNoteForm`, `CalibrationHealth` | `admin_sejourfr/CLAUDE.md:383-428` |
| Backend admin — rôle | `SecurityConfig` : `@EnableMethodSecurity` (l.23), `.requestMatchers("/api/admin/**").hasRole("ADMIN")` (l.101), 401 entry point / 403 access-denied (l.62-67). `@PreAuthorize("hasRole('ADMIN')")` en défense en profondeur sur 5 contrôleurs (ex. `BE/controller/AdminAiCostController.java:30`, `AdminSuiviController.java:20`) | `BE/security/SecurityConfig.java` |
| Backend admin — tests de droits | Matrice `backend_sejourfr/src/test/java/com/sejourfr/app/controller/AdminRoutesSecurityIT.java` : `adminRoutes()` l.52-123 (anonyme 401, USER 403, ADMIN ni 401 ni 403) ; **tout nouvel endpoint admin y ajoute sa ligne** (`backend_sejourfr/CLAUDE.md`, § Tests) | — |
| Backend admin — pagination | Style « A » des consoles récentes : `page`/`size` explicites, `size` défaut 25 borné `[1,100]`, **tri imposé et stable** (`createdAt DESC, id DESC` — `AdminUserService.java:66-67,83-84`), coût SQL **figé par page** et verrouillé par égalité dans l'IT | `docs/api-endpoints.md:1017-1075` |
| Backend admin — recherche | `Specification` + `PageRequest` (`AdminUserService.java:82-119`), `UserSpecifications.search` : UUID complet ⇒ égalité, sinon « contient » sans casse, jokers échappés (`LikePattern.contient`) ; lectures d'affichage en SQL natif dans un `*ReadRepository` (`AdminUserReadRepository.java:51-69`) | — |
| Admin courant | `BE/security/CurrentUser.getId()` (utilisé par `AdminCalibrationController.java:60-66`) | — |
| Configuration | `application.yaml` + POJO `@ConfigurationProperties` (~30 classes, `@ConfigurationPropertiesScan`) ; JSON versionnés chargés par version (`plan/plan-config-v1.json`, `analytics/analytics-config-v1.json`, `email/*`, `billing/revenue-rules-v1.json`, `progression/progression-config-v1.json`) ; grilles `RES/prompts/*`. **Aucun JSON de tarifs** : les tarifs LLM sont en YAML/env (`application.yaml:965-975, 989-996, 1072-1084`) | `backend_sejourfr/CLAUDE.md` § « Les nombres vivent en configuration » |
| Coût LLM | `estimateCostCents` **n'existe plus** (trace : commentaire `BE/util/MicroDollars.java:15`). Autorité unique **`BE/util/CoutAppelLlm.java:101-136`** (micro-dollars, 3 tarifs, heures pleines), Whisper : `BE/util/CoutTranscription.java:38-42`. Coût **persisté au moment de l'appel** — à **lire**, jamais recalculer | `docs/regles/notation-ia.md:214-287` |
| Vue de coût | `v_ai_usage` (`MIG/V048__vue_cout_ia.sql:46-140`) : UNION des 4 sources de coût, lue par `/api/admin/ai-costs` (agrégats seulement) | — |

### A.2 Familles de productions qui reçoivent une évaluation IA

| Famille | Tables | Évaluation | Entre dans l'écran ? |
|---|---|---|---|
| **1. Productions TCF EE/EO complètes** — entraînement libre, examen blanc d'épreuve (`attempts.slot_number`), sous-épreuve d'examen complet (`attempts.parent_attempt_id`) | `production_submissions` (`MIG/V011…:50-65`, `BE/entity/ProductionSubmission.java`), `production_tasks`, `transcriptions`, `ai_evaluations` (`BE/entity/AiEvaluation.java`) | 4 critères /20, note, niveau serveur, feedback | ✅ **cœur du MVP** — 185 lignes en dev (`is_diagnostic = false`) |
| **1 bis. EO temps réel** (examinateur vocal Gemini) | `realtime_sessions` (`BE/entity/RealtimeSession.java:34`) — **aucune colonne de note** ; la fin de session crée une `production_submissions` `source='REALTIME'` + une `transcriptions` `modele_utilise='realtime'` et repasse dans le **même correcteur** (`BE/service/realtime/RealtimeSessionService.java:274-335` → `ProductionEvaluationService.evaluateRealtimeTranscript` `:249-302`) | Identique à la famille 1 (confiance plafonnée `MOYENNE`, `AiEvaluationService.java:866-869`) | ✅ via la famille 1 (53 lignes REALTIME en dev). Lien session ⇄ soumission **implicite** `(attempt_id, production_task_id)`, pas de FK |
| **2. Diagnostic** (rapide ; sous-épreuves du diagnostic complet passent par la famille 1) | `production_submissions` `is_diagnostic=true` + `diagnostic_production_analyses` (`MIG/V029…:89-113`, 1-1 `UNIQUE(submission_id)`) | Contrat propre (`level_estimate`, `task_completion`, `communication_status`, `analysis_json`), **jamais** dans `ai_evaluations` | ❓ décision §F-2 (34 lignes en dev, 0 `ai_evaluations`) |
| **3. Compétences (petits sujets EE/EO)** | `user_skill_attempts` (`MIG/V025…:190-255`, `BE/entity/UserSkillAttempt.java:45`) — production **et** analyse sur la même ligne, réécrite en place | `criterion_status` + `analysis_json.level_reached` ; **pas de note /20, pas de critères pondérés** | ❓ décision §F-2 (37 analyses en dev) |

Requête de contrôle : `SELECT ps.is_diagnostic, count(e.id), count(d.id) FROM production_submissions ps LEFT JOIN ai_evaluations e … LEFT JOIN diagnostic_production_analyses d …` → `false : 179 évals / 0 analyses` ; `true : 0 / 34`.

### A.3 Cartographie des données (famille 1) — tableau du brief §2.2

| Information | Statut | Source | Remarque |
|---|---|---|---|
| ID production | ✅ | `production_submissions.id` | UUID ; la maquette affiche 8 caractères |
| Utilisateur — id | ✅ | `production_submissions.user_id` | index `idx_prod_sub_user_submitted (user_id, submitted_at DESC)` |
| Utilisateur — email | ✅ | `users.email` (jointure `user_id`) | compte supprimé : `deleted-<id>@anon.sejourfr` (`User.anonymize`) ; `users.is_internal` distingue les comptes internes (115 des 219 productions de dev) |
| Date | ✅ | `production_submissions.submitted_at` (aussi `created_at`, `updated_at`) | instant UTC, à formater Paris |
| Type EE/EO | ✅ | `production_tasks.epreuve` (`TCF_EE`/`TCF_EO`) via `production_task_id` | pas porté par la soumission |
| Tâche 1/2/3 | ✅ | `production_tasks.tache_numero` | — |
| Contexte de passation | ❓ | dérivable : `attempts.parent_attempt_id` (examen complet), `attempts.slot_number` (examen blanc d'épreuve), sinon entraînement ; `is_diagnostic` | **absent du brief et de la maquette**, utile ; sémantique exacte à confirmer (en dev, les productions d'examen portent `type=TRAINING`, `mode=ENTRAINEMENT` + `slot_number`) |
| Mode EO (enregistré / temps réel) | ✅ | `production_submissions.source` (`ASYNC`/`REALTIME`, `MIG/V017`) | absent de la maquette, déterminant pour lire une transcription |
| Sujet — titre | ✅ (nullable) | `production_tasks.titre` (`MIG/V028`) | repli « Sujet N » obligatoire (`docs/regles/notation-ia.md:495-505`) |
| Sujet — consigne | ✅ | `production_tasks.consigne` | — |
| Sujet — contexte | ✅ (nullable) | `production_tasks.contexte` | — |
| Sujet — bornes | ✅ | `production_tasks.mots_min/mots_max` (EE), `duree_min_sec/duree_max_sec` | `niveau_cible` existe aussi |
| Sujet — fiche examinateur EO T2 | ✅ mais **hors « reçu par le candidat »** | `production_tasks.agent_role_card` (`MIG/V021`) | « jamais exposée à un client, jamais envoyée à l'IA correctrice » (`docs/regles/notation-ia.md:489-492`) ⇒ ne pas la mêler au bloc « Sujet » |
| Texte candidat (EE) | ✅ | `production_submissions.texte_soumis` | — |
| Nb de mots (EE) | ✅ | `production_submissions.mots_count` | calculé à la soumission par séparation sur les espaces (`ProductionEvaluationService.java:174-177`) ; recalcul SQL identique sur la trace EE (67/67). **NULL en EO** |
| Audio original | ❌ **définitif** | — | **non conservé** (décision propriétaire, consentement) : `AudioEphemere.avecOctets` (`BE/util/AudioEphemere.java:36-43`), `setMediaUrl(null)` (`ProductionEvaluationService.java:148`). `media_url` = LEGACY (46 lignes historiques), **plus aucun code ne relit un audio de candidat** (`docs/regles/audio-productions.md`) |
| Clé R2 / rétention | ❌ | — | idem ; aucune rétention à afficher |
| Durée (EO) | ✅ | `production_submissions.media_duration_sec` ; aussi `transcriptions.audio_duration_sec` | ASYNC = durée Whisper ; REALTIME = durée de session (`ProductionEvaluationService.java:149,279`) |
| Transcription — texte | ✅ | `transcriptions.texte` (la plus récente : `TranscriptionRepository.java:14`) | le manager rend le texte **recollé** (`BE/manager/TranscriptionManager.java:40-43`) — c'est celui vu par le correcteur et le candidat |
| Transcription — outil | ✅ | `transcriptions.modele_utilise` | `whisper-1` (57) ou `realtime` (53, Gemini) |
| Transcription — qualité | ✅ | `transcriptions.qualite_degradee`, `taux_formes_suspectes`, `taux_collages` (+ `avg_logprob`, `no_speech_prob`, `compression_ratio`, Whisper seulement) (`MIG/V027`) | absent de la maquette ; utile au motif « problème de transcription » |
| Transcription — coût | ✅ (Whisper) | `transcriptions.cout_micro_usd` (`MIG/V035`) ; legacy `cout_estime_centimes` | temps réel : coût Gemini **non stocké** ❌ |
| Statut évaluation | ✅ | `production_submissions.statut` (`SUBMITTED/TRANSCRIBING/EVALUATING/EVALUATED/FAILED`) + `ai_evaluations.evaluabilite` (`EVALUABLE/NON_EVALUABLE`, `MIG/V041`) | « Non évaluable » est un **4ᵉ état** absent du brief (§F-6) |
| Scores par critère | ✅ (après filets) | `ai_evaluations.feedback_json.scores_criteres[] {code, label, note_sur_20, bande, commentaire, preuve}` | **notes APRÈS couplage serveur**, pas les notes brutes de l'IA (§C.2) ; NON_EVALUABLE ⇒ **aucun** critère (pas des zéros) |
| Barème | ✅ | grille `RES/prompts/production-rubrics-<rubrics_version>.json` : `rubrics.<EE_T1..EO_T3>.criteres[].poids` (0,25 ×4 depuis v5), échelle /20, `commun.niveau` (seuils), `commun.bandes_criteres` | la grille **n'est pas en base** ; seule la grille **active** est chargée (`ProductionRubricsProvider.java:112`) |
| Niveau renvoyé par l'IA | ✅ | `ai_evaluations.niveau_cecrl_ia` | « advisory », jamais exposé au candidat ; 17 évaluations sur 179 divergent du niveau serveur en dev |
| Note renvoyée par l'IA | ❌ | — | `feedback_json.note_globale` est **écrasée** par la note serveur (`AiEvaluationService.applyServerComputedNote` `:1437-1451`) ; l'écart > 3 points n'est que loggé |
| JSON brut IA | ❌ | — | non stocké ; `feedback_json` = sortie **validée + post-traitée + enrichie** (labels, bandes, preuves résolues, purges, `avertissements`, `plafond_niveau`, `version_ciblee`, `fluidite`) |
| Feedback (résumé, forts, à améliorer…) | ✅ | `feedback_json` : `accomplissement {objectif, objectif_resume, points_traites[], points_oublies[]}`, `points_forts[]`, `points_a_ameliorer[] {constat, comment, exemple}`, `confiance` + `confiance_raisons[]`, `avertissements[]`, `justification_niveau`, `version_ciblee {leviers[], a_retenir, exemple_cible \| reformulations, niveau_vise, niveau_constate}` ; legacy : `suggestions`, `exemples_corriges` (148 lignes), `version_amelioree` (12) | `justification_niveau` est **retirée** du DTO candidat (`ProductionSubmissionMapper.java:91-95`) mais répond directement à « pourquoi B1 et pas A2/B2 » |
| Feedback vu par le candidat | ✅ | `ProductionSubmissionMapper.toEvaluationDto` (`BE/mapper/ProductionSubmissionMapper.java:86-113`) → `EvaluationResultDto` | voir §C.3 ; le rendu exact dépend de chaque front (❓ §G) |
| Niveau final (tâche) | ✅ **persisté** | `ai_evaluations.niveau_cecrl` | calculé une fois à l'évaluation (`AiEvaluationService.java:299-307`) ; **non montré au candidat si `confiance` est absente** (97 évaluations legacy sur 179 en dev) |
| Plafond appliqué | ✅ | `feedback_json.plafond_niveau` (`AiEvaluationService.java:1250-1258`) | 0 ligne plafonnée en dev |
| Couplage appliqué | ❌ | — | seulement loggé (`AiEvaluationService.java:1197-1200`) ; non déductible avec certitude |
| Situation dans le palier | ✅ dérivé lecture | `SituationDansNiveau.of` (`BE/enums/SituationDansNiveau.java:85-100`) | calculé avec les seuils de la grille **active** (`ProductionSubmissionMapper.java:102-103`) |
| Provider | ❌ | — | seule `realtime_sessions.provider` existe ; `ai_evaluations` ne porte que le modèle. Déduire le provider du nom du modèle serait une invention |
| Modèle | ✅ | `ai_evaluations.modele_utilise` | `validation-serveur` pour un NON_EVALUABLE ; le modèle du 2ᵉ appel « version ciblée » n'est **pas** enregistré (même provider par règle) |
| Version du prompt | ✅ (2 champs) | `ai_evaluations.rubrics_version` (grille, `MIG/V022`, **NULL sur 112/179** lignes de dev) + `prompt_version` (tool-schema) | les versions du contrat « version ciblée » ne sont pas persistées ❌ |
| Tokens in / out | ✅ | `tokens_input`, `tokens_output`, `tokens_input_cache_hit` (`MIG/V034`) | **cumul** correction + réparation + seconde passe + version ciblée (`AiEvaluationService.java:279-282,392-401`, `ProductionVersionCibleeService.java:246-251`) — non ventilable |
| Coût | ✅ | `ai_evaluations.cout_micro_usd` (USD × 10⁻⁶) ; legacy `cout_estime_centimes` (centimes d'€, plus écrite) | les deux unités **ne s'additionnent jamais** (`MIG/V048…` en-tête) ; NULL = inconnu, jamais 0. Entité mappée en `Integer` sur une colonne `bigint` (`AiEvaluation.java:122`) |
| Début / fin / durée | ❓ partiel | `submitted_at` → `ai_evaluations.evaluated_at` | aucun horodatage de début d'appel ; `evaluated_at` est posé au `@PrePersist` de l'évaluation (`AiEvaluation.java:130-132`), **avant** le 2ᵉ appel « version ciblée » (`ProductionPipelineAsyncRunner.java:134` puis `:163`) ⇒ l'écart couvre file d'attente + appel(s) de correction + réparation, pas la version ciblée. Libeller « délai soumission → évaluation », jamais « durée d'appel » |
| Nb de tentatives | ❓ partiel | `production_submissions.retry_count` = relances **manuelles** `/retry` (max 3) | `ai_evaluations.nb_retries` **jamais écrite** (toujours 0) ; les 3 tentatives `@Retryable` et la réparation sémantique ne sont **pas** persistées ❌ |
| Message d'erreur | ✅ | `production_submissions.erreur_message` (≤ 1000 car., `ProductionPipelineFailureRecorder.java:23-37`) | un `FAILED` n'a **aucune** ligne `ai_evaluations` ⇒ ni tokens ni coût de l'appel raté ❌ |
| Note humaine (calibration) | ✅ | `human_calibration_notes` (plusieurs par soumission, la dernière fait foi) | hors brief, mais déjà présent à l'admin |

### A.4 Une production peut-elle avoir plusieurs évaluations ?

- **Oui par construction** : `ai_evaluations` est en 1-N (FK `submission_id`, index
  `idx_ai_eval_submission_latest (submission_id, evaluated_at DESC)`, `MIG/V011…:116-118`).
- **Le candidat voit la plus récente** : `AiEvaluationManager.findLatestBySubmissionId`
  (`AiEvaluationRepository.java:19`), utilisé par `ProductionSubmissionMapper.toDto` (l.41-44)
  et par le bilan (`ProductionBilanService.java:99-121`).
- **En pratique 1-1** : `/retry` n'est permis que sur `FAILED` (`ProductionEvaluationService.java:333-356`),
  aucun endpoint de ré-évaluation ; en dev `count(distinct submission_id) = count(*) = 179`.
- Les rejugements V040-V042 sont des `UPDATE` en place (`MIG/V042…:132-138`), pas de nouvelles lignes.
- ⚠️ **Une ligne d'évaluation n'est pas immuable** : le 2ᵉ appel « version au niveau visé »
  réécrit `feedback_json` et additionne ses tokens/coût sur la même ligne, **après** que
  l'évaluation est `EVALUATED` (`ProductionVersionCibleeService.java:194-195, 243-251`).

⇒ L'écran montre **la dernière évaluation** (même règle que le candidat) et affiche, si > 1,
« N évaluations » (cas théorique, non observé).

---

## B. Manquant

| Élément | Utilité pour l'écran | Type de changement |
|---|---|---|
| Endpoints admin liste/détail « Productions IA » | tout l'écran | `endpoint` + `backend` |
| Signalement (création, vérification, retrait, filtre) | boucle « signaler » | `migration` + `backend` + `endpoint` + `front` |
| Lecture de la grille **de l'évaluation** (seuils, poids, bandes) quand elle n'est pas la grille active | bloc « Calcul SejourFR » sur l'historique | `backend` (lecteur en lecture seule des fichiers `production-rubrics-vN.json`, aucune migration) |
| Écran liste + détail, entrée de nav, primitive repliable | front | `front` |
| Audio / URL signée | lecteur | **aucun** — ❌ définitif (décision propriétaire). Afficher « Audio non conservé » |
| Sortie brute de l'IA (avant filets) | bloc « JSON brut », « scores bruts » | `backend` + `migration` (colonne additive, écrite **à l'avenir** seulement) — **optionnel**, §F-4 |
| Trace du couplage (critère ramené de X à Y) | expliquer un écart IA ⇄ SejourFR | `backend` + `migration` (même colonne que ci-dessus) — optionnel, §F-4 |
| Provider | infos techniques | `backend` + `migration` (colonne additive) — optionnel ; historique « non disponible » |
| Durée d'appel, tentatives LLM, coût d'un appel raté | infos techniques | `backend` + `migration` — **hors MVP** recommandé (« non disponible ») |
| Versions du contrat « version ciblée » | infos techniques | `backend` + `migration` — hors MVP |
| Coût Gemini temps réel | infos techniques | hors périmètre (non mesuré nulle part) |
| Index de liste globale `submitted_at DESC, id DESC` | tri par défaut sans `user_id` | `migration` — utile seulement si le volume prod le justifie (❓ volume) |

---

## C. Chaîne de notation

### C.1 EE (écrit) — pas à pas

| # | Étape | Où | Remarques |
|---|---|---|---|
| 1 | Dépôt `POST /api/production-submissions` (JSON) | `BE/controller/ProductionSubmissionController.java:41,52` | idempotence `client_submission_id` (`MIG/V046`) |
| 2 | Bornes de mots **strictes** `production_tasks.mots_min/max` (T1 30-60, T2/T3 40-90) | `ProductionEvaluationService.java:436-462` via `ProductionTextBounds` | hors bornes ⇒ 4xx, **aucune** ligne, aucun appel |
| 3 | Insertion `SUBMITTED`, puis runner async (`EVALUATING`) | `ProductionPipelineAsyncRunner.java:109,134` | sans transaction englobante (invariant) |
| 4 | Contrôles déterministes **avant LLM** (vide / < 5 mots exploitables, alphabet non latin > 0,30, mots-outils < 0,10, recopie consigne ≥ 0,60) | `BE/service/ProductionValidityService.java:205-262` | invalide ⇒ `NON_EVALUABLE`, `modele_utilise='validation-serveur'`, note = niveau = **NULL**, 0 token (`AiEvaluationService.java:753-827`) |
| 5 | Prompt système = `commun.sections` + `commun.few_shot` de la grille ; message utilisateur = tâche, consigne, bornes, contexte, critères/barème/descripteurs, **puis** la production découpée en segments numérotés | `BE/service/EvaluationPromptBuilder.java:49-55, 79-126` ; grille `RES/prompts/production-rubrics-v15.json` (`EVAL_RUBRICS_VERSION`, `application.yaml:689`) | matrice grille ⇄ tool-schema vérifiée au boot (`ProductionRubricsProvider.java:45-89, 178-218`) : v15 ⇄ v9 |
| 6 | Appel LLM, outil forcé `submit_evaluation`, tool-schema `production-evaluation-tool-schema-v9.json` (`EVAL_PROMPT_VERSION`) | `OpenAiCompatibleEvalClient.java:51-95, 200-223` ; provider `${EVAL_LLM_PROVIDER:deepseek}` (`application.yaml:460`), modèle `deepseek-v4-flash` | sortie : `note_globale`, `niveau_cecrl`, `justification_niveau`, 4 `scores_criteres {code, note_sur_20 0-20, commentaire, preuve_segment}`, `points_forts ≤2`, `points_a_ameliorer ≤2`, `confiance(+raisons)`, `accomplissement` ; `additionalProperties:false` |
| 7 | Parsing ; sortie malformée = transitoire ⇒ `@Retryable maxAttempts=3` (en dur) ; 4xx terminal | `OpenAiCompatibleEvalClient.java:107-174, 247-298` | tentatives **non persistées** |
| 8 | Validation sémantique + **1** réparation ; mode dégradé si une seule preuve non rattachable | `EvaluationOutputValidator.java:173-217` ; `AiEvaluationService.evaluateValidated` `:333-452` | échec ⇒ `FAILED` + `erreur_message` |
| 9 | Post-traitement (filets ne pouvant qu'abaisser ou purger) : confiance `min(IA, plafond)` ; cohérence d'objectif ; retrait des champs hors contrat ; preuve numéro → texte exact ; labels ; plafonds de listes (2/2/3) ; **couplage** ; bandes ; filtre « marqueur A2 vendu comme levier » ; audit d'accents | `AiEvaluationService.postProcess` `:472-669`, `applyConfiance :850-893`, `applyObjectifCoherence :932-949`, `applyCouplage :1170-1202` | **le couplage réécrit `note_sur_20` en place** : la note brute de l'IA est perdue (log seulement) |
| 10 | **Note** = Σ `note_sur_20 × poids` (poids de la grille, 0,25 ×4), arrondi **1 décimale HALF_UP**, bornée [0;20] ; **écrase** `note_globale` du LLM | `AiEvaluationService.weightedNote :153-199`, `applyServerComputedNote :1437-1451` | tout critère manquant/dupliqué/hors bornes est **bloquant** (aucun repli sur la note LLM) |
| 11 | **Niveau** = moyenne des `source_criteres` (les 4 en v15) → `≥10 B2 · ≥6 B1 · ≥2 A2 · >0 A1 · 0 A1_NON_ATTEINT` ; écrase `feedback_json.niveau_cecrl` ; niveau LLM conservé à part | `AiEvaluationService.applyServerComputedNiveau :1462-1483` → `ProductionBilanService.computeNiveau :525-533`, `niveauFromCompetence :568-576` | seuils lus dans `commun.niveau` de la **grille** (`production-rubrics-v15.json` : `seuil_b2 10, seuil_b1 6, seuil_a2 2`), pas dans le YAML (`application.yaml:711-718` ne sert qu'aux grilles v3-v4.2) |
| 12 | **Plafonds** (après le niveau, ne peuvent qu'abaisser) : T3 avec `communiquer ≤ 1` ⇒ max A2 ; EO T2 avec `communiquer ≤ 1` ⇒ max A2 ; trace `plafond_niveau` | `AiEvaluationService.applyPlafonds :1221-1262` ; seuils `commun.plafonds` de la grille (1 / 1) | — |
| 13 | Persistance `ai_evaluations` (note, niveau, niveau IA, `feedback_json`, versions, tokens, coût) ; soumission `EVALUATED` | `AiEvaluationService.java:299-312` | niveau **figé** ; aucun recalcul rétroactif (sauf V042 pour les `validation-serveur`) |
| 14 | Best-effort hors transaction : quota gratuit, **2ᵉ appel « version au niveau visé »** (réécrit `feedback_json.version_ciblee`, additionne tokens/coût), observation du Plan | `ProductionPipelineAsyncRunner.java:152-169` | échec silencieux, jamais bloquant |
| 15 | Affichage candidat (§C.3) | `ProductionSubmissionMapper.java:86-113` | — |

**Où vivent les seuils et combien de versions du calcul ?**
- Seuils de niveau, couplage (`ecart_max`), plafonds et bandes : **dans le fichier de grille**
  (`commun.niveau`, `commun.couplage`, `commun.plafonds`, `commun.bandes_criteres`), versionné
  v3 → v15 ; repli YAML/POJO pour v3-v4.2 seulement (`ProductionRubricsProvider.java:252-320`).
  Table officielle TCF aussi dans l'enum `BandeNoteTcf` (donnée officielle = code).
- **Plusieurs versions du calcul ont existé** (moyenne de 3 critères de langue avec seuils
  8/12/15 jusqu'à v4.2 ; 4 critères depuis v5 ; échelle TCF depuis v6). **Les niveaux de tâche
  persistés ne sont jamais recalculés.** En revanche, ce qui est **dérivé à la lecture** (bilan
  d'épreuve, `SituationDansNiveau`) relit les `scores_criteres` stockés avec les seuils de la
  grille **active** — une ancienne évaluation peut donc avoir un « palier atteint/confirmé/solide »
  calculé sur une échelle qui n'était pas la sienne.
- Versions en dev : `rubrics_version` NULL sur **112/179** évaluations (`prompt_version` v1.5/v2,
  antérieures à `MIG/V022`) ⇒ pour elles, la règle appliquée **n'est pas traçable** (❓) ; v15
  = 31 lignes.

### C.2 EO (oral) — ce qui diffère de l'EE

| # | Étape | Où |
|---|---|---|
| 1a | **Enregistré** : multipart ; Whisper `whisper-1`, `language=fr`, prompt littéral, `verbose_json`, **synchrone, avant insertion** ; octets effacés dans un `finally` ; échec ⇒ 503, aucune ligne | `ProductionEvaluationService.java:145-171` ; `WhisperTranscriptionClient.java:53-74` ; `AudioEphemere.java:36-43` ; `application.yaml:422-439` |
| 1b | **Temps réel** : Gemini Live joue l'examinateur et transcrit ; à la fin, soumission `REALTIME` + transcription `modele_utilise='realtime'` ; Whisper sauté | `RealtimeSessionService.java:274-335` ; `ProductionEvaluationService.java:249-302` |
| 2 | Indicateur de qualité de transcription (persisté) ⇒ confiance plafonnée `FAIBLE` si dégradée ; temps réel ⇒ confiance ≤ `MOYENNE` | `TranscriptionQualityAudit`, `AiEvaluationService.java:850-893` |
| 3 | Texte **recollé** (tours) envoyé au correcteur ; tours `Examinateur :` non citables ; **la durée n'est jamais envoyée** | `TranscriptionManager.java:40-43`, `EvaluationPromptBuilder.java:61-62` |
| 4 | Garde-fou oral : rejet si un champ évaluatif fonde la note sur prononciation, accent, débit, fluidité, hésitations, orthographe… ; filets `stripOrthographicCorrections` + `EvaluationOralArtifactFilter` (langue étrangère, forme) | `EvaluationOutputValidator.java:553+` ; `AiEvaluationService.java:555-590` |
| 5 | Note / niveau / plafonds : **identiques à l'EE** (étapes 10-13) | — |
| 6 | Version ciblée orale : `reformulations` (jamais de réécriture), non émise si transcription dégradée | `docs/regles/notation-ia.md:43-156` |

⇒ **Il n'existe aucun critère « prononciation »** : il est interdit par construction.

### C.3 Ce que voit le candidat

`GET /api/production-submissions/{id}` → `ProductionSubmissionDto` → `evaluation` :
`EvaluationResultDto {evaluabilite, noteSurVingt, niveauObserve, confiance, avertissementNiveau,
situationDansNiveau, situationDansNiveauLabel, feedback}` (`BE/dto/EvaluationResultDto.java:132`).
- `feedback` = `feedback_json` persisté **moins** `niveau_cecrl` et `justification_niveau`
  (`ProductionSubmissionMapper.java:91-95`) : **version retravaillée par le serveur**, pas le JSON IA.
- `niveauObserve` = `ai_evaluations.niveau_cecrl` **seulement si `confiance` est présente**
  (`:97`), sinon le candidat ne voit **aucun** niveau.
- La note /20 d'une tâche isolée est **servie mais masquée** par les fronts (décision du
  2026-08-08) ; par critère, le candidat voit la **bande** (« Satisfaisant »…), pas le nombre.
- `transcription` = texte recollé (EO).
- Les fronts ne montrent plus `suggestions` / `exemples_corriges` / `version_amelioree`
  (legacy toujours en base).

⇒ L'admin peut obtenir **exactement les données** vues par le candidat en appelant le **même**
`toEvaluationDto` (une autorité). Le **rendu** exact (quels blocs un front affiche) reste propre à
chaque front (❓ §G).

### C.4 Deux traces concrètes (base de dev, anonymisées)

Requêtes (SELECT) : jointures `production_submissions ⋈ production_tasks ⋈ attempts ⋈
ai_evaluations [⋈ transcriptions ⋈ realtime_sessions]` sur les deux ids ci-dessous ; email et
texte du candidat **non reproduits**.

#### Trace EE — soumission `89defd39…` (EE, tâche 2, examen blanc d'épreuve, compte non interne)

| Étape | Valeur réelle |
|---|---|
| Sujet | T2, `niveau_cible` A2, bornes 40-90 mots, titre et contexte présents |
| Production | 67 mots (`mots_count` = recomptage SQL = 67) → dans les bornes |
| Validité pré-LLM | passée (`evaluabilite = EVALUABLE`) |
| Contrat | grille **v15** / tool-schema **v9**, modèle `deepseek-v4-flash` |
| Scores stockés (après couplage) | communiquer **8** · interagir **8** · lexique **7** · morphosyntaxe **7** |
| Couplage | plafond réalisation = moy(lexique, morpho) + `ecart_max` 1 = 7 + 1 = **8** ⇒ communiquer/interagir **exactement au plafond** : on ne peut pas savoir si l'IA avait mis plus (note brute non stockée) |
| Note serveur | 0,25×(8+8+7+7) = **7,5** → `note_sur_20 = 7.5` ✅ |
| Niveau serveur | moyenne des 4 = 7,5 → [6 ; 10[ ⇒ **B1** → `niveau_cecrl = B1` ✅ |
| Plafonds | T2 EE : aucun applicable ; pas de `plafond_niveau` |
| Niveau IA | `niveau_cecrl_ia = B1` (pas d'écart) |
| Bandes | 8 et 7 ∈ [6;10[ ⇒ « SATISFAISANT » ×4 ✅ |
| Confiance | `HAUTE` ⇒ niveau montré au candidat |
| Situation | (7,5 − 6) / (10 − 6) = 0,375 ⇒ tiers médian ⇒ **« B1 confirmé »** |
| Accomplissement | `ATTEINT`, 6 points traités, 0 oublié |
| `justification_niveau` (admin seulement) | explique « pourquoi pas A2 / pourquoi pas B2 » (test décisif B2 non passé) |
| Version ciblée | `niveau_vise B2`, `niveau_constate B1`, 3 leviers, `exemple_cible` |
| Technique | tokens in 34 959 (dont 34 048 en cache) / out 2 006 ; `cout_micro_usd = 928` (≈ 0,000 93 $) ; `nb_retries = 0` ; `retry_count = 0` ; `submitted_at → evaluated_at` ≈ 7 s |

#### Trace EO — soumission `29093b7c…` (EO, tâche 2, **temps réel**, examen blanc d'épreuve)

| Étape | Valeur réelle |
|---|---|
| Session vocale | `realtime_sessions` liée par `(attempt_id, production_task_id)` : provider `gemini`, modèle `gemini-2.5-flash-native-audio`, `COMPLETED`, ~2 min 36 s, 0 reprise |
| Audio | aucun (`media_url` NULL, `texte_soumis` NULL) ; durée `media_duration_sec = 139` |
| Transcription | `modele_utilise = realtime`, `langue_detectee = fr`, 2 295 caractères, `qualite_degradee = false` (taux 0 / 0) ; indicateurs Whisper NULL (normal en temps réel) ; coût NULL |
| Contrat | v15 / v9, `deepseek-v4-flash` |
| Scores stockés | communiquer **9** · interagir **9** · lexique **8** · morphosyntaxe **8** |
| Couplage | plafond = (8+8)/2 + 1 = **9** ⇒ réalisation exactement au plafond (même ambiguïté) |
| Note serveur | 0,25×(9+9+8+8) = **8,5** ✅ |
| Niveau serveur | 8,5 ∈ [6;10[ ⇒ **B1** ✅ |
| Plafond EO T2 « sans échange » | `communiquer = 9 > 1` ⇒ non applicable |
| Niveau IA | B1 (pas d'écart) |
| Confiance | `MOYENNE` (plafond temps réel) + 3 raisons ; avertissement oral unique (« nous analysons la transcription… ») |
| Situation | (8,5 − 6)/4 = 0,625 ⇒ **« B1 confirmé »** |
| Version ciblée | `niveau_vise B2`, `niveau_constate B1`, 3 leviers, `reformulations` |
| Technique | tokens in 36 126 (32 128 en cache) / out 2 073 ; `cout_micro_usd = 1 366` ; `retry_count = 0` ; ≈ 7 s soumission → évaluation |

**Critère d'acceptation n° 6 du brief** : pour ces deux productions, le niveau final se retrouve
à partir des scores affichés **à condition** que l'écran montre les poids (0,25), la règle
d'arrondi (1 décimale) et les seuils de la grille **v15** (2 / 6 / 10) — ce que propose §D.

Échecs observés en dev (pour l'état « Erreur ») : 3 `FAILED`, messages réels du type
« Sortie LLM invalide après une tentative de réparation : preuve[…] doit citer un passage
réel » ou « tool_call.arguments non désérialisable … » — **0 ligne `ai_evaluations`** pour eux.
2 lignes bloquées `SUBMITTED`/`EVALUATING` depuis juillet/août (❓ aucun balayeur connu).

---

## D. Architecture proposée (solution minimale, conventions existantes)

### D.1 Backend (`Controller → Service → Manager → Repository`)

**Contrôleur** `BE/controller/AdminProductionController.java`,
`@RequestMapping("/api/admin/productions")` + `@PreAuthorize("hasRole('ADMIN')")` (défense en
profondeur, comme `AdminAiCostController`). Ultra-fin.

```java
// Liste — style « A » des consoles Utilisateurs/Abonnements
@GetMapping
PageResponse<AdminProductionListItemDto> list(
    @RequestParam(required = false) String q,              // email « contient » | UUID complet = user_id OU submission id
    @RequestParam(required = false) EpreuveType epreuve,   // TCF_EE | TCF_EO
    @RequestParam(required = false) Integer tache,         // 1 | 2 | 3
    @RequestParam(required = false) AdminNiveauFiltre niveau,      // A1_NON_ATTEINT|A1|A2|B1|B2|NON_EVALUABLE|SANS_NIVEAU
    @RequestParam(required = false) AdminStatutIaFiltre statut,    // EN_COURS|EVALUEE|NON_EVALUABLE|ECHEC
    @RequestParam(required = false) AdminSignalementFiltre signalement, // SIGNALEES|VERIFIEES|NON_SIGNALEES
    @RequestParam(required = false) AdminPeriode periode,  // TODAY|LAST_7_DAYS|LAST_30_DAYS (Paris) — exclusif de from/to
    @RequestParam(required = false) String from,           // yyyy-MM-dd Paris, inclus
    @RequestParam(required = false) String to,
    @RequestParam(defaultValue = "false") boolean includeInternal, // ❓ §F-7
    @RequestParam(defaultValue = "DATE_DESC") AdminProductionTri sort, // DATE_DESC|DATE_ASC|NIVEAU_DESC|NIVEAU_ASC|EPREUVE
    @RequestParam(defaultValue = "0") int page,
    @RequestParam(defaultValue = "50") int size);          // borné [1,100] ; défaut : §F-9

@GetMapping("/{submissionId}")
AdminProductionDetailDto detail(@PathVariable UUID submissionId);   // 404 si inconnue / diagnostic hors périmètre

// Lot 3 — signalement
@PostMapping("/{submissionId}/flags")          // 201 ; 409 si un signalement actif existe ; 422 si aucune évaluation
AdminProductionFlagDto flag(@PathVariable UUID submissionId, @Valid @RequestBody AdminProductionFlagRequest body);
@PostMapping("/flags/{flagId}/verify")         // idempotent
AdminProductionFlagDto verify(@PathVariable UUID flagId);
@PostMapping("/flags/{flagId}/remove")         // retrait = soft (removed_at), §F-3
AdminProductionFlagDto remove(@PathVariable UUID flagId);
```

Tri : **toujours** suivi de `id DESC` (stabilité) ; tri niveau par `CASE` ordinal
(`A1_NON_ATTEINT < A1 < A2 < B1 < B2`), lignes sans niveau en dernier. Période : même découpe
Paris que `purchasedMonth` / Suivi ; `from` + `periode` ensemble ⇒ 400.

**DTO (records, admin uniquement — jamais ajoutés à `ProductionSubmissionDto` /
`EvaluationResultDto`, partagés web/mobile, cf. précédent `CalibrationSubmissionDto`)**

```java
record AdminProductionListItemDto(
    UUID id, Instant submittedAt,
    UUID userId, String userEmail, boolean userInternal,
    EpreuveType epreuve, short tache, String contexteLabel /* Entraînement | Examen blanc | Examen complet */,
    SubmissionSource source /* ASYNC | REALTIME */,
    NiveauCecrl niveau /* null = aucun */, String statutIa, String statutIaLabel /* servis */,
    String signalement /* NONE|OPEN|VERIFIED */) {}

record AdminProductionDetailDto(
    AdminProductionContexteDto contexte,       // candidat, email, ids, date, épreuve, tâche, contexte, source, niveau
    AdminProductionSujetDto sujet,             // titre (nullable) + titreAffiche (repli « Sujet N » SERVI), consigne, contexte, bornes
    AdminProductionReponseDto reponse,         // texte | transcription (recollée), motsCount, dureeSec, outilTranscription,
                                               // qualiteTranscription {degradee, tauxFormesSuspectes, tauxCollages},
                                               // audioDisponible=false + audioMotif (servi)
    ProductionSubmissionDto vueCandidat,       // le DTO EXACT du candidat (même mapper)
    AdminEvaluationIaDto evaluationIa,         // null si aucune : critères {code,label,noteSur20,poids,bande,commentaire,preuve},
                                               // niveauIa, justificationNiveau, confiance(+raisons), nbEvaluations
    AdminCalculNiveauDto calcul,               // null si non traçable : rubricsVersion, promptVersion, formule,
                                               // noteSur20 (persistée), seuils {a2,b1,b2}, ecartMaxCouplage,
                                               // niveauAvantPlafond (relu), plafondApplique, niveauPersiste,
                                               // niveauIa, ecartIa (bool), coherent (bool : relecture == persisté)
    AdminProductionTechniqueDto technique,     // modele, provider(null), tokens in/cache/out, coutMicroUsd, coutLegacyCentimes,
                                               // submittedAt, evaluatedAt, delaiSec, retryCount, erreurMessage, transcriptionCoutMicroUsd
    Map<String, Object> feedbackJsonPersiste,  // libellé « JSON persisté (après traitement serveur) », pas « réponse brute »
    AdminProductionFlagDto signalement) {}     // null si aucun actif

record AdminProductionFlagRequest(@NotNull MotifSignalement motif, @Size(max = 1000) String commentaire) {}
record AdminProductionFlagDto(UUID id, MotifSignalement motif, String motifLabel, String commentaire,
    Instant createdAt, String createdByName, Instant verifiedAt, String verifiedByName) {}
```

**Couches**
- `service/admin/AdminProductionService` (`@Transactional(readOnly = true)` — garantit
  l'absence d'écriture en lecture) : orchestre, **n'appelle aucun runner, aucun client LLM,
  aucun service candidat** qui résout le Plan ou le quota.
- `service/admin/AdminProductionFlagService` : création / vérification / retrait, admin courant
  via `CurrentUser`.
- Managers : `ProductionSubmissionManager` (+ `specification/AdminProductionSpecifications` ou
  un `repository/AdminProductionReadRepository` natif pour liste + tri niveau + filtres en **une**
  requête paginée + un comptage, comme `AdminUserReadRepository`), `AiEvaluationManager`,
  `TranscriptionManager`, `ProductionEvaluationFlagManager` (nouveau).
- Mapper pur `mapper/AdminProductionMapper` ; **réutilise** `ProductionSubmissionMapper.toDto`
  pour `vueCandidat` (une seule autorité de « ce que voit le candidat »).
- Calcul expliqué : un lecteur **en lecture seule** des grilles historiques
  (`production-rubrics-<rubrics_version>.json`, déjà dans le classpath, mis en cache), et
  **réutilisation** de `ProductionBilanService.computeNiveau` / `niveauFromCompetence` (même
  autorité que le candidat). Rien n'est réécrit en base ; un écart relecture ⇄ persisté est
  **affiché**, jamais corrigé (§F-5).
- Coût d'une page **figé** et verrouillé par égalité dans l'IT (convention).

**Tests (backend uniquement, `*IT` Zonky)** : ligne(s) dans `AdminRoutesSecurityIT.adminRoutes()`
(401/403/200) ; `AdminProductionControllerIT` : tri par défaut + stabilité, chaque filtre et leur
combinaison, recherche email/UUID, pagination + bornes de `size`, NON_EVALUABLE ≠ A1, FAILED sans
évaluation, absence d'écriture en lecture (comptage de lignes / `updated_at` inchangé), égalité du
nombre de requêtes par page ; flags : création, 409 doublon, vérifier, retirer, effet nul sur
`ai_evaluations`.

### D.2 Front admin (`FE/features/productions/`)

- Routes `App.tsx` : `/productions`, `/productions/:id` ; entrée `navigation.ts` (section §F-8),
  icône du jeu `Icon.tsx` (SVG ajouté si besoin), `detailLabel: "Production"`.
- `ProductionsPage.tsx` (+ `.module.css`) : `PageHeader`, recherche + filtres (selects ou
  `Chips`), tableau `DataTable.module.css` (`tableWrap` + `cardTable`, `data-label`),
  `Pagination` partagé ; état via `useUrlListState` dans `useProductionListParams.ts`.
- `ProductionDetailPage.tsx` : blocs dans l'ordre du brief ; `components/` : `FlagBanner`,
  `FlagModal` (sur `Modal`), `CalculBlock`, `TechBlock`, `RawJsonBlock`.
- **Réutilisation** de `ProductionView` et `EvaluationReport` (2ᵉ usage ⇒ les remonter hors de
  `calibration/`, cf. hygiène « à la 2ᵉ duplication ») ; nouvelle primitive
  `components/ui/Collapsible.tsx` (aucune n'existe).
- `api/productionsApi.ts` ; types miroirs dans `FE/types/api.ts` ; clés
  `["adminProductions","list",filters]`, `["adminProductions","detail",id]` ; une mutation de
  signalement invalide `["adminProductions"]`.
- Le front **n'affiche que des valeurs servies** : libellés de statut, contexte, titre de repli,
  formule, seuils, écart IA ⇄ SejourFR — aucun recalcul.
- Vérification : `npx tsc --noEmit` + build ; **aucun test front**.

### D.3 Solution minimale

Lot 1 = 2 endpoints de lecture sur la famille 1 (hors diagnostic), aucune migration ; Lot 2 =
écrans ; Lot 3 = une table de signalement + 3 endpoints. Toutes les données absentes s'affichent
« Non disponible » avec, quand il existe, le **motif** (« audio non conservé — décision de
consentement », « grille antérieure à la traçabilité des versions »).

---

## E. Migrations proposées (texte seulement — **non créées**)

Numérotation : dernier schéma = `MIG/V084__sessions_eo_acces_admin.sql` ; `V879` est un DDL
numéroté hors plage (`docs/migrations-flyway.md:166-171`) ; `spring.flyway.out-of-order: true`
(`application.yaml:28`) ⇒ **prochain numéro de schéma : `V085`** (`docs/migrations-flyway.md:251`).

### E.1 `V085__schema_signalements_evaluations.sql` (option recommandée, §F-3 A)

```sql
CREATE TABLE ai_evaluation_flags (
    id               UUID          PRIMARY KEY,
    evaluation_id    UUID          NOT NULL REFERENCES ai_evaluations (id) ON DELETE CASCADE,
    submission_id    UUID          NOT NULL REFERENCES production_submissions (id) ON DELETE CASCADE,
    motif            VARCHAR(32)   NOT NULL
        CONSTRAINT ck_ai_evaluation_flags_motif
            CHECK (motif IN ('NIVEAU_INCOHERENT', 'SCORE_INCOHERENT', 'FEEDBACK_INCORRECT',
                             'REPONSE_MAL_COMPRISE', 'TRANSCRIPTION', 'AUTRE')),
    commentaire      VARCHAR(1000) NULL,
    created_by       UUID          NOT NULL REFERENCES users (id),
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    verified_by      UUID          NULL REFERENCES users (id),
    verified_at      TIMESTAMPTZ   NULL,
    removed_by       UUID          NULL REFERENCES users (id),
    removed_at       TIMESTAMPTZ   NULL,
    CONSTRAINT ck_ai_evaluation_flags_verification
        CHECK ((verified_at IS NULL) = (verified_by IS NULL)),
    CONSTRAINT ck_ai_evaluation_flags_retrait
        CHECK ((removed_at IS NULL) = (removed_by IS NULL))
);

-- Au plus UN signalement vivant par évaluation ; un retrait libère la place.
CREATE UNIQUE INDEX uq_ai_evaluation_flags_actif
    ON ai_evaluation_flags (evaluation_id) WHERE removed_at IS NULL;

-- Filtre « Signalement » de la liste (jointure par soumission).
CREATE INDEX idx_ai_evaluation_flags_submission_actif
    ON ai_evaluation_flags (submission_id) WHERE removed_at IS NULL;

COMMENT ON TABLE ai_evaluation_flags IS
    'Signalements admin d''une évaluation IA. N''altère JAMAIS ai_evaluations : ni note, ni niveau, ni feedback.';
```

Notes : `submission_id` est dénormalisé pour le filtre de liste (l'évaluation affichée est la
dernière ; un signalement suit l'**évaluation** jugée). États servis : `OPEN` (ni vérifié ni
retiré), `VERIFIED`, retiré = absent. Les FK `users` sans cascade suivent `MIG/V083`
(`admin_access_operations.admin_user_id`). Rejeu de test : un `*IT` vérifie contraintes et index
partiel sur Postgres embarqué.

**Options écartées** : (B) colonnes `flag_*` sur `ai_evaluations` — fait muter la ligne de
résultat que le signalement ne doit jamais toucher, perd l'historique, et la ligne est déjà
réécrite par la version ciblée ; (C) journal d'événements append-only + état dérivé — plus pur,
mais trois transitions seulement : les colonnes `*_by/*_at` portent déjà la trace (§F-3).

### E.2 Optionnelles (seulement si §F-4 l'accepte — écrites **à l'avenir**, historique NULL)

```sql
-- V086__ai_evaluations_trace_technique.sql (additive)
ALTER TABLE ai_evaluations
    ADD COLUMN provider            VARCHAR(16) NULL,   -- valeur de sejourfr.production-evaluation.provider à l'appel
    ADD COLUMN sortie_llm_json     JSONB       NULL,   -- arguments du tool-call ACCEPTÉ, avant post-traitement
    ADD COLUMN ajustements_serveur JSONB       NULL;   -- ex. [{"type":"COUPLAGE","critere":"communiquer","avant":10,"apres":8.0}]
```

```sql
-- V087__idx_production_submissions_liste_admin.sql (seulement si le volume prod le justifie — ❓ §G)
CREATE INDEX idx_prod_sub_submitted_at ON production_submissions (submitted_at DESC, id DESC);
```

⚠️ Ne **jamais** écrire `ajustements_serveur` ni `sortie_llm_json` dans `feedback_json` : ce
dernier est servi tel quel (moins 2 clés) aux fronts candidats.

---

## F. Décisions à valider

**F-1 — Articulation avec la console Calibration existante.**
- A. Nouvel écran « Productions IA » **à côté** de Calibration, qui reste inchangée.
- B. « Productions IA » devient **la** liste et la fiche des productions ; Calibration garde
  son bandeau de santé et son formulaire d'annotation, qui s'ouvre depuis la fiche Productions IA ;
  la liste plate de Calibration (sans pagination ni filtre) est **supprimée** dans la foulée.
- C. Étendre Calibration (pagination, filtres, signalement) au lieu de créer un écran.
- **Recommandation : B** — la règle « refonte = suppression immédiate de l'ancien » et le brief
  (« pas d'architecture parallèle ») excluent A ; C mélange deux questions (justesse statistique
  vs contrôle unitaire). B réutilise `EvaluationReport`/`ProductionView` et l'endpoint
  `human-note`.

**F-2 — Familles de productions dans l'écran.**
- A. Famille 1 seulement (productions TCF complètes, EO temps réel compris), hors diagnostic.
- B. A + diagnostic (`diagnostic_production_analyses`, contrat sans note /20).
- C. A + B + Compétences (`user_skill_attempts`, niveau rendu par le LLM, pas de critères).
- **Recommandation : A** pour le MVP : c'est la seule famille où la question du brief
  (« pourquoi B1 et pas A2/B2 ») a une réponse calculée. B et C exigent des blocs « Calcul »
  différents ; à ouvrir ensuite avec un filtre « Famille ».

**F-3 — Modèle du signalement.** (cf. §E.1)
- A. Table dédiée, état en colonnes, retrait **soft** (`removed_at`).
- B. Colonnes sur `ai_evaluations`.
- C. Journal append-only + état dérivé.
- **Recommandation : A.** Question annexe : un NON_EVALUABLE (verdict serveur sans IA) est-il
  signalable ? Recommandé **oui** (motif « Autre » / « Réponse mal comprise »).

**F-4 — « Scores bruts » et « JSON brut » qui n'existent pas en base.**
- A. MVP honnête : afficher les **scores retenus** (« après garde-fous serveur ») et le
  `feedback_json` libellé « JSON persisté (après traitement serveur) » ; signaler quand un critère
  de réalisation est **exactement** au plafond de couplage (« possiblement ramené », sans
  l'affirmer).
- B. A + persister **à l'avenir** la sortie acceptée du LLM, le provider et les ajustements
  serveur (§E.2) ; l'historique reste « non disponible ».
- C. Ne rien afficher de « brut ».
- **Recommandation : A pour le MVP, B en lot séparé** si le propriétaire veut pouvoir trancher
  les écarts IA ⇄ SejourFR à l'avenir (coût : stockage ~5-10 Ko/ligne, aucun appel LLM).

**F-5 — Bloc « Calcul SejourFR » sur les évaluations qui ne sont pas en grille v15.**
- A. Relire la grille **de l'évaluation** (`rubrics_version`, fichiers déjà livrés) pour poids,
  seuils, couplage ; si `rubrics_version` est NULL : « règle non traçable », niveau persisté seul.
- B. Afficher les seuils de la grille **active** pour tout le monde.
- C. N'afficher le calcul que pour la grille active.
- **Recommandation : A** (B mentirait sur 148 évaluations sur 179 en dev ; C masque l'historique).
  Le niveau affiché reste **toujours** `ai_evaluations.niveau_cecrl` ; la relecture n'est qu'une
  vérification servie (`coherent`).

**F-6 — Statuts IA servis.**
- A. Quatre états : En cours (`SUBMITTED/TRANSCRIBING/EVALUATING`) · Évaluée · **Non évaluable**
  (`EVALUATED` + `NON_EVALUABLE`) · Échec (`FAILED`).
- B. Les trois du brief, NON_EVALUABLE rangé en « Succès ».
- **Recommandation : A** (un NON_EVALUABLE n'a ni note ni niveau : le ranger en « Succès » ferait
  lire une absence comme un résultat). Bonus servi : « en cours depuis > N h » pour les lignes
  bloquées (❓ seuil).

**F-7 — Comptes internes.**
- A. Exclus par défaut, filtre `includeInternal` (convention du Suivi).
- B. Inclus par défaut, filtre « exclure ».
- **Recommandation : A** si la convention Suivi est bien « exclus par défaut » (❓ à vérifier) ;
  sinon aligner sur elle.

**F-8 — Place dans la navigation.**
- A. « Pilotage » (maquette).
- B. « Génération IA », à côté de « Calibration notation » et « Coût de l'IA ».
- **Recommandation : B** si F-1 = B (les écrans IA restent groupés) ; A sinon.

**F-9 — Taille de page par défaut.**
- A. 50 (brief) — `useUrlListState` doit alors accepter un défaut par écran.
- B. 25 (convention actuelle `DEFAULT_PAGE_SIZE`).
- **Recommandation : A**, en paramétrant le hook (aucune nouvelle config JSON : c'est un réglage
  d'écran, comme partout ailleurs).

**F-10 — Libellé du niveau.**
- A. « Niveau observé (tâche) », avec la mention « le niveau qui fait foi pour le candidat est
  celui de l'épreuve » et l'indication « non montré au candidat » quand `confiance` est absente.
- B. « Niveau final » (brief).
- **Recommandation : A** — un entraînement ne décide jamais du niveau du candidat
  (`docs/notation-ia-eo-ee.md` §8 nonies) ; « final » induirait l'admin en erreur.

---

## G. Inconnues

1. **Volume de production** (nombre de productions/jour) : rien mesuré hors dev (219 soumissions) ;
   conditionne l'index §E.2 et le coût des filtres `LIKE` sur l'email.
2. **Règle appliquée aux 112 évaluations sans `rubrics_version`** (`prompt_version` v1.5/v2) :
   non traçable en base ; seuils de l'époque non stockés.
3. **Note brute de l'IA avant couplage** et **`note_globale` du LLM** : perdues (logs seulement ;
   rétention et accès aux logs de prod ❓).
4. **Tentatives LLM réelles** (`@Retryable` ×3 + réparation) et **coût des appels en échec** :
   non persistés.
5. **Rendu exact côté candidat** : quels champs de `feedback` chaque front affiche
   (`web_sejoufr/app/_components/production/ProductionFeedbackView.tsx`, écran mobile équivalent) —
   non audité bloc par bloc ; l'admin montrera les **données** servies, pas une copie du rendu.
6. **Sémantique du contexte de passation** (`slot_number`, `parent_attempt_id`, `type`, `mode`)
   pour libeller Entraînement / Examen blanc / Examen complet — à confirmer dans
   `docs/regles/examens-temps.md` / `freemium.md` avant de servir le libellé.
7. **Unicité du lien session temps réel ⇄ soumission** `(attempt_id, production_task_id)` : une
   même tâche rejouée dans un même attempt donnerait plusieurs sessions ❓.
8. **Durée du 2ᵉ appel « version ciblée »** : aucun horodatage ne la mesure (`evaluated_at` est
   posé avant lui) ; son coût est fusionné dans la ligne d'évaluation.
9. **Lignes bloquées `SUBMITTED`/`EVALUATING`** (2 en dev depuis l'été) : existe-t-il un balayeur ?
10. **Convention `includeInternal` du Suivi** (défaut) — à relire dans
    `FE/features/suivi/useSuiviParams.ts`.
11. **Écarts de configuration relevés en passant** (hors périmètre, à signaler) : défauts POJO ≠
    YAML (`ProductionEvaluationProperties.java:31` `rubricsVersion="v1"` vs `v15` ;
    `:726` `seuilA2=7.0` vs YAML `8.0`) ; `max-retries`, `retry-backoff-ms`,
    `cost-tracking-enabled` déclarés mais jamais lus ; `nb_retries` jamais écrite.

---

## Maquette v3 — écart maquette ⇄ données réelles ⇄ brief

La maquette (`sejourfr-admin-productions-ia-v3.html`) porte elle-même la mention « critères,
barèmes, règle de calcul et données techniques à remplacer par ceux de l'audit ». Design repris,
données branchées sur le backend réel.

| Élément de la maquette | Alimentable ? | Écart / correction |
|---|---|---|
| Sidebar (Suivi, Productions IA, Utilisateurs, Contenu…, Génération IA) | — | Liste **partielle** du menu réel (manquent Audit générations, Audios exemples EO, Calibration notation, Coût de l'IA, Notions civiques, Commerce, Échanges) ; seule l'entrée nouvelle compte (§F-8) |
| Police Plus Jakarta Sans | ❌ | L'admin est en **Inter** (+ JetBrains Mono pour les ids) — `CLAUDE.md` racine et `admin_sejourfr/CLAUDE.md` |
| Couleurs en variables locales (`--amber`, `--green`…) | ❓ | Utiliser les tokens de `FE/styles/global.css` ; teinte manquante ⇒ nouveau token, jamais un hex local |
| Compteur « 1 284 productions », pager « 1–50 sur 1 284 » | ✅ | `totalElements` du `PageResponse` ; composant `Pagination` existant |
| Recherche « Email, ID utilisateur ou ID production » | ✅ | email « contient », UUID **complet** ; la maquette montre des ids à 8 caractères (affichage seul) |
| Filtre Épreuve / Tâche | ✅ | `production_tasks.epreuve` / `tache_numero` |
| Filtre Niveau A1…B2 | ✅ | ajouter **A1 non atteint**, **Non évaluable**, **Sans niveau** (`null` ≠ A1) |
| Filtre Statut IA Succès/Erreur/En cours | ❓ | 4 états (§F-6) |
| Filtre Signalement | ✅ (après E.1) | ajouter « Vérifiées » |
| Période Aujourd'hui / 7 j / 30 j / personnalisée | ✅ | Paris, comme Suivi |
| Tri Plus récentes / anciennes / Niveau / Épreuve | ✅ | + `id DESC` pour la stabilité |
| Colonnes Date · Candidat (email + id) · Épreuve · Tâche · Niveau · Statut · Signalement | ✅ | suggérées en plus : **Mode** (enregistré / temps réel) et **Contexte** (entraînement / examen) |
| Hero : tags, titre, id, niveau rond, email, uid, date, épreuve, tâche | ✅ | libellé « Niveau observé (tâche) » (§F-10) ; « non montré au candidat » si pas de confiance |
| Bloc Sujet (titre, consigne, contexte) | ✅ | titre nullable ⇒ repli servi ; la fiche examinateur EO T2 n'est **pas** « reçue par le candidat » |
| Réponse EE + « N mots » | ✅ | `texte_soumis` + `mots_count` |
| **Lecteur audio** + durée « 02:41 » | ❌ / ✅ | **pas de lecteur** : « Audio non conservé (décision de consentement) » ; la **durée** est disponible |
| « Transcription automatique » | ✅ | + outil (Whisper / temps réel), indicateur de qualité ; en temps réel le texte contient les tours **Examinateur :** |
| Scores « x / 4 » avec pastilles | ❌ | échelle réelle **/20** par critère (pastilles ×20 illisibles ⇒ « 8 / 20 » + bande + poids 25 %) |
| Critères EE « Réalisation de la tâche, Cohérence, Lexique, Grammaire » | ❌ | réels (v5+) : **communiquer, interagir, lexique, morphosyntaxe**, libellés servis (`scores_criteres[].label`) ; codes différents en grilles ≤ v4.2 |
| Critère EO « **Prononciation** » | ❌ **interdit** | n'existe pas et ne peut pas exister (garde-fou oral) — à retirer |
| Calcul « Score 71 / 100 · B1 : 60–79 » | ❌ | réel : « Note 7,5 / 20 = 0,25 × (8+8+7+7) · B1 = [6 ; 10[ · grille v15 », + couplage et plafonds |
| « Niveau renvoyé par l'IA » + bandeau d'écart | ✅ | `niveau_cecrl_ia` ; seule la **note** IA est perdue |
| Feedback : résumé / points forts / à améliorer | ✅ partiel | pas de champ « résumé » : `accomplissement.objectif` + `objectif_resume` ; à améliorer = `{constat, comment, exemple}` ; manquent dans la maquette : confiance + raisons, avertissements, version ciblée, justification (admin seulement) |
| Infos techniques : Provider | ❌ | « Non disponible » (§F-4 B pour l'avenir) |
| Modèle | ✅ | `modele_utilise` |
| Version du prompt « ee-eval-v3 » | ✅ | **deux** versions : grille (`v15`) + tool-schema (`v9`) |
| Tokens entrée / sortie | ✅ | + cache ; **cumul** correction + version ciblée |
| Coût « 0,011 € » | ❌ unité | coût en **USD** (micro-dollars) ; legacy en centimes d'€ affiché à part, jamais additionné |
| Durée « 4,2 s » | ❓ | seulement « délai soumission → évaluation » |
| Tentatives « 3 » | ❓ | seulement les relances manuelles (`retry_count`) |
| Erreur « Timeout après 30 s (3 tentatives) » | ✅ forme | message réel de `erreur_message` ; tokens/coût de l'appel raté **non disponibles** |
| JSON brut | ❌ / ✅ | ce qui existe est le JSON **persisté après traitement** : le libeller ainsi |
| Bandeau de signalement, modale (6 motifs, commentaire), Marquer vérifiée, Retirer | ✅ (après E.1) | conforme au brief ; nom de l'admin = `users.first_name/last_name` |
| Bouton « Signaler » seulement si évaluation | ✅ | à étendre au NON_EVALUABLE (§F-3) |
| Repliables `<details>` | ❓ | aucune primitive : créer `Collapsible` |
| Breadcrumb « Admin / Productions IA / id » | ✅ | `navEntryFor` + `detailLabel` |

---

## Conflits brief ⇄ invariants du dépôt

| # | Le brief / la maquette demande | L'invariant du dépôt | Résolution proposée |
|---|---|---|---|
| 1 | Lecteur audio, « audio servi par URL signée courte durée » (§3.3, §3.6) | 🛑 **Aucun audio de candidat n'est conservé** (décision propriétaire, consentement) ; plus aucun code ne relit un audio ; jamais de réintroduction (`docs/regles/audio-productions.md`) | **« Audio non conservé »** + durée + transcription. Les 46 `media_url` historiques restent intouchées et **non lues**. Ne jamais recommander de stockage |
| 2 | « Config externalisée : tarifs par token, seuils, taille de page dans un JSON versionné » | Tarifs = YAML/env (« changer de LLM ne touche aucun `.java` ni `.yaml` », bascule par `.env`) ; seuils = **grille versionnée** + `BandeNoteTcf` (donnée officielle = code) ; coût **persisté à l'appel** par `CoutAppelLlm` ; « une règle = une autorité » | **Aucune nouvelle config** : l'écran **lit** coûts et seuils persistés/versionnés. Un JSON de tarifs créerait une 2ᵉ autorité (le défaut qui a produit 11 copies de `estimateCostCents`) |
| 3 | « Scores bruts par critère », « JSON brut » (§3.3 blocs 4 et 8) | Le JSON persisté est **post-traité** ; le couplage réécrit les notes en place | Afficher « scores retenus » et « JSON persisté » ; option §F-4 B pour l'avenir |
| 4 | « Niveau final » | Le niveau qui fait foi pour le candidat est celui de l'**épreuve** ; un entraînement ne décide jamais de son niveau ; pas de niveau montré sans confiance | Libellé « Niveau observé (tâche) » (§F-10) |
| 5 | « Calcul SejourFR » (§3.3 bloc 5), « valeurs fournies par le backend » | Dérivé serveur jamais recalculé par un front ; une règle = une autorité | Le backend sert formule, poids, seuils **de la grille de l'évaluation** via `ProductionBilanService.computeNiveau` ; le niveau affiché = `ai_evaluations.niveau_cecrl` (même source que le candidat) |
| 6 | Statut IA « succès / erreur / en cours » | `null` = inconnu, jamais mauvais ; NON_EVALUABLE n'a aucun critère (pas des zéros) | 4 états servis (§F-6) ; « — » pour l'absence, jamais A1 |
| 7 | Lecture passive (« ouvrir ne déclenche aucun appel IA ni écriture ») | Les services candidats peuvent résoudre le Plan, le quota, etc. ; la création d'un cycle de parcours a lieu « à la première lecture » ailleurs | Service admin **dédié**, `@Transactional(readOnly = true)`, n'appelle que des managers + les mappers purs ; testé |
| 8 | « Afficher exactement ce que le candidat a vu » | DTO partagés `ProductionSubmissionDto` / `EvaluationResultDto` à **ne pas** étendre pour l'admin (précédent Calibration) ; parité des 3 fronts | Réutiliser le **mapper** candidat tel quel dans un DTO **admin** ; **aucun DTO partagé ne change** ⇒ aucun impact web/mobile |
| 9 | Tests « droits, filtres, tri, pagination » (§4) | 🛑 Aucun **nouveau** test front ; backend : tests dans la même passe | Tests **backend uniquement** : `AdminRoutesSecurityIT` + `*IT` Zonky ; front vérifié par `tsc --noEmit` + build |
| 10 | « Pas d'architecture parallèle » / « réutiliser l'existant » | « Refonte = suppression immédiate de l'ancien » ; duplication = signal | Décision §F-1 (recommandé : Productions IA absorbe la liste Calibration, composants remontés et partagés) |
| 11 | Provider, durée, tentatives, coût en € (maquette) | Rien d'inventé ; coût en micro-USD ; legacy centimes jamais additionné | « Non disponible » + unités réelles ; options §E.2 |
| 12 | Pagination défaut 50 | Convention `DEFAULT_PAGE_SIZE = 25` | §F-9 |
| 13 | Police / couleurs de la maquette | Admin en Inter, tokens `global.css`, jamais de couleur en dur | Design repris, tokens existants |
| 14 | Livrable dans `docs/diagnostic/` | Demande du propriétaire | Ce répertoire-ci |
| 15 | Mesurer / vérifier la notation | 🛑 Aucun appel LLM payant, aucun banc sans demande explicite | Rien n'a été appelé ; les traces sont des `SELECT` |
| 16 | Backend | `Controller → Service → Manager → Repository` strict ; mappers purs | Respecté par §D.1 |

**Sécurité & données personnelles (brief §2.4)** : rôle ADMIN vérifié côté backend sur tout
`/api/admin/**` (`SecurityConfig.java:101`) + `@PreAuthorize` recommandé sur le nouveau
contrôleur ; 401/403 couverts par la matrice `AdminRoutesSecurityIT`. Aucun accès audio
(inexistant). Données sensibles exposées à l'admin : email, texte et transcription du candidat
(contenu personnel), modèle et coût ; **rien de nouveau** n'est exposé aux endpoints candidats
(DTO admin distincts, routes sous `/api/admin`). Pas d'export (hors MVP du brief). Aucun email ni
texte de candidat ne doit apparaître dans les logs des nouveaux services.
