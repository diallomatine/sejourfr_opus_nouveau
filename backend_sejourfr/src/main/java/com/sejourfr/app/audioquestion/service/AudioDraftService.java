package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.dto.AudioDraftDto;
import com.sejourfr.app.audioquestion.dto.BatchGenerationResultDto;
import com.sejourfr.app.audioquestion.dto.BatchGenerationResultDto.DraftOutcome;
import com.sejourfr.app.audioquestion.entity.AudioDraftStatus;
import com.sejourfr.app.audioquestion.entity.AudioQuestionDraft;
import com.sejourfr.app.audioquestion.repository.AudioQuestionDraftRepository;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client.R2UploadResult;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Media;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionStatus;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.repository.MediaRepository;
import com.sejourfr.app.repository.QuestionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Pipeline batch des drafts audio TCF CO.
 * Workflow complet :
 *   1. generateBatchAudio : prend 10 drafts TEXT_VALIDATED, genere l'audio via
 *      Azure Speech, upload R2, status -> AUDIO_PENDING_REVIEW.
 *   2. validateDraft : copie draft -> tables questions/choices/medias, status -> PUBLISHED.
 *   3. rejectDraft : marque le draft REJECTED avec la raison fournie.
 *
 * Les drafts sont inseres manuellement en base par script SQL externe (pas d'API d'import).
 *
 * generateBatchAudio est volontairement non-transactionnel : la reservation des
 * 10 drafts, puis chaque traitement unitaire, ouvre une transaction independante
 * via TransactionTemplate. Ainsi un echec d'azure/R2 sur le draft #4 ne rollback
 * pas les drafts #1-3 deja passes en AUDIO_PENDING_REVIEW.
 */
@Service
public class AudioDraftService {

    private static final Logger log = LoggerFactory.getLogger(AudioDraftService.class);

    private final AudioQuestionDraftRepository draftRepository;
    private final QuestionRepository questionRepository;
    private final MediaRepository mediaRepository;
    private final AzureSpeechClient azureSpeechClient;
    private final CloudflareR2Client r2Client;
    private final SsmlValidator ssmlValidator;
    private final TransactionTemplate txTemplate;

    public AudioDraftService(
            AudioQuestionDraftRepository draftRepository,
            QuestionRepository questionRepository,
            MediaRepository mediaRepository,
            AzureSpeechClient azureSpeechClient,
            CloudflareR2Client r2Client,
            SsmlValidator ssmlValidator,
            PlatformTransactionManager txManager) {
        this.draftRepository = draftRepository;
        this.questionRepository = questionRepository;
        this.mediaRepository = mediaRepository;
        this.azureSpeechClient = azureSpeechClient;
        this.r2Client = r2Client;
        this.ssmlValidator = ssmlValidator;
        this.txTemplate = new TransactionTemplate(txManager);
    }

    @Transactional(readOnly = true)
    public Page<AudioDraftDto> listPendingReview(Pageable pageable) {
        return draftRepository.findByStatus(AudioDraftStatus.AUDIO_PENDING_REVIEW, pageable)
            .map(AudioDraftDto::from);
    }

    @Transactional(readOnly = true)
    public long countPendingReview() {
        return draftRepository.countByStatus(AudioDraftStatus.AUDIO_PENDING_REVIEW);
    }

