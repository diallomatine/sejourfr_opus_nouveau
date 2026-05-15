package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.config.AnthropicProperties;
import com.sejourfr.app.audioquestion.dto.AnthropicGenerationResponse;
import com.sejourfr.app.audioquestion.dto.GenerateAudioQuestionRequest;
import com.sejourfr.app.audioquestion.dto.QuestionPreviewDto;
import com.sejourfr.app.audioquestion.entity.AudioQuestionGenerationLog;
import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import com.sejourfr.app.audioquestion.exception.AudioGenerationException;
import com.sejourfr.app.audioquestion.repository.AudioQuestionGenerationLogRepository;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client.R2UploadResult;
import com.sejourfr.app.audioquestion.service.SsmlValidator.ValidationResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import tools.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Pipeline complete de generation d'une question audio CO.
 * Etapes : rate-limit → Anthropic → SSML check → anti-doublon → Azure TTS → upload R2 → persistence DB.
 * En cas d'echec apres l'upload R2 mais avant ou pendant la persistence DB, le fichier MP3
 * est supprime de R2 (best-effort) pour eviter les orphelins.
 * Chaque tentative (succes ou echec) est logguee dans audio_question_generation_logs.
 */
@Service
public class AudioQuestionGenerationService {

    private static final Logger log = LoggerFactory.getLogger(AudioQuestionGenerationService.class);

    private final AnthropicClient anthropicClient;
    private final AzureSpeechClient azureSpeechClient;
    private final CloudflareR2Client r2Client;
    private final SsmlValidator ssmlValidator;
    private final DuplicateDetectionService duplicateService;
    private final GenerationRateLimiter rateLimiter;
    private final CostCalculator costCalculator;
    private final AudioQuestionPersistenceService persistenceService;
    private final AudioQuestionGenerationLogRepository logRepository;
    private final AnthropicProperties anthropicProps;
    private final ObjectMapper objectMapper;

    public AudioQuestionGenerationService(
            AnthropicClient anthropicClient,
            AzureSpeechClient azureSpeechClient,
            CloudflareR2Client r2Client,
            SsmlValidator ssmlValidator,
            DuplicateDetectionService duplicateService,
            GenerationRateLimiter rateLimiter,
            CostCalculator costCalculator,
            AudioQuestionPersistenceService persistenceService,
            AudioQuestionGenerationLogRepository logRepository,
            AnthropicProperties anthropicProps,
            ObjectMapper objectMapper) {
        this.anthropicClient = anthropicClient;
        this.azureSpeechClient = azureSpeechClient;
        this.r2Client = r2Client;
        this.ssmlValidator = ssmlValidator;
        this.duplicateService = duplicateService;
        this.rateLimiter = rateLimiter;
        this.costCalculator = costCalculator;
        this.persistenceService = persistenceService;
        this.logRepository = logRepository;
        this.anthropicProps = anthropicProps;
        this.objectMapper = objectMapper;
    }

