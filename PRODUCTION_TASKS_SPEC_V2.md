# SejourFR — Spécifications du module Expression orale & écrite (TCF)

**Version 2** — Intègre les retours sur la robustesse du pipeline IA et la calibration humaine.

> **À l'attention de Claude Code**
> Ce document décrit l'architecture à implémenter pour ajouter la prise en charge des épreuves d'expression orale (EO) et écrite (EE) du TCF IRN. Il s'inscrit dans un backend Spring Boot 4 / Java 21 / PostgreSQL existant qui gère déjà les épreuves QCM (civique + TCF compréhension orale, compréhension écrite, structure de la langue).
>
> **Important** : ne pas régresser l'existant. Toutes les évolutions doivent être additives ou rétro-compatibles via backfill.

---

## 1. Contexte fonctionnel

### Le TCF IRN comporte 4 épreuves obligatoires

| Épreuve | Format | Durée | Évaluation |
|---|---|---|---|
| Compréhension orale (CO) | 25 QCM audio | 20 min | Déterministe (existant) |
| Compréhension écrite (CE) | 25 QCM | 35 min | Déterministe (existant) |
| Expression écrite (EE) | 3 tâches rédactionnelles | 30 min | **IA (nouveau)** |
| Expression orale (EO) | 3 tâches entretien | 10 min | **IA (nouveau)** |

L'épreuve "Structure de la langue" est conservée comme **module d'entraînement bonus** (hors examen blanc TCF IRN officiel, mais utile pour la progression).

### Les 3 tâches du TCF IRN

**Expression orale :**
1. Tâche 1 — Entretien dirigé (3 min) : se présenter, parler de soi
2. Tâche 2 — Jeu de rôle (3,5 min) : situation pratique du quotidien
3. Tâche 3 — Point de vue (3,5 min) : exprimer un avis argumenté

**Expression écrite :**
1. Tâche 1 (60-120 mots) : rédiger un message simple
2. Tâche 2 (120-150 mots) : récit, expérience personnelle
3. Tâche 3 (150-180 mots) : exprimer un point de vue argumenté

---

## 2. Décisions d'architecture validées

### 2.1 Regroupement des épreuves d'un examen TCF blanc

**Pattern : Attempt parent + sous-Attempts.**

- Un examen TCF blanc complet = 1 `Attempt` parent (epreuve = `TCF_COMPLET`) + N `Attempt` enfants liés par `parent_attempt_id`.
- Chaque sous-Attempt porte une épreuve (`TCF_CO`, `TCF_CE`, `TCF_EO`, `TCF_EE`).
- L'utilisateur peut sauter une épreuve : pas de sous-Attempt créé pour celle-ci.
- L'entraînement libre crée un Attempt isolé (`parent_attempt_id = NULL`).
- Le score global du parent est calculé à partir des sous-Attempts (moyenne pondérée ou tableau de niveaux CECRL par compétence).

### 2.2 Pipeline d'évaluation

**Synchrone court terme, refactor async plus tard.**

- Le contrôleur HTTP attend la fin de Whisper + LLM (timeout 60 s).
- Latence attendue : 10-15 s pour 3 min d'audio.
- L'architecture isole le service d'évaluation (`ProductionEvaluationService.evaluate(submissionId)`) pour qu'on puisse plus tard le déporter dans une queue sans casser l'API publique.
- Les statuts intermédiaires (`TRANSCRIBING`, `EVALUATING`) sont présents dans le schéma pour préparer la migration future, mais ne sont pas utilisés en mode synchrone (on passe directement `SUBMITTED` → `EVALUATED` ou `FAILED`).

### 2.3 Robustesse du pipeline IA (NOUVEAU v2)

Le pipeline synchrone est solide **uniquement si** on encaisse les échecs partiels. Trois mécanismes obligatoires :

**a) Retry automatique avec backoff exponentiel**

Chaque appel externe (Whisper, Claude) bénéficie de 2 tentatives automatiques avant de marquer la submission en `FAILED` :
- Tentative 1 → échec → attendre 1 s → Tentative 2 → échec → attendre 2 s → Tentative 3 → échec définitif
- Les erreurs `429 (rate limit)` et `5xx` déclenchent un retry. Les `4xx` (sauf 429) non.
- À chaque appel raté, incrémenter un compteur de retry sur la submission pour le tracking de coût.

**b) Mode JSON structuré pour Claude (pas du prompt-prayer)**

