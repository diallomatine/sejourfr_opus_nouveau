package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.config.AnthropicProperties;
import com.sejourfr.app.audioquestion.domain.AudioMode;
import com.sejourfr.app.audioquestion.dto.AnthropicGenerationResponse;
import com.sejourfr.app.audioquestion.dto.GenerateAudioQuestionRequest;
import com.sejourfr.app.audioquestion.dto.QuestionPreviewDto;
import com.sejourfr.app.audioquestion.entity.AudioQuestionGenerationLog;
import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import com.sejourfr.app.audioquestion.exception.ContentValidationException;
import com.sejourfr.app.audioquestion.exception.DuplicateContentException;
import com.sejourfr.app.audioquestion.repository.AudioQuestionGenerationLogRepository;
import com.sejourfr.app.audioquestion.service.AudioQuestionPersistenceService.PersistenceResult;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client.R2UploadResult;
import com.sejourfr.app.audioquestion.service.SsmlValidator.ValidationResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tools.jackson.databind.ObjectMapper;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Orchestrateur de generation audio CO : enchainement rate-limit -> Claude ->
 * validation mode/amorce -> SSML -> anti-doublon -> Azure -> persistence, audit
 * loggue a chaque issue. Tous les clients externes sont mockes (aucun reseau/DB).
 * Le calcul de cout utilise le vrai {@link CostCalculator}.
 */
@ExtendWith(MockitoExtension.class)
class AudioQuestionGenerationServiceTest {

    private static final String INTRO = "Écoutez le document sonore, puis répondez à la question.";

    @Mock private AnthropicClient anthropicClient;
    @Mock private AzureSpeechClient azureSpeechClient;
    @Mock private CloudflareR2Client r2Client;
    @Mock private SsmlValidator ssmlValidator;
    @Mock private DuplicateDetectionService duplicateService;
    @Mock private GenerationRateLimiter rateLimiter;
    @Mock private AudioQuestionPersistenceService persistenceService;
    @Mock private AudioQuestionGenerationLogRepository logRepository;
    @Mock private ObjectMapper objectMapper;

    private final CostCalculator costCalculator = new CostCalculator();
    private final AnthropicProperties anthropicProps = new AnthropicProperties();

    private AudioQuestionGenerationService service;

