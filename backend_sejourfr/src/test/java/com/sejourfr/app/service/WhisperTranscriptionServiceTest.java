package com.sejourfr.app.service;

import com.sejourfr.app.config.OpenAiProperties;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Transcription;
import com.sejourfr.app.exception.TranscriptionException;
import com.sejourfr.app.manager.TranscriptionManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Orchestration Whisper. Depuis que l'audio d'un candidat n'est plus stocke, ce
 * service ne connait AUCUN stockage : il recoit des octets et rend un resultat,
 * puis persiste la transcription d'une submission deja creee. Le client HTTP est
 * mocke.
 */
@ExtendWith(MockitoExtension.class)
class WhisperTranscriptionServiceTest {

    @Mock private TranscriptionManager transcriptionManager;
    @Mock private WhisperTranscriptionClient whisperClient;

    private final OpenAiProperties props = new OpenAiProperties();

    private WhisperTranscriptionService service;

    @BeforeEach
    void setUp() {
        service = new WhisperTranscriptionService(transcriptionManager, whisperClient, props);
    }

    private ProductionSubmission submission() {
        ProductionSubmission sub = new ProductionSubmission();
        sub.setId(UUID.randomUUID());
        return sub;
    }

    @Test
    void transcribe_delegue_au_client_avec_les_octets_recus() {
        byte[] audio = {1, 2, 3};
        WhisperTranscriptionClient.WhisperResult attendu =
            new WhisperTranscriptionClient.WhisperResult("euh je pense que", "fr", 120);
        when(whisperClient.transcribe(eq(audio), eq("production.webm"))).thenReturn(attendu);

        assertThat(service.transcribe(audio, "production.webm")).isSameAs(attendu);
    }

    @Test
    void transcribe_sans_octets_refuse_avant_tout_appel_paye() {
        assertThatThrownBy(() -> service.transcribe(new byte[0], "production.webm"))
            .isInstanceOf(TranscriptionException.class);
        assertThatThrownBy(() -> service.transcribe(null, "production.webm"))
            .isInstanceOf(TranscriptionException.class);

        verify(whisperClient, never()).transcribe(org.mockito.ArgumentMatchers.any(),
            org.mockito.ArgumentMatchers.any());
    }

    @Test
    void transcribe_sans_nom_de_fichier_en_fournit_un_exploitable_par_whisper() {
        when(whisperClient.transcribe(org.mockito.ArgumentMatchers.any(), eq("audio.webm")))
            .thenReturn(new WhisperTranscriptionClient.WhisperResult("texte", "fr", 10));

        service.transcribe(new byte[]{7}, "  ");

        verify(whisperClient).transcribe(org.mockito.ArgumentMatchers.any(), eq("audio.webm"));
    }

    @Test
    void persist_mappe_le_resultat_le_prompt_litteral_et_le_cout() {
        ProductionSubmission sub = submission();

        Transcription result = service.persist(sub,
            new WhisperTranscriptionClient.WhisperResult("euh je pense que", "fr", 120));

        ArgumentCaptor<Transcription> saved = ArgumentCaptor.forClass(Transcription.class);
        verify(transcriptionManager).save(saved.capture());
        Transcription t = saved.getValue();
        assertThat(t.getSubmission()).isSameAs(sub);
        assertThat(t.getTexte()).isEqualTo("euh je pense que");
        assertThat(t.getLangueDetectee()).isEqualTo("fr");
        assertThat(t.getModeleUtilise()).isEqualTo(props.getWhisper().getModel());
        assertThat(t.getPromptUtilise()).isEqualTo(props.getWhisper().getLiteralModePrompt());
        assertThat(t.getAudioDurationSec()).isEqualTo(120);
        // 120 s * 0.006/60 USD/s * 100 = 1.2 cents -> arrondi sup = 2.
        assertThat(t.getCoutEstimeCentimes()).isEqualTo(2);
        assertThat(result).isSameAs(t);
    }
}