Au lieu de demander "réponds en JSON" dans le prompt et croiser les doigts, **utiliser le mécanisme `tool_use` de l'API Anthropic** :
- Déclarer un outil fictif `submit_evaluation` avec un `input_schema` JSON Schema strict
- Forcer le modèle à appeler cet outil via `tool_choice: { type: "tool", name: "submit_evaluation" }`
- Récupérer le résultat depuis le bloc `tool_use.input` (déjà parsé en objet)
- Garantit un JSON valide à 100 %, plus de parsing manuel ni de regex de "JSON repair"

Exemple de schéma pour `submit_evaluation` (à mettre dans une classe `EvaluationSchema`) :

```json
{
  "type": "object",
  "required": ["note_globale", "niveau_cecrl", "scores_criteres", "points_forts", "points_a_ameliorer"],
  "properties": {
    "note_globale": { "type": "number", "minimum": 0, "maximum": 20 },
    "niveau_cecrl": {
      "type": "string",
      "enum": ["A1_NON_ATTEINT", "A1", "A2", "B1", "B2", "C1", "C2"]
    },
    "scores_criteres": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["code", "note_sur_20", "commentaire"],
        "properties": {
          "code": { "type": "string" },
          "note_sur_20": { "type": "number", "minimum": 0, "maximum": 20 },
          "commentaire": { "type": "string" }
        }
      }
    },
    "points_forts": { "type": "array", "items": { "type": "string" } },
    "points_a_ameliorer": { "type": "array", "items": { "type": "string" } },
    "suggestions": { "type": "array", "items": { "type": "string" } },
    "exemples_corriges": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "original": { "type": "string" },
          "corrige": { "type": "string" },
          "explication": { "type": "string" }
        }
      }
    }
  }
}
```

**c) Endpoint de retry manuel pour les submissions FAILED**

`POST /api/production-submissions/{id}/retry` — relance le pipeline pour une submission échouée. Vérifications :
- Submission appartient à l'utilisateur connecté
- Statut actuel = `FAILED`
- Pas plus de 3 retries cumulés (anti-abus)

L'app mobile affiche un bouton "Réessayer l'évaluation" sur les submissions en `FAILED`, plutôt qu'une erreur silencieuse.

### 2.4 Whisper en mode "transcription littérale" (NOUVEAU v2)

**Problème** : Whisper a tendance à **auto-corriger** les fautes de prononciation à l'écrit. Un B1 ouest-africain qui dit "j'habites" sera retranscrit "j'habite" — le LLM ne verra jamais l'erreur et notera trop haut.

**Solution à investiguer dès le premier sprint** :

Passer un `prompt` à Whisper qui amorce une transcription littérale, par exemple :

```
prompt: "Transcription littérale d'un apprenant de français langue étrangère. Conserver les hésitations, les répétitions, et les éventuelles fautes grammaticales telles que prononcées."
```

À tester sur un échantillon de 10-20 enregistrements de non-natifs (idéalement issus de ton public cible) **avant d'avoir trop d'évaluations en prod**. Si Whisper continue à corriger malgré le prompt, deux options :
- Accepter la limite et ajuster le prompt LLM en conséquence ("attention : la transcription peut avoir lissé certaines fautes")
- Évaluer un modèle alternatif (AssemblyAI, Deepgram) pour la transcription "verbatim"

À documenter dans une issue technique dès le sprint 1.

---

## 3. Modèle de données

### 3.1 Évolutions de tables existantes

#### Table `attempts`

Ajouter deux colonnes :

| Colonne | Type | Nullable | Description |
|---|---|---|---|
| `epreuve` | VARCHAR(20) | NON | Nature de l'épreuve |
| `parent_attempt_id` | UUID | OUI | FK vers `attempts(id)` ON DELETE CASCADE |

**Valeurs autorisées pour `epreuve`** (CHECK constraint) :
`CIVIQUE`, `TCF_CO`, `TCF_CE`, `TCF_STRUCTURE`, `TCF_EO`, `TCF_EE`, `TCF_COMPLET`.

**Backfill** : `UPDATE attempts SET epreuve = 'CIVIQUE' WHERE epreuve IS NULL;` puis passer la colonne en NOT NULL.

**Index** : `CREATE INDEX idx_attempts_parent ON attempts(parent_attempt_id) WHERE parent_attempt_id IS NOT NULL;`

> Note : ne pas toucher à la colonne `mode` existante (`ENTRAINEMENT`/`EXAMEN`/`REVISION`). Elle reste orthogonale à `epreuve`.