    /**
     * Selectionne jusqu'a 10 drafts TEXT_VALIDATED (les plus anciens d'abord),
     * leur assigne un meme batch_id, puis traite chacun 1 par 1 :
     *   - status -> AUDIO_GENERATING (commit immediat)
     *   - synthese Azure + upload R2
     *   - status -> AUDIO_PENDING_REVIEW avec audio_url, audio_duration_sec, etc.
     *   - en cas d'erreur : status remis a TEXT_VALIDATED, batch_id efface (retry possible)
     */
    public BatchGenerationResultDto generateBatchAudio() {
        List<UUID> draftIds = pickAndReserveBatch();
        if (draftIds.isEmpty()) {
            return new BatchGenerationResultDto(null, 0, 0, 0, List.of());
        }
        UUID batchId = txTemplate.execute(status ->
            draftRepository.findById(draftIds.get(0))
                .map(AudioQuestionDraft::getBatchId)
                .orElse(null)
        );

        List<DraftOutcome> outcomes = new ArrayList<>(draftIds.size());
        int succeeded = 0;
        int failed = 0;

        for (UUID draftId : draftIds) {
            try {
                processOne(draftId);
                outcomes.add(new DraftOutcome(draftId, true, null));
                succeeded++;
            } catch (RuntimeException ex) {
                log.error("Generation audio draft {} echec : {}", draftId, ex.getMessage(), ex);
                resetToTextValidated(draftId);
                outcomes.add(new DraftOutcome(draftId, false, truncate(ex.getMessage(), 500)));
                failed++;
            }
        }

        log.info(
            "Batch audio drafts batchId={} requested={} succeeded={} failed={}",
            batchId, draftIds.size(), succeeded, failed
        );
        return new BatchGenerationResultDto(batchId, draftIds.size(), succeeded, failed, outcomes);
    }

    private List<UUID> pickAndReserveBatch() {
        return txTemplate.execute(status -> {
            List<AudioQuestionDraft> picked = draftRepository.findTop10ByStatusOrderByCreatedAtAsc(
                AudioDraftStatus.TEXT_VALIDATED
            );
            if (picked.isEmpty()) return List.<UUID>of();
            UUID batchId = UUID.randomUUID();
            List<UUID> ids = new ArrayList<>(picked.size());
            for (AudioQuestionDraft d : picked) {
                d.setStatus(AudioDraftStatus.AUDIO_GENERATING);
                d.setBatchId(batchId);
                ids.add(d.getId());
            }
            draftRepository.saveAll(picked);
            return ids;
        });
    }

    private void processOne(UUID draftId) {
        AudioQuestionDraft draft = txTemplate.execute(status ->
            draftRepository.findById(draftId)
                .orElseThrow(() -> new NotFoundException("Draft " + draftId + " disparu pendant batch"))
        );

        // Appels externes hors transaction DB : Azure peut prendre 5-15s, on ne tient
        // pas une connexion Postgres bloquee pendant ce temps.
        // Nettoyage prealable du SSML (orphan <break/> entre <voice>), identique au pipeline unitaire.
        String cleanedSsml = ssmlValidator.cleanForAzure(draft.getSsmlText());
        byte[] mp3 = azureSpeechClient.synthesize(cleanedSsml);
        UUID mediaId = UUID.randomUUID();
        R2UploadResult r2 = r2Client.uploadAudio(mediaId, mp3);
        Integer durationSec = estimateDurationSec(mp3.length);

        txTemplate.executeWithoutResult(status -> {
            AudioQuestionDraft fresh = draftRepository.findById(draftId)
                .orElseThrow(() -> new NotFoundException("Draft " + draftId + " disparu apres synthese"));
            fresh.setAudioUrl(r2.publicUrl());
            fresh.setAudioDurationSec(durationSec);
            fresh.setAudioVoiceUsed(fresh.getVoiceRecommended());
            fresh.setAudioGeneratedAt(Instant.now());
            fresh.setStatus(AudioDraftStatus.AUDIO_PENDING_REVIEW);
            draftRepository.save(fresh);
        });
    }

    private void resetToTextValidated(UUID draftId) {
        try {
            txTemplate.executeWithoutResult(status ->
                draftRepository.findById(draftId).ifPresent(d -> {
                    d.setStatus(AudioDraftStatus.TEXT_VALIDATED);
                    d.setBatchId(null);
                    d.setAudioUrl(null);
                    d.setAudioDurationSec(null);
                    d.setAudioVoiceUsed(null);
                    d.setAudioGeneratedAt(null);
                    draftRepository.save(d);
                })
            );
        } catch (RuntimeException reset) {
            log.error("Reset draft {} echec apres erreur : {}", draftId, reset.getMessage());
        }
    }

