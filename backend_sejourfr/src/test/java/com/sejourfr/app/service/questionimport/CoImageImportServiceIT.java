package com.sejourfr.app.service.questionimport;

import com.sejourfr.app.audioquestion.entity.AudioDraftStatus;
import com.sejourfr.app.audioquestion.entity.AudioQuestionDraft;
import com.sejourfr.app.audioquestion.entity.AudioQuestionDraft.DraftChoice;
import com.sejourfr.app.audioquestion.exception.R2UploadException;
import com.sejourfr.app.audioquestion.repository.AudioQuestionDraftRepository;
import com.sejourfr.app.audioquestion.service.AudioDraftService;
import com.sejourfr.app.audioquestion.service.AzureSpeechClient;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client.R2UploadResult;
import com.sejourfr.app.dto.CoImageImportError;
import com.sejourfr.app.dto.CoImageImportReport;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.CoImageImportErrorCode;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.QuestionStatus;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.repository.QuestionRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.ImagesDeTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.startsWith;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * Import CO image en base reelle (Zonky), R2 et Azure mockes. Verrouille :
 * l'analyse n'ecrit rien, l'import cree des BROUILLONS (jamais de question),
 * le tout ou rien (refus de validation, echec R2 compense), l'anti-doublon
 * {@code external_id}, et la publication existante (libelles A-D, texte dans
 * la transcription).
 */
class CoImageImportServiceIT extends AbstractIntegrationTest {

    @Autowired private CoImageImportService service;
    @Autowired private AudioQuestionDraftRepository draftRepository;
    @Autowired private QuestionRepository questionRepository;
    @Autowired private AudioDraftService audioDraftService;
    @Autowired private TestData testData;

    @MockitoBean private AzureSpeechClient azureSpeechClient;
    @MockitoBean private CloudflareR2Client r2Client;

    private static final byte[] PNG = ImagesDeTest.png(800, 600);
    private static final byte[] WEBP = ImagesDeTest.webpVp8x(1200, 900, false);

    @Test
    void analyser_n_ecrit_rien_et_n_envoie_rien() {
        long avant = draftRepository.count();
        long questionsAvant = questionRepository.count();

        CoImageImportReport r = service.analyser(manifeste("co-it-a", "co-it-b"), images());

        assertThat(r.ok()).isTrue();
        assertThat(r.imported()).isFalse();
        assertThat(r.questions()).allSatisfy(q -> assertThat(q.draftId()).isNull());
        assertThat(draftRepository.count()).isEqualTo(avant);
        assertThat(questionRepository.count()).isEqualTo(questionsAvant);
        verifyNoInteractions(r2Client);
    }

    @Test
    void importer_cree_des_brouillons_TEXT_VALIDATED_avec_image_sous_la_cle_du_brouillon() {
        envoisR2Reussis();
        long questionsAvant = questionRepository.count();

        CoImageImportReport r = service.importer(manifeste("co-it-a", "co-it-b"), images());

        assertThat(r.ok()).isTrue();
        assertThat(r.imported()).isTrue();
        assertThat(questionRepository.count()).as("aucune question avant la revue").isEqualTo(questionsAvant);
        for (var q : r.questions()) {
            AudioQuestionDraft d = draftRepository.findById(q.draftId()).orElseThrow();
            assertThat(d.getExternalId()).isEqualTo(q.externalId());
            assertThat(d.getStatus()).isEqualTo(AudioDraftStatus.TEXT_VALIDATED);
            assertThat(d.getAudioUrl()).isNull();
            assertThat(d.getTheme().getCode()).isEqualTo("TCF_CO");
            assertThat(d.getImageUrl()).startsWith("https://cdn.test/questions/images/drafts/" + d.getId() + "/");
            assertThat(d.getImageUrl()).isEqualTo(q.imageUrl());
            assertThat(d.getInlineSvg()).isNull();
            assertThat(d.getChoices()).extracting(DraftChoice::label).containsExactly("A", "B", "C", "D");
            assertThat(d.getChoices()).extracting(DraftChoice::text)
                    .containsExactly("Venez manger.", "Allez dormir.", "Regardez la télé.", "Lisez un livre.");
            assertThat(d.getTranscriptText()).contains("C. Regardez la télé.");
            assertThat(d.getSsmlText()).contains("C.<break time=\"300ms\"/>Regardez la télé.");
        }
        AudioQuestionDraft webp = draftRepository.findById(r.questions().get(1).draftId()).orElseThrow();
        assertThat(webp.getImageUrl()).endsWith(".webp");
        verify(r2Client).uploadImage(startsWith("questions/images/drafts/"), any(), org.mockito.ArgumentMatchers.eq("image/webp"));
    }

    @Test
    void importer_un_lot_invalide_n_ecrit_rien_et_n_envoie_rien() {
        long avant = draftRepository.count();

        CoImageImportReport r = service.importer(manifeste("co-it-a", "CO INVALIDE"), images());

        assertThat(r.ok()).isFalse();
        assertThat(r.imported()).isFalse();
        assertThat(r.questions().get(0).ok()).as("la question valide n'est pas importee seule").isTrue();
        assertThat(r.questions().get(1).errors()).extracting(CoImageImportError::code)
                .containsExactly(CoImageImportErrorCode.EXTERNAL_ID_INVALIDE);
        assertThat(draftRepository.count()).isEqualTo(avant);
        verifyNoInteractions(r2Client);
    }

