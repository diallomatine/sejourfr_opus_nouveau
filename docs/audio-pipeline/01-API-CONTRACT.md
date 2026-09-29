# 01 — Contrats d'API REST

## 1. Vue d'ensemble des endpoints

| Méthode | URI | Auth | Description |
|---|---|---|---|
| `POST` | `/api/admin/audio-questions/generate` | ADMIN | Génère une question audio (synchrone) |
| `GET` | `/api/admin/audio-questions/{id}/preview` | ADMIN | Récupère la prévisualisation d'une question DRAFT |
| `PATCH` | `/api/admin/audio-questions/{id}/validate` | ADMIN | Valide une question DRAFT (passe en ACTIVE) |
| `DELETE` | `/api/admin/audio-questions/{id}` | ADMIN | Rejette/supprime une question DRAFT |
| `GET` | `/api/admin/audio-questions/generation-logs` | ADMIN | Liste les logs de génération (audit) |

Tous les endpoints sont sous le préfixe `/api/admin/` et requièrent le rôle `ADMIN` (vérifié par le middleware d'auth existant).

---

## 2. Endpoint principal — Génération

### 2.1 Requête

```http
POST /api/admin/audio-questions/generate
Content-Type: application/json
Authorization: Bearer <jwt-admin>

{
  "niveau": "B1",
  "theme": "santé",
  "type_souhaite": "dialogue",
  "competence_visee": "co_detail_specifique",
  "consignes_specifiques": "Conversation entre une patiente et une secrétaire médicale"
}
```

### 2.2 Schéma de la requête (DTO Java)

```java
package com.sejourfr.audioquestion.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record GenerateAudioQuestionRequest(
    @NotNull
    @Pattern(regexp = "^(A2|B1|B2)$", message = "Le niveau doit être A2, B1 ou B2")
    String niveau,

    @Size(max = 64)
    String theme,                    // OPTIONNEL : si null, Claude choisit

    @Pattern(regexp = "^(annonce|monologue|dialogue|interview|reportage)?$")
    String typeSouhaite,             // OPTIONNEL

    @Pattern(regexp = "^co_[a-z_]+$")
    @Size(max = 64)
    String competenceVisee,          // OPTIONNEL

    @Size(max = 500)
    String consignesSpecifiques      // OPTIONNEL : contexte additionnel
) {}
```

### 2.3 Validation côté backend

- `niveau` : obligatoire, regex strict (A2 / B1 / B2)
- `theme` : optionnel, max 64 caractères, doit appartenir à la liste des thèmes autorisés (voir `05-BUSINESS-RULES.md`)
- `typeSouhaite` : optionnel, regex strict
- `competenceVisee` : optionnel, doit commencer par `co_` et appartenir à la liste autorisée
- `consignesSpecifiques` : optionnel, max 500 caractères, échappement HTML automatique

### 2.4 Réponse de succès (200 OK)

```json
{
  "questionId": "55555555-0014-0000-0000-000000000001",
  "status": "DRAFT",
  "audio": {
    "mediaId": "33333333-0014-0000-0000-000000000001",
    "url": "https://pub-abc123.r2.dev/audio/33333333-0014-0000-0000-000000000001.mp3",
    "durationSec": 40,
    "speakerCount": 2,
    "voices": [
      {"role": "patiente", "azureVoice": "fr-FR-DeniseNeural", "gender": "F"},
      {"role": "secrétaire médicale", "azureVoice": "fr-FR-BrigitteNeural", "gender": "F"}
    ],
    "transcript": "Bonjour, j'appelle pour prendre un rendez-vous...",
    "contextDescription": "Appel téléphonique : une patiente prend rendez-vous chez son médecin."
  },
  "question": {
    "statement": "À quelle heure est fixé le rendez-vous ?",
    "explanation": "La secrétaire propose précisément « jeudi 16 à 15h30 »...",
    "competenceCode": "co_detail_specifique",
    "difficulty": "B1",
    "theme": "santé"
  },
  "choices": [
    {"id": "<uuid>", "label": "14h30", "isCorrect": false, "displayOrder": 1},
    {"id": "<uuid>", "label": "15h30", "isCorrect": true,  "displayOrder": 2},
    {"id": "<uuid>", "label": "16h30", "isCorrect": false, "displayOrder": 3},
    {"id": "<uuid>", "label": "17h30", "isCorrect": false, "displayOrder": 4}
  ],
  "metadata": {
    "generatedAt": "2026-05-15T14:23:45Z",
    "generationDurationMs": 18500,
    "costEur": 0.0103,
    "anthropicInputTokens": 1240,
    "anthropicOutputTokens": 580,
    "azureCharactersCount": 312
  }
}
```

### 2.5 Schéma de la réponse (DTO Java)

```java
package com.sejourfr.audioquestion.dto;

import java.util.List;
import java.util.UUID;
import java.time.Instant;
import java.math.BigDecimal;

public record QuestionPreviewDto(
    UUID questionId,
    String status,                          // "DRAFT"
    AudioPreviewDto audio,
    QuestionContentDto question,
    List<ChoiceDto> choices,
    GenerationMetadataDto metadata
) {
    public record AudioPreviewDto(
        UUID mediaId,
        String url,
        int durationSec,
        int speakerCount,
        List<VoiceDto> voices,
        String transcript,
        String contextDescription
    ) {}

    public record VoiceDto(
        String role,
        String azureVoice,
        String gender                       // "F" ou "M"
    ) {}

    public record QuestionContentDto(
        String statement,
        String explanation,
        String competenceCode,
        String difficulty,
        String theme
    ) {}

    public record ChoiceDto(
        UUID id,
        String label,
        boolean isCorrect,
        int displayOrder
    ) {}

    public record GenerationMetadataDto(
        Instant generatedAt,
        long generationDurationMs,
        BigDecimal costEur,
        int anthropicInputTokens,
        int anthropicOutputTokens,
        int azureCharactersCount
    ) {}
}
```

---

## 3. Endpoint — Validation

### 3.1 Requête

```http
PATCH /api/admin/audio-questions/{id}/validate
Authorization: Bearer <jwt-admin>
```

Aucun body. L'ID est dans l'URL.

### 3.2 Réponse succès (200 OK)

```json
{
  "questionId": "55555555-0014-0000-0000-000000000001",
  "status": "ACTIVE",
  "activatedAt": "2026-05-15T14:30:12Z"
}
```

### 3.3 Comportement

- Vérifier que la question existe et est en statut `DRAFT`
- Si statut différent → erreur 409 Conflict
- Passer `is_active = true` et `status = 'ACTIVE'`
- Logger l'action dans une table d'audit (optionnel mais recommandé)

---

## 4. Endpoint — Rejet/Suppression

### 4.1 Requête

```http
DELETE /api/admin/audio-questions/{id}
Authorization: Bearer <jwt-admin>
```

### 4.2 Réponse succès (204 No Content)

Aucun body.

### 4.3 Comportement

- Vérifier que la question existe et est en statut `DRAFT`
- Si la question est `ACTIVE`, refuser : erreur 409 Conflict (utiliser l'archivage standard à la place)
- Récupérer le `media_id`, puis l'URL du fichier
- Supprimer le fichier MP3 de Cloudflare R2 (best-effort, ne pas bloquer la suppression DB)
- DELETE en cascade : choices → question → media

---

## 5. Endpoint — Prévisualisation (re-fetch)

Utile si l'admin recharge la page de prévisualisation. Retourne le même DTO que la génération.

### 5.1 Requête

```http
GET /api/admin/audio-questions/{id}/preview
Authorization: Bearer <jwt-admin>
```

### 5.2 Réponse

Idem `POST /generate` (même schéma `QuestionPreviewDto`).

---

## 6. Endpoint — Logs d'audit

### 6.1 Requête

```http
GET /api/admin/audio-questions/generation-logs?page=0&size=20&status=SUCCESS
Authorization: Bearer <jwt-admin>
```

### 6.2 Paramètres de requête

| Param | Type | Description |
|---|---|---|
| `page` | int | Numéro de page (défaut 0) |
| `size` | int | Taille de page (défaut 20, max 100) |
| `status` | enum | Filtrer par statut (optionnel) |
| `adminUserId` | UUID | Filtrer par admin (optionnel) |
| `from` | ISO date | Filtrer à partir de (optionnel) |
| `to` | ISO date | Filtrer jusqu'à (optionnel) |

### 6.3 Réponse

```json
{
  "content": [
    {
      "id": "<uuid>",
      "questionId": "<uuid>",
      "adminUserId": "<uuid>",
      "adminUserName": "Jean Dupont",
      "requestedParams": {"niveau": "B1", "theme": "santé"},
      "status": "SUCCESS",
      "costEur": 0.0103,
      "durationMs": 18500,
      "createdAt": "2026-05-15T14:23:45Z"
    }
  ],
  "totalElements": 142,
  "totalPages": 8,
  "currentPage": 0,
  "pageSize": 20
}
```

---

## 7. Codes d'erreur — Schéma standardisé

Toutes les erreurs suivent le format suivant :

```json
{
  "timestamp": "2026-05-15T14:23:45Z",
  "status": 400,
  "code": "INVALID_LEVEL",
  "message": "Le niveau doit être A2, B1 ou B2",
  "path": "/api/admin/audio-questions/generate",
  "traceId": "abc123-def456",
  "details": {
    "field": "niveau",
    "rejectedValue": "C1"
  }
}
```

### 7.1 Table complète des codes d'erreur

| HTTP | Code | Quand | Action côté front |
|---|---|---|---|
| 400 | `INVALID_LEVEL` | Niveau hors A2/B1/B2 | Afficher l'erreur de validation |
| 400 | `INVALID_THEME` | Thème non autorisé | Afficher l'erreur de validation |
| 400 | `INVALID_COMPETENCE` | Code compétence invalide | Afficher l'erreur de validation |
| 400 | `INVALID_TYPE_SOUHAITE` | Type non autorisé | Afficher l'erreur de validation |
| 401 | `UNAUTHORIZED` | Pas de token ou token invalide | Rediriger vers login |
| 403 | `FORBIDDEN` | Token valide mais pas ADMIN | Message "accès interdit" |
| 404 | `QUESTION_NOT_FOUND` | Question inexistante | Recharger la liste |
| 409 | `QUESTION_NOT_DRAFT` | Tentative de validation/suppression sur question non DRAFT | Recharger la liste |
| 422 | `ANTHROPIC_CONTENT_INVALID` | Claude a renvoyé un JSON invalide | Bouton "Régénérer" |
| 429 | `RATE_LIMIT_EXCEEDED` | Trop de générations en 1 minute | Attendre + retry après X secondes |
| 502 | `ANTHROPIC_API_ERROR` | Anthropic indisponible | Réessayer plus tard |
| 502 | `AZURE_SPEECH_API_ERROR` | Azure Speech indisponible | Réessayer plus tard |
| 502 | `R2_UPLOAD_ERROR` | Cloudflare R2 indisponible | Réessayer plus tard |
| 504 | `GENERATION_TIMEOUT` | Génération > 45s | Réessayer |
| 500 | `INTERNAL_ERROR` | Erreur inattendue | Contacter le support |

### 7.2 Schéma de l'erreur (DTO Java)

```java
package com.sejourfr.audioquestion.dto;

import java.time.Instant;
import java.util.Map;

public record ApiErrorResponse(
    Instant timestamp,
    int status,
    String code,
    String message,
    String path,
    String traceId,
    Map<String, Object> details          // optionnel
) {}
```

### 7.3 Règle d'or pour les erreurs

**Atomicité** : si la génération échoue à n'importe quelle étape (Anthropic, Azure, R2, DB), **AUCUNE donnée ne doit rester en base** ni sur R2. Le système doit être idempotent : un retry doit pouvoir se faire sans conflit.

- Si erreur après upload R2 → supprimer le MP3 de R2 avant de retourner l'erreur
- Si erreur après INSERT media mais avant INSERT question → rollback transactionnel
- Tout doit être dans la même transaction Spring `@Transactional` (sauf l'upload R2, qui est externe)

---

## 8. Headers et CORS

- Tous les endpoints retournent `Content-Type: application/json` (sauf `204 No Content`)
- CORS : autoriser l'origine du frontend admin (config Spring)
- Header `X-Request-Id` accepté en entrée et retourné en sortie (pour la traçabilité côté front)

---

## 9. Rate limiting

Implémenté via Redis ou cache local (Caffeine) :

- **Limite** : 10 générations / minute par admin
- En cas de dépassement : 429 + header `Retry-After: <seconds>`
- L'audit log enregistre les tentatives bloquées avec status `RATE_LIMITED`

---

## 10. Exemple de cycle complet (curl)

```bash
# 1. Générer
curl -X POST http://localhost:8080/api/admin/audio-questions/generate \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"niveau":"B1","theme":"santé","typeSouhaite":"dialogue"}'

# → 200 OK + body = QuestionPreviewDto (extraire questionId)

# 2. (L'admin écoute et lit, décide de valider)

# 3. Valider
curl -X PATCH http://localhost:8080/api/admin/audio-questions/$QUESTION_ID/validate \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# → 200 OK + statut ACTIVE

# Ou alternativement : rejeter
curl -X DELETE http://localhost:8080/api/admin/audio-questions/$QUESTION_ID \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# → 204 No Content
```
