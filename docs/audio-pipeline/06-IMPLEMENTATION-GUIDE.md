# 06 — Guide d'implémentation pour Claude Code

## 1. Comment utiliser ce dossier avec Claude Code

### 1.1 Setup initial

1. Place ce dossier complet (`sejourfr-audio-pipeline/`) à la racine de ton repo backend Spring Boot
2. Dans ton terminal, lance `claude` (CLI Claude Code) à la racine du projet
3. Donne cette consigne d'ouverture à Claude Code :

```
Je vais te demander d'implémenter une nouvelle feature dans ce backend Spring Boot.
Toutes les specs sont dans /sejourfr-audio-pipeline/.

Avant de commencer, lis dans l'ordre :
1. 00-OVERVIEW.md (vue d'ensemble)
2. 01-API-CONTRACT.md (contrats REST)
3. 02-DATABASE-SCHEMA.md (DB)
4. 03-INTEGRATIONS.md (Anthropic, Azure, R2)
5. 04-PROMPT-CLAUDE.md (prompt système)
6. 05-BUSINESS-RULES.md (règles métier)
7. 06-IMPLEMENTATION-GUIDE.md (CE fichier — ordre d'implémentation)
8. 07-ACCEPTANCE-TESTS.md (tests à écrire)
9. 08-OBSERVABILITY-SECURITY.md (logging, sécurité)

Confirme-moi quand tu as fini de lire. Ensuite, on attaquera étape par étape.
```

### 1.2 Comment Claude Code va procéder

L'implémentation se fait en **6 phases**, dans cet ordre. Ne pas sauter d'étape.

---

## 2. Phase 1 — Setup et configuration

### 2.1 Dépendances Maven à ajouter

Dans `pom.xml`, ajouter (si absentes) :

```xml
<!-- AWS S3 SDK pour Cloudflare R2 -->
<dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>s3</artifactId>
    <version>2.27.0</version>
</dependency>

<!-- Spring Retry -->
<dependency>
    <groupId>org.springframework.retry</groupId>
    <artifactId>spring-retry</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-aspects</artifactId>
</dependency>

<!-- Cache Caffeine -->
<dependency>
    <groupId>com.github.ben-manes.caffeine</groupId>
    <artifactId>caffeine</artifactId>
</dependency>

<!-- WebClient (déjà inclus avec WebFlux mais à vérifier) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webflux</artifactId>
</dependency>
```

### 2.2 Configuration `application.yml`

Voir `03-INTEGRATIONS.md` section 5.

### 2.3 Variables d'environnement

À déclarer dans `.env` (en dev) et dans le secrets manager de l'env de prod :

```bash
ANTHROPIC_API_KEY=sk-ant-...
ANTHROPIC_MODEL=claude-sonnet-4-6
AZURE_SPEECH_KEY=...
AZURE_SPEECH_REGION=francecentral
R2_ACCOUNT_ID=...
R2_ACCESS_KEY_ID=...
R2_SECRET_ACCESS_KEY=...
R2_BUCKET_NAME=sejourfr-audio
R2_PUBLIC_URL_BASE=https://pub-xxxxx.r2.dev
AUDIO_GENERATION_TIMEOUT_SEC=45
```

### 2.4 Activer Spring Retry et Caching

Dans la classe principale ou une config :

```java
@SpringBootApplication
@EnableRetry
@EnableCaching
@ConfigurationPropertiesScan
@EnableScheduling
public class SejourFrApplication {
    public static void main(String[] args) {
        SpringApplication.run(SejourFrApplication.class, args);
    }
}
```

---

## 3. Phase 2 — Base de données

### 3.1 Migration Flyway

Créer le fichier `src/main/resources/db/migration/V14__add_question_status_and_generation_logs.sql` avec le contenu du fichier `02-DATABASE-SCHEMA.md` section 2.

### 3.2 Activer l'extension `pg_trgm`

