# Pipeline d'évaluation des productions TCF (Expression Orale + Écrite)

Pendant du pipeline CO, mais pour **noter** une production utilisateur au lieu d'en générer
une. Stack : **OpenAI Whisper** (transcription audio en mode "littéral" pour ne pas masquer
les fautes des apprenants) → **Claude Sonnet 4.5** (évaluation via
`tool_use submit_evaluation`, JSON garanti) → **Cloudflare R2 privé** pour les audios user
(URL signée 15 min, distinct du bucket public utilisé pour les audios CO) → **Postgres**.

## Tables (cf. `V96__add_production_tasks.sql`)

- `production_tasks` (catalogue de consignes EO/EE)
- `production_submissions` (rendus user, statuts dans `SubmissionStatut`)
- `transcriptions` (sortie Whisper, prompt utilisé conservé pour debug)
- `ai_evaluations` (note + feedback structuré + tokens)
- `human_calibration_notes` (notes humaines de référence pour calibrer l'IA)

Seed `V130__seed_production_tasks.sql` : 18 tâches (A2/B1/B2 × tâches 1/2/3 × EO/EE).

## Services

Dans `backend_sejourfr/src/main/java/com/sejourfr/app/service/` (packages flat, pas un
sous-module comme `audioquestion/`) :

- `WhisperTranscriptionClient` + `WhisperTranscriptionService` (OpenAI multipart, retry
  Spring 3 tentatives)
- **Interface `EvaluationLlmClient`** avec deux impls : `EvaluationAnthropicClient`
  (Claude + tool_use) et `EvaluationOpenAiClient` (Chat Completions + function calling). Le
  bean primary est sélectionné dans `config/EvaluationLlmConfig` selon
  `sejourfr.production-evaluation.provider` (`openai` par défaut, `anthropic` possible). Le
  tool schema JSON est strictement identique entre providers — seule l'enveloppe HTTP
  change. Pour ajouter un 3e provider : implémenter l'interface (4 méthodes : `evaluate`,
  `getModelName`, `getPromptVersion`, calcul de coût dans `Outcome`), enregistrer le bean
  avec un `@Service("evaluationXxxClient")`, ajouter le case dans `EvaluationLlmConfig`.
- `EvaluationPromptBuilder` (charge `system-v1.md` + `user-template.md` au startup,
  substitution `{CONSIGNE}`, `{NIVEAU}`, etc.)
- `AiEvaluationService` (orchestration : prompt + LLM + persistance `AiEvaluation`)
- `ProductionAudioStorageService` (R2 privé + URL signée via `S3Presigner` ; le bean est
  ajouté à `audioquestion/config/CloudflareR2Config.java`)
- `ProductionEvaluationService` (orchestration `submitAndEvaluate` / `retry`) — **pas
  `@Transactional` au niveau orchestration** : chaque étape a son propre tx, ce qui permet
  de tomber en `FAILED` proprement et de reprendre du bon point au retry (skip Whisper si la
  transcription est déjà en base).
- `AdminCalibrationService` (dashboard écart IA vs humain).

## Prompts

Dans
`src/main/resources/prompts/production-evaluation-{system,user-template,tool-schema}-vX.Y.{md,json}`.
Chargés à la demande selon `prompt-version` du provider actif (default `v1.1`). Versionnés
dans `ai_evaluations.prompt_version` ; toute modif structurante = nouveau triplet `vX.Y`
(les anciens fichiers restent en place pour permettre un rollback via
`EVAL_PROMPT_VERSION=v1.0`).

En v1.1 : distinction explicite **note_globale (qualité de la tâche)** vs **niveau_cecrl
(compétence réelle, peut dépasser le niveau cible)**, descripteurs CECRL A1-C2 dans le
system prompt, champ `justification_niveau` (obligatoire, cite 2-3 marqueurs concrets)
ajouté au tool schema et exposé dans `EvaluationResultDto.justificationNiveau` (nullable
pour rétro-compat v1.0).

## Config

`sejourfr.openai` (Whisper) + `sejourfr.production-evaluation` (paramètres généraux +
`provider` + sous-objets `openai` et `anthropic` dédiés à l'évaluation). **Distinct** de
`sejourfr.anthropic` qui sert au pipeline CO et tourne sur Opus.

Variables d'env :

- `OPENAI_API_KEY` (mutualisé Whisper + eval OpenAI)
- `EVAL_OPENAI_API_KEY` (dédié si besoin)
- `EVAL_ANTHROPIC_API_KEY` (fallback `ANTHROPIC_API_KEY`)
- `EVAL_LLM_PROVIDER` (`openai` | `anthropic`)
- `EVAL_OPENAI_MODEL`, `EVAL_ANTHROPIC_MODEL`

Le coût estimé en centimes est calculé par le client lui-même (tarif
`cost-per-million-{input,output}-tokens` dans la config par provider) et persiste dans
`ai_evaluations.cout_estime_centimes`.

## Quotas

Gratuit : 2 submissions à vie par épreuve (EO + EE) via `SubscriptionService.hasTcf(userId)` ;
au-delà → 403. Premium TCF (plan INTEGRAL) = illimité. Retry manuel max 3 par submission.

## Mobile (Flutter)

Flow complet livré dans `mobile_sejourfr/lib/screens/tcf_production/`. **Entry par hub
d'entraînement libre** (3 cards T1/T2/T3, l'utilisateur choisit une seule tâche à la fois) —
la session 3-tâches chaînée est conservée pour le futur examen blanc. Cf. CLAUDE.md du
sous-projet. Web et admin n'ont pas encore d'UI EO/EE.

## Gotchas backend appris à la dure

- `chk_prod_sub_audio_or_text` interdit qu'un INSERT ait `media_url=null ET
  texte_soumis=null` : `ProductionEvaluationService` uploade R2 AVANT l'insert (avec un
  UUID indépendant de `submission.id` — sinon Hibernate + `@UuidGenerator` rejette une
  entité avec id pré-assigné comme "detached").
- `SubscriptionService` doit rester `@Transactional(readOnly = true)` au niveau classe :
  ses callers (ex: `ProductionSubmissionController.enforceQuota`) ne sont pas tous
  transactionnels, et avec `open-in-view: false` l'accès lazy à `Plan` plante sans session
  ouverte.
- `ProductionSubmissionDto.tacheNumero` est lu via
  `s.getProductionTask().getTacheNumero()` dans `ProductionSubmissionMapper` — déclenche le
  lazy-load du proxy. Toutes les routes de lecture (`mine`, `detail`, `lastPerTask`) sont
  donc annotées `@Transactional(readOnly = true)`. Avant cet ajout, le mapper ne touchait
  que `.getId()` des relations (no-op sur un proxy) et les routes pouvaient se passer de
  transaction.
