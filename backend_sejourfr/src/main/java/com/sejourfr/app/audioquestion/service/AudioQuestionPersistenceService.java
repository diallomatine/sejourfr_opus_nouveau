package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.dto.AnthropicGenerationResponse;
import com.sejourfr.app.audioquestion.dto.QuestionPreviewDto;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client.R2UploadResult;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Media;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionStatus;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.repository.MediaRepository;
import com.sejourfr.app.repository.QuestionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Persiste atomiquement le triplet Media (AUDIO) + Question (DRAFT) + 4 Choice,
 * et delegue l'upload R2 a l'orchestrateur via un callback. L'ordre est :
 *
 *   1. Media SANS id (Hibernate genere via @UuidGenerator) + persist initial
 *   2. Upload R2 avec l'id genere (callback) -> {objectKey, publicUrl}
 *   3. Media.url + Media.storageKey ecrits (auto-flush dans la transaction)
 *   4. Question + Choices persistes
 *
 * Si l'upload R2 echoue, la transaction rollback => Media n'est jamais commit.
 * Si l'INSERT Question echoue, l'orchestrateur supprime le MP3 R2 manuellement.
 */
@Service
public class AudioQuestionPersistenceService {

    private final QuestionRepository questionRepository;
    private final MediaRepository mediaRepository;
    private final TcfCoThemeResolver themeResolver;

    public AudioQuestionPersistenceService(
            QuestionRepository questionRepository,
            MediaRepository mediaRepository,
            TcfCoThemeResolver themeResolver) {
        this.questionRepository = questionRepository;
        this.mediaRepository = mediaRepository;
        this.themeResolver = themeResolver;
    }

    /**
     * Callback fonctionnel pour effectuer l'upload R2 une fois l'id Media connu.
     * @return l'AdresseObjet R2 (key + url publique)
     */
    @FunctionalInterface
    public interface R2Uploader {
        R2UploadResult upload(UUID mediaId);
    }

    @Transactional
    public PersistenceResult persistAndUpload(
            byte[] mp3Bytes,
            AnthropicGenerationResponse claudeResponse,
            PersistenceMetadata metadata,
            R2Uploader r2Uploader) {

        Theme theme = themeResolver.resolve();
        AnthropicGenerationResponse.AudioSection audio = claudeResponse.audio();
        AnthropicGenerationResponse.QuestionSection q = claudeResponse.question();

        Media media = new Media();
        media.setType(MediaType.AUDIO);
        media.setContentType("audio/mpeg");
        media.setSizeBytes((long) mp3Bytes.length);
        media.setDurationSec(audio.estimatedDurationSec());
        media.setAltText(audio.contextDescription());
        media.setTranscript(audio.transcript());
        media = mediaRepository.saveAndFlush(media);

        R2UploadResult r2Result = r2Uploader.upload(media.getId());
        media.setUrl(r2Result.publicUrl());
        media.setStorageKey(r2Result.objectKey());

        Question question = new Question();
        question.setModule(Module.TCF);
        question.setTheme(theme);
        question.setDifficulty(Difficulty.valueOf(q.difficulty()));
        question.setQuestionType(QuestionType.CO);
        question.setStatement(q.statement());
        question.setExplanation(q.explanation());
        question.setMedia(media);
        question.setActive(false);
        question.setStatus(QuestionStatus.DRAFT);
        question.setTcfSubTheme(q.themeSuggested());
        question.setCompetenceCode(q.competenceCode());
        question.setAudioMode(audio.audioMode());

        for (AnthropicGenerationResponse.ChoiceSection c : claudeResponse.choices()) {
            Choice choice = new Choice();
            choice.setLabel(c.label());
            choice.setCorrect(c.isCorrect());
            choice.setDisplayOrder(c.displayOrder());
            question.addChoice(choice);
        }

        Question saved = questionRepository.saveAndFlush(question);

        QuestionPreviewDto preview = toPreview(
            saved, q.themeSuggested(), q.competenceCode(), q.difficulty(), audio, metadata
        );
        return new PersistenceResult(preview, r2Result);
    }

    private static QuestionPreviewDto toPreview(
            Question saved,
            String themeSuggested,
            String competenceCode,
            String difficulty,
            AnthropicGenerationResponse.AudioSection audio,
            PersistenceMetadata metadata) {

        QuestionPreviewDto.AudioPreviewDto audioDto = new QuestionPreviewDto.AudioPreviewDto(
            saved.getMedia().getId(),
            saved.getMedia().getUrl(),
            audio.estimatedDurationSec(),
            audio.speakerCount(),
            audio.voices().stream()
                .map(v -> new QuestionPreviewDto.VoiceDto(v.role(), v.azureVoice(), v.gender()))
                .toList(),
            audio.transcript(),
            audio.contextDescription(),
            audio.audioMode()
        );

        QuestionPreviewDto.QuestionContentDto questionDto = new QuestionPreviewDto.QuestionContentDto(
            saved.getStatement(),
            saved.getExplanation(),
            competenceCode,
            difficulty,
            themeSuggested
        );

        List<QuestionPreviewDto.ChoiceDto> choices = saved.getChoices().stream()
            .sorted((a, b) -> Integer.compare(a.getDisplayOrder(), b.getDisplayOrder()))
            .map(c -> new QuestionPreviewDto.ChoiceDto(
                c.getId(), c.getLabel(), c.isCorrect(), c.getDisplayOrder()
            ))
            .toList();

        QuestionPreviewDto.GenerationMetadataDto metadataDto = new QuestionPreviewDto.GenerationMetadataDto(
            metadata.generatedAt(),
            metadata.generationDurationMs(),
            metadata.costEur(),
            metadata.anthropicInputTokens(),
            metadata.anthropicOutputTokens(),
            metadata.anthropicCacheReadTokens(),
            metadata.azureCharactersCount()
        );

        return new QuestionPreviewDto(
            saved.getId(),
            saved.getStatus().name(),
            audioDto,
            questionDto,
            choices,
            metadataDto
        );
    }

    public record PersistenceMetadata(
        Instant generatedAt,
        long generationDurationMs,
        BigDecimal costEur,
        Integer anthropicInputTokens,
        Integer anthropicOutputTokens,
        Integer anthropicCacheReadTokens,
        Integer azureCharactersCount
    ) {}

    public record PersistenceResult(QuestionPreviewDto preview, R2UploadResult r2Result) {}
}