Ajouter dans la migration V14 :

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

### 3.3 Entités JPA

Créer (ou mettre à jour) :

1. `com.sejourfr.question.domain.QuestionStatus` (enum)
2. `com.sejourfr.question.domain.Question` (ajouter le champ `status`)
3. `com.sejourfr.audioquestion.domain.AudioQuestionGenerationLog` (nouvelle)

### 3.4 Repositories

Créer :

1. `com.sejourfr.audioquestion.repository.AudioQuestionGenerationLogRepository`
2. Mettre à jour `MediaRepository` (ajouter `findSimilarTranscript`)
3. Mettre à jour `QuestionRepository` (ajouter méthodes pour filtrer par status)

### 3.5 Test

```bash
mvn flyway:migrate
mvn spring-boot:run
```

Vérifier que la migration a bien été appliquée (table `flyway_schema_history`).

---

## 4. Phase 3 — DTOs et exceptions

Créer dans cet ordre :

### 4.1 Exceptions

```
com.sejourfr.audioquestion.exception/
├── AudioGenerationException.java          (super-classe)
├── AnthropicGenerationException.java
├── AnthropicTransientException.java
├── AnthropicContentInvalidException.java
├── AzureSpeechException.java
├── AzureSpeechTransientException.java
├── R2UploadException.java
├── ContentValidationException.java
├── SsmlValidationException.java
├── DuplicateContentException.java
├── RateLimitExceededException.java
└── QuestionNotDraftException.java
```

Chacune doit avoir :
- Un constructeur `(String message)`
- Un constructeur `(String message, Throwable cause)`
- Une annotation `@ResponseStatus` avec le code HTTP correspondant (voir `01-API-CONTRACT.md` section 7)

### 4.2 DTOs

Voir `01-API-CONTRACT.md` pour le détail. À créer :

```
com.sejourfr.audioquestion.dto/
├── GenerateAudioQuestionRequest.java
├── QuestionPreviewDto.java                (avec records imbriqués)
├── AnthropicGenerationResponse.java       (avec records imbriqués)
├── ValidationResultDto.java
└── ApiErrorResponse.java
```

### 4.3 Gestionnaire global d'exceptions

```java
@RestControllerAdvice
public class AudioQuestionExceptionHandler {

    @ExceptionHandler(AudioGenerationException.class)
    public ResponseEntity<ApiErrorResponse> handleGeneration(...) { ... }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiErrorResponse> handleValidation(...) { ... }

    // etc.
}
```

---

## 5. Phase 4 — Clients externes (Anthropic, Azure, R2)

L'ordre est important : on construit les clients un par un et on les teste isolément avant de les composer.

### 5.1 AnthropicClient

**Étape 1** : Charger le prompt système au démarrage (depuis classpath)

```java
@Component
@RequiredArgsConstructor
public class PromptLoader {

    @PostConstruct
    public void loadPrompts() {
        try (InputStream is = getClass().getResourceAsStream("/prompts/audio-question-system-v1.md")) {
            this.audioQuestionSystemPrompt = new String(is.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    public String getAudioQuestionSystemPrompt() { return audioQuestionSystemPrompt; }
}
```

**Étape 2** : Implémenter `AnthropicClient` (WebClient ou RestTemplate au choix). Voir `03-INTEGRATIONS.md` section 2 pour le détail HTTP.

**Étape 3** : Tester avec un mock d'Anthropic (utiliser WireMock ou MockWebServer).

### 5.2 AzureSpeechClient

**Étape 1** : `AzureSpeechTokenService` (cache du token avec Caffeine)

**Étape 2** : `AzureSpeechClient` (synthesize SSML → byte[])

**Étape 3** : Tester avec un SSML valide.

### 5.3 CloudflareR2Client

**Étape 1** : `CloudflareR2Config` (bean S3Client)

**Étape 2** : `CloudflareR2Client` (uploadAudio, deleteAudio)

