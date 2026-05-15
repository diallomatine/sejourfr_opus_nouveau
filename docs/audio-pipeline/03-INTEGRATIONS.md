# 03 — Intégrations externes (Anthropic, Azure Speech, Cloudflare R2)

## 1. Vue d'ensemble

Le pipeline appelle **3 services externes en séquence**. Chaque appel a sa propre logique de retry, timeout et gestion d'erreur. Si l'un échoue, la chaîne s'arrête proprement (rollback total).

```
[Backend] → Anthropic API → JSON
         → Azure Speech API → MP3 binaire
         → Cloudflare R2 → URL publique
```

---

## 2. Intégration Anthropic (LLM)

### 2.1 Configuration

```java
package com.sejourfr.audioquestion.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "sejourfr.anthropic")
public record AnthropicProperties(
    String apiKey,                    // depuis ANTHROPIC_API_KEY
    String model,                     // ANTHROPIC_MODEL, défaut "claude-sonnet-4-6"
    String apiUrl,                    // défaut "https://api.anthropic.com/v1/messages"
    String anthropicVersion,          // défaut "2023-06-01"
    int timeoutSec,                   // défaut 30
    int maxRetries,                   // défaut 2
    int maxTokens                     // défaut 2000
) {}
```

### 2.2 Appel HTTP

```http
POST https://api.anthropic.com/v1/messages
Content-Type: application/json
x-api-key: <ANTHROPIC_API_KEY>
anthropic-version: 2023-06-01

{
  "model": "claude-sonnet-4-6",
  "max_tokens": 2000,
  "system": "<contenu du fichier 04-PROMPT-CLAUDE.md>",
  "messages": [
    {
      "role": "user",
      "content": "{\"niveau\":\"B1\",\"theme\":\"santé\",\"typeSouhaite\":\"dialogue\"}"
    },
    {
      "role": "assistant",
      "content": "{"
    }
  ]
}
```

**Astuce importante** : la dernière entrée `assistant` avec `"{"` **force Claude à amorcer sa réponse par un JSON valide** sans préambule. Ne pas oublier.

### 2.3 Réponse Anthropic

```json
{
  "id": "msg_01...",
  "type": "message",
  "role": "assistant",
  "model": "claude-sonnet-4-6",
  "content": [
    {
      "type": "text",
      "text": "\"audio\": { ... },\n  \"question\": { ... },\n  \"choices\": [ ... ]\n}"
    }
  ],
  "stop_reason": "end_turn",
  "usage": {
    "input_tokens": 1240,
    "output_tokens": 580
  }
}
```

**Attention** : la réponse de Claude commence directement par le contenu du JSON (la première `{` étant celle qu'on a forcée dans l'amorce). Le backend doit donc reconstruire le JSON complet :

```java
String rawContent = response.getContent().get(0).getText();
String fullJson = "{" + rawContent;  // on rajoute la { initiale
```

### 2.4 Validation du JSON renvoyé

Avant de continuer la pipeline, le backend **doit valider strictement** que le JSON correspond au schéma attendu (voir `04-PROMPT-CLAUDE.md`). Utiliser Jackson + Bean Validation :

```java
package com.sejourfr.audioquestion.dto;

import jakarta.validation.constraints.*;
import java.util.List;

public record AnthropicGenerationResponse(
    @NotNull @Valid AudioSection audio,
    @NotNull @Valid QuestionSection question,
    @NotNull @Size(min = 4, max = 4) List<@Valid ChoiceSection> choices
) {
    public record AudioSection(
        @NotBlank @Size(max = 5000) String transcript,
        @NotBlank @Size(max = 8000) String ssml,
        @Min(1) @Max(5) int speakerCount,
        @NotEmpty @Size(min = 1, max = 5) @Valid List<VoiceInfo> voices,
        @Min(5) @Max(180) int estimatedDurationSec,
        @NotBlank @Size(max = 500) String contextDescription
    ) {}

    public record VoiceInfo(
        @NotBlank String role,
        @Pattern(regexp = "^fr-FR-[A-Za-z]+Neural$") String azureVoice,
        @Pattern(regexp = "^(F|M)$") String gender
    ) {}

    public record QuestionSection(
        @NotBlank @Size(max = 500) String statement,
        @NotBlank @Size(min = 50, max = 1500) String explanation,
        @Pattern(regexp = "^co_[a-z_]+$") String competenceCode,
        @Pattern(regexp = "^(A2|B1|B2)$") String difficulty,
        @NotBlank String themeSuggested
    ) {}

    public record ChoiceSection(
        @NotBlank @Size(max = 200) String label,
        boolean isCorrect,
        @Min(1) @Max(4) int displayOrder
    ) {}
}
```

**Validation supplémentaire en code** (pas couverte par Bean Validation) :

