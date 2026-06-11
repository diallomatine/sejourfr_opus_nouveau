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
  (`rubrics-version`, défaut `v3`) — **source unique de TOUTES les instructions à l'IA**.
  Deux blocs : `commun` (global : `sections` ordonnées `{titre, contenu}` + `few_shot`) et
  `rubrics.<EE|EO>_T<n>` (par tâche : critères+poids+label, barème, descripteurs A1-C2,
  consignes). `getCommun()` + `getTask(épreuve, tâche)`. Clé de lookup dérivée de
  `(épreuve, tâche)` : retire `TCF_` puis suffixe `_T<n>` → `EE_T1`, `EO_T3`. **Plus aucun
  fallback DB `criteres_evaluation`.** Fichier absent/illisible = échec au démarrage (fail-fast).
- **`ProductionRubricsValidator`** (`@EventListener(ApplicationReadyEvent)`) : garde-fou de
  démarrage. Refuse de booter si (a) `commun.sections` vide ou `few_shot` absent, (b) une tâche
  `is_active=TRUE` (EO/EE) n'a pas de rubrique, (c) `Σ poids ≠ 1.0` (±0.001) sur une rubrique,
  ou (d) un `code` n'est pas dans `{pertinence, coherence, lexique, morphosyntaxe}`. Erreurs
  loggées en ERROR `[rubriques]` + `IllegalStateException`.
- `EvaluationPromptBuilder` : **génère** les prompts depuis le JSON, **plus aucun `.md`**.
  `buildSystemPrompt()` = `commun.sections` rendues `# titre\ncontenu` + `few_shot` (identique
  pour toutes les tâches, mis en cache). `buildUserPrompt(...)` = **données seulement** :
  épreuve/tâche, niveau cible + consigne + longueur attendue (DB), contexte (DB), puis
  critères/barème/descripteurs/consignes du bloc tâche, la production, la durée factuelle (EO),
  et la ligne finale « appelle submit_evaluation ». Aucune instruction de notation en dur.
- `AiEvaluationService` (orchestration : prompt + LLM + persistance `AiEvaluation`)
- `ProductionAudioStorageService` (R2 privé + URL signée via `S3Presigner` ; le bean est
  ajouté à `audioquestion/config/CloudflareR2Config.java`)
- `ProductionEvaluationService` (orchestration `submitAndEvaluate` / `retry`) — **pas
  `@Transactional` au niveau orchestration** : chaque étape a son propre tx, ce qui permet
  de tomber en `FAILED` proprement et de reprendre du bon point au retry (skip Whisper si la
  transcription est déjà en base).
- `AdminCalibrationService` (dashboard écart IA vs humain).

## Prompts

### Architecture des instructions à l'IA (depuis v3) — UN seul fichier, 0 dans le code

Règle d'or : **toutes** les instructions à l'IA vivent dans
`prompts/production-rubrics-<version>.json` (piloté par `EVAL_RUBRICS_VERSION`, défaut `v3`).
Le code ne fait que **rendre** ce fichier — aucune instruction de notation en dur, ni dans des
`.md`, ni dans le code.

1. **GLOBAL → `commun`** (rendu dans le **system prompt** par `EvaluationPromptBuilder`) :
   `sections` (liste ordonnée `{titre, contenu}` = rôle, deux dimensions note/niveau, échelle
   CECRL, barème absolu, cohérence note↔niveau, hors-sujet, oral=transcription, longueur,
   méthode, format) + `few_shot` (ancres de calibration production→scores→niveau). Mutualisé :
   le barème absolu, la tolérance transcription orale, la règle de longueur vivent **une seule
   fois** ici ; les blocs par tâche n'y renvoient que par « cf. bloc commun ».
2. **PAR TÂCHE → `rubrics.<EE|EO>_T<n>`** : `criteres` (+ poids + label), `bareme_note` (nuance
   spécifique uniquement), `descripteurs` A1-C2, `consignes_correcteur` (spécifique uniquement).
   Rendus dans le **user message** à côté des données DB.