    private final UUID adminId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new AudioQuestionGenerationService(
            anthropicClient, azureSpeechClient, r2Client, ssmlValidator, duplicateService,
            rateLimiter, costCalculator, persistenceService, logRepository, anthropicProps, objectMapper);
    }

    private AnthropicGenerationResponse content(AudioMode mode, String ssml, String transcript,
                                                List<AnthropicGenerationResponse.ChoiceSection> choices) {
        AnthropicGenerationResponse.AudioSection audio = new AnthropicGenerationResponse.AudioSection(
            transcript, ssml, 1,
            List.of(new AnthropicGenerationResponse.VoiceInfo("narrateur", "fr-FR-DeniseNeural", "F")),
            30, "contexte", mode);
        AnthropicGenerationResponse.QuestionSection question = new AnthropicGenerationResponse.QuestionSection(
            "Que dit le locuteur ?",
            "Explication suffisamment longue pour respecter la contrainte de taille minimale.",
            "co_detail_specifique", "B1", "vie_pratique_logement");
        return new AnthropicGenerationResponse(audio, question, choices);
    }

    private List<AnthropicGenerationResponse.ChoiceSection> writtenChoices() {
        return List.of(
            new AnthropicGenerationResponse.ChoiceSection("Bonjour", true, 1),
            new AnthropicGenerationResponse.ChoiceSection("Bonsoir", false, 2),
            new AnthropicGenerationResponse.ChoiceSection("Salut", false, 3),
            new AnthropicGenerationResponse.ChoiceSection("Au revoir", false, 4));
    }

    private AnthropicClient.Outcome outcome(AnthropicGenerationResponse content) {
        return new AnthropicClient.Outcome(content, 1000, 500, 0);
    }

    private GenerateAudioQuestionRequest request(AudioMode mode) {
        return new GenerateAudioQuestionRequest("B1", null, null, null, null, mode);
    }

    @Test
    void generate_modeQuiConstateUnDefaut_refuseAvantToutAppelPayant() {
        // WRITTEN_QUESTION_SPOKEN_CHOICES qualifie un audio existant qui enonce
        // les propositions avec leurs lettres : on ne produit pas de nouveau
        // contenu dans ce format, la dette se solde en regenerant l'audio SANS
        // les lettres. Refus avant Claude, Azure, rate-limit et audit.
        assertThatThrownBy(() -> service.generate(
                request(AudioMode.WRITTEN_QUESTION_SPOKEN_CHOICES), adminId))
            .isInstanceOf(com.sejourfr.app.exception.BusinessException.class)
            .hasMessageContaining("WRITTEN_QUESTION_SPOKEN_CHOICES");

        verify(rateLimiter, never()).checkAllowed(any());
        verify(anthropicClient, never()).generate(any());
        verify(azureSpeechClient, never()).synthesize(anyString());
        verify(logRepository, never()).save(any());
    }

    @Test
    void generate_happy_path_renvoie_le_preview_et_loggue_success() {
        String ssml = "<speak>" + INTRO + "</speak>";
        String transcript = INTRO + " Bonjour";
        AnthropicGenerationResponse content = content(AudioMode.WRITTEN_QUESTION, ssml, transcript, writtenChoices());
        when(anthropicClient.generate(any())).thenReturn(outcome(content));
        when(ssmlValidator.validate(any())).thenReturn(
            new ValidationResult(ssml, "Bonjour", 250, List.of("fr-FR-DeniseNeural")));
        when(azureSpeechClient.synthesize(ssml)).thenReturn(new byte[]{1, 2, 3});
        UUID questionId = UUID.randomUUID();
        QuestionPreviewDto preview = new QuestionPreviewDto(questionId, "DRAFT", null, null, List.of(), null);
        when(persistenceService.persistAndUpload(any(), any(), any(), any()))
            .thenReturn(new PersistenceResult(preview, new R2UploadResult("audio/x.mp3", "https://cdn/audio/x.mp3")));

        QuestionPreviewDto result = service.generate(request(AudioMode.WRITTEN_QUESTION), adminId);

        assertThat(result).isSameAs(preview);
        ArgumentCaptor<AudioQuestionGenerationLog> audit = ArgumentCaptor.forClass(AudioQuestionGenerationLog.class);
        verify(logRepository).save(audit.capture());
        assertThat(audit.getValue().getStatus()).isEqualTo(GenerationStatus.SUCCESS);
        assertThat(audit.getValue().getQuestionId()).isEqualTo(questionId);
        verify(rateLimiter).checkAllowed(adminId);
        verify(duplicateService).checkNotDuplicate(transcript, "B1");
    }

    @Test
    void generate_rejette_un_mode_audio_different_du_demande() {
        // Demande FULL_AUDIO, Claude renvoie WRITTEN_QUESTION.
        String ssml = "<speak>" + INTRO + "</speak>";
        AnthropicGenerationResponse content = content(AudioMode.WRITTEN_QUESTION, ssml, INTRO, writtenChoices());
        when(anthropicClient.generate(any())).thenReturn(outcome(content));

        assertThatThrownBy(() -> service.generate(request(AudioMode.FULL_AUDIO), adminId))
            .isInstanceOf(ContentValidationException.class);

        verify(ssmlValidator, never()).validate(any());
        ArgumentCaptor<AudioQuestionGenerationLog> audit = ArgumentCaptor.forClass(AudioQuestionGenerationLog.class);
        verify(logRepository).save(audit.capture());
        assertThat(audit.getValue().getStatus()).isEqualTo(GenerationStatus.FAILED_CONTENT_VALIDATION);
    }

    @Test
    void generate_rejette_un_ssml_sans_amorce_standardisee() {
        AnthropicGenerationResponse content = content(
            AudioMode.WRITTEN_QUESTION, "<speak>Bonjour</speak>", INTRO + " Bonjour", writtenChoices());
        when(anthropicClient.generate(any())).thenReturn(outcome(content));

        assertThatThrownBy(() -> service.generate(request(AudioMode.WRITTEN_QUESTION), adminId))
            .isInstanceOf(ContentValidationException.class);
        verify(azureSpeechClient, never()).synthesize(anyString());
    }

    @Test
    void generate_full_audio_exige_les_libelles_reponse_a_b_c_d() {
        String ssml = "<speak>" + INTRO + " Réponse A Réponse B Réponse C Réponse D</speak>";
        AnthropicGenerationResponse content = content(AudioMode.FULL_AUDIO, ssml, INTRO + " texte", writtenChoices());
        when(anthropicClient.generate(any())).thenReturn(outcome(content));

        assertThatThrownBy(() -> service.generate(request(AudioMode.FULL_AUDIO), adminId))
            .isInstanceOf(ContentValidationException.class);
    }

    @Test
    void generate_propage_un_doublon_et_loggue_failed_duplicate() {
        String ssml = "<speak>" + INTRO + "</speak>";
        String transcript = INTRO + " Bonjour";
        AnthropicGenerationResponse content = content(AudioMode.WRITTEN_QUESTION, ssml, transcript, writtenChoices());
        when(anthropicClient.generate(any())).thenReturn(outcome(content));
        when(ssmlValidator.validate(any())).thenReturn(
            new ValidationResult(ssml, "Bonjour", 250, List.of("fr-FR-DeniseNeural")));
        doThrowDuplicate();

        assertThatThrownBy(() -> service.generate(request(AudioMode.WRITTEN_QUESTION), adminId))
            .isInstanceOf(DuplicateContentException.class);

        verify(azureSpeechClient, never()).synthesize(anyString());
        verify(persistenceService, never()).persistAndUpload(any(), any(), any(), any());
        ArgumentCaptor<AudioQuestionGenerationLog> audit = ArgumentCaptor.forClass(AudioQuestionGenerationLog.class);
        verify(logRepository).save(audit.capture());
        assertThat(audit.getValue().getStatus()).isEqualTo(GenerationStatus.FAILED_DUPLICATE);
    }

    private void doThrowDuplicate() {
        org.mockito.Mockito.doThrow(new DuplicateContentException("doublon"))
            .when(duplicateService).checkNotDuplicate(anyString(), anyString());
    }
}