---

### 3.2 Nouvelles tables

#### Table `production_tasks`

Équivalent de `questions` pour les épreuves productives. Une tâche est une consigne rejouable à l'infini.

| Colonne | Type | Nullable | Description |
|---|---|---|---|
| `id` | UUID PK | NON | `gen_random_uuid()` |
| `epreuve` | VARCHAR(20) | NON | `TCF_EO` ou `TCF_EE` |
| `tache_numero` | SMALLINT | NON | 1, 2 ou 3 |
| `niveau_cible` | VARCHAR(4) | NON | `A2`, `B1` ou `B2` |
| `consigne` | TEXT | NON | Texte affiché à l'utilisateur |
| `contexte` | TEXT | OUI | Scénario du jeu de rôle, contexte additionnel |
| `duree_max_sec` | INTEGER | OUI | Pour l'oral uniquement |
| `mots_min` | INTEGER | OUI | Pour l'écrit uniquement |
| `mots_max` | INTEGER | OUI | Pour l'écrit uniquement |
| `criteres_evaluation` | JSONB | NON | Grille passée au LLM, default `'{}'::jsonb` |
| `is_active` | BOOLEAN | NON | Default `FALSE` (validation manuelle avant publication) |
| `created_at` | TIMESTAMPTZ | NON | Default `NOW()` |

**Contraintes** :
- `epreuve IN ('TCF_EO', 'TCF_EE')`
- `tache_numero BETWEEN 1 AND 3`
- `niveau_cible IN ('A2', 'B1', 'B2')`
- Cohérence audio/texte : si `epreuve = 'TCF_EO'` alors `duree_max_sec NOT NULL` et `mots_min IS NULL` ; sinon inverse.

**Index** : `(epreuve, niveau_cible, is_active)`.

**Format de `criteres_evaluation`** (exemple) :

```json
{
  "criteres": [
    { "code": "pertinence",      "label": "Pertinence du contenu",   "poids": 0.30 },
    { "code": "grammaire",       "label": "Correction grammaticale", "poids": 0.25 },
    { "code": "vocabulaire",     "label": "Richesse lexicale",       "poids": 0.20 },
    { "code": "coherence",       "label": "Cohérence du discours",   "poids": 0.15 },
    { "code": "prononciation",   "label": "Prononciation",           "poids": 0.10 }
  ],
  "niveau_attendu": "B1",
  "consignes_correcteur": "Évaluer en tant qu'examinateur TCF officiel."
}
```

---

#### Table `production_submissions`

La trace de ce que l'utilisateur a rendu. Une submission est rattachée à un Attempt (sous-Attempt pour un examen blanc complet).

| Colonne | Type | Nullable | Description |
|---|---|---|---|
| `id` | UUID PK | NON | |
| `attempt_id` | UUID FK | NON | Vers `attempts(id)` ON DELETE CASCADE |
| `production_task_id` | UUID FK | NON | Vers `production_tasks(id)` |
| `user_id` | UUID FK | NON | Vers `users(id)` (dénormalisé pour les requêtes rapides) |
| `submitted_at` | TIMESTAMPTZ | NON | Default `NOW()` |
| `media_url` | VARCHAR(500) | OUI | URL S3 de l'audio (EO uniquement) |
| `media_duration_sec` | INTEGER | OUI | Durée réelle de l'audio |
| `texte_soumis` | TEXT | OUI | Texte rédigé (EE uniquement) |
| `mots_count` | INTEGER | OUI | Compteur de mots (EE) |
| `statut` | VARCHAR(20) | NON | Voir ci-dessous |
| `retry_count` | SMALLINT | NON | Default 0, max 3 (NOUVEAU v2) |
| `erreur_message` | TEXT | OUI | Si `statut = 'FAILED'` |
| `created_at` | TIMESTAMPTZ | NON | Default `NOW()` |
| `updated_at` | TIMESTAMPTZ | NON | Default `NOW()` |

**Statuts** (CHECK) :
`SUBMITTED`, `TRANSCRIBING`, `EVALUATING`, `EVALUATED`, `FAILED`.

**Contraintes** :
- Cohérence audio/texte : exactement une des deux colonnes `media_url` / `texte_soumis` est remplie selon l'épreuve de la task référencée.
- `retry_count BETWEEN 0 AND 3`

**Index** :
- `(attempt_id)` pour récupérer toutes les submissions d'un attempt
- `(user_id, submitted_at DESC)` pour l'historique utilisateur
- `(statut)` partiel sur les non-`EVALUATED` pour les jobs de reprise

