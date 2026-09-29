package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.dto.QuestionPreviewDto;
import com.sejourfr.app.audioquestion.dto.ValidationResultDto;
import com.sejourfr.app.audioquestion.entity.AudioQuestionGenerationLog;
import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import com.sejourfr.app.audioquestion.exception.QuestionNotDraftException;
import com.sejourfr.app.audioquestion.repository.AudioQuestionGenerationLogRepository;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Media;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.QuestionStatus;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.repository.MediaRepository;
import com.sejourfr.app.repository.QuestionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Cycle de vie d'une question audio CO : preview (re-fetch degrade), validate
 * (DRAFT -> ACTIVE) et reject (suppression DB + cleanup R2 best-effort). Repos et
 * client R2 mockes.
 */
@ExtendWith(MockitoExtension.class)
class AudioQuestionLifecycleServiceTest {

    @Mock private QuestionRepository questionRepository;
    @Mock private MediaRepository mediaRepository;
    @Mock private AudioQuestionGenerationLogRepository logRepository;
    @Mock private CloudflareR2Client r2Client;

    private AudioQuestionLifecycleService service;

    private final UUID questionId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new AudioQuestionLifecycleService(
            questionRepository, mediaRepository, logRepository, r2Client);
    }

    private Media audioMedia() {
        Media m = new Media();
        m.setId(UUID.randomUUID());
        m.setType(MediaType.AUDIO);
        m.setUrl("https://cdn/audio/x.mp3");
        m.setStorageKey("audio/x.mp3");
        m.setDurationSec(42);
        m.setTranscript("Bonjour");
        m.setAltText("contexte");
        return m;
    }

    private Question audioQuestion(QuestionStatus status, Media media) {
        Question q = new Question();
        q.setId(questionId);
        q.setQuestionType(QuestionType.CO);
        q.setDifficulty(Difficulty.B1);
        q.setStatement("Que dit le locuteur ?");
        q.setExplanation("Explication.");
        q.setStatus(status);
        q.setMedia(media);
        Choice c = new Choice();
        c.setLabel("Bonjour");
        c.setCorrect(true);
        c.setDisplayOrder(0);
        q.addChoice(c);
        return q;
    }

    @Test
    void loadAudioQuestion_inexistante_404() {
        when(questionRepository.findById(questionId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.preview(questionId))
            .isInstanceOf(NotFoundException.class);
    }

    @Test
    void loadAudioQuestion_non_co_404() {
        Question q = audioQuestion(QuestionStatus.ACTIVE, audioMedia());
        q.setQuestionType(QuestionType.CE);
        when(questionRepository.findById(questionId)).thenReturn(Optional.of(q));

        assertThatThrownBy(() -> service.preview(questionId))
            .isInstanceOf(NotFoundException.class);
    }

    @Test
    void loadAudioQuestion_sans_media_404() {
        Question q = audioQuestion(QuestionStatus.ACTIVE, null);
        when(questionRepository.findById(questionId)).thenReturn(Optional.of(q));

        assertThatThrownBy(() -> service.preview(questionId))
            .isInstanceOf(NotFoundException.class);
    }

    @Test
    void preview_construit_le_dto_depuis_le_dernier_log() {
        Question q = audioQuestion(QuestionStatus.DRAFT, audioMedia());
        when(questionRepository.findById(questionId)).thenReturn(Optional.of(q));
        AudioQuestionGenerationLog log = new AudioQuestionGenerationLog();
        log.setDurationMs(1234);
        log.setAnthropicCostEur(new BigDecimal("0.01000"));
        log.setAzureCostEur(new BigDecimal("0.00200"));
        log.setAzureCharactersCount(300);
        when(logRepository.findFirstByQuestionIdOrderByCreatedAtDesc(questionId))
            .thenReturn(Optional.of(log));

        QuestionPreviewDto dto = service.preview(questionId);

        assertThat(dto.questionId()).isEqualTo(questionId);
        assertThat(dto.status()).isEqualTo("DRAFT");
        assertThat(dto.audio().transcript()).isEqualTo("Bonjour");
        assertThat(dto.audio().durationSec()).isEqualTo(42);
        assertThat(dto.choices()).hasSize(1);
        assertThat(dto.metadata().generationDurationMs()).isEqualTo(1234L);
        assertThat(dto.metadata().costEur()).isEqualByComparingTo("0.01200");
        assertThat(dto.metadata().azureCharactersCount()).isEqualTo(300);
    }

    @Test
    void preview_sans_log_utilise_des_metriques_par_defaut() {
        Question q = audioQuestion(QuestionStatus.DRAFT, audioMedia());
        when(questionRepository.findById(questionId)).thenReturn(Optional.of(q));
        when(logRepository.findFirstByQuestionIdOrderByCreatedAtDesc(questionId))
            .thenReturn(Optional.empty());

        QuestionPreviewDto dto = service.preview(questionId);

        assertThat(dto.metadata().generationDurationMs()).isZero();
        assertThat(dto.metadata().costEur()).isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    void validate_passe_la_question_active() {
        Question q = audioQuestion(QuestionStatus.DRAFT, audioMedia());
        when(questionRepository.findById(questionId)).thenReturn(Optional.of(q));
        when(questionRepository.saveAndFlush(any(Question.class))).thenAnswer(inv -> inv.getArgument(0));
        UUID adminId = UUID.randomUUID();

        ValidationResultDto result = service.validate(questionId, adminId);

        assertThat(q.getStatus()).isEqualTo(QuestionStatus.ACTIVE);
        assertThat(q.isActive()).isTrue();
        assertThat(result.status()).isEqualTo("ACTIVE");
        assertThat(result.activatedAt()).isNotNull();
    }

    @Test
    void validate_refuse_une_question_non_draft() {
        Question q = audioQuestion(QuestionStatus.ACTIVE, audioMedia());
        when(questionRepository.findById(questionId)).thenReturn(Optional.of(q));

        assertThatThrownBy(() -> service.validate(questionId, UUID.randomUUID()))
            .isInstanceOf(QuestionNotDraftException.class);
        verify(questionRepository, never()).saveAndFlush(any());
    }

    @Test
    void reject_supprime_la_question_le_media_et_nettoie_r2() {
        Media media = audioMedia();
        Question q = audioQuestion(QuestionStatus.DRAFT, media);
        when(questionRepository.findById(questionId)).thenReturn(Optional.of(q));

        service.reject(questionId, UUID.randomUUID());

        verify(questionRepository).delete(q);
        verify(questionRepository).flush();
        verify(mediaRepository).deleteById(media.getId());
        verify(r2Client).deleteAudio("audio/x.mp3");
    }

    @Test
    void reject_refuse_une_question_non_draft() {
        Question q = audioQuestion(QuestionStatus.ACTIVE, audioMedia());
        when(questionRepository.findById(questionId)).thenReturn(Optional.of(q));

        assertThatThrownBy(() -> service.reject(questionId, UUID.randomUUID()))
            .isInstanceOf(QuestionNotDraftException.class);
        verify(questionRepository, never()).delete(any(Question.class));
    }
}
