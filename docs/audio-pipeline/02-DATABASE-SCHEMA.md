# 02 — Schéma de base de données et migrations

## 1. Vue d'ensemble

Pour supporter la pipeline audio, **2 évolutions** sont nécessaires sur le schéma existant :

1. **Ajout du statut** sur la table `questions` (DRAFT / ACTIVE / ARCHIVED)
2. **Création d'une table d'audit** `audio_question_generation_logs`

Les tables `questions`, `medias`, `choices` existent déjà et ne sont pas modifiées dans leur structure principale.

---

## 2. Migration Flyway — V14

Nom du fichier : `V14__add_question_status_and_generation_logs.sql`

```sql
-- ============================================================================
-- V14 : Support de la pipeline de génération audio (CO)
-- ============================================================================
-- Cette migration prépare le support de la génération automatique de questions
-- audio via Anthropic Claude + Azure Speech + Cloudflare R2.
--
-- Changements :
--   1. Ajout d'un statut sur la table `questions` (DRAFT / ACTIVE / ARCHIVED)
--   2. Création de la table d'audit `audio_question_generation_logs`
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 🔧 1. STATUT DES QUESTIONS
-- ----------------------------------------------------------------------------
-- Les questions générées passent d'abord par un statut DRAFT
-- (non visible des utilisateurs). L'admin doit les valider pour qu'elles
-- passent en ACTIVE et soient utilisables dans l'app.

ALTER TABLE questions
    ADD COLUMN IF NOT EXISTS status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE';

ALTER TABLE questions
    ADD CONSTRAINT chk_question_status
    CHECK (status IN ('DRAFT', 'ACTIVE', 'ARCHIVED'));

CREATE INDEX IF NOT EXISTS idx_questions_status
    ON questions(status);

-- Note : les questions existantes sont par défaut en ACTIVE (rétrocompatibilité)
-- Seules les questions générées via la pipeline démarrent en DRAFT.


-- ----------------------------------------------------------------------------
-- 📊 2. TABLE D'AUDIT DES GÉNÉRATIONS
-- ----------------------------------------------------------------------------
-- Cette table trace chaque tentative de génération de question audio,
-- avec les paramètres, les coûts associés, le statut final et le résultat.
-- Elle sert à :
--   - Auditer les actions des admins
--   - Suivre les coûts (Anthropic + Azure)
--   - Diagnostiquer les échecs
--   - Identifier les abus (rate limit)

CREATE TABLE IF NOT EXISTS audio_question_generation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Lien vers la question créée (NULL si échec avant insertion)
    question_id UUID REFERENCES questions(id) ON DELETE SET NULL,

    -- Qui a déclenché la génération
    admin_user_id UUID NOT NULL REFERENCES users(id),

    -- Paramètres reçus (sérialisés en JSON)
    requested_params JSONB NOT NULL,

    -- Métriques Anthropic
    anthropic_input_tokens INT,
    anthropic_output_tokens INT,
    anthropic_cost_eur NUMERIC(8,5),

    -- Métriques Azure Speech
    azure_characters_count INT,
    azure_cost_eur NUMERIC(8,5),

    -- Cloudflare R2
    r2_object_key VARCHAR(256),

    -- Performance
    duration_ms INT,

    -- Statut final de la génération
    status VARCHAR(32) NOT NULL,
    -- Valeurs possibles :
    --   SUCCESS
    --   FAILED_VALIDATION       (erreur dans la requête)
    --   FAILED_ANTHROPIC        (Anthropic API a échoué)
    --   FAILED_ANTHROPIC_PARSE  (JSON renvoyé invalide)
    --   FAILED_AZURE_SPEECH     (Azure TTS a échoué)
    --   FAILED_R2_UPLOAD        (upload Cloudflare a échoué)
    --   FAILED_DB               (insertion DB a échoué)
    --   FAILED_TIMEOUT          (timeout global dépassé)
    --   RATE_LIMITED            (admin a dépassé son quota)

    -- Message d'erreur si statut != SUCCESS
    error_message TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_generation_status
        CHECK (status IN (
            'SUCCESS',
            'FAILED_VALIDATION',
            'FAILED_ANTHROPIC',
            'FAILED_ANTHROPIC_PARSE',
            'FAILED_AZURE_SPEECH',
            'FAILED_R2_UPLOAD',
            'FAILED_DB',
            'FAILED_TIMEOUT',
            'RATE_LIMITED'
        ))
);

-- Index pour les requêtes courantes
CREATE INDEX idx_audio_gen_logs_admin
    ON audio_question_generation_logs(admin_user_id, created_at DESC);

CREATE INDEX idx_audio_gen_logs_status
    ON audio_question_generation_logs(status, created_at DESC);

CREATE INDEX idx_audio_gen_logs_question
    ON audio_question_generation_logs(question_id)
    WHERE question_id IS NOT NULL;

-- Index pour le rate limiting (récupérer les générations de la dernière minute)
CREATE INDEX idx_audio_gen_logs_rate_limit
    ON audio_question_generation_logs(admin_user_id, created_at DESC)
    WHERE status = 'SUCCESS';


-- ----------------------------------------------------------------------------
-- 📌 3. COMMENTAIRES POUR LA DOCUMENTATION
-- ----------------------------------------------------------------------------

COMMENT ON COLUMN questions.status IS
    'Statut de la question : DRAFT (brouillon admin), ACTIVE (utilisable), ARCHIVED (retiré)';

COMMENT ON TABLE audio_question_generation_logs IS
    'Audit des générations de questions audio CO via la pipeline Anthropic + Azure + R2';

COMMENT ON COLUMN audio_question_generation_logs.requested_params IS
    'Paramètres JSON de la requête : niveau, thème, type, compétence, consignes';

COMMENT ON COLUMN audio_question_generation_logs.r2_object_key IS
    'Clé de l''objet dans le bucket R2 (ex: audio/uuid.mp3)';
```