---

#### Table `transcriptions`

Uniquement pour l'EO. Séparée de `production_submissions` pour permettre la re-transcription et le versioning.

| Colonne | Type | Nullable | Description |
|---|---|---|---|
| `id` | UUID PK | NON | |
| `submission_id` | UUID FK | NON | Vers `production_submissions(id)` ON DELETE CASCADE |
| `texte` | TEXT | NON | Transcription brute |
| `langue_detectee` | VARCHAR(8) | OUI | Code ISO (ex: `fr`) |
| `modele_utilise` | VARCHAR(40) | NON | Ex: `whisper-1` |
| `prompt_utilise` | TEXT | OUI | Prompt Whisper utilisé (mode littéral, v2) |
| `audio_duration_sec` | INTEGER | OUI | Durée traitée par Whisper |
| `cout_estime_centimes` | INTEGER | OUI | En centimes d'€, pour le tracking financier |
| `created_at` | TIMESTAMPTZ | NON | Default `NOW()` |

**Index** : `(submission_id)`.

> Une submission peut potentiellement avoir plusieurs transcriptions si on re-transcrit (ex: changement de modèle). Mais en MVP, on en garde une seule (la dernière).

---

#### Table `ai_evaluations`

Résultat de l'analyse par le LLM. Une submission peut avoir plusieurs évaluations (re-évaluation, A/B test de prompts, etc.).

| Colonne | Type | Nullable | Description |
|---|---|---|---|
| `id` | UUID PK | NON | |
| `submission_id` | UUID FK | NON | Vers `production_submissions(id)` ON DELETE CASCADE |
| `modele_utilise` | VARCHAR(40) | NON | Ex: `claude-sonnet-4` |
| `prompt_version` | VARCHAR(20) | NON | Versioning des prompts (ex: `v1.0`) |
| `note_sur_20` | DECIMAL(4,1) | OUI | Ex: 14.5 |
| `niveau_cecrl` | VARCHAR(20) | OUI | `A1_NON_ATTEINT`, `A1`, `A2`, `B1`, `B2`, `C1`, `C2` |
| `feedback_json` | JSONB | NON | Détail structuré (voir ci-dessous) |
| `tokens_input` | INTEGER | OUI | Pour le tracking de coût |
| `tokens_output` | INTEGER | OUI | |
| `cout_estime_centimes` | INTEGER | OUI | En centimes d'€ |
| `nb_retries` | SMALLINT | NON | Default 0, nombre de retries avant succès (v2) |
| `evaluated_at` | TIMESTAMPTZ | NON | Default `NOW()` |

**Index** :
- `(submission_id, evaluated_at DESC)` pour récupérer la dernière éval

**Format de `feedback_json`** (à respecter par le LLM via le schéma tool_use) :

```json
{
  "note_globale": 14.5,
  "niveau_cecrl": "B1",
  "scores_criteres": [
    { "code": "pertinence",     "note_sur_20": 16, "commentaire": "..." },
    { "code": "grammaire",      "note_sur_20": 12, "commentaire": "..." },
    { "code": "vocabulaire",    "note_sur_20": 14, "commentaire": "..." },
    { "code": "coherence",      "note_sur_20": 15, "commentaire": "..." }
  ],
  "points_forts": [
    "Bonne utilisation du passé composé",
    "Vocabulaire varié sur le thème du travail"
  ],
  "points_a_ameliorer": [
    "Accord des participes passés avec 'avoir'",
    "Confusion entre 'depuis' et 'pendant'"
  ],
  "suggestions": [
    "Réviser la règle d'accord du participe passé avec COD antéposé",
    "Pratiquer les indicateurs temporels"
  ],
  "exemples_corriges": [
    {
      "original": "Les livres que j'ai lu",
      "corrige":  "Les livres que j'ai lus",
      "explication": "Accord avec le COD 'que' placé avant le verbe"
    }
  ]
}
```

---

#### Table `human_calibration_notes` (NOUVEAU v2)

Permet de comparer les notes IA à des références humaines pour calibrer le système.

