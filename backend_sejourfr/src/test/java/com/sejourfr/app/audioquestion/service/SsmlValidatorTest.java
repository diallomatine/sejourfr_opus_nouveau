package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.domain.AudioMode;
import com.sejourfr.app.audioquestion.dto.AnthropicGenerationResponse.AudioSection;
import com.sejourfr.app.audioquestion.dto.AnthropicGenerationResponse.VoiceInfo;
import com.sejourfr.app.audioquestion.exception.ContentValidationException;
import com.sejourfr.app.audioquestion.exception.SsmlValidationException;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class SsmlValidatorTest {

    private final SsmlValidator validator = new SsmlValidator();

    private AudioSection audio(String ssml, String transcript, int speakerCount, List<VoiceInfo> voices) {
        return new AudioSection(
            transcript, ssml, speakerCount, voices,
            30, "Contexte de test", AudioMode.WRITTEN_QUESTION
        );
    }

    // ----- cleanForAzure / stripOrphanBreaks -----

    @Test
    void cleanForAzure_retire_le_break_entre_deux_voice() {
        String ssml = "<speak xml:lang=\"fr-FR\">"
            + "<voice name=\"fr-FR-DeniseNeural\">Bonjour</voice>"
            + "<break time=\"500ms\"/>"
            + "<voice name=\"fr-FR-HenriNeural\">Au revoir</voice></speak>";

        String cleaned = validator.cleanForAzure(ssml);

        assertThat(cleaned).doesNotContain("<break");
        assertThat(cleaned)
            .isEqualTo("<speak xml:lang=\"fr-FR\">"
                + "<voice name=\"fr-FR-DeniseNeural\">Bonjour</voice>"
                + "<voice name=\"fr-FR-HenriNeural\">Au revoir</voice></speak>");
    }

    @Test
    void cleanForAzure_retire_le_break_juste_apres_speak() {
        String ssml = "<speak xml:lang=\"fr-FR\"><break time=\"300ms\"/>"
            + "<voice name=\"fr-FR-DeniseNeural\">Bonjour</voice></speak>";

        assertThat(validator.cleanForAzure(ssml)).doesNotContain("<break");
    }

    @Test
    void cleanForAzure_retire_le_break_juste_avant_la_fin_speak() {
        String ssml = "<speak xml:lang=\"fr-FR\">"
            + "<voice name=\"fr-FR-DeniseNeural\">Bonjour</voice><break time=\"300ms\"/></speak>";

        assertThat(validator.cleanForAzure(ssml)).doesNotContain("<break");
    }

    @Test
    void cleanForAzure_conserve_le_break_a_l_interieur_d_une_voice() {
        String ssml = "<speak xml:lang=\"fr-FR\">"
            + "<voice name=\"fr-FR-DeniseNeural\">Bonjour<break time=\"300ms\"/>madame</voice></speak>";

        assertThat(validator.cleanForAzure(ssml)).contains("<break");
    }

    // ----- validate : chemin nominal -----

    @Test
    void validate_extrait_texte_voix_et_compte_caracteres() {
        String spoken = "Bonjour madame comment allez vous";
        String ssml = "<speak version=\"1.0\" xml:lang=\"fr-FR\">"
            + "<voice name=\"fr-FR-DeniseNeural\">" + spoken + "</voice></speak>";
        AudioSection section = audio(
            ssml, spoken, 1,
            List.of(new VoiceInfo("Patient", "fr-FR-DeniseNeural", "F"))
        );

        SsmlValidator.ValidationResult result = validator.validate(section);

        assertThat(result.spokenText()).isEqualTo(spoken);
        assertThat(result.azureCharactersCount()).isEqualTo(spoken.length());
        assertThat(result.usedVoices()).containsExactly("fr-FR-DeniseNeural");
        assertThat(result.cleanedSsml()).isEqualTo(ssml);
    }

    // ----- validate : echecs structurels (SsmlValidationException) -----

    @Test
    void validate_rejette_si_racine_n_est_pas_speak() {
        String ssml = "<root xml:lang=\"fr-FR\">"
            + "<voice name=\"fr-FR-DeniseNeural\">Bonjour</voice></root>";
        AudioSection section = audio(ssml, "Bonjour", 1,
            List.of(new VoiceInfo("R", "fr-FR-DeniseNeural", "F")));

        assertThatThrownBy(() -> validator.validate(section))
            .isInstanceOf(SsmlValidationException.class)
            .hasMessageContaining("racine SSML");
    }

    @Test
    void validate_rejette_si_xml_lang_n_est_pas_fr_FR() {
        String ssml = "<speak xml:lang=\"en-US\">"
            + "<voice name=\"fr-FR-DeniseNeural\">Bonjour</voice></speak>";
        AudioSection section = audio(ssml, "Bonjour", 1,
            List.of(new VoiceInfo("R", "fr-FR-DeniseNeural", "F")));

        assertThatThrownBy(() -> validator.validate(section))
            .isInstanceOf(SsmlValidationException.class)
            .hasMessageContaining("xml:lang");
    }

    @Test
    void validate_rejette_si_aucune_voice() {
        String ssml = "<speak xml:lang=\"fr-FR\">Bonjour tout le monde</speak>";
        AudioSection section = audio(ssml, "Bonjour tout le monde", 1, List.of());

        assertThatThrownBy(() -> validator.validate(section))
            .isInstanceOf(SsmlValidationException.class)
            .hasMessageContaining("<voice>");
    }

    @Test
    void validate_rejette_une_voix_hors_whitelist() {
        String ssml = "<speak xml:lang=\"fr-FR\">"
            + "<voice name=\"fr-FR-FakeNeural\">Bonjour</voice></speak>";
        AudioSection section = audio(ssml, "Bonjour", 1,
            List.of(new VoiceInfo("R", "fr-FR-FakeNeural", "F")));

        assertThatThrownBy(() -> validator.validate(section))
            .isInstanceOf(SsmlValidationException.class)
            .hasMessageContaining("Voix Azure non autorisee");
    }

    @Test
    void validate_rejette_un_ssml_non_parseable() {
        String ssml = "<speak xml:lang=\"fr-FR\"><voice name=\"fr-FR-DeniseNeural\">Bonjour";
        AudioSection section = audio(ssml, "Bonjour", 1,
            List.of(new VoiceInfo("R", "fr-FR-DeniseNeural", "F")));

        assertThatThrownBy(() -> validator.validate(section))
            .isInstanceOf(SsmlValidationException.class)
            .hasMessageContaining("non parseable");
    }

    // ----- validate : echecs metier (ContentValidationException) -----

    @Test
    void validate_rejette_si_voix_declarees_differentes_des_voix_utilisees() {
        String spoken = "Bonjour madame";
        String ssml = "<speak xml:lang=\"fr-FR\">"
            + "<voice name=\"fr-FR-DeniseNeural\">" + spoken + "</voice></speak>";
        // declaree = Eloise, utilisee = Denise
        AudioSection section = audio(ssml, spoken, 1,
            List.of(new VoiceInfo("R", "fr-FR-EloiseNeural", "F")));

        assertThatThrownBy(() -> validator.validate(section))
            .isInstanceOf(ContentValidationException.class)
            .hasMessageContaining("Voix declarees");
    }

    @Test
    void validate_rejette_si_speakerCount_different_du_nombre_de_voix() {
        String spoken = "Bonjour madame";
        String ssml = "<speak xml:lang=\"fr-FR\">"
            + "<voice name=\"fr-FR-DeniseNeural\">" + spoken + "</voice></speak>";
        AudioSection section = audio(ssml, spoken, 2,
            List.of(new VoiceInfo("R", "fr-FR-DeniseNeural", "F")));

        assertThatThrownBy(() -> validator.validate(section))
            .isInstanceOf(ContentValidationException.class)
            .hasMessageContaining("speakerCount");
    }

    @Test
    void validate_rejette_si_transcript_incoherent_avec_le_ssml() {
        String ssml = "<speak xml:lang=\"fr-FR\">"
            + "<voice name=\"fr-FR-DeniseNeural\">Bonjour madame comment allez vous</voice></speak>";
        AudioSection section = audio(ssml, "texte totalement different xyz abcd", 1,
            List.of(new VoiceInfo("R", "fr-FR-DeniseNeural", "F")));

        assertThatThrownBy(() -> validator.validate(section))
            .isInstanceOf(ContentValidationException.class)
            .hasMessageContaining("transcript");
    }
}