3. **CODE → aucune instruction, assemblage seulement** : `buildSystemPrompt()` concatène
   `commun.sections` (`# titre\ncontenu`) + `few_shot` (mis en cache). `buildUserPrompt(...)`
   assemble des **données** : épreuve/tâche, `{NIVEAU}` = `production_tasks.niveau_cible`,
   consigne (DB), longueur attendue = `mots_min`-`mots_max` (DB, EE), contexte (DB), critères /
   barème / descripteurs / consignes (fichier), production, durée factuelle (EO), et la ligne
   finale « appelle submit_evaluation ».

**Tool-schema = contrat de sortie, séparé.** `production-evaluation-tool-schema-vX.Y.json` reste
chargé par les clients LLM selon `prompt-version` (défaut `v1.5`) et versionné dans
`ai_evaluations.prompt_version`. Ce n'est PAS une instruction de notation → il ne fond pas dans le
fichier rubriques.

**Rollback** : les prompts désormais inutilisés sont archivés dans
`src/main/resources/prompts/old/` (anciens `system`/`user-template`/`tool-schema` ≤ v1.4,
`production-rubrics-v1/v2.json`, `audio-question-system-v1.md`) — toujours sur le classpath mais
plus chargés. Seuls restent dans `prompts/` : `production-rubrics-v3.json`,
`production-evaluation-tool-schema-v1.5.json`, `audio-question-system-v2.md`,
`audio-question-tool-schema.json`. Revenir en arrière = remonter les fichiers voulus dans
`prompts/` + restaurer le code .md-based + `EVAL_RUBRICS_VERSION=v2`.

La colonne `production_tasks.criteres_evaluation` est **dépréciée** (V428, non lue, nullable).

### `note_globale` calculée serveur (depuis la centralisation rubriques)

`AiEvaluationService` **recalcule** `note_globale = round(Σ note_sur_20[code] × poids[code])`
à partir de `scores_criteres` (LLM) et des poids de la rubrique (arrondi entier le plus proche,
HALF_UP, borné `[0,20]`), puis **écrase** la valeur du LLM avant persistance. La note du LLM
devient *advisory* : un écart `|LLM − serveur| > 3` est loggé en WARN pour calibration. Corrige
l'incohérence observée (global 16/20 alors que les critères étaient à 2-6/20). Le hors-sujet
reste cohérent : tous les critères à 0 → `Σ(0×poids)=0`. Sans rubrique/scores exploitables (cas
limite, tâche désactivée), la note du LLM est conservée (WARN). **Schéma `tool_use` inchangé →
aucun changement mobile.**

### `niveau_cecrl` calculé serveur (le niveau LLM est advisory, jamais affiché)

Comme pour la note, le `niveau_cecrl` **affiché** n'est plus celui du LLM : `AiEvaluationService`
le calcule à partir des **critères porteurs du niveau** (`lexique` + `morphosyntaxe`, configurables
via `niveau-cecrl.source-criteres`). Motivation : le LLM est fiable par critère mais sous-estime le
niveau absolu sur texte court (observé : lexique 16 + morpho 16 → bande B2, mais le LLM renvoie B1).

`competence = moyenne(notes des source-critères)` → bande via les seuils config
(`seuil-b2=15`, `seuil-b1=12`, `seuil-a2=7`) :

| competence | niveau |
|---|---|
| ≥ 15 | B2 |
| 12 – <15 | B1 |
| 7 – <12 | A2 |
| > 0 – <7 | A1 |
| hors-sujet (`note_globale = 0`) | A1_NON_ATTEINT |