| Colonne | Type | Nullable | Description |
|---|---|---|---|
| `id` | UUID PK | NON | |
| `submission_id` | UUID FK | NON | Vers `production_submissions(id)` |
| `evaluator_user_id` | UUID FK | NON | Vers `users(id)` (admin ou prof partenaire) |
| `note_humaine_sur_20` | DECIMAL(4,1) | NON | |
| `niveau_cecrl_humain` | VARCHAR(20) | NON | |
| `commentaires` | TEXT | OUI | Notes libres de l'évaluateur |
| `ecart_note` | DECIMAL(4,1) | OUI | Calculé : `note_humaine - note_ai` (dernière éval) |
| `created_at` | TIMESTAMPTZ | NON | Default `NOW()` |

**Index** : `(submission_id)`, `(evaluator_user_id, created_at DESC)`.

**Usage** :
- L'admin sélectionne 50-100 submissions à annoter, idéalement réparties sur tous les niveaux.
- Un dashboard admin affiche l'écart moyen, l'écart-type, et les cas où l'IA s'écarte de plus de 3 points.
- Quand l'écart devient stable et faible (< 1,5 point en moyenne, < 5 % d'écarts > 3 points), on peut affirmer que l'évaluation IA est fiable.
- Tant que la calibration n'est pas validée, afficher un disclaimer dans l'app : "Cette évaluation est indicative et peut différer de l'évaluation officielle."

---

### 3.3 Diagramme des nouvelles relations

```
users
  ├─ attempts (parent)
  │    ├─ attempts (enfants, par épreuve)
  │    │    └─ production_submissions
  │    │         ├─ transcriptions (EO uniquement)
  │    │         ├─ ai_evaluations (1..N)
  │    │         └─ human_calibration_notes (0..N, v2)
  │    └─ attempt_questions (existant, pour QCM)

production_tasks (catalogue de consignes, indépendant des attempts)
```

---

## 4. Migrations Flyway

Créer **une seule migration** `V<N>__add_production_tasks.sql` où `<N>` est le prochain numéro disponible.

Ordre des opérations :

1. `ALTER TABLE attempts` : ajouter `epreuve` (nullable au début), ajouter `parent_attempt_id` + FK + index
2. `UPDATE attempts SET epreuve = 'CIVIQUE'` pour le backfill
3. `ALTER TABLE attempts ALTER COLUMN epreuve SET NOT NULL`
4. `ALTER TABLE attempts ADD CONSTRAINT chk_attempts_epreuve CHECK (...)`
5. `CREATE TABLE production_tasks ...`
6. `CREATE TABLE production_submissions ...`
7. `CREATE TABLE transcriptions ...`
8. `CREATE TABLE ai_evaluations ...`
9. `CREATE TABLE human_calibration_notes ...` (v2)
10. Tous les index

---

## 5. Entités JPA

### Conventions du projet (à respecter)

- Packages flat sous `com.sejourfr.app.{controller, service, repository, entity, dto, enums, security, config}`.
- Entités : classes avec annotations JPA.
- DTOs : Java records.
- Enums : dans le package `enums`.
- Repositories : interfaces étendant `JpaRepository<Entity, UUID>`.

### Enums à créer

```java
package com.sejourfr.app.enums;

public enum EpreuveType {
    CIVIQUE, TCF_CO, TCF_CE, TCF_STRUCTURE, TCF_EO, TCF_EE, TCF_COMPLET
}

public enum NiveauCecrl {
    A1_NON_ATTEINT, A1, A2, B1, B2, C1, C2
}

public enum SubmissionStatut {
    SUBMITTED, TRANSCRIBING, EVALUATING, EVALUATED, FAILED
}
```

### Entités principales

- **`ProductionTask`** : mapping direct, `@JdbcTypeCode(SqlTypes.JSON)` pour `criteres_evaluation`.
- **`ProductionSubmission`** : `@ManyToOne` vers `Attempt`, `ProductionTask`, `User`. `@OneToOne` vers `Transcription`. `@OneToMany` vers `AiEvaluation` et `HumanCalibrationNote`.
- **`Transcription`** : `@OneToOne` vers `ProductionSubmission`.
- **`AiEvaluation`** : `@ManyToOne` vers `ProductionSubmission`.
- **`HumanCalibrationNote`** (v2) : `@ManyToOne` vers `ProductionSubmission` et `User`.
- **`Attempt` (modifié)** : ajouter `EpreuveType epreuve` et `@ManyToOne Attempt parentAttempt` + `@OneToMany List<Attempt> subAttempts`.

---

## 6. Services

### 6.1 `WhisperTranscriptionService`

```
Transcription transcribe(UUID submissionId)
```

