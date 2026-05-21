# SejourFR — Guide racine pour Claude Code

Monorepo (4 dossiers indépendants, pas de workspace npm/Maven parent) de **SejourFR**, plateforme
d'entraînement aux examens **civique** (CSP, CR, naturalisation) et **TCF IRN** (A2/B1/B2), obligatoires
depuis le **1ᵉʳ janvier 2026**.

> Avant de coder sur un sous-projet, **toujours lire son `CLAUDE.md` local** : les conventions précises (state
> management, styling, runner, etc.) y vivent. Ce fichier-ci est un index transverse, pas un substitut.

## Les 4 sous-projets

| Dossier                                              | Stack                                                                       | Rôle                                                                            | Port dev    | Guide       |
|------------------------------------------------------|-----------------------------------------------------------------------------|---------------------------------------------------------------------------------|-------------|-------------|
| `backend_sejourfr/`                                  | Spring Boot 4 / Java 21 / PostgreSQL / Flyway / JWT                         | API REST unique pour les 3 fronts                                               | 8080        | `README.md` |
| `admin_sejourfr/`                                    | React 19 + Vite + TS strict + TanStack Query + React Router 7 + CSS Modules | Console admin (questions, thèmes, conversations, médias)                        | 5173 (Vite) | `CLAUDE.md` |
| `web_sejoufr/` ⚠️ (typo : *sejoufr*, pas *sejourfr*) | Next.js 16 App Router + React 19 + Tailwind v4 (tokens seuls)               | Vitrine + parcours utilisateur + paiement Stripe + 1 examen blanc / 10 QCM démo | 3000        | `CLAUDE.md` |
| `mobile_sejourfr/`                                   | Flutter 3.6+ / Dart 3.6+ / Riverpod 2 + Dio + go_router                     | App d'entraînement quotidien (cœur produit)                                     | —           | `CLAUDE.md` |

**Stratégie business** : le web pousse à l'abonnement (paiement Stripe **hors stores** pour éviter la
commission Apple/Google), puis l'utilisateur s'entraîne principalement sur le mobile. Le web permet aussi 1
examen blanc + 10 QCM d'entraînement par module pour convertir.

## Domaine métier (vocabulaire commun)

- **Module** : `CIVIQUE` ou `TCF`
- **TargetProcedure** (civique) : `CSP` (titre de séjour) / `CR` (résident) / `NAT` (naturalisation)
- **TargetLevel** (TCF) : `A2` / `B1` / `B2`
- **AttemptType** : `TRAINING` (correction immédiate après chaque réponse) / `MOCK_EXAM` (examen blanc, pas de
  correction live, chrono) / `REVIEW`
