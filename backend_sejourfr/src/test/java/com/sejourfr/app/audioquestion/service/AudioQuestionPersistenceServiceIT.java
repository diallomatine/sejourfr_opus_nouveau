package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.domain.AudioMode;
import com.sejourfr.app.audioquestion.dto.AnthropicGenerationResponse;
import com.sejourfr.app.audioquestion.service.AudioQuestionPersistenceService.PersistenceMetadata;
import com.sejourfr.app.audioquestion.service.AudioQuestionPersistenceService.PersistenceResult;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client.R2UploadResult;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionStatus;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.repository.QuestionRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Test d'integration : {@code persistAndUpload} ecrit reellement le triplet
 * Media(AUDIO) + Question(DRAFT) + 4 Choice en base, dans l'ordre Media -> upload
 * R2 (callback) -> Question. Le theme TCF_CO vient du seed de reference (V101).
 */
class AudioQuestionPersistenceServiceIT extends AbstractIntegrationTest {

    @Autowired private AudioQuestionPersistenceService service;
    @Autowired private QuestionRepository questionRepository;

    private AnthropicGenerationResponse claudeResponse() {
        AnthropicGenerationResponse.AudioSection audio = new AnthropicGenerationResponse.AudioSection(
            "Bonjour, je voudrais reserver une chambre.",
            "<speak xml:lang=\"fr-FR\"><voice name=\"fr-FR-DeniseNeural\">Bonjour</voice></speak>",
            1,
            List.of(new AnthropicGenerationResponse.VoiceInfo("client", "fr-FR-DeniseNeural", "F")),
            30, "Un client a la reception d'un hotel", AudioMode.WRITTEN_QUESTION);
        AnthropicGenerationResponse.QuestionSection question = new AnthropicGenerationResponse.QuestionSection(
            "Que veut le client ?",
            "Le client souhaite reserver une chambre : l'explication doit etre suffisamment detaillee.",
            "co_detail_specifique", "B1", "logement");
        List<AnthropicGenerationResponse.ChoiceSection> choices = List.of(
            new AnthropicGenerationResponse.ChoiceSection("Reserver une chambre", true, 1),
            new AnthropicGenerationResponse.ChoiceSection("Payer la note", false, 2),
            new AnthropicGenerationResponse.ChoiceSection("Demander un taxi", false, 3),
            new AnthropicGenerationResponse.ChoiceSection("Annuler une reservation", false, 4));
        return new AnthropicGenerationResponse(audio, question, choices);
    }

    @Test
    void persistAndUpload_persiste_media_question_et_choix() {
        byte[] mp3 = {1, 2, 3, 4, 5};
        PersistenceMetadata metadata = new PersistenceMetadata(
            Instant.now(), 1500L, new BigDecimal("0.02000"), 1000, 500, 0, 250);

        PersistenceResult result = service.persistAndUpload(
            mp3, claudeResponse(), metadata,
            mediaId -> new R2UploadResult("audio/" + mediaId + ".mp3", "https://cdn/audio/" + mediaId + ".mp3"));

        assertThat(result.preview().questionId()).isNotNull();
        assertThat(result.preview().status()).isEqualTo(QuestionStatus.DRAFT.name());
        assertThat(result.preview().choices()).hasSize(4);
        assertThat(result.r2Result().objectKey()).startsWith("audio/");

        Question saved = questionRepository.findById(result.preview().questionId()).orElseThrow();
        assertThat(saved.getModule()).isEqualTo(Module.TCF);
        assertThat(saved.getQuestionType()).isEqualTo(QuestionType.CO);
        assertThat(saved.getStatus()).isEqualTo(QuestionStatus.DRAFT);
        assertThat(saved.isActive()).isFalse();
        assertThat(saved.getChoices()).hasSize(4);
        assertThat(saved.getMedia()).isNotNull();
        assertThat(saved.getMedia().getType()).isEqualTo(MediaType.AUDIO);
        assertThat(saved.getMedia().getUrl()).isEqualTo(result.r2Result().publicUrl());
        assertThat(saved.getMedia().getStorageKey()).isEqualTo(result.r2Result().objectKey());
        assertThat(saved.getMedia().getTranscript()).isEqualTo("Bonjour, je voudrais reserver une chambre.");
    }
}
