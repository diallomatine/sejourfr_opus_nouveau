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
**Bornes officielles TCF IRN** posées par `V415__fix_ee_words_eo_duree_min.sql` (V130
contenait des valeurs erronées) :

- EE : T1 = **30-60 mots**, T2 et T3 = **40-90 mots**.
- EO : cible affichée `duree_max_sec` (180 s pour T1, 210 s pour T2/T3), minimum
  acceptable `duree_min_sec` = **120 s** (colonne ajoutée par `V414__production_task_duree_min_sec.sql`).

## Services

Dans `backend_sejourfr/src/main/java/com/sejourfr/app/service/` (packages flat, pas un
sous-module comme `audioquestion/`) :

- `WhisperTranscriptionClient` + `WhisperTranscriptionService` (OpenAI multipart, retry
  Spring 3 tentatives)
- **Interface `EvaluationLlmClient`** : `EvaluationAnthropicClient` (Claude + tool_use) +
  **`OpenAiCompatibleEvalClient`** (Chat Completions + function calling), un client générique
  instancié **une fois par provider compatible OpenAI** — OpenAI **et DeepSeek** — via 2
  `@Bean` dans `config/EvaluationLlmConfig`, piloté par l'interface `ChatCompletionSettings`
  (blocs `OpenAi` / `DeepSeek` de `ProductionEvaluationProperties`). Le bean actif est
  sélectionné selon `sejourfr.production-evaluation.provider` (`openai` défaut, `anthropic`,
  `deepseek`). Tool schema JSON identique entre providers — seule l'enveloppe HTTP change.
  **Ajouter un provider OpenAI-compatible** (DeepSeek, Mistral, …) = un bloc de config
  implémentant `ChatCompletionSettings` + un `@Bean` d'une ligne ; **un provider au format
  différent** = implémenter `EvaluationLlmClient` (4 méthodes) + un `case` dans
  `EvaluationLlmConfig`.
- **`ProductionRubricsProvider`** : charge `prompts/production-rubrics-<version>.json`
  (`rubrics-version`, défaut `v1`) — **source unique du « comment noter » par tâche**
  (critères+poids, barème, descripteurs A1-C2, consignes correcteur), lookup
  `(épreuve, tâche)`. Fallback DB `criteres_evaluation` si une tâche manque.
- `EvaluationPromptBuilder` (charge `system-vX.Y.md` + `user-template-vX.Y.md`, substitue
  `{CONSIGNE}`, `{NIVEAU}`, et injecte la rubrique de la tâche : `{CRITERES}`,
  `{BAREME_NOTE}`, `{DESCRIPTEURS}`, `{CONSIGNES_CORRECTEUR}`). N'injecte **que des données**,
  aucune instruction (cf. archi 2 couches dans Prompts).
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
Chargés à la demande selon `prompt-version` du provider actif (**default `v1.4`**). Versionnés
dans `ai_evaluations.prompt_version` ; toute modif structurante = nouveau triplet `vX.Y`
(les anciens fichiers restent en place pour permettre un rollback via
`EVAL_PROMPT_VERSION=v1.2` / `v1.3`).

### Architecture des instructions à l'IA (depuis v1.4) — 2 couches, 0 dans le code

Règle d'or : on n'éparpille pas le « comment noter ». Trois niveaux, chacun avec **une seule
source** :

1. **GLOBAL → le system prompt** (`system-vX.Y.md`) : échelle CECRL, note≠niveau, hors-sujet,
   oral = transcription (on n'évalue pas prononciation/débit/durée), méthode, format de sortie.
   Identique pour toutes les tâches.
2. **PAR TÂCHE → `prompts/production-rubrics-<v>.json`** (via `ProductionRubricsProvider`) :
   pour chaque `(épreuve, tâche)`, la rubrique fixe — `criteres` (+ poids), `bareme_note`,
   `descripteurs` A1-C2, `consignes_correcteur`. **C'est LE seul endroit à éditer pour ajuster
   la notation d'une tâche.** Versionné via `rubrics-version` (`EVAL_RUBRICS_VERSION`, défaut
   `v1`), indépendant de `prompt-version`.
3. **CODE → aucune instruction** : `EvaluationPromptBuilder` n'injecte que des données
   (production, durée factuelle, rubrique). La durée EO est une simple ligne
   `DURÉE (indicative) : …` ; l'ordre de l'ignorer vit une seule fois dans le system prompt.

Le user-template v1.4 expose les slots `{CRITERES}`, `{BAREME_NOTE}`, `{DESCRIPTEURS}`,
`{CONSIGNES_CORRECTEUR}` (+ `{CONSIGNE}`, `{PRODUCTION}`, `{DUREE_BLOCK}`). Fallback : si une
tâche n'est pas dans le fichier de rubriques, le builder retombe sur la colonne DB
`production_tasks.criteres_evaluation` (conservée pour compat/réversibilité).