- **Epreuve** (granularité fine de l'attempt, orthogonale à `mode`/`module`) : `CIVIQUE` / `TCF_CO` /
  `TCF_CE` / `TCF_STRUCTURE` / `TCF_EO` / `TCF_EE` / `TCF_COMPLET`. `TCF_COMPLET` est un conteneur d'examen
  blanc TCF complet ; les sous-attempts sont liés via `attempts.parent_attempt_id`.
- **QuestionType** : `KNOWLEDGE` / `SITUATION`
- **Difficulty** : `EASY` / `MEDIUM` / `HARD`
- **MediaType** : `AUDIO` / `IMAGE` / `VIDEO` (TCF compréhension orale → audio surtout)
- **NiveauCecrl** (évaluation IA EO/EE) : `A1_NON_ATTEINT` / `A1` / `A2` / `B1` / `B2` / `C1` / `C2`. Distinct
  de `TargetLevel` qui est le palier visé par l'utilisateur.
- **SubmissionStatut** (EO/EE) : `SUBMITTED` → `TRANSCRIBING` (EO) → `EVALUATING` → `EVALUATED` | `FAILED`.
- **Role** : `USER` / `ADMIN`

Le backend est la **source de vérité** des DTOs. Les 3 fronts maintiennent leurs miroirs **à la main** :

- `admin_sejourfr/src/types/api.ts`
- `web_sejoufr/lib/types.ts`
- `mobile_sejourfr/lib/core/models/*.dart`

→ Quand un DTO Java change, mettre à jour les 3.

## Identité visuelle commune

Strictement identique sur les 4 surfaces (les écarts sont des **bugs**).

**Couleurs**

- Bleu France `#1E3A8C` (dark `#15296B`, light `#E8ECF8`, soft `#F4F6FC`)
- Rouge France `#E1372F` (dark `#B5251E`, light `#FDECEB`) — réservé aux CTAs critiques + signaux d'urgence
- Ink `#0F1839` / Ink-2 `#1F2950`
- Muted `#6B7299` / `#9CA2BD`
- Vert succès `#168F5B` · Ambre `#E8A317`
- Lignes `#E4E7F2` / `#EEF0F8` · Papier `#FAFAF7` / `#F2F1EC`

⚠️ Note : le web utilise `#1E3A8C`, l'admin documente `#1E3A8F` dans son CLAUDE.md — vérifier le code source
en cas de doute (le code fait foi).

**Typographies**

- **Plus Jakarta Sans** (web/mobile) ou **Inter** (admin) — corps, UI, boutons
- **Fraunces** — titres éditoriaux ; les `<em>` dans les titres sont **toujours rouges**
- **JetBrains Mono** — eyebrows, labels techniques, badges, valeurs numériques

**Logo** : Cocarde (3 cercles concentriques bleu/blanc/rouge) + Wordmark (`Sejour` bleu, `FR` rouge) + Tagline
`EXAMEN CIVIQUE · TCF`.

**Règle absolue** : ne jamais hardcoder une couleur ou une font. Toujours passer par les tokens locaux (
`var(--color-*)`, `AppColors.*`, `AppFonts.*`).

## API backend partagée

Base : `http://localhost:8080`. CORS dev autorise `localhost:3000` (web Next.js) et `localhost:5173` (admin
Vite). Auth JWT Bearer (access ~60 min + refresh 30 j) — **refresh automatique** dans le client HTTP de chaque
front.

Endpoints clés :

- `POST /api/auth/{login,register,refresh,forgot-password,reset-password}` · `GET /api/auth/me`
- `GET /api/themes?module=CIVIQUE|TCF`
- `GET /api/lots?module=TCF&questionType=CO|CE&difficulty=A2|B1|B2` (lots d'entraînement TCF, cf. § Lots
  ci-dessous)
- `POST /api/attempts` · `POST /api/attempts/production` (attempt vide pour EO/EE) ·
  `GET /api/attempts/{id}` · `POST /api/attempts/{id}/answers` · `POST /api/attempts/{id}/finish`
- `GET /api/me/{questions/favorites,questions/wrong,stats}?module=...` ·
  `POST|DELETE /api/me/questions/{id}/favorite`
- **EO/EE TCF** : `GET /api/production-tasks?epreuve=TCF_EO&niveau=B1[&tacheNumero=1|2|3]` ·
  `GET /api/production-tasks/{id}` · `POST /api/production-submissions` (multipart audio **ou** JSON texte
  selon `Content-Type`) · `POST /api/production-submissions/{id}/retry` ·
  `GET /api/production-submissions/{id}` · `GET /api/users/me/production-submissions?epreuve=...` ·
  `GET /api/users/me/production-submissions/last-per-task?epreuve=...&niveau=...` (sert au hub mobile :
  dernière submission de l'utilisateur par numéro de tâche, 0 à 3 lignes)
- Admin :
  `/api/admin/{dashboard,questions,themes,conversations,media,passages,audio-questions,calibration/{submissions,stats}}`
- **À implémenter** : `POST /api/billing/create-checkout-session` (Stripe)

## Démarrage local (rappels)

```bash
# Backend (depuis backend_sejourfr/)
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
# DB attendue : Postgres local, db = sejourfr_nouveau, user = diallomatine (cf. application-dev.yaml)
# Mail : MailHog sur localhost:1025 (UI http://localhost:8025)

# Admin (depuis admin_sejourfr/)
npm install && npm run dev

# Web (depuis web_sejoufr/)
npm install && npm run dev-web   # ⚠️ script "dev-web", pas "dev"

# Mobile (depuis mobile_sejourfr/)
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8080   # iOS sim
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080    # Android emu
```

## Comptes seed (profil dev uniquement)

| Email                    | Mot de passe | Rôle  |
|--------------------------|--------------|-------|
| `admin@sejourfr.fr`      | `Admin123!`  | ADMIN |
| `user@sejourfr.fr`       | `User123!`   | USER  |
| `karim.test@sejourfr.fr` | `User123!`   | USER  |

## Migrations Flyway — organisation et convention de numérotation

Flyway scanne récursivement `classpath:db/migration` (prod & dev) et `classpath:db/migration-dev` (dev
uniquement). L'arborescence est organisée par **plages numériques** et par **dossiers thématiques** :

```
db/migration/
├── 00_schema/                       V0xx        évolutions de schéma (step 10 : place pour hotfix entre 2 features)
├── 10_reference/                    V1xx        données de référence (thèmes, plans, exam templates)
├── 20_civique/                      V2xx        seeds civique
│   ├── 00_initial/                  V20x        seed des thèmes (V200 principes, V201 thèmes 2-5)
│   ├── 10_institutions/             V21x        (V210-V216 = reformulations lot01-04 + niveau CSP/CR/NAT)
│   ├── 20_droits_devoirs/           V22x
│   ├── 30_histoire_geo/             V23x
│   └── 40_societe/                  V24x
└── 30_tcf/                          V3xx        seeds TCF
    ├── 00_lots_mixtes/              V30x        CE + STRUCTURE dans le même fichier
    ├── 10_ce/                       V31x        CE focalisée par niveau (V310 A2, V311 B1, V312 B2)
    ├── 20_structure/                V32x        STRUCTURE focalisée
    └── 30_echantillons/             V33x        échantillons de validation de méthode

db/migration-dev/                    V9xx        seeds dev uniquement (V900 comptes seed, attempts factices)
```

**Convention** : le numéro de version du fichier reflète son emplacement dans l'arbre.

- `00_schema/Vxxx` : 1er chiffre = 0 (catégorie schéma). Espacement step 10 (V001, V010, V020...) pour pouvoir
  intercaler. **DDL pur** (CREATE/ALTER), pas d'INSERT qui dépend de données seedées plus tard.
- `10_reference/V1xx` : seeds de référence (thèmes, plans, exam templates). Toute donnée fixe partagée
  prod/dev.
- `20_civique/10_institutions/V21x` : 1er chiffre 2 = civique, 2e chiffre 1 = institutions. Files V210..V219 (
  10 slots par sous-thème).
- Idem TCF.

**Pour ajouter une migration :**

- Nouvelle évolution de schéma → `00_schema/`, prochain V0x0 libre.
- Nouveau seed civique → sous-dossier du thème, prochain numéro libre dans le namespace (10 slots).
- Nouveau seed TCF → `00_lots_mixtes/`, `10_ce/`, `20_structure/` ou `30_echantillons/` selon la nature.
- Si le namespace est plein (rare), ajouter un nouveau sous-dossier (ex. `50_xxx/` → V25x).

`out-of-order: true` est activé : l'ordre d'ajout n'est pas contraint tant que les numéros restent uniques.

## Lots d'entraînement TCF (calcul dynamique, sans schéma)

Un **lot** est un sous-ensemble déterministe de questions filtrées par
(`module=TCF`, `questionType=CO|CE`, `difficulty=A2|B1|B2`), trié par
`created_at ASC, id ASC`. **Aucune table dédiée** : la composition d'un lot
est dérivée de sa position dans le pool. Tant que le pool ne change pas,
Lot 1 renvoie toujours les mêmes questions.

**Tailles fixes par niveau** (constantes dans `LotService.LOT_SIZE_{A2,B1,B2}`) :

- A2 = 15 questions
- B1 = 20 questions
- B2 = 25 questions

Règle de découpage :

- Pool == 0 → aucun lot exposé.
- Pool < lotSize standard → **1 lot partiel** avec tout le pool. Utile quand
  le pool CO se remplit progressivement (admin génère des audio questions
  par lot de 5-10 via le pipeline IA). Évite d'afficher "0 lot" alors que des
  questions sont prêtes côté admin.
- Pool ≥ lotSize → N lots complets de taille standard. Les questions au-delà
  du dernier multiple sont ignorées (elles seront exposées quand un nouveau
  multiple sera atteint). Exemple A2 avec 47 questions : Lot 1 (1-15), Lot 2
  (16-30), Lot 3 (31-45), les 2 restantes en attente.

`AttemptService.startFromLot` utilise `LotService.resolveLotSize(...)` pour
résoudre la taille effective du lot demandé — même source de vérité que
`GET /api/lots`, donc impossible que les deux endpoints divergent.

**Trace lot ↔ attempt** : la migration `V097__attempts_lot_columns.sql` ajoute
trois colonnes nullables sur `attempts` (`lot_numero`, `lot_question_type`,
`lot_difficulty`) que `startFromLot` remplit. L'index partiel
`idx_attempts_user_lot` couvre la query `findFinishedByUserAndLot`
(`AttemptRepository`) qu'`AttemptManager.findLastFinishedByLots` utilise pour
renvoyer le dernier attempt fini par lot (clé = `lot_numero`). `LotService.list`
enrichit chaque `LotDto` avec `lastScore` + `lastAttemptedAt` du user pour
que le mobile différencie visuellement les lots déjà faits (carte teintée +
badge score `X/Y`).

## Examens module TCF (CO ou CE, sous-set de MOCK_EXAM)

Distinct de l'examen blanc complet (toutes épreuves) : un **examen module**
est un MOCK_EXAM scopé à une seule épreuve TCF QCM (CO ou CE), pour
permettre de simuler la passation d'une épreuve unique.

Migration `V098__attempts_module_exam_columns.sql` ajoute :
- `module_exam_question_type` (varchar 24) : `CO` ou `CE` quand scopé, NULL sinon
- `weighted_score` + `max_weighted_score` (int) : score pondéré persisté à la
  finalisation pour éviter de re-joindre `attempt_questions` à chaque lecture
- Index partiel `idx_attempts_module_exam` sur
  `(user_id, module, module_exam_question_type, finished_at DESC)`

**Composition** (`AttemptService.composeModuleExam`) :
- 8 A2 + 9 B1 + 8 B2 = 25 questions progressives, tirage aléatoire dans chaque
  strate (`module=TCF`, `questionType=CO|CE`)
- Fallback si une strate est sous-dotée : on complète sans contrainte de niveau

**Chrono** : 20 min CO / 35 min CE (constantes `MODULE_EXAM_CO_SECONDS` /
`MODULE_EXAM_CE_SECONDS`).

**Score pondéré** : A2=1, B1=2, B2=3 → max 50 pts pour la répartition 8/9/8.
Calculé à la finalisation par `computeWeightedScore`.

**Endpoints** :
- `POST /api/attempts {type:MOCK_EXAM, module:TCF, moduleExamQuestionType:CO|CE}`
  → `AttemptService.startModuleExam` (premium TCF requis)
- `GET /api/me/attempts?type=MOCK_EXAM&module=TCF&moduleExamQuestionType=CO|CE`
  → historique des examens passés/en cours du user
- `GET /api/me/questions/wrong?module=TCF&questionType=CO|CE`
  → questions ratées filtrées par épreuve (utilisé par l'onglet Erreurs)

`AttemptSummaryResponse` (et son miroir Dart `AttemptSummary`) exposent
`moduleExamQuestionType`, `weightedScore`, `maxWeightedScore` (null pour les
autres attempts). Côté mobile : `_ExamsTab` dans `TcfQcmDetailScreen` affiche
l'intro + l'historique avec badge score coloré, `_ErrorsTab` liste les
questions ratées avec leur niveau.

**Côté backend** (`backend_sejourfr/src/main/java/com/sejourfr/app/`) :

- `dto/LotDto.java` (record `numero / difficulty / totalQuestions`)
- `service/LotService.java` (calcul dynamique + helpers statiques `lotSizeFor`)
- `controller/LotController.java` (`GET /api/lots`)
- `manager/QuestionManager.findLotQuestions(...)` (fenêtre paginée par lotNumero)
- `dto/StartAttemptRequest.java` accepte un champ `lotNumero` ; quand présent,
  `AttemptService.startFromLot` construit l'attempt avec la fenêtre exacte
  (reservé premium TCF, retourne 403 sinon).
- `repository/QuestionRepository.countActiveMatching` étendu avec un filtre
  `questionType` (callers `AdminExamTemplateService` passent `null`).

**Côté mobile** (`mobile_sejourfr/lib/`) :

- `core/models/lot_models.dart` (LotDto Dart)
- `core/api/lots_repository.dart` (`GET /api/lots`)
- `core/models/attempt_models.dart` : `StartAttemptRequest.lotNumero` ajouté
- `screens/module_detail/tcf_qcm_detail_screen.dart` : onglet Séries affiche
  3 sections par niveau, lots chargés via `_lotsProvider` family.

Pour ajouter un 4ᵉ niveau (jamais prévu vu que TCF s'arrête à B2) ou changer
la taille d'un lot : modifier les constantes dans `LotService` + ajouter le
niveau dans `_seriesLevels` côté mobile. Pas de migration.

## Pipeline de génération audio TCF (Compréhension Orale)

Le backend a un pipeline **Claude (Anthropic) → Azure Speech → Cloudflare R2 → Postgres** dans
`backend_sejourfr/src/main/java/com/sejourfr/app/audioquestion/`. Côté admin React, c'est dans
`admin_sejourfr/src/features/audioQuestions/`. Endpoints sous `/api/admin/audio-questions/*`.

Deux modes d'audio (colonne `questions.audio_mode`, enum `AudioMode`) :

- `WRITTEN_QUESTION` : document sonore lu, question et 4 choix écrits à l'écran (défaut).
- `FULL_AUDIO` : document + question + 4 choix tous lus dans l'audio ; labels en base = `"Réponse A/B/C/D"`.

Toute question audio commence par l'amorce standardisée **« Écoutez le document sonore, puis répondez à la
question. »** (vérifiée strictement côté serveur, sinon rejet 422). Pour les questions non audio (
CE/STRUCTURE), `audio_mode` reste `NULL`.

Prompts dans `backend_sejourfr/src/main/resources/prompts/` : `audio-question-system-v1.md` (legacy, gardé
pour traçabilité) et `audio-question-system-v2.md` (actif par défaut). Bascule via `ANTHROPIC_PROMPT_VERSION`
dans l'env. Schéma de l'outil Claude : `audio-question-tool-schema.json`.

## Pipeline d'évaluation des productions TCF (Expression Orale + Écrite)

Pendant du pipeline CO, mais pour **noter** une production utilisateur au lieu d'en générer une. Stack : *
*OpenAI Whisper** (transcription audio en mode "littéral" pour ne pas masquer les fautes des apprenants) → *
*Claude Sonnet 4.5** (évaluation via `tool_use submit_evaluation`, JSON garanti) → **Cloudflare R2 privé**
pour les audios user (URL signée 15 min, distinct du bucket public utilisé pour les audios CO) → **Postgres**.

Tables (cf. `V96__add_production_tasks.sql`) : `production_tasks` (catalogue de consignes EO/EE),
`production_submissions` (rendus user, statuts dans `SubmissionStatut`), `transcriptions` (sortie Whisper,
prompt utilisé conservé pour debug), `ai_evaluations` (note + feedback structuré + tokens),
`human_calibration_notes` (notes humaines de référence pour calibrer l'IA). Seed
`V130__seed_production_tasks.sql` : 18 tâches (A2/B1/B2 × tâches 1/2/3 × EO/EE).

Services dans `backend_sejourfr/src/main/java/com/sejourfr/app/service/` (packages flat, pas un sous-module
comme `audioquestion/`) :

- `WhisperTranscriptionClient` + `WhisperTranscriptionService` (OpenAI multipart, retry Spring 3 tentatives)
- **Interface `EvaluationLlmClient`** avec deux impls : `EvaluationAnthropicClient` (Claude + tool_use) et
  `EvaluationOpenAiClient` (Chat Completions + function calling). Le bean primary est sélectionné dans
  `config/EvaluationLlmConfig` selon `sejourfr.production-evaluation.provider` (`openai` par défaut,
  `anthropic` possible). Le tool schema JSON est strictement identique entre providers — seule l'enveloppe
  HTTP change. Pour ajouter un 3e provider : implémenter l'interface (4 méthodes : `evaluate`, `getModelName`,
  `getPromptVersion`, calcul de coût dans `Outcome`), enregistrer le bean avec un
  `@Service("evaluationXxxClient")`, ajouter le case dans `EvaluationLlmConfig`.
- `EvaluationPromptBuilder` (charge `system-v1.md` + `user-template.md` au startup, substitution `{CONSIGNE}`,
  `{NIVEAU}`, etc.)
- `AiEvaluationService` (orchestration : prompt + LLM + persistance `AiEvaluation`)
- `ProductionAudioStorageService` (R2 privé + URL signée via `S3Presigner` ; le bean est ajouté à
  `audioquestion/config/CloudflareR2Config.java`)
- `ProductionEvaluationService` (orchestration `submitAndEvaluate` / `retry`) — **pas `@Transactional` au
  niveau orchestration** : chaque étape a son propre tx, ce qui permet de tomber en `FAILED` proprement et de
  reprendre du bon point au retry (skip Whisper si la transcription est déjà en base).
- `AdminCalibrationService` (dashboard écart IA vs humain).

Prompts dans
`src/main/resources/prompts/production-evaluation-{system,user-template,tool-schema}-vX.Y.{md,json}`. Chargés
à la demande selon `prompt-version` du provider actif (default `v1.1`). Versionnés dans
`ai_evaluations.prompt_version` ; toute modif structurante = nouveau triplet `vX.Y` (les anciens fichiers
restent en place pour permettre un rollback via `EVAL_PROMPT_VERSION=v1.0`). En v1.1 : distinction explicite *
*note_globale (qualité de la tâche)** vs **niveau_cecrl (compétence réelle, peut dépasser le niveau cible)**,
descripteurs CECRL A1-C2 dans le system prompt, champ `justification_niveau` (obligatoire, cite 2-3 marqueurs
concrets) ajouté au tool schema et exposé dans `EvaluationResultDto.justificationNiveau` (nullable pour
rétro-compat v1.0).

Config : `sejourfr.openai` (Whisper) + `sejourfr.production-evaluation` (paramètres généraux + `provider` +
sous-objets `openai` et `anthropic` dédiés à l'évaluation). **Distinct** de `sejourfr.anthropic` qui sert au
pipeline CO et tourne sur Opus. Variables d'env : `OPENAI_API_KEY` (mutualisé Whisper + eval OpenAI),
`EVAL_OPENAI_API_KEY` (dédié si besoin), `EVAL_ANTHROPIC_API_KEY` (fallback `ANTHROPIC_API_KEY`),
`EVAL_LLM_PROVIDER` (`openai` | `anthropic`), `EVAL_OPENAI_MODEL`, `EVAL_ANTHROPIC_MODEL`. Le coût estimé en
centimes est calculé par le client lui-même (tarif `cost-per-million-{input,output}-tokens` dans la config par
provider) et persiste dans `ai_evaluations.cout_estime_centimes`.

Quota gratuit : 2 submissions à vie par épreuve (EO + EE) via `SubscriptionService.hasTcf(userId)` ; au-delà →

403. Premium TCF (plan INTEGRAL) = illimité. Retry manuel max 3 par submission.

**Mobile (Flutter)** : flow complet livré dans `mobile_sejourfr/lib/screens/tcf_production/`. **Entry par hub
d'entraînement libre** (3 cards T1/T2/T3, l'utilisateur choisit une seule tâche à la fois) — la session
3-tâches chaînée est conservée pour le futur examen blanc. Cf. CLAUDE.md du sous-projet. Web et admin n'ont
pas encore d'UI EO/EE.

**Gotchas backend appris à la dure** :

- `chk_prod_sub_audio_or_text` interdit qu'un INSERT ait `media_url=null ET texte_soumis=null` :
  `ProductionEvaluationService` uploade R2 AVANT l'insert (avec un UUID indépendant de `submission.id` — sinon
  Hibernate + `@UuidGenerator` rejette une entité avec id pré-assigné comme "detached").
- `SubscriptionService` doit rester `@Transactional(readOnly = true)` au niveau classe : ses callers (ex:
  `ProductionSubmissionController.enforceQuota`) ne sont pas tous transactionnels, et avec
  `open-in-view: false` l'accès lazy à `Plan` plante sans session ouverte.
- `ProductionSubmissionDto.tacheNumero` est lu via `s.getProductionTask().getTacheNumero()` dans
  `ProductionSubmissionMapper` — déclenche le lazy-load du proxy. Toutes les routes de lecture (`mine`,
  `detail`, `lastPerTask`) sont donc annotées `@Transactional(readOnly = true)`. Avant cet ajout, le mapper ne
  touchait que `.getId()` des relations (no-op sur un proxy) et les routes pouvaient se passer de transaction.

## Architecture mentale par projet

**Tous les fronts suivent l'organisation par feature** (miroir du backend Java) :

- Backend Java : `entity/`, `repository/`, `manager/`, `service/`, `controller/`, `dto/`, `mapper/`,
  `specification/`, `security/`, `config/`, `exception/`, `enums/` (+ sous-module historique `audioquestion/`
  à part)
- Admin React : `features/{questions,themes,conversations,dashboard}/` + `api/`, `auth/`, `components/ui/`,
  `routes/`, `types/`
- Web Next : `app/{inscription,connexion,examen-blanc,paiement}/` + `app/_components/` + `lib/{api,types}.ts`
- Mobile Flutter : `screens/{auth,home,training,exam,question_runner,review,profile,…}/` +
  `core/{api,auth,models,router,theme,utils,widgets}/`

Le **runner de questions** (mobile `screens/question_runner/` et web `examen-blanc/page.tsx`) est le composant
le plus complexe — relire son CLAUDE.md local avant de toucher.

### Convention backend Java : Controller → Service → Manager → Repository (strict)

- **Controllers** : ultra-fins, délèguent tout au service. Pas de logique, pas de mapping inline, pas d'accès
  repo. `@RequiredArgsConstructor` Lombok.
- **Services** : orchestrent un cas d'usage (validations, règles métier, transactions, mapping DTO).
  N'accèdent JAMAIS un `*Repository` directement — passent par les managers. Un service peut appeler plusieurs
  managers (y compris d'autres agrégats) et d'autres services.
- **Managers** (`manager/`) : seule couche autorisée à appeler les `*Repository`. Wrappent JPA et exposent une
  API métier (ex: `findActiveById`, `countByPassage`). Un manager par agrégat, même pour du CRUD trivial —
  règle uniforme. Convention `int limit` au lieu de `Pageable` quand c'est suffisant ;
  `Specification + Pageable` quand la recherche est dynamique.
- **Mappers** : `@Component`, purs. Reçoivent l'entité + éventuels compléments (ex: `count`) en paramètres,
  retournent un DTO. Ne touchent ni repo ni manager. Si un mapping a besoin d'une lookup, le service la fait
  avant.
- **Lombok** : `@RequiredArgsConstructor` sur tous les controllers/services/managers/mappers. `@Slf4j` au lieu
  du `LoggerFactory.getLogger(...)`. Sur les entités JPA : `@Getter/@Setter` OK, **jamais `@Data`** ni
  `@EqualsAndHashCode` automatique (toString/equals + lazy loading = bugs).
- **Exception** : `audioquestion/` est un sous-module isolé qui n'a pas été migré (mini-module historique,
  refacto reportée). Ses services peuvent encore appeler `MediaRepository` direct.

## Préférences de collaboration (durables)

- **Pas de README ni de docs générés automatiquement.** Ne créer un `.md` que si l'utilisateur le demande.
- **Code direct + brèves explications.** Pas de récap de fin de message ni de narration d'étapes triviales.
- **Pour les décisions structurantes : proposer des options avec leurs tradeoffs, pas imposer.**
- **Pas de Tailwind utility-first dans le markup web** — Tailwind v4 sert uniquement aux tokens via `@theme`.
  Styles dans `globals.css` ou `<style>` JSX scoped.
- **Responsive obligatoire (web + admin)** : tout écran doit fonctionner du mobile (~360 px) au desktop.
  Tester mentalement chaque modif sur 360 / 768 / 1280 minimum. Pas de largeur fixe en px sans
  `max-width: 100%`, pas de grilles à colonnes fixes sans `@media` de repli, pas de tableaux sans alternative
  carte sur petit écran. Si une modif touche un layout existant, vérifier que les breakpoints en place
  tiennent toujours.
- **Admin & runner** : pas d'UI kit, pas de CSS-in-JS, pas de `clsx`. CSS Modules vanilla.
- **Mobile** : Riverpod uniquement (pas de Bloc/Provider/GetX), `context.go/push` (jamais `Navigator.push`),
  `withValues(alpha:)` (pas `withOpacity`).
- **Tous** : TypeScript/Dart strict, pas de `any`/`dynamic`, imports relatifs, pas de commentaire qui
  paraphrase le code.
- **Hygiène d'architecture (non négociable)** : la plateforme est faite pour durer, chaque ajout doit
  préserver une archi propre et lisible — pas de patch rapide qui s'accumule en désordre.
    - Tout nouveau fichier prend sa place dans l'arbo `feature/` existante (cf. CLAUDE.md local). Si une
      feature grossit, créer un dossier dédié plutôt que d'empiler des fichiers à la racine d'un voisin.
    - Duplication = signal : à la 2ᵉ occurrence, **extraire** un widget/util/service partagé (ex:
      `hub_widgets.dart`, `paywall_sheet.dart` factorisés au moment où ils sont apparus 2× dans les hubs
      Civique/TCF). À 3 occurrences, c'est de la dette.
    - Refonte = suppression immédiate de l'ancien. Quand un écran/route/composant est remplacé, supprimer le
      fichier + tous les imports + toutes les références CTA dans la foulée. Pas de cohabitation "au cas où"
      qui pourrit ensuite.
    - Respecter la convention de couches du backend Java (Controller → Service → Manager → Repository, mappers
      purs) et les conventions par sous-projet documentées dans chaque `CLAUDE.md` local. Pas d'exception "
      juste pour cette fois".
- **Maintenir les `CLAUDE.md` à jour** : après une modif structurante (nouvelle feature, nouveau pipeline,
  changement de convention, nouvelle migration importante, nouveau dossier `features/*`), mettre à jour le
  CLAUDE.md local concerné et celui de la racine si la modif est transverse. Pas de changelog exhaustif —
  juste de quoi qu'un futur Claude se repère vite. Inutile d'y consigner les bugfixes ou les
  micro-ajustements.

## Git

- Remote : `git@github.com:diallomatine/sejourfr_opus_nouveau.git`
- Branche par défaut : `develop` (PRs vers `main`)
- Le repo racine est **un seul git** qui couvre les 4 dossiers — un commit peut toucher plusieurs surfaces (
  utile quand on aligne un DTO backend avec ses miroirs front).

## Refonte entraînement (en cours)

Bascule progressive d'une nav "Entraîner / Examen" générique vers **2 hubs métier dédiés Civique et
TCF**, calqués sur le design `tcf_entrainement_mobile_design.html` à la racine (14 écrans, archi
hub → détail module → série → questions → feedback → fin de série).

**Statut mobile (lots 1 → 5 faits)** : bottom nav `Accueil · Civique · TCF · Progression · Profil`.
Hubs Civique (5 thèmes officiels) et TCF (CO/CE/EE IA/EO IA) dans
`mobile_sejourfr/lib/screens/{civique,tcf}/`,
widgets de hub partagés dans `screens/hub/widgets/hub_widgets.dart`.
Tap module → **écran détail** (`screens/module_detail/`) avec hero, stats et CTA :

- Thèmes civique + TCF CO/CE : score de maîtrise + bouton "Commencer l'entraînement" → POST attempts
  → runner. **Le détail TCF CO/CE a en plus 3 onglets Séries / Examens / Erreurs**. L'onglet Séries
  affiche 3 cards niveau (A2 vert / B1 ambre / B2 rouge). Tap niveau → push
  `TcfLevelLotsScreen` (écran dédié, hero coloré au niveau + liste des lots chargés depuis
  `GET /api/lots`, cf. § Lots d'entraînement). Lot A2 = 15 Q, B1 = 20 Q, B2 = 25 Q. Tap d'un lot →
  `POST /api/attempts {lotNumero}` (réservé premium, paywall sinon). Examens et Erreurs sont en
  placeholder "Bientôt" pour l'instant.
- TCF EE/EO : carte "Comment ça marche" + "Voir les tâches" qui push `ProductionHubScreen`
  (sélection T1/T2/T3). Les anciens écrans
  `TrainingSetupScreen` et `ExamSetupScreen` ont été **supprimés**, ainsi que les routes `/training`
  et `/exam`. Sheet paywall réutilisable dans `core/widgets/paywall_sheet.dart`. Carte "Examen blanc
  complet" présente mais inactive.

**Reste à faire mobile (lots suivants)** : lot 4b — brancher les onglets Examens (réutiliser
`examsByModuleProvider` qui partait avec `exam_setup_screen.dart` supprimé) et Erreurs (utiliser
`userContentRepository.wrongAnswered`) ; branchement de l'examen blanc complet sur la carte
sombre des hubs ; score par épreuve TCF côté backend (pour remplacer l'agrégat global affiché
actuellement sur CO/CE).

**À reproduire côté web** (`web_sejoufr/`) une fois le mobile stabilisé : même découpe Civique/TCF
dans la nav principale, mêmes hubs, même paywall. La parité front mobile↔web est un axe produit.

Cf. `mobile_sejourfr/CLAUDE.md` section "Bottom nav et hubs Civique / TCF" pour le détail technique.

## Roadmap commune (qui n'existe pas encore)

- **Paiement Stripe** : front prêt (web `paiement/page.tsx`), endpoint
  `POST /api/billing/create-checkout-session` **à créer côté Java** (dep `com.stripe:stripe-java`, Price IDs
  en `application.yaml`).
- **Refresh JWT côté web** : l'intercepteur n'est pas encore branché dans `web_sejoufr/lib/api.ts` (admin et
  mobile l'ont déjà).
- **Middleware Next** pour protéger les routes auth via cookie `sejourfr.accessToken`.
- **Dashboard utilisateur, entraînement libre, révision, succès post-paiement** côté web.
- **Clients / abonnements / stats par user** côté admin (entités existent, pas d'endpoints encore).
- **EO/EE TCF côté web + admin** : mobile livré (hub d'entraînement single-task, recording WAV, écrans
  complets) ; reste à coder le miroir web (entraînement EO/EE en navigateur via `MediaRecorder` API) et
  l'écran admin de calibration humaine consommant `/api/admin/calibration/*`.
- **Examen blanc EO/EE** : flow 3-tâches chaîné prévu (cf. mobile CLAUDE.md). Stratégie validée : Option 3
  fire-and-forget — chaque submit part en async pendant que l'utilisateur attaque la tâche suivante, les
  résultats sont agrégés à la fin. Routes legacy `/tcf/expression-X/nouvelle`, `/progression`, `/bilan` +
  `EoSessionController.start()` / `EeSessionController.start()` (mode 3-tâches) déjà en place, à réactiver le
  moment venu.
- **Rate limiting global EO/EE** : la spec demandait 10/h et 50/jour, pas branché (mériterait un filter Spring
  dédié type Bucket4j).
- **AAC pour EO mobile** : `record_ios 1.2.0` produit un fichier vide sur iOS 26 en AAC-LC → workaround WAV (
  32 KB/s = ~6 Mo pour 3 min). Repasser à AAC dès qu'une version `record_ios` iOS 26-compatible sort, pour
  économiser ~5x sur l'upload.
- **Offline-first mobile** (SQLite/Drift dans `core/storage/`) — non commencé.
- **In-app purchase** mobile : **volontairement reporté**, on pousse l'utilisateur à payer sur le web.
- **Tests** : aucun sur les 4 projets. Cibles à venir : Vitest+RTL (admin/web), `flutter_test`+`mocktail` (
  mobile, prioriser les controllers Riverpod), JUnit (backend, prioriser l'orchestration EO/EE qui n'a que des
  mocks à brancher).
