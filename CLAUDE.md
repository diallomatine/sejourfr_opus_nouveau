# SejourFR — Guide racine pour Claude Code

Monorepo (4 dossiers indépendants, pas de workspace npm/Maven parent) de **SejourFR**, plateforme d'entraînement aux examens **civique** (CSP, CR, naturalisation) et **TCF IRN** (A2/B1/B2), obligatoires depuis le **1ᵉʳ janvier 2026**.

> Avant de coder sur un sous-projet, **toujours lire son `CLAUDE.md` local** : les conventions précises (state management, styling, runner, etc.) y vivent. Ce fichier-ci est un index transverse, pas un substitut.

## Les 4 sous-projets

| Dossier | Stack | Rôle | Port dev | Guide |
|---|---|---|---|---|
| `backend_sejourfr/` | Spring Boot 4 / Java 21 / PostgreSQL / Flyway / JWT | API REST unique pour les 3 fronts | 8080 | `README.md` |
| `admin_sejourfr/` | React 19 + Vite + TS strict + TanStack Query + React Router 7 + CSS Modules | Console admin (questions, thèmes, conversations, médias) | 5173 (Vite) | `CLAUDE.md` |
| `web_sejoufr/` ⚠️ (typo : *sejoufr*, pas *sejourfr*) | Next.js 16 App Router + React 19 + Tailwind v4 (tokens seuls) | Vitrine + parcours utilisateur + paiement Stripe + 1 examen blanc / 10 QCM démo | 3000 | `CLAUDE.md` |
| `mobile_sejourfr/` | Flutter 3.6+ / Dart 3.6+ / Riverpod 2 + Dio + go_router | App d'entraînement quotidien (cœur produit) | — | `CLAUDE.md` |

**Stratégie business** : le web pousse à l'abonnement (paiement Stripe **hors stores** pour éviter la commission Apple/Google), puis l'utilisateur s'entraîne principalement sur le mobile. Le web permet aussi 1 examen blanc + 10 QCM d'entraînement par module pour convertir.

## Domaine métier (vocabulaire commun)