### Historique des versions

- **v1.1** : distinction **note_globale (qualité de la tâche)** vs **niveau_cecrl (compétence
  réelle, peut dépasser le niveau cible)** ; descripteurs CECRL A1-C2 ; champ
  `justification_niveau` (obligatoire) ajouté au tool schema, exposé dans
  `EvaluationResultDto.justificationNiveau` (nullable, rétro-compat v1.0).
- **v1.2** : **règle hors-sujet** — si la production ne traite pas la consigne, l'IA met
  `note_globale=0`, `niveau_cecrl=A1_NON_ATTEINT`, tous les `scores_criteres[].note_sur_20=0`
  et la phrase exacte « Production hors-sujet : la consigne n'a pas été traitée. » dans
  `points_a_ameliorer`. Hors-sujet *partiel* = forte pénalité de pertinence sans annuler la note.
- **v1.3** : **EO évaluée comme du texte transcrit** — l'IA ne note plus prononciation /
  intonation / débit / durée (elle n'a pas l'audio). Les blocs débit/durée Java passent en
  informatif.
- **v1.4** (actif) : **archi rubriques par tâche** (ci-dessus). user-template gagne
  `{BAREME_NOTE}` + `{DESCRIPTEURS}`, la notice de transcription est absorbée dans le system
  prompt, le bloc « débit » est supprimé, la durée devient une donnée factuelle.

Le schéma `tool_use` est inchangé depuis v1.1 (mêmes champs) — aucun changement côté mobile
pour parser l'output.

## Validation et enrichissements serveur

**EE — bornes de mots** (`ProductionEvaluationService.validateTextWordCount`) :

- `mots < task.motsMin` → 400 (trop court, bloquant).
- `task.motsMin ≤ mots ≤ task.motsMax` → OK.
- `task.motsMax < mots ≤ task.motsMax × 1.2` → OK (tolérance) + un avertissement modéré
  ajouté à la correction.
- `mots > task.motsMax × 1.2` → 400 (trop long, bloquant).

Le mobile désactive déjà le bouton « Valider » hors `[motsMin, motsMax × 1.2]` ; le 400
est un garde-fou serveur. Garde-fou absolu indépendant de la tâche :
`props.maxTextWords = 300` (anti-payload géant).

**EO — durée** : aucun blocage. L'utilisateur reçoit toujours une correction IA, même
si la durée est sous la cible voire sous le minimum de 120 s. Trois leviers :

1. `EvaluationPromptBuilder` injecte un `{DUREE_BLOCK}` **factuel** quand
   `duree < task.dureeMaxSec` (`DURÉE (indicative) : …`). **Depuis v1.4 l'IA ne minore plus
   la note pour la durée** (on évalue la transcription comme du texte) ; il reste l'avertissement
   utilisateur (levier 2).
2. `AiEvaluationService.buildAvertissements` ajoute un message orienté utilisateur dans
   `feedback["avertissements"]` (variante plus appuyée si `duree < task.dureeMinSec`).
3. Côté mobile, le chrono EO est codé en couleur (rouge < 120 s / orange < cible /
   vert ≥ cible) avec un hint bienveillant non bloquant si la prise est courte.

**Avertissements (`feedback["avertissements"]`, List<String>)** — construits côté serveur
par `AiEvaluationService.buildAvertissements(sub, task)` AVANT persistance dans
`ai_evaluations.feedback_json`. Pas de table dédiée : la liste vit dans le JSONB du
feedback et remonte au mobile via `EvaluationResultDto.feedback` (Map). Le mobile la lit
sur `EvaluationFeedback.avertissements` et l'affiche dans `AvertissementsCard`.

**Libellés des critères** — l'IA ne renvoie que le `code` (`pertinence`, `coherence`, …)
dans `scores_criteres`. `AiEvaluationService.enrichScoresWithLabels` joint le `label` de la
grille à chaque item avant persistance. Source du label = la rubrique de la tâche
(`production-rubrics-<v>.json`, fallback `production_tasks.criteres_evaluation`), pas de table
parallèle côté mobile. Le mobile (`CriterionRow`) utilise `criterion.label` si présent, sinon retombe
sur une table locale (fallback pour les évaluations antérieures à v1.2).

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

UI bornes & avertissements :

- EE : `MotsCard` colorise le compteur (rouge < min / vert / orange dans la tolérance /
  rouge au-delà de max × 1.2) ; le bouton « Valider » suit la même règle que le backend.
- EO : `_TimerBig` colorise le chrono ; `eo_finished_screen` affiche un hint non
  bloquant si la prise < 120 s mais laisse toujours soumettre.
- Résultats EE+EO : `AvertissementsCard` orange en tête de page (rien affiché si la
  liste est vide).

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
