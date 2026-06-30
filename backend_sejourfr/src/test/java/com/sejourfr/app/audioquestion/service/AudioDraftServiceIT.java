package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.dto.AudioDraftDto;
import com.sejourfr.app.audioquestion.dto.BatchGenerationResultDto;
import com.sejourfr.app.audioquestion.entity.AudioDraftStatus;
import com.sejourfr.app.audioquestion.entity.AudioQuestionDraft;
import com.sejourfr.app.audioquestion.repository.AudioQuestionDraftRepository;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client.R2UploadResult;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.QuestionStatus;
import com.sejourfr.app.repository.QuestionRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

/**
 * Tests d'integration du pipeline batch des drafts audio. Les transitions de
 * statut et la copie draft -> questions sont verifiees en base reelle ; Azure
 * Speech et Cloudflare R2 sont remplaces par des mocks (pas d'appel externe).
 */
class AudioDraftServiceIT extends AbstractIntegrationTest {

    @Autowired private AudioDraftService service;
    @Autowired private TestData testData;
    @Autowired private AudioQuestionDraftRepository draftRepository;
    @Autowired private QuestionRepository questionRepository;

    @MockitoBean private AzureSpeechClient azureSpeechClient;
    @MockitoBean private CloudflareR2Client r2Client;

    private AudioQuestionDraft pendingReviewDraft() {
        AudioQuestionDraft d = testData.audioQuestionDraft();
        d.setStatus(AudioDraftStatus.AUDIO_PENDING_REVIEW);
        d.setAudioUrl("https://cdn.test/audio/" + UUID.randomUUID() + ".mp3");
        d.setAudioDurationSec(42);
        return draftRepository.save(d);
    }

    @Test
    void validateDraft_publie_le_draft_et_cree_une_question() {
        AudioQuestionDraft draft = pendingReviewDraft();
        UUID adminId = UUID.randomUUID();

        AudioDraftDto dto = service.validateDraft(draft.getId(), adminId);

        assertThat(dto.status()).isEqualTo(AudioDraftStatus.PUBLISHED);

        AudioQuestionDraft reloaded = draftRepository.findById(draft.getId()).orElseThrow();
        assertThat(reloaded.getStatus()).isEqualTo(AudioDraftStatus.PUBLISHED);
        assertThat(reloaded.getAudioValidatedBy()).isEqualTo(adminId.toString());

        List<Question> tcfCo = questionRepository.findAll().stream()
            .filter(q -> draft.getStatement().equals(q.getStatement()))
            .toList();
        assertThat(tcfCo).hasSize(1);
        assertThat(tcfCo.get(0).getStatus()).isEqualTo(QuestionStatus.ACTIVE);
        assertThat(tcfCo.get(0).getMedia()).isNotNull();
    }

    @Test
    void validateDraft_refuse_un_draft_non_pending_review() {
        AudioQuestionDraft draft = testData.audioQuestionDraft(); // TEXT_VALIDATED

        org.assertj.core.api.Assertions.assertThatThrownBy(
                () -> service.validateDraft(draft.getId(), UUID.randomUUID()))
            .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void rejectDraft_marque_le_draft_rejected_avec_raison() {
        AudioQuestionDraft draft = testData.audioQuestionDraft();

        AudioDraftDto dto = service.rejectDraft(draft.getId(), "Audio inaudible", UUID.randomUUID());

        assertThat(dto.status()).isEqualTo(AudioDraftStatus.REJECTED);
        AudioQuestionDraft reloaded = draftRepository.findById(draft.getId()).orElseThrow();
        assertThat(reloaded.getStatus()).isEqualTo(AudioDraftStatus.REJECTED);
        assertThat(reloaded.getRejectionReason()).isEqualTo("Audio inaudible");
    }

    @Test
    void generateBatchAudio_synthetise_et_passe_le_draft_en_pending_review() {
        // Garantit au moins un draft B1 TEXT_VALIDATED éligible. Le schéma Flyway
        // seede d'autres drafts TEXT_VALIDATED ; le batch en réserve le top-10 par
        // createdAt ASC, donc on n'assert pas sur CE draft précis mais sur un draft
        // effectivement traité (remonté dans outcomes) — la transition testée est
        // la même : TEXT_VALIDATED -> AUDIO_PENDING_REVIEW.
        testData.audioQuestionDraft(); // TEXT_VALIDATED, difficulty B1
        when(azureSpeechClient.synthesize(anyString())).thenReturn(new byte[]{1, 2, 3, 4});
        when(r2Client.uploadAudio(any(UUID.class), any(byte[].class)))
            .thenAnswer(inv -> new R2UploadResult(
                "audio/" + inv.getArgument(0) + ".mp3",
                "https://cdn.test/audio/" + inv.getArgument(0) + ".mp3"));

        BatchGenerationResultDto result = service.generateBatchAudio(Difficulty.B1);

        assertThat(result.succeeded()).isGreaterThanOrEqualTo(1);
        assertThat(result.failed()).isZero();

        UUID processedId = result.outcomes().stream()
            .filter(BatchGenerationResultDto.DraftOutcome::success)
            .map(BatchGenerationResultDto.DraftOutcome::draftId)
            .findFirst()
            .orElseThrow();
        AudioQuestionDraft reloaded = draftRepository.findById(processedId).orElseThrow();
        assertThat(reloaded.getStatus()).isEqualTo(AudioDraftStatus.AUDIO_PENDING_REVIEW);
        assertThat(reloaded.getAudioUrl()).isNotBlank();
        assertThat(reloaded.getBatchId()).isNotNull();
    }
}