    public QuestionPreviewDto generate(GenerateAudioQuestionRequest request, UUID adminUserId) {
        Instant startTime = Instant.now();
        AudioQuestionGenerationLog audit = newAuditLog(request, adminUserId);

        R2UploadResult r2Result = null;
        try {
            rateLimiter.checkAllowed(adminUserId);

            AnthropicClient.Outcome claude = anthropicClient.generate(request);
            audit.setAnthropicInputTokens(claude.inputTokens());
            audit.setAnthropicOutputTokens(claude.outputTokens());
            audit.setAnthropicCacheReadTokens(claude.cacheReadTokens());
            BigDecimal anthropicCost = costCalculator.anthropicCostEur(
                claude.inputTokens(), claude.outputTokens(), claude.cacheReadTokens()
            );
            audit.setAnthropicCostEur(anthropicCost);

            AnthropicGenerationResponse content = claude.content();
            ValidationResult ssml = ssmlValidator.validate(content.audio());
            audit.setAzureCharactersCount(ssml.azureCharactersCount());
            audit.setAzureVoiceNames(String.join(",", ssml.usedVoices()));
            BigDecimal azureCost = costCalculator.azureCostEur(ssml.azureCharactersCount());
            audit.setAzureCostEur(azureCost);

            duplicateService.checkNotDuplicate(
                content.audio().transcript(),
                content.question().difficulty()
            );

            byte[] mp3 = azureSpeechClient.synthesize(ssml.cleanedSsml());

            BigDecimal totalCost = anthropicCost.add(azureCost);
            AudioQuestionPersistenceService.PersistenceMetadata metadata =
                new AudioQuestionPersistenceService.PersistenceMetadata(
                    startTime,
                    millisSince(startTime),
                    totalCost,
                    claude.inputTokens(),
                    claude.outputTokens(),
                    claude.cacheReadTokens(),
                    ssml.azureCharactersCount()
                );

            // Persist Media (genere son id) -> upload R2 avec cet id -> persist Question + Choices.
            // L'orchestrateur conserve r2Result pour rollback en cas d'echec post-upload (rare).
            AudioQuestionPersistenceService.PersistenceResult persistenceResult;
            try {
                persistenceResult = persistenceService.persistAndUpload(
                    mp3, content, metadata,
                    mediaId -> {
                        R2UploadResult r = r2Client.uploadAudio(mediaId, mp3);
                        audit.setR2ObjectKey(r.objectKey());
                        return r;
                    }
                );
                r2Result = persistenceResult.r2Result();
            } catch (RuntimeException dbError) {
                if (audit.getR2ObjectKey() != null) safeDeleteR2(audit.getR2ObjectKey());
                audit.setStatus(GenerationStatus.FAILED_DB);
                audit.setErrorMessage(truncate(dbError.getMessage(), 1000));
                audit.setDurationMs(intMillis(startTime));
                logRepository.save(audit);
                log.error("Persistence DB echec : {}", dbError.getMessage(), dbError);
                throw dbError;
            }
            QuestionPreviewDto preview = persistenceResult.preview();

            audit.setQuestionId(preview.questionId());
            audit.setStatus(GenerationStatus.SUCCESS);
            audit.setDurationMs(intMillis(startTime));
            logRepository.save(audit);

            log.info(
                "Generation audio OK questionId={} admin={} duration={}ms cost={}EUR",
                preview.questionId(), adminUserId, audit.getDurationMs(), totalCost
            );
            return preview;

        } catch (AudioGenerationException ex) {
            if (r2Result != null && ex.getGenerationStatus() != null
                && ex.getGenerationStatus() != GenerationStatus.SUCCESS) {
                safeDeleteR2(r2Result.objectKey());
            }
            GenerationStatus s = ex.getGenerationStatus();
            if (s != null) {
                audit.setStatus(s);
                audit.setErrorMessage(truncate(ex.getMessage(), 1000));
                audit.setDurationMs(intMillis(startTime));
                logRepository.save(audit);
            }
            throw ex;

        } catch (RuntimeException ex) {
            if (r2Result != null) safeDeleteR2(r2Result.objectKey());
            audit.setStatus(GenerationStatus.FAILED_DB);
            audit.setErrorMessage(truncate(ex.getMessage(), 1000));
            audit.setDurationMs(intMillis(startTime));
            logRepository.save(audit);
            log.error("Generation audio erreur inattendue : {}", ex.getMessage(), ex);
            throw ex;
        }
    }

    private AudioQuestionGenerationLog newAuditLog(GenerateAudioQuestionRequest request, UUID adminUserId) {
        AudioQuestionGenerationLog audit = new AudioQuestionGenerationLog();
        audit.setAdminUserId(adminUserId);
        audit.setPromptVersion(anthropicProps.getPromptVersion());
        audit.setAnthropicModel(anthropicProps.getModel());
        audit.setRequestedParams(serializeParams(request));
        return audit;
    }

    private String serializeParams(GenerateAudioQuestionRequest request) {
        try {
            return objectMapper.writeValueAsString(request);
        } catch (Exception e) {
            return "{\"error\":\"serialization_failed\"}";
        }
    }

    private void safeDeleteR2(String objectKey) {
        try {
            r2Client.deleteAudio(objectKey);
        } catch (Exception cleanup) {
            log.warn("Cleanup R2 echec pour {} : {}", objectKey, cleanup.getMessage());
        }
    }

    private static long millisSince(Instant start) {
        return Math.max(0, Instant.now().toEpochMilli() - start.toEpochMilli());
    }

    private static int intMillis(Instant start) {
        long ms = millisSince(start);
        return ms > Integer.MAX_VALUE ? Integer.MAX_VALUE : (int) ms;
    }

    private static String truncate(String s, int max) {
        if (s == null) return null;
        return s.length() > max ? s.substring(0, max) : s;
    }
}
