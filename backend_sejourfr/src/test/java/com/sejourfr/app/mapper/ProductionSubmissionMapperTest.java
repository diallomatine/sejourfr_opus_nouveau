package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ProductionSubmissionDto;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.ConfianceEvaluation;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.service.ProductionAudioStorageService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Le mapper interroge AiEvaluationManager / TranscriptionManager (dernière éval
 * + transcription) et ProductionAudioStorageService (URL signée) : ces
 * collaborateurs touchent le repo / R2 et sont mockés. Le reste est du mapping
 * pur (sanitisation du feedback, branches null d'attempt / task).
 */
class ProductionSubmissionMapperTest {

    private AiEvaluationManager aiEvaluationManager;
    private TranscriptionManager transcriptionManager;
    private ProductionAudioStorageService audioStorage;
    private ProductionSubmissionMapper mapper;

    @BeforeEach
    void setUp() {
        aiEvaluationManager = mock(AiEvaluationManager.class);
        transcriptionManager = mock(TranscriptionManager.class);
        audioStorage = mock(ProductionAudioStorageService.class);
        mapper = new ProductionSubmissionMapper(aiEvaluationManager, transcriptionManager, audioStorage);
    }

    private ProductionSubmission submission(UUID id) {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(id);
        s.setStatut(SubmissionStatut.EVALUATED);
        s.setMediaUrl("eo/key.mp3");
        s.setTexteSoumis("Mon texte");
        s.setMotsCount(80);
        s.setMediaDurationSec(95);
        s.setRetryCount((short) 1);
        s.setErreurMessage(null);
        s.setSubmittedAt(Instant.parse("2026-03-01T10:00:00Z"));
        return s;
    }

    @Test
    void toDto_withEvalAndTranscription_sanitizesFeedbackAndMapsAllFields() {
        UUID id = UUID.randomUUID();
        UUID attemptId = UUID.randomUUID();
        UUID taskId = UUID.randomUUID();

        ProductionSubmission s = submission(id);
        Attempt attempt = new Attempt();
        attempt.setId(attemptId);
        s.setAttempt(attempt);
        ProductionTask task = new ProductionTask();
        task.setId(taskId);
        task.setTacheNumero((short) 2);
        s.setProductionTask(task);

        Map<String, Object> feedback = new LinkedHashMap<>();
        feedback.put("note_globale", 14);
        feedback.put("niveau_cecrl", "B1");
        feedback.put("justification_niveau", "secret interne");
        feedback.put("points_forts", "lexique");

        AiEvaluation eval = new AiEvaluation();
        eval.setNoteSur20(new BigDecimal("14.0"));
        eval.setFeedbackJson(feedback);

        when(aiEvaluationManager.findLatestBySubmissionId(id)).thenReturn(Optional.of(eval));
        when(transcriptionManager.findLatestTexteBySubmissionId(id))
                .thenReturn(Optional.of("transcription whisper"));

        ProductionSubmissionDto dto = mapper.toDto(s);

        assertThat(dto.id()).isEqualTo(id);
        assertThat(dto.attemptId()).isEqualTo(attemptId);
        assertThat(dto.productionTaskId()).isEqualTo(taskId);
        assertThat(dto.tacheNumero()).isEqualTo((short) 2);
        assertThat(dto.statut()).isEqualTo(SubmissionStatut.EVALUATED);
        assertThat(dto.mediaUrl()).isEqualTo("eo/key.mp3");
        assertThat(dto.texteSoumis()).isEqualTo("Mon texte");
        assertThat(dto.motsCount()).isEqualTo(80);
        assertThat(dto.mediaDurationSec()).isEqualTo(95);
        assertThat(dto.retryCount()).isEqualTo((short) 1);
        assertThat(dto.erreurMessage()).isNull();
        assertThat(dto.submittedAt()).isEqualTo(Instant.parse("2026-03-01T10:00:00Z"));
        assertThat(dto.transcription()).isEqualTo("transcription whisper");

        assertThat(dto.evaluation()).isNotNull();
        assertThat(dto.evaluation().noteSurVingt()).isEqualByComparingTo("14.0");
        assertThat(dto.evaluation().feedback())
                .containsEntry("note_globale", 14)
                .containsEntry("points_forts", "lexique")
                .doesNotContainKeys("niveau_cecrl", "justification_niveau");
        // La sanitisation ne doit pas muter la map d'origine de l'entité.
        assertThat(feedback).containsKey("niveau_cecrl");
    }

    @Test
    void toDto_evalV2_exposeLeNiveauObserveAvecSaConfiance() {
        UUID id = UUID.randomUUID();
        ProductionSubmission s = submission(id);
        s.setAttempt(null);
        s.setProductionTask(null);

        Map<String, Object> feedback = new LinkedHashMap<>();
        feedback.put("niveau_cecrl", "B1");
        feedback.put("confiance", "MOYENNE");

        AiEvaluation eval = new AiEvaluation();
        eval.setNoteSur20(new BigDecimal("13.0"));
        eval.setNiveauCecrl(NiveauCecrl.B1);
        eval.setFeedbackJson(feedback);

        when(aiEvaluationManager.findLatestBySubmissionId(id)).thenReturn(Optional.of(eval));
        when(transcriptionManager.findLatestTexteBySubmissionId(id)).thenReturn(Optional.empty());

        ProductionSubmissionDto dto = mapper.toDto(s);

        assertThat(dto.evaluation().niveauObserve()).isEqualTo(NiveauCecrl.B1);
        assertThat(dto.evaluation().confiance()).isEqualTo(ConfianceEvaluation.MOYENNE);
        assertThat(dto.evaluation().avertissementNiveau())
                .isEqualTo(ProductionSubmissionMapper.AVERTISSEMENT_NIVEAU);
        // Le niveau brut reste hors du feedback : une seule porte d'affichage.
        assertThat(dto.evaluation().feedback()).doesNotContainKey("niveau_cecrl");
    }

    @Test
    void toDto_evalLegacySansConfiance_nExposePasDeNiveau() {
        UUID id = UUID.randomUUID();
        ProductionSubmission s = submission(id);
        s.setAttempt(null);
        s.setProductionTask(null);

        // Feedback au format v3 : niveau persisté, mais aucune confiance.
        Map<String, Object> feedback = new LinkedHashMap<>();
        feedback.put("note_globale", 13);

        AiEvaluation eval = new AiEvaluation();
        eval.setNoteSur20(new BigDecimal("13.0"));
        eval.setNiveauCecrl(NiveauCecrl.B1);
        eval.setFeedbackJson(feedback);

        when(aiEvaluationManager.findLatestBySubmissionId(id)).thenReturn(Optional.of(eval));
        when(transcriptionManager.findLatestTexteBySubmissionId(id)).thenReturn(Optional.empty());

        ProductionSubmissionDto dto = mapper.toDto(s);

        assertThat(dto.evaluation().niveauObserve()).isNull();
        assertThat(dto.evaluation().confiance()).isNull();
        assertThat(dto.evaluation().avertissementNiveau()).isNull();
        assertThat(dto.evaluation().noteSurVingt()).isEqualByComparingTo("13.0");
    }

    @Test
    void toDto_nullEvalAndTranscriptionAndAssociations() {
        UUID id = UUID.randomUUID();
        ProductionSubmission s = submission(id);
        s.setAttempt(null);
        s.setProductionTask(null);

        when(aiEvaluationManager.findLatestBySubmissionId(id)).thenReturn(Optional.empty());
        when(transcriptionManager.findLatestTexteBySubmissionId(id)).thenReturn(Optional.empty());

        ProductionSubmissionDto dto = mapper.toDto(s);

        assertThat(dto.attemptId()).isNull();
        assertThat(dto.productionTaskId()).isNull();
        assertThat(dto.tacheNumero()).isNull();
        assertThat(dto.evaluation()).isNull();
        assertThat(dto.transcription()).isNull();
        assertThat(dto.mediaUrl()).isEqualTo("eo/key.mp3");
    }

    @Test
    void toDto_nullFeedbackJson_yieldNullFeedback() {
        UUID id = UUID.randomUUID();
        ProductionSubmission s = submission(id);
        s.setAttempt(null);
        s.setProductionTask(null);

        AiEvaluation eval = new AiEvaluation();
        eval.setNoteSur20(new BigDecimal("12.0"));
        eval.setFeedbackJson(null);

        when(aiEvaluationManager.findLatestBySubmissionId(id)).thenReturn(Optional.of(eval));
        when(transcriptionManager.findLatestTexteBySubmissionId(id)).thenReturn(Optional.empty());

        ProductionSubmissionDto dto = mapper.toDto(s);

        assertThat(dto.evaluation()).isNotNull();
        assertThat(dto.evaluation().noteSurVingt()).isEqualByComparingTo("12.0");
        assertThat(dto.evaluation().feedback()).isNull();
    }

    @Test
    void toDtoWithSignedAudio_replacesMediaUrlWithPresignedUrl() {
        UUID id = UUID.randomUUID();
        ProductionSubmission s = submission(id);
        s.setAttempt(null);
        s.setProductionTask(null);

        when(aiEvaluationManager.findLatestBySubmissionId(id)).thenReturn(Optional.empty());
        when(transcriptionManager.findLatestTexteBySubmissionId(id)).thenReturn(Optional.empty());
        when(audioStorage.presignGet("eo/key.mp3")).thenReturn("https://signed.example/key.mp3?sig=x");

        ProductionSubmissionDto dto = mapper.toDtoWithSignedAudio(s);

        assertThat(dto.mediaUrl()).isEqualTo("https://signed.example/key.mp3?sig=x");
        assertThat(dto.id()).isEqualTo(id);
        assertThat(dto.texteSoumis()).isEqualTo("Mon texte");
    }

    @Test
    void toDtoWithSignedAudio_blankMediaUrl_skipsPresign() {
        UUID id = UUID.randomUUID();
        ProductionSubmission s = submission(id);
        s.setAttempt(null);
        s.setProductionTask(null);
        s.setMediaUrl("   ");

        when(aiEvaluationManager.findLatestBySubmissionId(id)).thenReturn(Optional.empty());
        when(transcriptionManager.findLatestTexteBySubmissionId(id)).thenReturn(Optional.empty());

        ProductionSubmissionDto dto = mapper.toDtoWithSignedAudio(s);

        assertThat(dto.mediaUrl()).isEqualTo("   ");
        verify(audioStorage, never()).presignGet(any());
    }
}
