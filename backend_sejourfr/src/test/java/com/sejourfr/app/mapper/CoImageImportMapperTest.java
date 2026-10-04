package com.sejourfr.app.mapper;

import com.sejourfr.app.audioquestion.entity.AudioDraftStatus;
import com.sejourfr.app.audioquestion.entity.AudioQuestionDraft;
import com.sejourfr.app.audioquestion.entity.AudioQuestionDraft.DraftChoice;
import com.sejourfr.app.dto.CoImageImportError;
import com.sejourfr.app.dto.CoImageImportQuestion;
import com.sejourfr.app.dto.CoImageImportQuestionReport;
import com.sejourfr.app.dto.CoImageImportReport;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.CoImageImportErrorCode;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.service.ImageUploadSupport.Dimensions;
import com.sejourfr.app.service.ImageUploadSupport.FormatImage;
import com.sejourfr.app.service.questionimport.FichierImport;
import com.sejourfr.app.service.questionimport.QuestionAnalysee;
import com.sejourfr.app.service.questionimport.ResultatValidation;
import com.sejourfr.app.util.PropositionsLuesCoImage;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class CoImageImportMapperTest {

    private final CoImageImportMapper mapper = new CoImageImportMapper();
    private final Theme theme = new Theme();
    private final List<String> propositions = List.of("Venez manger.", "Allez dormir.", "Regardez la télé.", "Lisez.");

    {
        theme.setCode("TCF_CO");
        theme.setName("Compréhension orale");
        theme.setModule(Module.TCF);
    }

    @Test
    void brouillon_garde_les_lettres_en_label_et_le_texte_a_part() {
        AudioQuestionDraft d = mapper.versBrouillon(valide(2));

        assertThat(d.getChoices()).extracting(DraftChoice::label).containsExactly("A", "B", "C", "D");
        assertThat(d.getChoices()).extracting(DraftChoice::text).containsExactlyElementsOf(propositions);
        assertThat(d.getChoices()).extracting(DraftChoice::isCorrect).containsExactly(false, false, true, false);
        assertThat(d.getChoices()).extracting(DraftChoice::displayOrder).containsExactly(1, 2, 3, 4);
    }

    @Test
    void brouillon_derive_audio_et_reprend_le_gabarit_V802() {
        AudioQuestionDraft d = mapper.versBrouillon(valide(0));

        assertThat(d.getExternalId()).isEqualTo("co-a2-001");
        assertThat(d.getStatus()).isEqualTo(AudioDraftStatus.TEXT_VALIDATED);
        assertThat(d.getDifficulty()).isEqualTo(Difficulty.A2);
        assertThat(d.getTheme()).isSameAs(theme);
        assertThat(d.getStatement()).isEqualTo("Écoutez les propositions et choisissez celle qui correspond à l'image.");
        assertThat(d.getCompetenceCode()).isEqualTo("co_image_proposition");
        assertThat(d.getVoiceRecommended()).isEqualTo("fr-FR-DeniseNeural");
        assertThat(d.getImageAltText()).isEqualTo("Une femme appelle.");
        assertThat(d.getExplanation()).isEqualTo("Seule A.");
        assertThat(d.getTranscriptText()).isEqualTo(PropositionsLuesCoImage.transcription(propositions));
        assertThat(d.getSsmlText()).isEqualTo(PropositionsLuesCoImage.ssml(propositions));
        assertThat(d.getImageUrl()).as("posee par le service apres l'envoi R2").isNull();
        assertThat(d.getInlineSvg()).isNull();
    }

    @Test
    void rapport_analyse_sans_brouillon_et_question_fautive_sans_derive() {
        QuestionAnalysee fautive = new QuestionAnalysee(1,
                new CoImageImportQuestion("co-x", "Z9", "NOPE", "x.png", "", List.of("a", "b"), "E", null),
                "co-x", null, null, null, null, null, null, null, null, null,
                List.of(new CoImageImportError(CoImageImportErrorCode.NIVEAU_INVALIDE, "level", "…")));
        ResultatValidation r = new ResultatValidation(List.of(), List.of(valide(0), fautive));

        CoImageImportReport rapport = mapper.rapport(r, "CO_IMAGE", "charte-images-co-v1", 20, Map.of());

        assertThat(rapport.ok()).isFalse();
        assertThat(rapport.imported()).isFalse();
        assertThat(rapport.questionCount()).isEqualTo(2);
        CoImageImportQuestionReport ok = rapport.questions().get(0);
        assertThat(ok.ok()).isTrue();
        assertThat(ok.themeCode()).isEqualTo("TCF_CO");
        assertThat(ok.imageFormat()).isEqualTo("png");
        assertThat(ok.imageWidth()).isEqualTo(800);
        assertThat(ok.transcriptText()).startsWith("Écoutez les quatre propositions.");
        assertThat(ok.choices()).extracting(CoImageImportQuestionReport.ChoicePreview::letter)
                .containsExactly("A", "B", "C", "D");
        assertThat(ok.choices().get(0).correct()).isTrue();
        assertThat(ok.draftId()).isNull();
        CoImageImportQuestionReport ko = rapport.questions().get(1);
        assertThat(ko.level()).isEqualTo("Z9");
        assertThat(ko.themeCode()).isEqualTo("NOPE");
        assertThat(ko.transcriptText()).isNull();
        assertThat(ko.choices()).extracting(CoImageImportQuestionReport.ChoicePreview::text).containsExactly("a", "b");
    }

    @Test
    void rapport_import_porte_les_brouillons_crees() {
        AudioQuestionDraft cree = mapper.versBrouillon(valide(0));
        cree.setId(UUID.randomUUID());
        cree.setImageUrl("https://cdn/questions/images/drafts/x/y.png");

        CoImageImportReport rapport = mapper.rapport(new ResultatValidation(List.of(), List.of(valide(0))),
                "CO_IMAGE", "charte-images-co-v1", 20, Map.of(0, cree));

        assertThat(rapport.imported()).isTrue();
        assertThat(rapport.questions().get(0).draftId()).isEqualTo(cree.getId());
        assertThat(rapport.questions().get(0).imageUrl()).isEqualTo(cree.getImageUrl());
    }

    private QuestionAnalysee valide(int bonne) {
        return new QuestionAnalysee(0,
                new CoImageImportQuestion("co-a2-001", "A2", null, "a.png", "Une femme appelle.", propositions,
                        String.valueOf("ABCD".charAt(bonne)), "Seule A."),
                "co-a2-001", Difficulty.A2, theme, propositions, bonne, "Une femme appelle.", "Seule A.",
                new FichierImport("a.png", new byte[]{1, 2}), FormatImage.PNG, new Dimensions(800, 600), List.of());
    }
}
