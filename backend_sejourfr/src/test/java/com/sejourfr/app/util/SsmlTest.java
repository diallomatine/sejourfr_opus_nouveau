package com.sejourfr.app.util;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Gele le gabarit que produisaient, avant extraction, les deux constructeurs
 * SSML de {@code ProductionExampleAudioService} et
 * {@code DiagnosticInstructionAudioService} : l'extraction ne change pas un octet.
 */
class SsmlTest {

    @Test
    void echapperXml_echappe_les_cinq_entites() {
        assertThat(Ssml.echapperXml("a & b < c > d \" e ' f"))
                .isEqualTo("a &amp; b &lt; c &gt; d &quot; e &apos; f");
    }

    @Test
    void echapperXml_n_echappe_pas_deux_fois() {
        assertThat(Ssml.echapperXml("&amp;")).isEqualTo("&amp;amp;");
    }

    @Test
    void voixUnique_reproduit_le_gabarit_historique_a_l_octet() {
        String historique = "<speak version=\"1.0\" xml:lang=\"fr-FR\">"
                + "<voice name=\"fr-FR-HenriNeural\">"
                + "<prosody rate=\"0.95\">Bonjour.<break time=\"300ms\"/> Merci</prosody>"
                + "</voice></speak>";

        assertThat(Ssml.voixUnique("fr-FR-HenriNeural", "Bonjour.<break time=\"300ms\"/> Merci"))
                .isEqualTo(historique);
    }
}
