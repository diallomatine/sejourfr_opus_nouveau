package com.sejourfr.app.util;

import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * LES PASSAGES A SURLIGNER SONT UN CONFORT — ils tombent seuls, jamais avec leur
 * texte.
 *
 * <p>Ce que verrouille cette classe : un segment inexploitable est RETIRE avec son
 * motif, l'extrait conserve est la sous-chaine ORIGINALE exacte du texte, et un
 * extrait reellement invente reste refuse. Le filet servant DEUX surfaces
 * (productions et Competences), il est aussi verrouille qu'il lit les noms de
 * champs qu'on lui donne, et rien d'autre.
 */
class SegmentsSurlignageTest {

    private static final String TEXTE =
        "Je suis heureux de t'annoncer que j'ai emménagé près de la gare. "
            + "Ce logement — lumineux — me plaît beaucoup.";

    /** Plafond de l'etiquette declare par les deux grilles. */
    private static final int PLAFOND_APPORT = 3;

    private static final SegmentsSurlignage FILET =
        SegmentsSurlignage.surLesChamps("extrait", "apport");

    private static Map<String, Object> segment(String extrait, String apport) {
        Map<String, Object> s = new LinkedHashMap<>();
        s.put("extrait", extrait);
        s.put("apport", apport);
        return s;
    }

    private static SegmentsSurlignage.Resultat purge(Object... segments) {
        return FILET.purge(new ArrayList<>(Arrays.asList(segments)), TEXTE, PLAFOND_APPORT);
    }

    @Test
    void unSegmentConformeEstConserve() {
        SegmentsSurlignage.Resultat resultat =
            purge(segment("j'ai emménagé près de la gare", "plus précis"));

        assertThat(resultat.retires()).isEmpty();
        assertThat(resultat.gardes()).singleElement().satisfies(garde -> {
            assertThat(garde.get("extrait")).isEqualTo("j'ai emménagé près de la gare");
            assertThat(garde.get("apport")).isEqualTo("plus précis");
        });
    }

    /** L'INVARIANT : ce qui est servi existe LITTERALEMENT dans le texte affiché. */
    @Test
    void lExtraitConserveEstLaSousChaineOriginaleExacte() {
        SegmentsSurlignage.Resultat resultat =
            purge(segment("logement - lumineux - me plaît", "plus imagé"));

        String extrait = String.valueOf(resultat.gardes().get(0).get("extrait"));
        assertThat(extrait).isEqualTo("logement — lumineux — me plaît");
        assertThat(TEXTE).contains(extrait);
    }

    @Test
    void unExtraitInventeEstRetire() {
        SegmentsSurlignage.Resultat resultat =
            purge(segment("un passage que le texte ne contient pas", "plus précis"));

        assertThat(resultat.gardes()).isEmpty();
        assertThat(resultat.retires()).singleElement().satisfies(retire ->
            assertThat(retire.motif())
                .isEqualTo(SegmentsSurlignage.Motif.EXTRAIT_INTROUVABLE));
    }

    @Test
    void unSegmentMalFormeEstRetire() {
        SegmentsSurlignage.Resultat resultat = purge(
            "une chaine au lieu d'un objet",
            segment(null, "plus précis"),
            segment("j'ai emménagé", "   "),
            segment("j'ai emménagé", "une étiquette beaucoup trop bavarde pour tenir"));

        assertThat(resultat.gardes()).isEmpty();
        assertThat(resultat.retires()).hasSize(4)
            .allSatisfy(retire -> assertThat(retire.motif())
                .isEqualTo(SegmentsSurlignage.Motif.MALFORME));
    }

    /** TOLERANCE REELLE : le plafond vaut 3 mots, quatre passent, cinq non. */
    @Test
    void unApportDeQuatreMotsPasse_deCinqEstRetire() {
        assertThat(purge(segment("j'ai emménagé", "plus précis et net")).gardes()).hasSize(1);
        assertThat(purge(segment("j'ai emménagé", "plus précis et net encore")).retires())
            .hasSize(1);
    }

    @Test
    void uneCleHorsContratFaitTomberLeSeulSegment() {
        Map<String, Object> segment = segment("j'ai emménagé", "plus précis");
        segment.put("note", 14);

        SegmentsSurlignage.Resultat resultat = purge(segment);

        assertThat(resultat.gardes()).isEmpty();
        assertThat(resultat.retires()).singleElement().satisfies(retire ->
            assertThat(retire.motif()).isEqualTo(SegmentsSurlignage.Motif.MALFORME));
    }

    @Test
    void auDelaDeTroisSegmentsLesSurnumerairesSontTronques() {
        SegmentsSurlignage.Resultat resultat = purge(
            segment("Je suis heureux", "plus chaleureux"),
            segment("j'ai emménagé", "plus précis"),
            segment("près de la gare", "plus situé"),
            segment("me plaît beaucoup", "plus nuancé"));

        assertThat(resultat.gardes()).hasSize(SegmentsSurlignage.MAX_SEGMENTS);
        assertThat(resultat.retires()).singleElement().satisfies(retire ->
            assertThat(retire.motif()).isEqualTo(SegmentsSurlignage.Motif.EN_TROP));
    }

    /** Sans texte, il n'y a rien a surligner — et surtout rien a inventer. */
    @Test
    void sansTexteOuSansListeRienNEstConserve() {
        assertThat(FILET.purge(
            List.of(segment("j'ai emménagé", "plus précis")), "  ", PLAFOND_APPORT).gardes())
            .isEmpty();
        assertThat(FILET.purge("pas une liste", TEXTE, PLAFOND_APPORT).gardes()).isEmpty();
        assertThat(FILET.purge(null, TEXTE, PLAFOND_APPORT).gardes()).isEmpty();
    }

    /** Sans plafond declare par la grille, on ne rejette rien sur la longueur. */
    @Test
    void sansPlafondDeclareLEtiquetteNEstPasJugee() {
        assertThat(FILET.purge(
            List.of(segment("j'ai emménagé", "une étiquette vraiment très bavarde")),
            TEXTE, null).gardes()).hasSize(1);
    }

    /**
     * Le filet lit les champs QU'ON LUI DONNE. Sans ce paramètre, partager la
     * mecanique entre deux contrats aurait suppose que les deux nomment leurs
     * champs pareil pour toujours.
     */
    @Test
    void lesNomsDeChampsSontCeuxDuContratAppelant() {
        SegmentsSurlignage autre = SegmentsSurlignage.surLesChamps("passage", "gain");
        Map<String, Object> segment = new LinkedHashMap<>();
        segment.put("passage", "j'ai emménagé");
        segment.put("gain", "plus précis");

        SegmentsSurlignage.Resultat resultat =
            autre.purge(List.of(segment), TEXTE, PLAFOND_APPORT);

        assertThat(resultat.retires()).isEmpty();
        assertThat(resultat.gardes()).singleElement().satisfies(garde -> {
            assertThat(garde.get("passage")).isEqualTo("j'ai emménagé");
            assertThat(garde.get("gain")).isEqualTo("plus précis");
        });
        // Les memes donnees lues avec les cles de l'autre contrat sont malformees.
        assertThat(FILET.purge(List.of(segment), TEXTE, PLAFOND_APPORT).gardes()).isEmpty();
    }
}
