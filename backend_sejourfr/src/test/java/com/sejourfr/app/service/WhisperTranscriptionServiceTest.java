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
        // 2 min x 0,006 $/min = 0,012 $ = 12 000 micro-dollars, exactement.
        // L'ancien calcul arrondissait au centime SUPERIEUR et persistait « 2 »,
        // soit 0,02 $ : 67 % de trop sur ce cas.
        assertThat(t.getCoutMicroUsd()).isEqualTo(12_000);
        assertThat(result).isSameAs(t);
    }

    @Test
    void persist_facture_l_audio_median_a_son_prix_et_non_au_centime_superieur() {
        // 95 s, la mediane du depot : 0,0095 $. L'arrondi au centime superieur
        // en faisait « 1 centime », ~5 % de trop — c'etait le dernier endroit du
        // depot a arrondir une facture au centime.
        service.persist(submission(),
            new WhisperTranscriptionClient.WhisperResult("texte", "fr", 95));

        ArgumentCaptor<Transcription> saved = ArgumentCaptor.forClass(Transcription.class);
        verify(transcriptionManager).save(saved.capture());
        assertThat(saved.getValue().getCoutMicroUsd()).isEqualTo(9_500);
    }

    @Test
    void persist_sans_duree_ne_facture_rien_plutot_que_zero() {
        // null et non 0 : un cout de 0 persiste se lirait « gratuit », ce qui est
        // une affirmation, alors qu'on n'a rien mesure.
        service.persist(submission(),
            new WhisperTranscriptionClient.WhisperResult("texte", "fr", null));

        ArgumentCaptor<Transcription> saved = ArgumentCaptor.forClass(Transcription.class);
        verify(transcriptionManager).save(saved.capture());
        assertThat(saved.getValue().getCoutMicroUsd()).isNull();
    }

    @Test
    void persist_sans_tarif_configure_n_invente_aucun_montant() {
        props.getWhisper().setCostPerMinuteUsd(0);

        service.persist(submission(),
            new WhisperTranscriptionClient.WhisperResult("texte", "fr", 120));

        ArgumentCaptor<Transcription> saved = ArgumentCaptor.forClass(Transcription.class);
        verify(transcriptionManager).save(saved.capture());
        assertThat(saved.getValue().getCoutMicroUsd()).isNull();
    }
}