**Étape 3** : Tester sur un bucket de dev (créer un bucket `sejourfr-audio-dev`).

---

## 6. Phase 5 — Service d'orchestration

### 6.1 AudioQuestionGenerationService

C'est le service principal. Il orchestre :

1. Validation de la requête
2. Rate limiting
3. Appel Anthropic
4. Validation du JSON renvoyé
5. Détection de doublons
6. Appel Azure Speech
7. Upload R2
8. Persistance DB (transactionnelle)
9. Log d'audit
10. En cas d'erreur : rollback R2 + log

**Squelette** :

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class AudioQuestionGenerationService {

    private final AnthropicClient anthropicClient;
    private final AzureSpeechClient azureSpeechClient;
    private final CloudflareR2Client r2Client;
    private final SsmlValidator ssmlValidator;
    private final DuplicateDetectionService duplicateService;
    private final GenerationRateLimiter rateLimiter;
    private final AudioQuestionPersistenceService persistenceService;
    private final AudioQuestionGenerationLogRepository logRepository;
    private final Clock clock;

    public QuestionPreviewDto generate(
        GenerateAudioQuestionRequest request,
        UUID adminUserId
    ) {
        Instant startTime = clock.instant();
        AudioQuestionGenerationLog log = new AudioQuestionGenerationLog();
        log.setAdminUserId(adminUserId);
        log.setRequestedParams(JsonUtils.toJson(request));

        try {
            // 1. Rate limiting
            rateLimiter.checkAllowed(adminUserId);

            // 2. Validation requête (Bean Validation s'en charge en partie)
            validateRequest(request);

            // 3. Appel Anthropic
            AnthropicGenerationResponse claudeResponse = callAnthropic(request, log);

            // 4. Validation du contenu retourné
            validateClaudeResponse(claudeResponse);

            // 5. Détection de doublons
            duplicateService.checkNotDuplicate(
                claudeResponse.audio().transcript(),
                claudeResponse.question().difficulty()
            );

            // 6. Synthèse Azure
            byte[] mp3Bytes = callAzureSpeech(claudeResponse, log);

            // 7. Upload R2
            UUID mediaId = UUID.randomUUID();
            CloudflareR2Client.R2UploadResult r2Result = callR2Upload(mediaId, mp3Bytes, log);

            // 8. Persistance DB
            QuestionPreviewDto result;
            try {
                result = persistenceService.persistInTransaction(
                    mediaId, claudeResponse, r2Result, adminUserId
                );
            } catch (Exception e) {
                // Rollback R2 manuel
                try { r2Client.deleteAudio(r2Result.objectKey()); }
                catch (Exception cleanup) { log.warn("R2 cleanup failed", cleanup); }
                throw e;
            }

            // 9. Log SUCCESS
            log.setQuestionId(result.questionId());
            log.setStatus(GenerationStatus.SUCCESS);
            log.setDurationMs((int) Duration.between(startTime, clock.instant()).toMillis());
            logRepository.save(log);

            return result;

        } catch (Exception e) {
            // Log FAILED_* avec le status approprié
            log.setStatus(mapExceptionToStatus(e));
            log.setErrorMessage(e.getMessage());
            log.setDurationMs((int) Duration.between(startTime, clock.instant()).toMillis());
            logRepository.save(log);
            throw e;
        }
    }
}
```

### 6.2 AudioQuestionPersistenceService

Séparé pour gérer la transactionnalité :

```java
@Service
@RequiredArgsConstructor
public class AudioQuestionPersistenceService {

    private final MediaRepository mediaRepository;
    private final QuestionRepository questionRepository;
    private final ChoiceRepository choiceRepository;