Comportement :
1. Récupère la submission, vérifie qu'elle a une `media_url`.
2. Télécharge l'audio depuis S3 (stream).
3. Appelle `POST /v1/audio/transcriptions` (modèle `whisper-1`, langue `fr`, format `verbose_json`).
4. **Passe le `prompt` de transcription littérale** (v2, voir 2.4).
5. Persiste une `Transcription` avec le `prompt_utilise`.
6. Met à jour `submission.statut = 'EVALUATING'`.

**Retry** : 2 tentatives auto avec backoff (v2). Si toutes échouent, lever une exception qui sera attrapée par l'orchestrateur.

Configuration :
- Clé API dans `application.yml` (`openai.api-key`).
- Client HTTP : `RestClient` (Spring Boot 4).
- Timeout : 60 s.

### 6.2 `AiEvaluationService`

```
AiEvaluation evaluate(UUID submissionId)
```

Comportement :
1. Récupère la submission + la task + la transcription/texte.
2. Construit la requête Claude avec :
   - Système : rôle d'examinateur TCF
   - Message utilisateur : consigne + production
   - **`tools`** : déclaration de l'outil `submit_evaluation` avec son `input_schema` (v2)
   - **`tool_choice`** : forcer l'appel à `submit_evaluation` (v2)
3. Récupère le résultat depuis le bloc `tool_use.input` (déjà parsé en JSON valide).
4. Persiste une `AiEvaluation`.
5. Met à jour `submission.statut = 'EVALUATED'`.

**Retry** : 2 tentatives auto avec backoff (v2). Incrémenter `nb_retries` à chaque retry réussi.

### 6.3 `ProductionEvaluationService` (orchestration)

```
ProductionSubmission submitAndEvaluate(UUID userId, UUID taskId, UUID attemptId, MultipartFile audio OR String texte)
ProductionSubmission retry(UUID submissionId, UUID userId)   // v2
```

Comportement de `submitAndEvaluate` :
1. Valide la submission (durée audio, nombre de mots, etc.).
2. Upload S3 si audio.
3. Crée la submission en `SUBMITTED`.
4. Appelle `WhisperTranscriptionService` (si EO) puis `AiEvaluationService`.
5. Si tout réussit → `EVALUATED`, retourne avec l'évaluation.
6. Si échec → `FAILED` avec `erreur_message`, retourne sans évaluation.

