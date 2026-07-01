package com.sejourfr.app.service;

import com.sejourfr.app.config.OpenAiProperties;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Transcription;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.exception.TranscriptionException;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.TranscriptionManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Orchestration Whisper : construction de la requete (nom de fichier extrait de
 * l'URL, prompt litteral applique), mapping de la reponse, transitions de statut
 * et estimation de cout. Le client HTTP Whisper et le stockage R2 sont mockes.
 */
@ExtendWith(MockitoExtension.class)
class WhisperTranscriptionServiceTest {

    @Mock private ProductionSubmissionManager submissionManager;
    @Mock private TranscriptionManager transcriptionManager;
    @Mock private ProductionAudioStorageService audioStorage;
    @Mock private WhisperTranscriptionClient whisperClient;

    private final OpenAiProperties props = new OpenAiProperties();

    private WhisperTranscriptionService service;

    private final UUID submissionId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new WhisperTranscriptionService(
            submissionManager, transcriptionManager, audioStorage, whisperClient, props);
    }

    private ProductionSubmission submission(String mediaUrl, Integer mediaDurationSec) {
        ProductionSubmission sub = new ProductionSubmission();
        sub.setId(submissionId);
        sub.setMediaUrl(mediaUrl);
        sub.setMediaDurationSec(mediaDurationSec);
        sub.setStatut(SubmissionStatut.SUBMITTED);
        return sub;
    }

    @Test
    void transcribe_submission_introuvable_404() {
        when(submissionManager.findById(submissionId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.transcribe(submissionId))
            .isInstanceOf(NotFoundException.class);
    }

    @Test
    void transcribe_sans_media_url_leve_transcription_exception() {
        when(submissionManager.findById(submissionId)).thenReturn(Optional.of(submission(null, null)));

        assertThatThrownBy(() -> service.transcribe(submissionId))
            .isInstanceOf(TranscriptionException.class);
    }

    @Test
    void transcribe_happy_path_extrait_le_filename_applique_le_prompt_litteral_et_mappe() {
        ProductionSubmission sub = submission("https://r2.sejourfr/prod/abc/recording.webm", null);
        when(submissionManager.findById(submissionId)).thenReturn(Optional.of(sub));
        byte[] audio = {1, 2, 3};
        when(audioStorage.download(sub.getMediaUrl())).thenReturn(audio);
        when(whisperClient.transcribe(eq(audio), eq("recording.webm")))
            .thenReturn(new WhisperTranscriptionClient.WhisperResult("euh je pense que", "fr", 120));

        Transcription result = service.transcribe(submissionId);

        ArgumentCaptor<Transcription> saved = ArgumentCaptor.forClass(Transcription.class);
        verify(transcriptionManager).save(saved.capture());
        Transcription t = saved.getValue();
        assertThat(t.getTexte()).isEqualTo("euh je pense que");
        assertThat(t.getLangueDetectee()).isEqualTo("fr");
        assertThat(t.getModeleUtilise()).isEqualTo(props.getWhisper().getModel());
        assertThat(t.getPromptUtilise()).isEqualTo(props.getWhisper().getLiteralModePrompt());
        assertThat(t.getAudioDurationSec()).isEqualTo(120);
        // 120 s * 0.006/60 USD/s * 100 = 1.2 cents -> arrondi sup = 2.
        assertThat(t.getCoutEstimeCentimes()).isEqualTo(2);

        assertThat(result).isSameAs(t);
        assertThat(sub.getStatut()).isEqualTo(SubmissionStatut.EVALUATING);
        assertThat(sub.getMediaDurationSec()).isEqualTo(120);
        // SUBMITTED -> TRANSCRIBING -> EVALUATING : deux sauvegardes de la submission.
        verify(submissionManager, times(2)).save(sub);
    }

    @Test
    void transcribe_conserve_la_duree_existante_de_la_submission() {
        ProductionSubmission sub = submission("https://r2.sejourfr/prod/audio.mp3", 200);
        when(submissionManager.findById(submissionId)).thenReturn(Optional.of(sub));
        when(audioStorage.download(any())).thenReturn(new byte[]{9});
        when(whisperClient.transcribe(any(), eq("audio.mp3")))
            .thenReturn(new WhisperTranscriptionClient.WhisperResult("texte", "fr", 95));

        service.transcribe(submissionId);

        ArgumentCaptor<Transcription> saved = ArgumentCaptor.forClass(Transcription.class);
        verify(transcriptionManager).save(saved.capture());
        // La transcription stocke la duree DETECTEE par Whisper.
        assertThat(saved.getValue().getAudioDurationSec()).isEqualTo(95);
        // La submission conserve sa duree pre-existante (non ecrasee).
        assertThat(sub.getMediaDurationSec()).isEqualTo(200);
    }
}
