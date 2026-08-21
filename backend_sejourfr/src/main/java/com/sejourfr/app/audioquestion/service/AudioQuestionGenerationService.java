package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.config.AnthropicProperties;
import com.sejourfr.app.audioquestion.domain.AudioMode;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.audioquestion.dto.AnthropicGenerationResponse;
import com.sejourfr.app.audioquestion.dto.GenerateAudioQuestionRequest;
import com.sejourfr.app.audioquestion.dto.QuestionPreviewDto;
import com.sejourfr.app.audioquestion.entity.AudioQuestionGenerationLog;
import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import com.sejourfr.app.audioquestion.exception.AudioGenerationException;
import com.sejourfr.app.audioquestion.exception.ContentValidationException;
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
        // Refuse avant toute trace d'audit et tout appel payant : cette demande
        // ne demarre pas une generation, elle n'en est pas une.
        refuseModeNonGenerable(request.audioModeOrDefault());

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
            validateAudioMode(content, request.audioModeOrDefault());

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

    /**
     * Phrase d'amorce standardisee obligatoire au debut de TOUT audio CO.
     * Cherchee comme substring dans le SSML (avec et sans accent sur "Ecoutez/Repondez")
     * et dans le transcript. Toute deviation est un rejet 422.
     */
    private static final String INTRO_PHRASE = "Écoutez le document sonore, puis répondez à la question.";

    private static final java.util.List<String> EXPECTED_FULL_AUDIO_LABELS =
        java.util.List.of("Réponse A", "Réponse B", "Réponse C", "Réponse D");

    /**
     * Verifie que la reponse Claude respecte le mode audio demande :
     *  1. Le `audio.audioMode` retourne correspond au mode demande.
     *  2. L'amorce standardisee est presente dans le SSML et dans le transcript.
     *  3. En FULL_AUDIO : les `choices.label` sont strictement "Reponse A/B/C/D".
     *  4. En FULL_AUDIO : le SSML lit explicitement chaque "Reponse A/B/C/D".
     */
    /**
     * {@link AudioMode#WRITTEN_QUESTION_SPOKEN_CHOICES} <b>constate un defaut de
     * contenu, il ne se genere pas</b> : un audio qui enonce les propositions avec
     * leurs lettres alors que l'ecran affiche leur texte fige la correspondance
     * lettre <-> reponse, donc interdit tout melange et laisse le biais de
     * position en place. On ne produit pas volontairement de nouvelles questions
     * dans ce format ; la dette existante se solde en regenerant l'audio
     * <em>sans</em> les lettres.
     *
     * <p>Refuse AVANT tout appel payant (Claude, Azure).
     */
    private void refuseModeNonGenerable(AudioMode requestedMode) {
        if (requestedMode == AudioMode.WRITTEN_QUESTION_SPOKEN_CHOICES) {
            throw new BusinessException(
                "Le mode " + AudioMode.WRITTEN_QUESTION_SPOKEN_CHOICES
                    + " constate un defaut de contenu existant : il ne se genere pas. "
                    + "Modes generables : " + AudioMode.WRITTEN_QUESTION + ", " + AudioMode.FULL_AUDIO + "."
            );
        }
    }

    private void validateAudioMode(AnthropicGenerationResponse response, AudioMode requestedMode) {
        AudioMode returnedMode = response.audio().audioMode();

        if (returnedMode != requestedMode) {
            throw new ContentValidationException(
                "Mode audio retourne (" + returnedMode + ") different du mode demande (" + requestedMode + ")"
            );
        }

        String ssml = response.audio().ssml();
        String transcript = response.audio().transcript();
        if (!ssml.contains(INTRO_PHRASE)) {
            throw new ContentValidationException(
                "Le SSML doit obligatoirement contenir l'amorce standardisee : \"" + INTRO_PHRASE + "\""
            );
        }
        if (!transcript.contains(INTRO_PHRASE)) {
            throw new ContentValidationException(
                "Le transcript doit obligatoirement contenir l'amorce standardisee : \"" + INTRO_PHRASE + "\""
            );
        }

        if (returnedMode == AudioMode.FULL_AUDIO) {
            var choices = response.choices();
            for (int i = 0; i < EXPECTED_FULL_AUDIO_LABELS.size(); i++) {
                String expected = EXPECTED_FULL_AUDIO_LABELS.get(i);
                String actual = choices.get(i).label();
                if (!expected.equals(actual)) {
                    throw new ContentValidationException(
                        "En mode FULL_AUDIO, choices[" + i + "].label doit etre \"" + expected
                            + "\", recu : \"" + actual + "\""
                    );
                }
                if (!ssml.contains(expected)) {
                    throw new ContentValidationException(
                        "En mode FULL_AUDIO, le SSML doit contenir l'annonce \"" + expected + "\""
                    );
                }
            }
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