Plafond **B2** (cible naturalisation ; C1/C2 non fiables sur T1). Si un critère source manque :
WARN + fallback sur `note_globale` (moyenne pondérée déjà calculée) — jamais de crash. Le niveau
calculé **écrase** `feedback.niveau_cecrl` (persisté) ; le niveau brut du LLM est conservé en
base dans **`ai_evaluations.niveau_cecrl_ia`** (V429, interne, **jamais exposé**) pour mesurer
l'écart. Une divergence ≥ 1 cran IA vs calcul est loggée (sens sous/sur-estimation) et agrégée par
`AdminCalibrationService.niveauStats()` → `GET /api/admin/calibration/stats/niveau`. Seuils
ajustables sans redéploiement. La math (computeNiveau/competence/seuils) vit dans
`ProductionBilanService` ; `AiEvaluationService` la délègue.

### Niveau CECRL : jamais par tâche, seulement au bilan d'épreuve en examen blanc

Décision produit (2026-06-11) : l'IA note mal une production courte isolée (EE T1 = 30-60
mots), donc **aucun niveau CECRL n'est exposé tâche par tâche**, ni en entraînement ni en
examen — le niveau par soumission reste calculé et persisté (`ai_evaluations.niveau_cecrl`)
pour la calibration admin, mais :

- `EvaluationResultDto` ne porte plus que `noteSurVingt` + `feedback` (les champs
  `niveauCecrl`/`justificationNiveau` ont été supprimés) ; `ProductionSubmissionMapper`
  expurge `niveau_cecrl` et `justification_niveau` du feedback avant envoi.
- **Entraînement libre** : note /20 + feedback critères, point final.
- **Examen blanc** (session module EE/EO `slot_number` ou sous-attempt d'un TCF complet) :
  le niveau apparaît au **bilan d'épreuve**, calculé par `ProductionBilanService.bilanEpreuve` =
  moyenne **pondérée** des compétences des 3 tâches (poids croissants `poids-taches`,
  défaut 1/2/3 comme la pondération officielle TCF) → mêmes seuils → plafond B2. Remplace
  l'ancien plancher `min()` des 3 niveaux (une seule éval basse plafonnait l'épreuve).
  Hors-sujet (note 0) = compétence 0 : pénalise sans annuler.
- Exposition : `GET /api/attempts/{attemptId}/production-bilan` → `ProductionBilanResponse
  {attemptId, epreuve, exam, evaluatedCount, expectedCount, moyenneSur20, niveauGlobal}`
  (`niveauGlobal` null hors examen ou tant que les 3 tâches ne sont pas évaluées), et
  `FullTcfExamResponse.SubAttempt.cecrlLevel` (même calcul via `FullTcfExamService`).
  Les fronts ne calculent **plus aucun plancher local**.

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
- **v1.4 / v1.5** : **archi rubriques par tâche** (`.md` system + user-template). user-template
  gagne `{BAREME_NOTE}` + `{DESCRIPTEURS}`, la notice de transcription est absorbée dans le system
  prompt, le bloc « débit » est supprimé, la durée devient une donnée factuelle. v1.5 ajoute le
  contrôle de cohérence note↔niveau + le tool-schema `v1.5`.
- **rubrics v2** : `criteres_evaluation` DB abandonné, rubrique par tâche = source unique du
  « comment noter » (critères/barème/descripteurs/consignes), `note_globale` recalculée serveur.
- **rubrics v3** (actif) : **le fichier devient la source unique de TOUTES les instructions**
  (global + par tâche). Le `commun` (sections + few-shot) est rendu dans le system prompt, le bloc
  tâche dans le user message ; les `.md` system/user-template ne sont **plus lus** (le code ne fait
  qu'assembler le JSON). `EVAL_RUBRICS_VERSION=v3` pilote tout le contenu d'éval ; `prompt-version`
  ne gouverne plus que le tool-schema. Schéma `tool_use` inchangé → aucun changement mobile.

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
grille à chaque item avant persistance. Source du label = **uniquement** la rubrique de la tâche
(`production-rubrics-<v>.json`), pas de table parallèle côté mobile. Codes canoniques :
`pertinence`, `coherence`, `lexique`, `morphosyntaxe` (l'EO n'évalue pas `prononciation`). Le
mobile (`CriterionRow`) utilise `criterion.label` si présent, sinon retombe
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
