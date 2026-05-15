# 00 — Vue d'ensemble : Pipeline de génération de questions audio CO

## 1. Objectif

Permettre à un administrateur de SejourFR de générer **une question de Compréhension Orale (CO)** complète en un clic depuis l'espace d'administration. Le système orchestre la génération du contenu (Anthropic Claude), la synthèse vocale (Azure Speech), le stockage du fichier audio (Cloudflare R2) et la prévisualisation par l'admin avant validation manuelle.

## 2. Décisions clés (figées)

| Décision | Valeur |
|---|---|
| Mode de génération | **Synchrone** (l'admin attend 10-30s la réponse complète) |
| Workflow | **Prévisualisation obligatoire** : l'admin écoute et lit avant validation |
| Volume | **1 question par clic** (pas de génération en lot pour le MVP) |
| Statut intermédiaire | `DRAFT` (visible uniquement de l'admin, non utilisable en examen) |
| Statut final après validation | `ACTIVE` (devient utilisable par les utilisateurs) |
| Gestion des clés API | **Variables d'environnement backend** uniquement |
| Stockage audio | **Cloudflare R2** (compatible API S3) |
| TTS retenu | **Azure Speech Service** (voix neural FR-FR) |
| LLM retenu | **Anthropic Claude Sonnet 4.6** (suffisant pour ce cas d'usage) |
| Stack backend | **Spring Boot 3.x + Java 17+ + PostgreSQL** |

## 3. Flux fonctionnel complet

```
┌──────────────────────────────────────────────────────────────────────┐
│                         ESPACE ADMIN (Angular)                        │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  [Bouton : Générer une question audio]                                │
│        │                                                              │
│        ▼                                                              │
│  Formulaire : niveau, thème (opt), type (opt), compétence (opt)       │
│        │                                                              │
│        ▼                                                              │
│  Spinner "Génération en cours…" (10-30 secondes)                      │
│        │                                                              │
│        ▼                                                              │
│  Écran de prévisualisation :                                          │
│   - Player audio (lecture du MP3)                                     │
│   - Transcript en clair                                               │
│   - Énoncé de la question                                             │
│   - 4 choix avec la bonne réponse soulignée                           │
│   - Explication                                                       │
│   - Métadonnées (durée, voix, coût)                                   │
│   - Boutons : [Valider et activer] [Rejeter et régénérer] [Annuler]   │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      BACKEND SPRING BOOT                              │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  POST /api/admin/audio-questions/generate                             │
│   {                                                                   │
│     "niveau": "B1", "theme": "santé",                                 │
│     "type_souhaite": "dialogue",                                      │
│     "competence_visee": "co_detail_specifique"                        │
│   }                                                                   │
│                                                                       │
│  ┌─ STEP 1 : Génération du contenu via Anthropic ─────────────┐       │
│  │   POST api.anthropic.com/v1/messages                       │       │
│  │   → JSON strict : transcript + SSML + question + choices   │       │
│  │   → Validation du schéma (sinon erreur)                    │       │
│  └────────────────────────────────────────────────────────────┘       │
│                              │                                        │
│  ┌─ STEP 2 : Synthèse vocale via Azure Speech ────────────────┐       │
│  │   POST <region>.tts.speech.microsoft.com/cognitiveservices │       │
│  │   /v1 (Body = SSML)                                        │       │
│  │   → Stream MP3 (binaire)                                   │       │
│  │   → Sauvegarde temporaire en mémoire (max 5 MB)            │       │
│  └────────────────────────────────────────────────────────────┘       │
│                              │                                        │
│  ┌─ STEP 3 : Upload sur Cloudflare R2 ────────────────────────┐       │
│  │   PUT s3://<bucket>/audio/<uuid>.mp3                       │       │
│  │   → URL publique générée                                   │       │
│  └────────────────────────────────────────────────────────────┘       │
│                              │                                        │
│  ┌─ STEP 4 : Persistance en base (statut DRAFT) ──────────────┐       │
│  │   INSERT INTO medias (id, type, url, ...)                  │       │
│  │   INSERT INTO questions (..., is_active = false,           │       │
│  │                          status = 'DRAFT')                 │       │
│  │   INSERT INTO choices (...)                                │       │
│  └────────────────────────────────────────────────────────────┘       │
│                              │                                        │
│  Retour 200 : objet complet QuestionPreviewDto                        │
│                                                                       │
│  ──────────────────────────────────────────────────────────────       │
│                                                                       │
│  PATCH /api/admin/audio-questions/{id}/validate                       │
│   → Passe la question de DRAFT à ACTIVE                               │
│                                                                       │
│  DELETE /api/admin/audio-questions/{id}                               │
│   → Supprime la question DRAFT + supprime le MP3 de R2                │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

## 4. Architecture technique

### 4.1 Modules à créer dans le backend

```
src/main/java/com/sejourfr/
├── audioquestion/
│   ├── controller/
│   │   └── AudioQuestionAdminController.java
│   ├── service/
│   │   ├── AudioQuestionGenerationService.java
│   │   ├── AnthropicClient.java
│   │   ├── AzureSpeechClient.java
│   │   └── CloudflareR2Client.java
│   ├── dto/
│   │   ├── GenerateAudioQuestionRequest.java
│   │   ├── QuestionPreviewDto.java
│   │   ├── AnthropicResponseDto.java
│   │   └── ...
│   ├── domain/
│   │   ├── AudioQuestionGenerationLog.java (entité d'audit)
│   │   └── QuestionStatus.java (enum DRAFT, ACTIVE, ARCHIVED)
│   ├── exception/
│   │   ├── AnthropicGenerationException.java
│   │   ├── AzureSpeechException.java
│   │   ├── R2UploadException.java
│   │   └── ContentValidationException.java
│   └── config/
│       ├── AnthropicProperties.java
│       ├── AzureSpeechProperties.java
│       └── CloudflareR2Properties.java
```

### 4.2 Évolutions de schéma (DB)

Une seule migration nécessaire (V14) :

```sql
-- Ajout du statut sur les questions (pour distinguer DRAFT / ACTIVE / ARCHIVED)
ALTER TABLE questions ADD COLUMN IF NOT EXISTS status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE';
ALTER TABLE questions ADD CONSTRAINT chk_question_status CHECK (status IN ('DRAFT', 'ACTIVE', 'ARCHIVED'));
CREATE INDEX IF NOT EXISTS idx_questions_status ON questions(status);

-- Table d'audit pour traçabilité (qui a généré quoi, combien ça a coûté)
CREATE TABLE IF NOT EXISTS audio_question_generation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID REFERENCES questions(id) ON DELETE SET NULL,
    admin_user_id UUID REFERENCES users(id),
    requested_params JSONB NOT NULL,
    anthropic_input_tokens INT,
    anthropic_output_tokens INT,
    anthropic_cost_eur NUMERIC(8,5),
    azure_characters_count INT,
    azure_cost_eur NUMERIC(8,5),
    r2_object_key VARCHAR(256),
    duration_ms INT,
    status VARCHAR(16) NOT NULL,  -- SUCCESS, FAILED_ANTHROPIC, FAILED_AZURE, FAILED_R2, FAILED_DB
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audio_gen_logs_admin ON audio_question_generation_logs(admin_user_id, created_at DESC);
CREATE INDEX idx_audio_gen_logs_status ON audio_question_generation_logs(status, created_at DESC);
```

## 5. Variables d'environnement requises

| Variable | Exemple | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | `sk-ant-...` | Clé API Anthropic |
| `ANTHROPIC_MODEL` | `claude-sonnet-4-6` | Modèle à utiliser |
| `AZURE_SPEECH_KEY` | `...` | Clé Azure Speech Service |
| `AZURE_SPEECH_REGION` | `francecentral` | Région Azure |
| `R2_ACCOUNT_ID` | `...` | ID compte Cloudflare |
| `R2_ACCESS_KEY_ID` | `...` | Access key R2 |
| `R2_SECRET_ACCESS_KEY` | `...` | Secret key R2 |
| `R2_BUCKET_NAME` | `sejourfr-audio` | Nom du bucket |
| `R2_PUBLIC_URL_BASE` | `https://pub-...r2.dev` | URL publique du bucket |
| `AUDIO_GENERATION_TIMEOUT_SEC` | `45` | Timeout total (par défaut 45s) |
| `AUDIO_GENERATION_MAX_RETRIES` | `2` | Nombre de retries sur erreur transitoire |

## 6. Estimation des coûts par question

À titre indicatif (prix 2026, peuvent varier) :

| Composant | Coût unitaire | Coût/question |
|---|---|---|
| Anthropic Claude Sonnet 4.6 | $3/M tokens input, $15/M output | ~$0.005 (≈ 0.005 €) |
| Azure Speech Neural | $16/M caractères | ~$0.002 pour 130 caractères |
| Cloudflare R2 stockage | $0.015/GB/mois | négligeable (~50 KB par MP3) |
| Cloudflare R2 bande passante | gratuit (sortie) | 0 |
| **TOTAL par question** | — | **≈ 0.01 €** |

Pour 1000 questions générées : ~10 €. C'est très raisonnable.

## 7. Sécurité

- Aucune clé API exposée au frontend
- Endpoints admin protégés par le système d'auth existant (vérification du rôle `ADMIN`)
- Rate limiting : max 10 générations / minute / admin (pour limiter les coûts en cas d'abus)
- Audit complet : chaque génération est tracée avec qui, quand, paramètres, coût, statut
- Validation stricte des entrées (niveau, thème) côté backend

## 8. Liste des fichiers de specs

| Fichier | Contenu |
|---|---|
| `00-OVERVIEW.md` | Vue d'ensemble (ce fichier) |
| `01-API-CONTRACT.md` | Endpoints REST, DTOs, codes erreur, schémas JSON |
| `02-DATABASE-SCHEMA.md` | Migrations SQL Flyway |
| `03-INTEGRATIONS.md` | Specs Anthropic, Azure Speech, Cloudflare R2 |
| `04-PROMPT-CLAUDE.md` | Prompt système + schéma JSON strict |
| `05-BUSINESS-RULES.md` | Règles métier (calibrage, voix, validation) |
| `06-IMPLEMENTATION-GUIDE.md` | Guide pour Claude Code : ordre d'implémentation |
| `07-ACCEPTANCE-TESTS.md` | Tests d'acceptation Given/When/Then |
| `08-OBSERVABILITY-SECURITY.md` | Logging, monitoring, rate limit |

## 9. Critères d'acceptation globaux

Le projet est livré OK quand :

1. ✅ L'admin peut cliquer sur "Générer une question audio" avec des paramètres
2. ✅ La réponse arrive en moins de 45 secondes (timeout)
3. ✅ Le MP3 est lisible dans la prévisualisation
4. ✅ La question est en base avec statut `DRAFT` (non visible des utilisateurs)
5. ✅ L'admin peut valider → la question passe en `ACTIVE`
6. ✅ L'admin peut rejeter → la question est supprimée + MP3 effacé de R2
7. ✅ En cas d'erreur sur l'une des 3 intégrations, message d'erreur clair et rien n'est sauvegardé en base
8. ✅ Chaque génération est tracée dans `audio_question_generation_logs`
9. ✅ Aucune clé API n'apparaît dans les logs ou le frontend
10. ✅ Tests unitaires sur chaque service (mocks des APIs externes)
11. ✅ Tests d'intégration sur le contrôleur (avec mocks)
12. ✅ Un test end-to-end manuel passe (génération réelle avec vrais comptes API)