    @Transactional
    public QuestionPreviewDto persistInTransaction(
        UUID mediaId,
        AnthropicGenerationResponse claudeResponse,
        CloudflareR2Client.R2UploadResult r2Result,
        UUID adminUserId
    ) {
        // 1. Insert Media
        Media media = Media.builder()
            .id(mediaId)
            .type(MediaType.AUDIO)
            .url(r2Result.publicUrl())
            .transcript(claudeResponse.audio().transcript())
            .durationSec(claudeResponse.audio().estimatedDurationSec())
            .altText(claudeResponse.audio().contextDescription())
            .build();
        mediaRepository.save(media);

        // 2. Insert Question (DRAFT)
        Question question = Question.builder()
            .id(UUID.randomUUID())
            .module("TCF")
            .themeId(getCoThemeUuid())
            .difficulty(claudeResponse.question().difficulty())
            .questionType("CO")
            .competenceCode(claudeResponse.question().competenceCode())
            .statement(claudeResponse.question().statement())
            .explanation(claudeResponse.question().explanation())
            .mediaId(mediaId)
            .isActive(false)              // DRAFT n'est pas active
            .status(QuestionStatus.DRAFT)
            .build();
        questionRepository.save(question);

        // 3. Insert Choices
        List<Choice> choices = claudeResponse.choices().stream()
            .map(c -> Choice.builder()
                .id(UUID.randomUUID())
                .questionId(question.getId())
                .label(c.label())
                .isCorrect(c.isCorrect())
                .displayOrder(c.displayOrder())
                .build())
            .toList();
        choiceRepository.saveAll(choices);

        // 4. Construire le DTO de réponse
        return buildPreviewDto(media, question, choices, claudeResponse);
    }
}
```

---

## 7. Phase 6 — Controller et endpoints

### 7.1 AudioQuestionAdminController

```java
@RestController
@RequestMapping("/api/admin/audio-questions")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AudioQuestionAdminController {

    private final AudioQuestionGenerationService generationService;
    private final AudioQuestionValidationService validationService;
    private final AudioQuestionDeletionService deletionService;
    private final AudioQuestionLogService logService;

    @PostMapping("/generate")
    public QuestionPreviewDto generate(
        @Valid @RequestBody GenerateAudioQuestionRequest request,
        @AuthenticationPrincipal AdminUser admin
    ) {
        return generationService.generate(request, admin.getId());
    }

    @GetMapping("/{id}/preview")
    public QuestionPreviewDto preview(@PathVariable UUID id) {
        return generationService.getPreview(id);
    }

    @PatchMapping("/{id}/validate")
    public ValidationResultDto validate(
        @PathVariable UUID id,
        @AuthenticationPrincipal AdminUser admin
    ) {
        return validationService.validate(id, admin.getId());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void reject(
        @PathVariable UUID id,
        @AuthenticationPrincipal AdminUser admin
    ) {
        deletionService.reject(id, admin.getId());
    }

    @GetMapping("/generation-logs")
    public Page<GenerationLogDto> getLogs(
        Pageable pageable,
        @RequestParam(required = false) GenerationStatus status,
        @RequestParam(required = false) UUID adminUserId
    ) {
        return logService.findLogs(pageable, status, adminUserId);
    }
}
```

---

## 8. Ordre d'implémentation recommandé

Pour Claude Code, voici l'ordre optimal qui permet de tester au fur et à mesure :

| Étape | Tâche | Test possible |
|---|---|---|
| 1 | Dépendances Maven + config `application.yml` | Compilation OK |
| 2 | Migration V14 + entités JPA | `mvn flyway:migrate` OK |
| 3 | Exceptions + DTOs + handler global | Tests unitaires DTO |
| 4 | `PromptLoader` (charge le prompt système) | Test unitaire |
| 5 | `AnthropicClient` avec mock | Test d'intégration avec MockWebServer |
| 6 | `AzureSpeechTokenService` + `AzureSpeechClient` | Test avec compte Azure dev |
| 7 | `CloudflareR2Config` + `CloudflareR2Client` | Test upload sur bucket dev |
| 8 | `SsmlValidator` + `DuplicateDetectionService` | Tests unitaires |
| 9 | `GenerationRateLimiter` | Test unitaire avec mock du clock |
| 10 | `AudioQuestionPersistenceService` (transactionnel) | Test d'intégration DB |
| 11 | `AudioQuestionGenerationService` (orchestrateur) | Test E2E avec tous les mocks |
| 12 | `AudioQuestionValidationService` (valide DRAFT → ACTIVE) | Test E2E |
| 13 | `AudioQuestionDeletionService` (rejette + supprime R2) | Test E2E |
| 14 | `AudioQuestionAdminController` (endpoints REST) | Tests `@WebMvcTest` |
| 15 | Tests d'acceptation manuels (voir 07-ACCEPTANCE-TESTS.md) | Génération réelle |

---

## 9. Structure finale des packages

```
src/main/java/com/sejourfr/
├── audioquestion/
│   ├── config/
│   │   ├── AnthropicProperties.java
│   │   ├── AzureSpeechProperties.java
│   │   ├── CloudflareR2Properties.java
│   │   ├── CloudflareR2Config.java
│   │   └── AudioGenerationProperties.java
│   ├── controller/
│   │   ├── AudioQuestionAdminController.java
│   │   └── AudioQuestionExceptionHandler.java
│   ├── domain/
│   │   ├── AudioQuestionGenerationLog.java
│   │   └── GenerationStatus.java
│   ├── dto/
│   │   ├── GenerateAudioQuestionRequest.java
│   │   ├── QuestionPreviewDto.java
│   │   ├── AnthropicGenerationResponse.java
│   │   ├── ValidationResultDto.java
│   │   ├── GenerationLogDto.java
│   │   └── ApiErrorResponse.java
│   ├── exception/
│   │   └── (toutes les exceptions)
│   ├── repository/
│   │   └── AudioQuestionGenerationLogRepository.java
│   ├── scheduled/
│   │   └── AudioQuestionCleanupJob.java
│   ├── service/
│   │   ├── AudioQuestionGenerationService.java
│   │   ├── AudioQuestionPersistenceService.java
│   │   ├── AudioQuestionValidationService.java
│   │   ├── AudioQuestionDeletionService.java
│   │   ├── AudioQuestionLogService.java
│   │   ├── AnthropicClient.java
│   │   ├── AzureSpeechClient.java
│   │   ├── AzureSpeechTokenService.java
│   │   ├── CloudflareR2Client.java
│   │   ├── PromptLoader.java
│   │   ├── DuplicateDetectionService.java
│   │   ├── GenerationRateLimiter.java
│   │   ├── SsmlValidator.java
│   │   └── CostCalculator.java
│   └── util/
│       └── RetryBackoff.java

src/main/resources/
├── application.yml
├── prompts/
│   └── audio-question-system-v1.md
└── db/migration/
    └── V14__add_question_status_and_generation_logs.sql

src/test/java/com/sejourfr/audioquestion/
├── controller/
├── service/
└── ... (tests miroirs de la structure ci-dessus)
```

---

## 10. Démarrage avec Claude Code — script de prompt

Quand tu lances Claude Code dans ton repo, tu peux lui dire :

```
Implémente la phase 1 : setup et configuration.

Plus précisément :
1. Ajoute les dépendances Maven (voir 06-IMPLEMENTATION-GUIDE.md §2.1)
2. Crée la configuration application.yml (voir 03-INTEGRATIONS.md §5)
3. Active Spring Retry, Caching, et Scheduling sur la classe principale
4. Compile et confirme que tout fonctionne

Ne passe pas à la phase 2 tant que je n'ai pas validé.
```

Puis à chaque phase suivante :

```
Passe à la phase 2 : base de données.
```

Cette approche par phases permet de :
- Détecter les problèmes tôt
- Tester progressivement
- Garder Claude Code focalisé sur une tâche claire
- Pouvoir corriger ou ajuster sans tout refaire