---

## 3. Schéma des tables impactées (référence)

### 3.1 Table `questions` après V14

```sql
-- Structure attendue (référence)
CREATE TABLE questions (
    id UUID PRIMARY KEY,
    module VARCHAR(16) NOT NULL,              -- 'TCF' ou 'CIVIQUE'
    theme_id UUID REFERENCES themes(id),
    difficulty VARCHAR(8) NOT NULL,            -- 'A2', 'B1', 'B2', etc.
    question_type VARCHAR(16) NOT NULL,        -- 'CE', 'CO', 'STRUCTURE'
    competence_code VARCHAR(64),
    statement TEXT NOT NULL,
    explanation TEXT NOT NULL,
    passage_id UUID REFERENCES passages(id),
    media_id UUID REFERENCES medias(id),
    is_active BOOLEAN NOT NULL DEFAULT true,
    status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',  -- NOUVEAU
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_question_status CHECK (status IN ('DRAFT', 'ACTIVE', 'ARCHIVED'))
);
```

### 3.2 Table `medias` (rappel — déjà existante)

```sql
CREATE TABLE medias (
    id UUID PRIMARY KEY,
    type VARCHAR(16) NOT NULL,                 -- 'AUDIO', 'IMAGE'
    url TEXT,                                  -- URL S3/R2 (audio) ou NULL si SVG inline
    alt_text TEXT,
    inline_svg TEXT,                           -- ajouté en V13
    duration_sec INT,                          -- pour audio
    transcript TEXT                            -- pour audio (transcription pédagogique)
);
```

