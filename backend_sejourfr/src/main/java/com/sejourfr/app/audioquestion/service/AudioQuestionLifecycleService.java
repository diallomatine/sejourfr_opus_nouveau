package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.dto.QuestionPreviewDto;
import com.sejourfr.app.audioquestion.dto.ValidationResultDto;
import com.sejourfr.app.audioquestion.entity.AudioQuestionGenerationLog;
import com.sejourfr.app.audioquestion.exception.QuestionNotDraftException;
import com.sejourfr.app.audioquestion.repository.AudioQuestionGenerationLogRepository;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Media;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.QuestionStatus;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.repository.MediaRepository;
import com.sejourfr.app.repository.QuestionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Operations sur une question audio existante :
 *   - {@link #preview} : re-fetch d'un DRAFT (admin recharge la page)
 *   - {@link #validate} : DRAFT -> ACTIVE
 *   - {@link #reject} : DELETE DRAFT (DB cascade) + cleanup R2 best-effort
 *
 * Le re-fetch est "degrade" : les voices et le speakerCount du SSML ne sont
 * pas stockes, donc renvoyes vides/0. Le MP3, transcript, question, choices,
 * explication, contextDescription et metriques de cout restent disponibles.
 */
@Service
public class AudioQuestionLifecycleService {

    private static final Logger log = LoggerFactory.getLogger(AudioQuestionLifecycleService.class);

    private final QuestionRepository questionRepository;
    private final MediaRepository mediaRepository;
    private final AudioQuestionGenerationLogRepository logRepository;
    private final CloudflareR2Client r2Client;

    public AudioQuestionLifecycleService(
            QuestionRepository questionRepository,
            MediaRepository mediaRepository,
            AudioQuestionGenerationLogRepository logRepository,
            CloudflareR2Client r2Client) {
        this.questionRepository = questionRepository;
        this.mediaRepository = mediaRepository;
        this.logRepository = logRepository;
        this.r2Client = r2Client;
    }

    @Transactional(readOnly = true)
    public QuestionPreviewDto preview(UUID questionId) {
        Question q = loadAudioQuestion(questionId);
        return buildPreview(q);
    }

    @Transactional
    public ValidationResultDto validate(UUID questionId, UUID adminUserId) {
        Question q = loadAudioQuestion(questionId);
        if (q.getStatus() != QuestionStatus.DRAFT) {
            throw new QuestionNotDraftException(
                "La question n'est pas en DRAFT (statut actuel : " + q.getStatus() + ")"
            );
        }
        q.setStatus(QuestionStatus.ACTIVE);
        q.setActive(true);
        Question saved = questionRepository.saveAndFlush(q);
        Instant activatedAt = saved.getUpdatedAt() != null ? saved.getUpdatedAt() : Instant.now();
        log.info("Question audio {} validee (ACTIVE) par admin {}", questionId, adminUserId);
        return new ValidationResultDto(saved.getId(), saved.getStatus().name(), activatedAt);
    }

    @Transactional
    public void reject(UUID questionId, UUID adminUserId) {
        Question q = loadAudioQuestion(questionId);
        if (q.getStatus() != QuestionStatus.DRAFT) {
            throw new QuestionNotDraftException(
                "Seules les questions en DRAFT peuvent etre rejetees. Statut actuel : " + q.getStatus()
            );
        }
        Media media = q.getMedia();
        String objectKey = media != null ? media.getStorageKey() : null;
        UUID mediaId = media != null ? media.getId() : null;

        questionRepository.delete(q);
        questionRepository.flush();
        if (mediaId != null) {
            mediaRepository.deleteById(mediaId);
        }
        if (objectKey != null && !objectKey.isBlank()) {
            try {
                r2Client.deleteAudio(objectKey);
            } catch (Exception cleanup) {
                log.warn("R2 cleanup echec pour {} : {}", objectKey, cleanup.getMessage());
            }
        }
        log.info("Question audio {} rejetee/supprimee par admin {}", questionId, adminUserId);
    }

    private Question loadAudioQuestion(UUID questionId) {
        Question q = questionRepository.findById(questionId)
            .orElseThrow(() -> new NotFoundException("Question " + questionId + " inexistante"));
        if (q.getQuestionType() != QuestionType.CO || q.getMedia() == null
                || q.getMedia().getType() != MediaType.AUDIO) {
            throw new NotFoundException("Question " + questionId + " n'est pas une question audio CO");
        }
        return q;
    }

    private QuestionPreviewDto buildPreview(Question q) {
        Media media = q.getMedia();
        Optional<AudioQuestionGenerationLog> latestLog =
            logRepository.findFirstByQuestionIdOrderByCreatedAtDesc(q.getId());

        QuestionPreviewDto.AudioPreviewDto audioDto = new QuestionPreviewDto.AudioPreviewDto(
            media.getId(),
            media.getUrl(),
            media.getDurationSec() != null ? media.getDurationSec() : 0,
            0,
            Collections.emptyList(),
            media.getTranscript(),
            media.getAltText(),
            q.getAudioMode()
        );

        QuestionPreviewDto.QuestionContentDto questionDto = new QuestionPreviewDto.QuestionContentDto(
            q.getStatement(),
            q.getExplanation(),
            q.getCompetenceCode(),
            q.getDifficulty().name(),
            q.getTcfSubTheme()
        );

        List<QuestionPreviewDto.ChoiceDto> choices = q.getChoices().stream()
            .sorted((a, b) -> Integer.compare(a.getDisplayOrder(), b.getDisplayOrder()))
            .map(this::toChoiceDto)
            .toList();

        QuestionPreviewDto.GenerationMetadataDto metadataDto = latestLog
            .map(l -> new QuestionPreviewDto.GenerationMetadataDto(
                l.getCreatedAt(),
                l.getDurationMs() != null ? l.getDurationMs() : 0L,
                sumCosts(l.getAnthropicCostEur(), l.getAzureCostEur()),
                l.getAnthropicInputTokens(),
                l.getAnthropicOutputTokens(),
                l.getAnthropicCacheReadTokens(),
                l.getAzureCharactersCount()
            ))
            .orElse(new QuestionPreviewDto.GenerationMetadataDto(
                q.getCreatedAt(), 0L, BigDecimal.ZERO, null, null, null, null
            ));

        return new QuestionPreviewDto(
            q.getId(),
            q.getStatus().name(),
            audioDto,
            questionDto,
            choices,
            metadataDto
        );
    }

    private QuestionPreviewDto.ChoiceDto toChoiceDto(Choice c) {
        return new QuestionPreviewDto.ChoiceDto(
            c.getId(), c.getLabel(), c.isCorrect(), c.getDisplayOrder()
        );
    }

    private static BigDecimal sumCosts(BigDecimal a, BigDecimal b) {
        BigDecimal x = a != null ? a : BigDecimal.ZERO;
        BigDecimal y = b != null ? b : BigDecimal.ZERO;
        return x.add(y);
    }
}