    @Test
    void un_external_id_deja_importe_est_refuse_quel_que_soit_le_statut() {
        AudioQuestionDraft existant = testData.audioQuestionDraft();
        existant.setExternalId("co-it-deja");
        existant.setStatus(AudioDraftStatus.REJECTED);
        draftRepository.saveAndFlush(existant);
        long avant = draftRepository.count();

        CoImageImportReport r = service.importer(manifeste("co-it-a", "co-it-deja"), images());

        assertThat(r.imported()).isFalse();
        assertThat(r.questions().get(1).errors()).extracting(CoImageImportError::code)
                .containsExactly(CoImageImportErrorCode.EXTERNAL_ID_DEJA_IMPORTE);
        assertThat(draftRepository.count()).isEqualTo(avant);
        verifyNoInteractions(r2Client);
    }

    /**
     * Hors transaction de test : c'est la vraie transaction de l'import qui doit
     * etre annulee. L'echec du 2e envoi R2 ne laisse aucune ligne, et la cle du
     * 1er envoi est supprimee.
     */
    @Test
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    void un_echec_R2_au_deuxieme_envoi_annule_tout_et_supprime_le_premier_envoi() {
        String[] premiereCle = new String[1];
        when(r2Client.uploadImage(anyString(), any(), anyString()))
                .thenAnswer(inv -> {
                    premiereCle[0] = inv.getArgument(0);
                    return new R2UploadResult(premiereCle[0], "https://cdn.test/" + premiereCle[0]);
                })
                .thenThrow(new R2UploadException("R2 indisponible"));
        List<String> ids = List.of("co-it-r2-a", "co-it-r2-b");

        assertThatThrownBy(() -> service.importer(manifeste(ids.get(0), ids.get(1)), images()))
                .isInstanceOf(R2UploadException.class);

        assertThat(draftRepository.findAll()).extracting(AudioQuestionDraft::getExternalId)
                .doesNotContainAnyElementsOf(ids);
        verify(r2Client).deleteObject(premiereCle[0]);
    }

    /**
     * La publication EXISTANTE ({@code validateDraft}) d'un brouillon importe :
     * question CO_IMAGE, libelles A-D (jamais le texte, qui fuirait dans le JSON
     * du runner), propositions dans la transcription de l'audio.
     */
    @Test
    void la_publication_d_un_brouillon_importe_garde_les_lettres_et_met_le_texte_dans_la_transcription() {
        envoisR2Reussis();
        CoImageImportReport r = service.importer(manifeste("co-it-pub-a", "co-it-pub-b"), images());
        AudioQuestionDraft d = draftRepository.findById(r.questions().get(0).draftId()).orElseThrow();
        d.setStatus(AudioDraftStatus.AUDIO_PENDING_REVIEW);
        d.setAudioUrl("https://cdn.test/audio/" + UUID.randomUUID() + ".mp3");
        d.setAudioDurationSec(12);
        draftRepository.saveAndFlush(d);

        audioDraftService.validateDraft(d.getId(), UUID.randomUUID());

        Question q = questionRepository.findAll().stream()
                .filter(x -> x.getMedia() != null && d.getImageUrl().equals(x.getMedia().getUrl()))
                .findFirst().orElseThrow();
        assertThat(q.getQuestionType()).isEqualTo(QuestionType.CO_IMAGE);
        assertThat(q.getStatus()).isEqualTo(QuestionStatus.ACTIVE);
        assertThat(q.isActive()).isTrue();
        assertThat(q.getMedia().getType()).isEqualTo(MediaType.IMAGE);
        assertThat(q.getMedia().getAltText()).isEqualTo("Une femme appelle sa famille.");
        assertThat(q.getChoices()).extracting(Choice::getLabel).containsExactly("A", "B", "C", "D");
        assertThat(q.getChoices()).extracting(Choice::isCorrect).containsExactly(true, false, false, false);
        assertThat(q.getAudioMedia().getTranscript()).isEqualTo(d.getTranscriptText())
                .contains("A. Venez manger.");
        assertThat(q.getStatement()).isEqualTo("Écoutez les propositions et choisissez celle qui correspond à l'image.");
    }

    private void envoisR2Reussis() {
        when(r2Client.uploadImage(anyString(), any(), anyString()))
                .thenAnswer(inv -> new R2UploadResult(inv.getArgument(0), "https://cdn.test/" + inv.getArgument(0)));
    }

    private static List<MultipartFile> images() {
        return List.of(
                new MockMultipartFile("images", "a.png", "image/png", PNG),
                new MockMultipartFile("images", "b.webp", "image/webp", WEBP));
    }

    private static String manifeste(String idA, String idB) {
        return "{\"version\":\"1\",\"format\":\"CO_IMAGE\",\"questions\":["
                + question(idA, "a.png") + "," + question(idB, "b.webp") + "]}";
    }

    static String question(String externalId, String image) {
        return "{\"externalId\":\"" + externalId + "\",\"level\":\"A2\",\"image\":\"" + image + "\","
                + "\"sceneDescription\":\"Une femme appelle sa famille.\","
                + "\"choices\":[\"Venez manger.\",\"Allez dormir.\",\"Regardez la télé.\",\"Lisez un livre.\"],"
                + "\"correctAnswer\":\"A\",\"explanation\":\"Seule A.\"}";
    }
}