Comportement de `retry` :
1. Vérifie que la submission appartient bien à `userId`.
2. Vérifie `statut = 'FAILED'` et `retry_count < 3`.
3. Incrémente `retry_count`.
4. Relance le pipeline depuis le bon point (transcription manquante → repart de Whisper ; transcription OK mais évaluation KO → repart de l'évaluation, économie de coût).

---

## 7. Prompt LLM

Le prompt est désormais **simplifié** car le format JSON est garanti par le mécanisme `tool_use`. On se concentre sur la qualité de l'évaluation.

### Structure du prompt système

```
Tu es un examinateur officiel du TCF IRN (Test de Connaissance du Français pour
l'Intégration, la Résidence et la Nationalité). Tu évalues les productions
{orales|écrites} de candidats selon le Cadre Européen Commun de Référence pour
les Langues (CECRL).

Tes principes d'évaluation :
- Sois juste, précis, et constructif.
- Évalue ce qui est produit, pas ce que tu imagines pouvoir être produit.
- Identifie de vrais points forts (pas de compliment de courtoisie).
- Sois explicite sur les erreurs : cite-les littéralement et corrige-les.
- Adapte ton niveau d'exigence au niveau cible (A2 ≠ B1 ≠ B2).

Tu utiliseras l'outil submit_evaluation pour structurer ta réponse.
```

### Structure du prompt utilisateur

```
ÉPREUVE : Expression {orale|écrite}, tâche {N}
NIVEAU CIBLE : {A2|B1|B2}

CONSIGNE DONNÉE AU CANDIDAT :
"{consigne}"

{contexte_si_present}

PRODUCTION DU CANDIDAT :
"{transcription_ou_texte}"

{si_transcription_litterale}
Note : la transcription provient d'un système automatique configuré en mode
littéral. Elle peut contenir des erreurs grammaticales reflétant la production
orale réelle du candidat (ex: "j'habites", "les voitures rouge"). Tiens compte
de ces erreurs dans ton évaluation.
{/si_transcription_litterale}

Évalue cette production en utilisant l'outil submit_evaluation.
```

Versionner ce prompt dans une classe `PromptTemplates` avec `version = "v1.0"`. Toute modification = nouvelle version, tracée dans `ai_evaluations.prompt_version`.

---

## 8. Endpoints REST

### Routes à créer

| Méthode | Chemin | Description |
|---|---|---|
| `GET` | `/api/production-tasks?epreuve=TCF_EO&niveau=B1` | Liste des tâches disponibles |
| `GET` | `/api/production-tasks/{id}` | Détail d'une tâche |
| `POST` | `/api/production-submissions` | Soumettre une production (multipart audio ou JSON texte) |
| `POST` | `/api/production-submissions/{id}/retry` | **Retry d'une submission FAILED (v2)** |
| `GET` | `/api/production-submissions/{id}` | Récupérer une submission + son évaluation |
| `GET` | `/api/users/me/production-submissions?epreuve=TCF_EO` | Historique de l'utilisateur |

### Endpoints admin (v2)

| Méthode | Chemin | Description |
|---|---|---|
| `GET` | `/api/admin/calibration/submissions?status=evaluated&hasHumanNote=false` | Submissions à annoter |
| `POST` | `/api/admin/calibration/submissions/{id}/human-note` | Soumettre une note humaine |
| `GET` | `/api/admin/calibration/stats` | Dashboard : écart moyen, écart-type, % d'écarts > 3 points |

### DTOs (records)

```java
public record ProductionTaskDto(
    UUID id, EpreuveType epreuve, int tacheNumero, String niveauCible,
    String consigne, String contexte,
    Integer dureeMaxSec, Integer motsMin, Integer motsMax
) {}

public record ProductionSubmissionDto(
    UUID id, UUID attemptId, UUID productionTaskId,
    String statut, String mediaUrl, String texteSoumis,
    Integer motsCount, Integer mediaDurationSec,
    Integer retryCount,                // v2
    String erreurMessage,              // v2 (si FAILED)
    Instant submittedAt,
    EvaluationResultDto evaluation
) {}

public record EvaluationResultDto(
    BigDecimal noteSurVingt, String niveauCecrl,
    Map<String, Object> feedback
) {}

public record HumanCalibrationNoteDto(   // v2
    UUID submissionId,
    BigDecimal noteHumaineSurVingt,
    String niveauCecrlHumain,
    String commentaires
) {}
```

---

## 9. UX de latence côté front (NOUVEAU v2)

Le pipeline synchrone bloque le client 10 à 20 secondes. Une UX bien faite rend ce temps acceptable. **Le front doit afficher des étapes textuelles qui progressent** au lieu d'un simple spinner.

### Étapes à afficher côté mobile et web

Pendant l'attente de la réponse `POST /api/production-submissions` :

```
00:00 → "Envoi de ton enregistrement…"
00:02 → "Transcription en cours…" (avec icône waveform)
00:08 → "Analyse pédagogique…" (avec icône Brain)
00:14 → "Préparation de ton bilan…"
00:18 → Affichage du résultat
```

Le timing est **simulé côté front** (les étapes défilent à des intervalles prédéfinis, indépendamment de l'avancée réelle du backend). Si le backend répond plus vite que prévu → on saute directement à l'étape suivante. Si plus lent → on bloque sur la dernière étape avec un texte rassurant ("Encore quelques secondes…").

En cas de `FAILED` : afficher un message clair + bouton "Réessayer l'évaluation" qui appelle l'endpoint de retry.

Cette UX est plus déterminante pour la satisfaction utilisateur que la migration en async.

---

## 10. Configuration

### `application.yml` (sections à ajouter)

```yaml
openai:
  api-key: ${OPENAI_API_KEY}
  whisper:
    model: whisper-1
    timeout-seconds: 60
    literal-mode-prompt: >
      Transcription littérale d'un apprenant de français langue étrangère.
      Conserver les hésitations, les répétitions, et les éventuelles fautes
      grammaticales telles que prononcées.
    max-retries: 2
    retry-backoff-ms: 1000

anthropic:
  api-key: ${ANTHROPIC_API_KEY}
  model: claude-sonnet-4
  timeout-seconds: 60
  max-tokens: 2000
  max-retries: 2
  retry-backoff-ms: 1000

storage:
  audio:
    s3-bucket: ${AUDIO_BUCKET:sejourfr-audio-dev}
    presigned-url-expiry-minutes: 15

production-evaluation:
  max-audio-duration-seconds: 300
  max-text-words: 300
  cost-tracking-enabled: true
  max-retries-per-submission: 3
```

### Variables d'environnement requises

- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `AUDIO_BUCKET`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`

---

## 11. Sécurité et freemium

### Règles d'accès (Premium uniquement pour le MVP)

- Les endpoints `/api/production-submissions` sont **réservés aux utilisateurs Premium**.
- En version gratuite : autoriser **2 submissions par utilisateur sur l'EO et 2 sur l'EE** (à vie) pour la démo.

### Rate limiting

- Max 10 submissions / heure / utilisateur.
- Max 50 / jour.

### RGPD

- L'audio est stocké en S3 privé, URL signée 15 min.
- Suppression du compte utilisateur → suppression cascade des audios + transcriptions + évaluations.
- Mention CGU : "Votre voix est transmise à OpenAI pour transcription et à Anthropic pour évaluation. Aucune donnée n'est utilisée pour l'entraînement de modèles."

---

## 12. Tests à écrire

### Tests unitaires

- `WhisperTranscriptionServiceTest` : mock OpenAI, vérifie parsing + retry
- `AiEvaluationServiceTest` : mock Claude, vérifie le tool_use parsing + retry + gestion d'erreur
- `ProductionEvaluationServiceTest` : orchestration end-to-end avec mocks
- `ProductionSubmissionRetryTest` (v2) : retry depuis FAILED, anti-abus 3 max

### Tests d'intégration

- `ProductionSubmissionControllerIT` : upload audio test → submission créée → évaluation présente
- Test du quota freemium
- Test du regroupement parent / sous-attempts
- Test du flow FAILED → retry → EVALUATED (v2)

### Données de test

Créer des `production_tasks` de seed dans une migration `V<N+1>__seed_production_tasks.sql` :
- 3 tâches EO par niveau (A2, B1, B2) = 9 tâches
- 3 tâches EE par niveau = 9 tâches
- Total : 18 tâches seed

---

## 13. Ordre de livraison suggéré

Pour Claude Code, livrer dans cet ordre :

1. **Migration Flyway** complète + backfill
2. **Enums** + **entités JPA** + **repositories**
3. **DTOs** + mappers
4. **Services bas niveau** : `WhisperTranscriptionService`, `AiEvaluationService` (avec retry + tool_use)
5. **Service d'orchestration** : `ProductionEvaluationService` (avec méthode `retry`)
6. **Contrôleurs REST** + validation + endpoint retry
7. **Tests unitaires** des services
8. **Tests d'intégration** des endpoints
9. **Seed data** : 18 tâches d'exemple
10. **Documentation OpenAPI** mise à jour
11. **Endpoints admin de calibration** (peut être livré dans un second lot)

---

## 14. Hors-périmètre de cette étape

- ❌ Pipeline asynchrone (queue, polling, WebSocket)
- ❌ Évaluation phonétique fine (Azure Speech, wav2vec2)
- ❌ A/B test automatique de modèles LLM
- ❌ Console admin React pour gérer les `production_tasks` (sera fait dans une étape ultérieure)
- ❌ Recommandations d'exercices personnalisées post-évaluation (à concevoir séparément)

---

## 15. Points d'attention

- **Coût API** : à chaque submission, on dépense ~0,02 € (Whisper + Claude). Logger systématiquement via `cout_estime_centimes`.
- **Idempotence** : implémenter un header `X-Idempotency-Key` pour éviter la double facturation en cas de double-clic.
- **Validation de l'audio** : refuser > 25 Mo et > 5 min de durée. Détecter le format avec `ffprobe` ou `tika`.
- **Sanitization du texte** : trim, NFC, refuser < 10 mots.
- **Fallback LLM** : si Claude échoue après 2 retries, marquer `FAILED` avec message clair. Pas de note bidon.
- **Calibration progressive** (v2) : commencer à collecter des notes humaines dès la mise en prod. Cible : 50 notes en 2 semaines pour première mesure d'écart.

---

## 16. Glossaire

- **CECRL** : Cadre Européen Commun de Référence pour les Langues (A1, A2, B1, B2, C1, C2)
- **TCF IRN** : Test de Connaissance du Français — Intégration, Résidence, Nationalité
- **CSP** : Carte de Séjour Pluriannuelle (niveau A2 requis depuis 2026)
- **CR** : Carte de Résident (niveau B1)
- **NAT** : Naturalisation française (niveau B2)
- **EO / EE** : Expression Orale / Expression Écrite
- **CO / CE** : Compréhension Orale / Compréhension Écrite
- **tool_use** : mécanisme de l'API Anthropic permettant de forcer un format de réponse structuré via un schéma JSON