    /**
     * Copie le draft (audio + question + 4 choix) vers les tables principales
     * questions/choices/medias, puis passe le draft en PUBLISHED.
     */
    @Transactional
    public AudioDraftDto validateDraft(UUID draftId, UUID adminUserId) {
        AudioQuestionDraft draft = loadDraft(draftId);
        if (draft.getStatus() != AudioDraftStatus.AUDIO_PENDING_REVIEW) {
            throw new IllegalStateException(
                "Seuls les drafts AUDIO_PENDING_REVIEW peuvent etre valides (actuel : " + draft.getStatus() + ")"
            );
        }
        if (draft.getAudioUrl() == null || draft.getAudioUrl().isBlank()) {
            throw new IllegalStateException("Draft " + draftId + " n'a pas d'audio_url");
        }

        Theme theme = draft.getTheme();

        Media media = new Media();
        media.setType(MediaType.AUDIO);
        media.setContentType("audio/mpeg");
        media.setDurationSec(draft.getAudioDurationSec());
        media.setUrl(draft.getAudioUrl());
        media.setStorageKey(extractObjectKey(draft.getAudioUrl()));
        media.setTranscript(draft.getTranscriptText());
        media = mediaRepository.saveAndFlush(media);

        Question q = new Question();
        q.setModule(Module.TCF);
        q.setTheme(theme);
        q.setDifficulty(draft.getDifficulty());
        q.setQuestionType(QuestionType.CO);
        q.setStatement(draft.getStatement());
        q.setExplanation(draft.getExplanation());
        q.setCompetenceCode(draft.getCompetenceCode());
        q.setMedia(media);
        q.setActive(true);
        q.setStatus(QuestionStatus.ACTIVE);

        List<AudioQuestionDraft.DraftChoice> draftChoices = draft.getChoices();
        if (draftChoices != null) {
            for (AudioQuestionDraft.DraftChoice c : draftChoices) {
                Choice choice = new Choice();
                choice.setLabel(c.label());
                choice.setCorrect(c.isCorrect());
                choice.setDisplayOrder(c.displayOrder());
                q.addChoice(choice);
            }
        }
        questionRepository.saveAndFlush(q);

        draft.setStatus(AudioDraftStatus.PUBLISHED);
        draft.setAudioValidatedAt(Instant.now());
        draft.setAudioValidatedBy(adminUserId != null ? adminUserId.toString() : null);
        AudioQuestionDraft saved = draftRepository.save(draft);

        log.info("Draft {} publie en question {} par admin {}", draftId, q.getId(), adminUserId);
        return AudioDraftDto.from(saved);
    }

    @Transactional
    public AudioDraftDto rejectDraft(UUID draftId, String reason, UUID adminUserId) {
        AudioQuestionDraft draft = loadDraft(draftId);
        if (draft.getStatus() == AudioDraftStatus.PUBLISHED) {
            throw new IllegalStateException("Draft deja publie, rejet impossible");
        }
        draft.setStatus(AudioDraftStatus.REJECTED);
        draft.setRejectionReason(reason);
        draft.setAudioValidatedAt(Instant.now());
        draft.setAudioValidatedBy(adminUserId != null ? adminUserId.toString() : null);
        AudioQuestionDraft saved = draftRepository.save(draft);
        log.info("Draft {} rejete par admin {} : {}", draftId, adminUserId, truncate(reason, 200));
        return AudioDraftDto.from(saved);
    }

    private AudioQuestionDraft loadDraft(UUID draftId) {
        return draftRepository.findById(draftId)
            .orElseThrow(() -> NotFoundException.of("AudioQuestionDraft", draftId));
    }

    /**
     * Estimation grossiere de la duree audio depuis la taille MP3.
     * Azure TTS sort par defaut en audio-24khz-48kbitrate-mono-mp3 (~6 kB/s).
     */
    private static Integer estimateDurationSec(int mp3Bytes) {
        if (mp3Bytes <= 0) return null;
        return Math.max(1, mp3Bytes / 6000);
    }

    /**
     * Extrait la cle R2 (audio/{uuid}.mp3) depuis une publicUrl.
     */
    private static String extractObjectKey(String publicUrl) {
        if (publicUrl == null) return null;
        int idx = publicUrl.indexOf("/audio/");
        if (idx < 0) return null;
        return publicUrl.substring(idx + 1);
    }

    private static String truncate(String s, int max) {
        if (s == null) return null;
        return s.length() > max ? s.substring(0, max) : s;
    }
}