- **Module** : `CIVIQUE` ou `TCF`
- **TargetProcedure** (civique) : `CSP` (titre de séjour) / `CR` (résident) / `NAT` (naturalisation)
- **TargetLevel** (TCF) : `A2` / `B1` / `B2`
- **AttemptType** : `TRAINING` (correction immédiate après chaque réponse) / `MOCK_EXAM` (examen blanc, pas de correction live, chrono) / `REVIEW`
- **Epreuve** (granularité fine de l'attempt, orthogonale à `mode`/`module`) : `CIVIQUE` / `TCF_CO` / `TCF_CE` / `TCF_STRUCTURE` / `TCF_EO` / `TCF_EE` / `TCF_COMPLET`. `TCF_COMPLET` est un conteneur d'examen blanc TCF complet ; les sous-attempts sont liés via `attempts.parent_attempt_id`.
- **QuestionType** : `KNOWLEDGE` / `SITUATION`
- **Difficulty** : `EASY` / `MEDIUM` / `HARD`
- **MediaType** : `AUDIO` / `IMAGE` / `VIDEO` (TCF compréhension orale → audio surtout)
- **NiveauCecrl** (évaluation IA EO/EE) : `A1_NON_ATTEINT` / `A1` / `A2` / `B1` / `B2` / `C1` / `C2`. Distinct de `TargetLevel` qui est le palier visé par l'utilisateur.
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

⚠️ Note : le web utilise `#1E3A8C`, l'admin documente `#1E3A8F` dans son CLAUDE.md — vérifier le code source en cas de doute (le code fait foi).

**Typographies**
- **Plus Jakarta Sans** (web/mobile) ou **Inter** (admin) — corps, UI, boutons
- **Fraunces** — titres éditoriaux ; les `<em>` dans les titres sont **toujours rouges**
- **JetBrains Mono** — eyebrows, labels techniques, badges, valeurs numériques

**Logo** : Cocarde (3 cercles concentriques bleu/blanc/rouge) + Wordmark (`Sejour` bleu, `FR` rouge) + Tagline `EXAMEN CIVIQUE · TCF`.

**Règle absolue** : ne jamais hardcoder une couleur ou une font. Toujours passer par les tokens locaux (`var(--color-*)`, `AppColors.*`, `AppFonts.*`).

## API backend partagée

Base : `http://localhost:8080`. CORS dev autorise `localhost:3000` (web Next.js) et `localhost:5173` (admin Vite). Auth JWT Bearer (access ~60 min + refresh 30 j) — **refresh automatique** dans le client HTTP de chaque front.

Endpoints clés :
- `POST /api/auth/{login,register,refresh,forgot-password,reset-password}` · `GET /api/auth/me`
- `GET /api/themes?module=CIVIQUE|TCF`
- `POST /api/attempts` · `POST /api/attempts/production` (attempt vide pour EO/EE) · `GET /api/attempts/{id}` · `POST /api/attempts/{id}/answers` · `POST /api/attempts/{id}/finish`
- `GET /api/me/{questions/favorites,questions/wrong,stats}?module=...` · `POST|DELETE /api/me/questions/{id}/favorite`
- **EO/EE TCF** : `GET /api/production-tasks?epreuve=TCF_EO&niveau=B1` · `GET /api/production-tasks/{id}` · `POST /api/production-submissions` (multipart audio **ou** JSON texte selon `Content-Type`) · `POST /api/production-submissions/{id}/retry` · `GET /api/production-submissions/{id}` · `GET /api/users/me/production-submissions?epreuve=...`
- Admin : `/api/admin/{dashboard,questions,themes,conversations,media,passages,audio-questions,calibration/{submissions,stats}}`
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

| Email | Mot de passe | Rôle |
|---|---|---|
| `admin@sejourfr.fr` | `Admin123!` | ADMIN |
| `user@sejourfr.fr` | `User123!` | USER |
| `karim.test@sejourfr.fr` | `User123!` | USER |

## Migrations Flyway — organisation et convention de numérotation

Flyway scanne récursivement `classpath:db/migration` (prod & dev) et `classpath:db/migration-dev` (dev uniquement). L'arborescence est organisée par **plages numériques** et par **dossiers thématiques** :

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
- `00_schema/Vxxx` : 1er chiffre = 0 (catégorie schéma). Espacement step 10 (V001, V010, V020...) pour pouvoir intercaler. **DDL pur** (CREATE/ALTER), pas d'INSERT qui dépend de données seedées plus tard.
- `10_reference/V1xx` : seeds de référence (thèmes, plans, exam templates). Toute donnée fixe partagée prod/dev.
- `20_civique/10_institutions/V21x` : 1er chiffre 2 = civique, 2e chiffre 1 = institutions. Files V210..V219 (10 slots par sous-thème).
- Idem TCF.

**Pour ajouter une migration :**
- Nouvelle évolution de schéma → `00_schema/`, prochain V0x0 libre.
- Nouveau seed civique → sous-dossier du thème, prochain numéro libre dans le namespace (10 slots).
- Nouveau seed TCF → `00_lots_mixtes/`, `10_ce/`, `20_structure/` ou `30_echantillons/` selon la nature.
- Si le namespace est plein (rare), ajouter un nouveau sous-dossier (ex. `50_xxx/` → V25x).

`out-of-order: true` est activé : l'ordre d'ajout n'est pas contraint tant que les numéros restent uniques.

## Pipeline de génération audio TCF (Compréhension Orale)

Le backend a un pipeline **Claude (Anthropic) → Azure Speech → Cloudflare R2 → Postgres** dans `backend_sejourfr/src/main/java/com/sejourfr/app/audioquestion/`. Côté admin React, c'est dans `admin_sejourfr/src/features/audioQuestions/`. Endpoints sous `/api/admin/audio-questions/*`.

Deux modes d'audio (colonne `questions.audio_mode`, enum `AudioMode`) :
- `WRITTEN_QUESTION` : document sonore lu, question et 4 choix écrits à l'écran (défaut).
- `FULL_AUDIO` : document + question + 4 choix tous lus dans l'audio ; labels en base = `"Réponse A/B/C/D"`.

Toute question audio commence par l'amorce standardisée **« Écoutez le document sonore, puis répondez à la question. »** (vérifiée strictement côté serveur, sinon rejet 422). Pour les questions non audio (CE/STRUCTURE), `audio_mode` reste `NULL`.

Prompts dans `backend_sejourfr/src/main/resources/prompts/` : `audio-question-system-v1.md` (legacy, gardé pour traçabilité) et `audio-question-system-v2.md` (actif par défaut). Bascule via `ANTHROPIC_PROMPT_VERSION` dans l'env. Schéma de l'outil Claude : `audio-question-tool-schema.json`.

## Pipeline d'évaluation des productions TCF (Expression Orale + Écrite)

Pendant du pipeline CO, mais pour **noter** une production utilisateur au lieu d'en générer une. Stack : **OpenAI Whisper** (transcription audio en mode "littéral" pour ne pas masquer les fautes des apprenants) → **Claude Sonnet 4.5** (évaluation via `tool_use submit_evaluation`, JSON garanti) → **Cloudflare R2 privé** pour les audios user (URL signée 15 min, distinct du bucket public utilisé pour les audios CO) → **Postgres**.

Tables (cf. `V96__add_production_tasks.sql`) : `production_tasks` (catalogue de consignes EO/EE), `production_submissions` (rendus user, statuts dans `SubmissionStatut`), `transcriptions` (sortie Whisper, prompt utilisé conservé pour debug), `ai_evaluations` (note + feedback structuré + tokens), `human_calibration_notes` (notes humaines de référence pour calibrer l'IA). Seed `V130__seed_production_tasks.sql` : 18 tâches (A2/B1/B2 × tâches 1/2/3 × EO/EE).

Services dans `backend_sejourfr/src/main/java/com/sejourfr/app/service/` (packages flat, pas un sous-module comme `audioquestion/`) :
- `WhisperTranscriptionClient` + `WhisperTranscriptionService` (OpenAI multipart, retry Spring 3 tentatives)
- `EvaluationAnthropicClient` + `EvaluationPromptBuilder` + `AiEvaluationService` (Claude + tool_use)
- `ProductionAudioStorageService` (R2 privé + URL signée via `S3Presigner` ; le bean est ajouté à `audioquestion/config/CloudflareR2Config.java`)
- `ProductionEvaluationService` (orchestration `submitAndEvaluate` / `retry`) — **pas `@Transactional` au niveau orchestration** : chaque étape a son propre tx, ce qui permet de tomber en `FAILED` proprement et de reprendre du bon point au retry (skip Whisper si la transcription est déjà en base).
- `AdminCalibrationService` (dashboard écart IA vs humain).

Prompts dans `src/main/resources/prompts/production-evaluation-{system-v1.md, user-template.md, tool-schema.json}`. Versionnés dans `ai_evaluations.prompt_version` (toute modif = nouvelle version).

Config : `sejourfr.openai` (Whisper) + `sejourfr.production-evaluation` (paramètres généraux + sous-objet `anthropic` dédié). **Distinct** de `sejourfr.anthropic` qui sert au pipeline CO et tourne sur Opus. Variables d'env : `OPENAI_API_KEY`, `EVAL_ANTHROPIC_API_KEY` (fallback `ANTHROPIC_API_KEY`).

Quota gratuit : 2 submissions à vie par épreuve (EO + EE) via `SubscriptionService.hasTcf(userId)` ; au-delà → 403. Premium TCF (plan INTEGRAL) = illimité. Retry manuel max 3 par submission.

**Mobile (Flutter)** : flow complet livré dans `mobile_sejourfr/lib/screens/tcf_production/` (cf. CLAUDE.md du sous-projet). Web et admin n'ont pas encore d'UI EO/EE.

**Gotchas backend appris à la dure** :
- `chk_prod_sub_audio_or_text` interdit qu'un INSERT ait `media_url=null ET texte_soumis=null` : `ProductionEvaluationService` uploade R2 AVANT l'insert (avec un UUID indépendant de `submission.id` — sinon Hibernate + `@UuidGenerator` rejette une entité avec id pré-assigné comme "detached").
- `SubscriptionService` doit rester `@Transactional(readOnly = true)` au niveau classe : ses callers (ex: `ProductionSubmissionController.enforceQuota`) ne sont pas tous transactionnels, et avec `open-in-view: false` l'accès lazy à `Plan` plante sans session ouverte.

## Architecture mentale par projet

**Tous les fronts suivent l'organisation par feature** (miroir du backend Java) :
- Backend Java : `entity/`, `repository/`, `service/`, `controller/`, `dto/`, `mapper/`, `specification/`, `security/`, `config/`, `exception/`, `enums/`
- Admin React : `features/{questions,themes,conversations,dashboard}/` + `api/`, `auth/`, `components/ui/`, `routes/`, `types/`
- Web Next : `app/{inscription,connexion,examen-blanc,paiement}/` + `app/_components/` + `lib/{api,types}.ts`
- Mobile Flutter : `screens/{auth,home,training,exam,question_runner,review,profile,…}/` + `core/{api,auth,models,router,theme,utils,widgets}/`

Le **runner de questions** (mobile `screens/question_runner/` et web `examen-blanc/page.tsx`) est le composant le plus complexe — relire son CLAUDE.md local avant de toucher.

## Préférences de collaboration (durables)

- **Pas de README ni de docs générés automatiquement.** Ne créer un `.md` que si l'utilisateur le demande.
- **Code direct + brèves explications.** Pas de récap de fin de message ni de narration d'étapes triviales.
- **Pour les décisions structurantes : proposer des options avec leurs tradeoffs, pas imposer.**
- **Pas de Tailwind utility-first dans le markup web** — Tailwind v4 sert uniquement aux tokens via `@theme`. Styles dans `globals.css` ou `<style>` JSX scoped.
- **Admin & runner** : pas d'UI kit, pas de CSS-in-JS, pas de `clsx`. CSS Modules vanilla.
- **Mobile** : Riverpod uniquement (pas de Bloc/Provider/GetX), `context.go/push` (jamais `Navigator.push`), `withValues(alpha:)` (pas `withOpacity`).
- **Tous** : TypeScript/Dart strict, pas de `any`/`dynamic`, imports relatifs, pas de commentaire qui paraphrase le code.
- **Maintenir les `CLAUDE.md` à jour** : après une modif structurante (nouvelle feature, nouveau pipeline, changement de convention, nouvelle migration importante, nouveau dossier `features/*`), mettre à jour le CLAUDE.md local concerné et celui de la racine si la modif est transverse. Pas de changelog exhaustif — juste de quoi qu'un futur Claude se repère vite. Inutile d'y consigner les bugfixes ou les micro-ajustements.

## Git

- Remote : `git@github.com:diallomatine/sejourfr_opus_nouveau.git`
- Branche par défaut : `develop` (PRs vers `main`)
- Le repo racine est **un seul git** qui couvre les 4 dossiers — un commit peut toucher plusieurs surfaces (utile quand on aligne un DTO backend avec ses miroirs front).

## Roadmap commune (qui n'existe pas encore)

- **Paiement Stripe** : front prêt (web `paiement/page.tsx`), endpoint `POST /api/billing/create-checkout-session` **à créer côté Java** (dep `com.stripe:stripe-java`, Price IDs en `application.yaml`).
- **Refresh JWT côté web** : l'intercepteur n'est pas encore branché dans `web_sejoufr/lib/api.ts` (admin et mobile l'ont déjà).
- **Middleware Next** pour protéger les routes auth via cookie `sejourfr.accessToken`.
- **Dashboard utilisateur, entraînement libre, révision, succès post-paiement** côté web.
- **Clients / abonnements / stats par user** côté admin (entités existent, pas d'endpoints encore).
- **EO/EE TCF côté web + admin** : mobile livré (sessions, recording WAV, écrans complets) ; reste à coder le miroir web (entraînement EO/EE en navigateur via `MediaRecorder` API) et l'écran admin de calibration humaine consommant `/api/admin/calibration/*`.
- **Rate limiting global EO/EE** : la spec demandait 10/h et 50/jour, pas branché (mériterait un filter Spring dédié type Bucket4j).
- **AAC pour EO mobile** : `record_ios 1.2.0` produit un fichier vide sur iOS 26 en AAC-LC → workaround WAV (32 KB/s = ~6 Mo pour 3 min). Repasser à AAC dès qu'une version `record_ios` iOS 26-compatible sort, pour économiser ~5x sur l'upload.
- **Offline-first mobile** (SQLite/Drift dans `core/storage/`) — non commencé.
- **In-app purchase** mobile : **volontairement reporté**, on pousse l'utilisateur à payer sur le web.
- **Tests** : aucun sur les 4 projets. Cibles à venir : Vitest+RTL (admin/web), `flutter_test`+`mocktail` (mobile, prioriser les controllers Riverpod), JUnit (backend, prioriser l'orchestration EO/EE qui n'a que des mocks à brancher).
