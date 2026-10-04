package com.sejourfr.app.util;

import com.sejourfr.app.audioquestion.service.AzureVoices;
import com.sejourfr.app.audioquestion.service.SsmlValidator;
import org.junit.jupiter.api.Test;
import org.w3c.dom.Document;
import org.xml.sax.InputSource;

import javax.xml.parsers.DocumentBuilderFactory;
import java.io.StringReader;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PropositionsLuesCoImageTest {

    private static final List<String> PROPOSITIONS = List.of(
            "Allez vous coucher rapidement.",
            "Finissez vos exercices de français.",
            "Regardez la télévision maintenant.",
            "Venez manger tout de suite.");

    @Test
    void transcription_suit_le_gabarit_V802() {
        // Recopie du transcript_text du brouillon V802 n°1.
        String v802 = """
                Écoutez les quatre propositions. Choisissez celle qui correspond à l'image.

                A. Allez vous coucher rapidement.
                B. Finissez vos exercices de français.
                C. Regardez la télévision maintenant.
                D. Venez manger tout de suite.""";

        assertThat(PropositionsLuesCoImage.transcription(PROPOSITIONS)).isEqualTo(v802);
    }

    @Test
    void ssml_lit_l_introduction_puis_les_lettres_dans_l_ordre() {
        String ssml = PropositionsLuesCoImage.ssml(PROPOSITIONS);

        assertThat(ssml).isEqualTo("<speak version=\"1.0\" xml:lang=\"fr-FR\">"
                + "<voice name=\"fr-FR-DeniseNeural\"><prosody rate=\"0.95\">"
                + "Écoutez les quatre propositions. Choisissez celle qui correspond à l&apos;image."
                + "<break time=\"1500ms\"/>"
                + "A.<break time=\"300ms\"/>Allez vous coucher rapidement.<break time=\"700ms\"/>"
                + "B.<break time=\"300ms\"/>Finissez vos exercices de français.<break time=\"700ms\"/>"
                + "C.<break time=\"300ms\"/>Regardez la télévision maintenant.<break time=\"700ms\"/>"
                + "D.<break time=\"300ms\"/>Venez manger tout de suite."
                + "</prosody></voice></speak>");
        assertThat(ssml.indexOf("A.")).isLessThan(ssml.indexOf("B."));
        assertThat(ssml.indexOf("B.")).isLessThan(ssml.indexOf("C."));
        assertThat(ssml.indexOf("C.")).isLessThan(ssml.indexOf("D."));
    }

    @Test
    void ssml_echappe_le_texte_des_propositions() throws Exception {
        List<String> piegees = List.of("Tom & Léa", "<break time=\"9s\"/>", "Il dit \"oui\"", "C'est > 3");

        String ssml = PropositionsLuesCoImage.ssml(piegees);

        assertThat(ssml).contains("Tom &amp; Léa", "&lt;break time=&quot;9s&quot;/&gt;",
                "Il dit &quot;oui&quot;", "C&apos;est &gt; 3");
        assertThat(ssml).doesNotContain("9s\"/>");
        Document doc = parser(ssml);
        assertThat(doc.getElementsByTagName("break").getLength()).isEqualTo(1 + 4 + 3);
        assertThat(doc.getDocumentElement().getTextContent()).contains("Tom & Léa", "<break time=\"9s\"/>");
    }

    @Test
    void ssml_survit_au_nettoyage_azure_sans_perdre_la_pause_d_introduction() {
        String ssml = PropositionsLuesCoImage.ssml(PROPOSITIONS);

        assertThat(new SsmlValidator().cleanForAzure(ssml)).isEqualTo(ssml);
        assertThat(AzureVoices.ALLOWED).contains(PropositionsLuesCoImage.VOIX);
    }

    @Test
    void exige_quatre_propositions() {
        assertThatThrownBy(() -> PropositionsLuesCoImage.ssml(List.of("a", "b", "c")))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> PropositionsLuesCoImage.transcription(null))
                .isInstanceOf(IllegalArgumentException.class);
    }

    private static Document parser(String xml) throws Exception {
        DocumentBuilderFactory f = DocumentBuilderFactory.newInstance();
        f.setNamespaceAware(true);
        return f.newDocumentBuilder().parse(new InputSource(new StringReader(xml)));
    }
}