- Exactement 1 choix avec `isCorrect = true`
- Les `displayOrder` couvrent {1, 2, 3, 4} sans doublon
- Le SSML est un XML valide (parser avec un validateur XML)
- Le SSML contient au moins une balise `<voice>` avec un nom matching `voices[].azureVoice`

### 2.5 Gestion des erreurs Anthropic

| Cas | Action |
|---|---|
| Timeout (>30s) | Retry (max 2 fois) avec backoff exponentiel |
| HTTP 429 (rate limit Anthropic) | Retry avec délai > Retry-After header |
| HTTP 5xx | Retry (max 2 fois) |
| HTTP 4xx (autre que 429) | Pas de retry, log + erreur 502 FAILED_ANTHROPIC |
| JSON invalide | Pas de retry, log + erreur 422 ANTHROPIC_CONTENT_INVALID |
| Validation schéma échoue | Pas de retry, log + erreur 422 ANTHROPIC_CONTENT_INVALID |

### 2.6 Calcul du coût Anthropic

Prix Sonnet 4.6 (à actualiser depuis https://docs.claude.com/) :
- Input : ~$3 / million de tokens
- Output : ~$15 / million de tokens

```java
public BigDecimal computeAnthropicCost(int inputTokens, int outputTokens) {
    BigDecimal inputCost = BigDecimal.valueOf(inputTokens)
        .multiply(BigDecimal.valueOf(3))
        .divide(BigDecimal.valueOf(1_000_000), 8, RoundingMode.HALF_UP);
    BigDecimal outputCost = BigDecimal.valueOf(outputTokens)
        .multiply(BigDecimal.valueOf(15))
        .divide(BigDecimal.valueOf(1_000_000), 8, RoundingMode.HALF_UP);
    BigDecimal totalUsd = inputCost.add(outputCost);
    // Conversion USD → EUR (à externaliser via un service de taux de change)
    return totalUsd.multiply(BigDecimal.valueOf(0.92)).setScale(5, RoundingMode.HALF_UP);
}
```

---

## 3. Intégration Azure Speech (TTS)

### 3.1 Configuration

```java
package com.sejourfr.audioquestion.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "sejourfr.azure-speech")
public record AzureSpeechProperties(
    String key,                       // AZURE_SPEECH_KEY
    String region,                    // AZURE_SPEECH_REGION (ex: "francecentral")
    String outputFormat,              // défaut "audio-24khz-48kbitrate-mono-mp3"
    int timeoutSec,                   // défaut 20
    int maxRetries                    // défaut 2
) {
    public String getEndpointUrl() {
        return String.format(
            "https://%s.tts.speech.microsoft.com/cognitiveservices/v1",
            region
        );
    }

    public String getTokenEndpointUrl() {
        return String.format(
            "https://%s.api.cognitive.microsoft.com/sts/v1.0/issueToken",
            region
        );
    }
}
```

### 3.2 Authentification : obtention du token

Azure Speech utilise un token Bearer de 10 minutes, à obtenir via la clé API :

```http
POST https://francecentral.api.cognitive.microsoft.com/sts/v1.0/issueToken
Ocp-Apim-Subscription-Key: <AZURE_SPEECH_KEY>
Content-Length: 0
```

Réponse : le body est directement le token JWT (texte brut).

**Recommandation** : mettre en cache le token (Caffeine ou Redis) avec une expiration de 9 minutes pour éviter de le redemander à chaque génération.

```java
@Service
public class AzureSpeechTokenService {

    private final Cache<String, String> tokenCache = Caffeine.newBuilder()
        .expireAfterWrite(Duration.ofMinutes(9))
        .maximumSize(1)
        .build();

    public String getToken() {
        return tokenCache.get("token", k -> fetchNewToken());
    }

    private String fetchNewToken() {
        // appel HTTP, return body as String
    }
}
```

### 3.3 Synthèse vocale (TTS)

```http
POST https://francecentral.tts.speech.microsoft.com/cognitiveservices/v1
Authorization: Bearer <token>
Content-Type: application/ssml+xml
X-Microsoft-OutputFormat: audio-24khz-48kbitrate-mono-mp3
User-Agent: SejourFR

<speak version="1.0" xml:lang="fr-FR">
  <voice name="fr-FR-DeniseNeural">
    Bonjour, j'appelle pour prendre un rendez-vous...
  </voice>
  <break time="400ms"/>
  <voice name="fr-FR-BrigitteNeural">
    Bien sûr madame, quel jour vous convient ?
  </voice>
</speak>
```

**Réponse** : flux binaire MP3 (avec headers `Content-Type: audio/mpeg`).

### 3.4 Format audio recommandé

| Format | Taille typique 1 min | Qualité | Verdict |
|---|---|---|---|
| `audio-16khz-32kbitrate-mono-mp3` | ~240 KB | Correcte | Trop léger pour parole travaillée |
| `audio-24khz-48kbitrate-mono-mp3` | ~360 KB | Bonne | **Recommandé** |
| `audio-24khz-96kbitrate-mono-mp3` | ~720 KB | Excellente | Overkill pour parole |
| `audio-48khz-192kbitrate-mono-mp3` | ~1.4 MB | Studio | Inutile pour TCF |

Pour SejourFR : `audio-24khz-48kbitrate-mono-mp3` (équilibre qualité/poids parfait pour mobile).

### 3.5 Gestion des erreurs Azure

| Cas | Action |
|---|---|
| 401 Unauthorized | Refresh du token + retry une fois |
| 429 Too Many Requests | Retry avec backoff exponentiel (max 2 fois) |
| 5xx | Retry (max 2 fois) |
| 4xx (autres) | Log + erreur 502 FAILED_AZURE_SPEECH |
| SSML invalide | Erreur 422 FAILED_AZURE_SPEECH (avec détails) |
| Timeout | Erreur 504 GENERATION_TIMEOUT |

### 3.6 Limites à connaître

- **Taille SSML max** : 10 minutes de speech, soit ~6000 caractères texte effectif
- **Voix simultanées dans un SSML** : illimité, mais éviter > 4 voix par audio (devient confus)
- **Quota par défaut** : 200 transactions/seconde (largement suffisant)

### 3.7 Calcul du coût Azure

Prix Azure Speech Neural (à actualiser) : ~$16 / 1M caractères.

```java
public BigDecimal computeAzureCost(int charactersCount) {
    BigDecimal costUsd = BigDecimal.valueOf(charactersCount)
        .multiply(BigDecimal.valueOf(16))
        .divide(BigDecimal.valueOf(1_000_000), 8, RoundingMode.HALF_UP);
    return costUsd.multiply(BigDecimal.valueOf(0.92))
        .setScale(5, RoundingMode.HALF_UP);
}
```

Le nombre de caractères est compté **sur le texte effectif** (sans les balises SSML).

---

## 4. Intégration Cloudflare R2 (stockage)

### 4.1 Configuration

```java
package com.sejourfr.audioquestion.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "sejourfr.r2")
public record CloudflareR2Properties(
    String accountId,                 // R2_ACCOUNT_ID
    String accessKeyId,               // R2_ACCESS_KEY_ID
    String secretAccessKey,           // R2_SECRET_ACCESS_KEY
    String bucketName,                // R2_BUCKET_NAME
    String publicUrlBase,             // R2_PUBLIC_URL_BASE (ex: https://pub-xxxx.r2.dev)
    int timeoutSec,                   // défaut 15
    int maxRetries                    // défaut 2
) {
    public String getEndpoint() {
        return String.format("https://%s.r2.cloudflarestorage.com", accountId);
    }
}
```

### 4.2 Pourquoi Cloudflare R2 ?

- **API compatible S3** : on utilise le SDK AWS S3 sans modification
- **Pas de frais de sortie (egress)** : énorme avantage par rapport à S3 pour les apps mobiles qui streament beaucoup
- **Performant** : CDN global Cloudflare en frontal
- **Tarif simple** : $0.015/GB/mois de stockage, gratuit en bande passante

### 4.3 Dépendance Maven

```xml
<dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>s3</artifactId>
    <version>2.27.0</version>
</dependency>
```

### 4.4 Client S3 configuré pour R2

```java
package com.sejourfr.audioquestion.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;

import java.net.URI;

@Configuration
public class CloudflareR2Config {

    @Bean
    public S3Client r2S3Client(CloudflareR2Properties props) {
        return S3Client.builder()
            .endpointOverride(URI.create(props.getEndpoint()))
            .credentialsProvider(StaticCredentialsProvider.create(
                AwsBasicCredentials.create(props.accessKeyId(), props.secretAccessKey())
            ))
            .region(Region.of("auto"))  // R2 utilise "auto"
            .build();
    }
}
```

### 4.5 Upload d'un MP3

```java
package com.sejourfr.audioquestion.service;

import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;

@Service
@RequiredArgsConstructor
public class CloudflareR2Client {

    private final S3Client r2S3Client;
    private final CloudflareR2Properties props;

    /**
     * Upload un fichier MP3 sur R2 et retourne l'URL publique.
     */
    public R2UploadResult uploadAudio(UUID mediaId, byte[] mp3Bytes) {
        String objectKey = "audio/" + mediaId + ".mp3";

        PutObjectRequest request = PutObjectRequest.builder()
            .bucket(props.bucketName())
            .key(objectKey)
            .contentType("audio/mpeg")
            .contentLength((long) mp3Bytes.length)
            .cacheControl("public, max-age=31536000, immutable")
            .build();

        r2S3Client.putObject(request, RequestBody.fromBytes(mp3Bytes));

        String publicUrl = props.publicUrlBase() + "/" + objectKey;
        return new R2UploadResult(objectKey, publicUrl);
    }

    /**
     * Supprime un fichier (en cas de rollback ou de rejet par l'admin).
     */
    public void deleteAudio(String objectKey) {
        DeleteObjectRequest request = DeleteObjectRequest.builder()
            .bucket(props.bucketName())
            .key(objectKey)
            .build();
        r2S3Client.deleteObject(request);
    }

    public record R2UploadResult(String objectKey, String publicUrl) {}
}
```

### 4.6 Configuration du bucket R2

Avant que le code fonctionne, l'admin doit configurer côté Cloudflare :

1. **Créer le bucket** `sejourfr-audio` (ou autre nom configurable)
2. **Activer l'accès public** : Bucket Settings → Public Access → R2.dev subdomain → Enable
3. **Récupérer l'URL publique** : sous la forme `https://pub-<hash>.r2.dev`
4. **(Optionnel)** : configurer un domaine custom (ex: `audio.sejourfr.app`)
5. **Créer une API token** : R2 → Manage R2 API Tokens → Create with scope "Object Read & Write" sur le bucket
6. **Récupérer** : Access Key ID + Secret Access Key

### 4.7 Gestion des erreurs R2

| Cas | Action |
|---|---|
| 403 Forbidden | Clés API incorrectes → log + erreur 502 |
| 404 Not Found | Bucket inexistant → log + erreur 502 |
| 5xx | Retry (max 2 fois) |
| Timeout | Erreur 504 GENERATION_TIMEOUT |
| Échec après retries | Erreur 502 FAILED_R2_UPLOAD |

### 4.8 Convention de nommage des objets

```
audio/<media_uuid>.mp3
```

Exemple : `audio/33333333-0014-0000-0000-000000000001.mp3`

**Pourquoi cette convention** :
- Le `media_id` est l'ID dans la table `medias`
- Permet de retrouver l'objet à supprimer sans stocker un chemin séparé
- Suffix `.mp3` pour faciliter le debug
- Pas de date dans le chemin (les MP3 sont immuables une fois validés)

---

## 5. Configuration `application.yml`

```yaml
sejourfr:
  anthropic:
    api-key: ${ANTHROPIC_API_KEY}
    model: ${ANTHROPIC_MODEL:claude-sonnet-4-6}
    api-url: https://api.anthropic.com/v1/messages
    anthropic-version: 2023-06-01
    timeout-sec: 30
    max-retries: 2
    max-tokens: 2000

  azure-speech:
    key: ${AZURE_SPEECH_KEY}
    region: ${AZURE_SPEECH_REGION:francecentral}
    output-format: audio-24khz-48kbitrate-mono-mp3
    timeout-sec: 20
    max-retries: 2

  r2:
    account-id: ${R2_ACCOUNT_ID}
    access-key-id: ${R2_ACCESS_KEY_ID}
    secret-access-key: ${R2_SECRET_ACCESS_KEY}
    bucket-name: ${R2_BUCKET_NAME:sejourfr-audio}
    public-url-base: ${R2_PUBLIC_URL_BASE}
    timeout-sec: 15
    max-retries: 2

  audio-generation:
    global-timeout-sec: ${AUDIO_GENERATION_TIMEOUT_SEC:45}
    rate-limit-per-minute: 10

logging:
  level:
    com.sejourfr.audioquestion: INFO
    com.sejourfr.audioquestion.service.AnthropicClient: DEBUG
```

---

## 6. Stratégie de retry et backoff

Tous les retries utilisent un **backoff exponentiel** avec jitter :

```java
package com.sejourfr.audioquestion.util;

import java.time.Duration;
import java.util.Random;

public class RetryBackoff {
    private static final Random RANDOM = new Random();

    public static Duration computeDelay(int attemptNumber) {
        // attempt 1: 1s, attempt 2: 2s, attempt 3: 4s (avec jitter ±25%)
        long baseMs = 1000L * (1L << (attemptNumber - 1));
        long jitter = (long) (baseMs * 0.25 * RANDOM.nextDouble());
        return Duration.ofMillis(baseMs + jitter);
    }
}
```

Pour les retries automatiques, utiliser **Spring Retry** :

```java
@Retryable(
    retryFor = {AnthropicTransientException.class},
    maxAttempts = 3,
    backoff = @Backoff(delay = 1000, multiplier = 2, random = true)
)
public AnthropicGenerationResponse callAnthropic(...) { ... }
```