**Note importante** : pour la pipeline audio, on utilise :
- `type = 'AUDIO'`
- `url` = URL publique R2
- `transcript` = transcription complète (pour l'admin et pour la révision après réponse)
- `duration_sec` = durée du MP3 en secondes
- `alt_text` = description du contexte (ex: "Appel téléphonique chez un médecin")

---

## 4. Politique de rétention

### 4.1 Questions DRAFT

- Une question DRAFT non validée dans les **30 jours** est automatiquement supprimée (job cron quotidien)
- Le MP3 associé sur R2 est aussi supprimé
- L'entrée dans `audio_question_generation_logs` est conservée (audit)

### 4.2 Logs d'audit

- Conservation : **2 ans** glissants
- Au-delà : suppression automatique (job cron mensuel)
- Possibilité d'export CSV avant suppression (sécurité)

### 4.3 Job cron à implémenter

```java
package com.sejourfr.audioquestion.scheduled;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class AudioQuestionCleanupJob {

    @Scheduled(cron = "0 0 3 * * *", zone = "Europe/Paris") // 3h du matin tous les jours
    public void cleanupExpiredDrafts() {
        // Suppression des DRAFT > 30 jours
        // 1. Récupérer les questions DRAFT créées il y a plus de 30 jours
        // 2. Pour chaque : supprimer le MP3 de R2 + DELETE en cascade en DB
        // 3. Logger les actions
    }

    @Scheduled(cron = "0 0 4 1 * *", zone = "Europe/Paris") // 4h du matin le 1er du mois
    public void cleanupOldLogs() {
        // Suppression des logs > 2 ans
    }
}
```

---

## 5. Index et performance

### 5.1 Pourquoi ces index ?

| Index | Cas d'usage |
|---|---|
| `idx_questions_status` | Filtrer rapidement les questions DRAFT (liste admin) |
| `idx_audio_gen_logs_admin` | Liste paginée des générations d'un admin |
| `idx_audio_gen_logs_status` | Stats globales (combien d'échecs, etc.) |
| `idx_audio_gen_logs_rate_limit` | Compter les succès des 60 dernières secondes pour un admin |

### 5.2 Estimation des volumes

À titre indicatif :
- **1000 questions audio générées / mois** → 1000 lignes dans `audio_question_generation_logs`
- **Sur 2 ans** : 24 000 lignes → reste très léger, aucun problème de performance attendu

---

## 6. Script de rollback (en cas de problème)

```sql
-- V14_rollback.sql (à n'exécuter que manuellement, pas en migration auto)

-- Supprimer la table d'audit
DROP TABLE IF EXISTS audio_question_generation_logs;

-- Retirer la colonne status de questions
ALTER TABLE questions DROP CONSTRAINT IF EXISTS chk_question_status;
DROP INDEX IF EXISTS idx_questions_status;
ALTER TABLE questions DROP COLUMN IF EXISTS status;
```

---

## 7. Entités JPA correspondantes

### 7.1 Mise à jour de l'enum `QuestionStatus`

```java
package com.sejourfr.question.domain;

public enum QuestionStatus {
    DRAFT,
    ACTIVE,
    ARCHIVED
}
```

### 7.2 Mise à jour de l'entité `Question`

```java
package com.sejourfr.question.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "questions")
public class Question {
    // ... champs existants ...

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 16)
    private QuestionStatus status = QuestionStatus.ACTIVE;

    // getters / setters
}
```

### 7.3 Nouvelle entité `AudioQuestionGenerationLog`

```java
package com.sejourfr.audioquestion.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "audio_question_generation_logs")
public class AudioQuestionGenerationLog {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "question_id")
    private UUID questionId;  // peut être null si l'insertion DB a échoué

    @Column(name = "admin_user_id", nullable = false)
    private UUID adminUserId;

    @Column(name = "requested_params", nullable = false, columnDefinition = "jsonb")
    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    private String requestedParams;  // JSON string

    @Column(name = "anthropic_input_tokens")
    private Integer anthropicInputTokens;

    @Column(name = "anthropic_output_tokens")
    private Integer anthropicOutputTokens;

    @Column(name = "anthropic_cost_eur", precision = 8, scale = 5)
    private BigDecimal anthropicCostEur;

    @Column(name = "azure_characters_count")
    private Integer azureCharactersCount;

    @Column(name = "azure_cost_eur", precision = 8, scale = 5)
    private BigDecimal azureCostEur;

    @Column(name = "r2_object_key", length = 256)
    private String r2ObjectKey;

    @Column(name = "duration_ms")
    private Integer durationMs;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 32)
    private GenerationStatus status;

    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    // getters / setters / builder

    public enum GenerationStatus {
        SUCCESS,
        FAILED_VALIDATION,
        FAILED_ANTHROPIC,
        FAILED_ANTHROPIC_PARSE,
        FAILED_AZURE_SPEECH,
        FAILED_R2_UPLOAD,
        FAILED_DB,
        FAILED_TIMEOUT,
        RATE_LIMITED
    }
}
```
