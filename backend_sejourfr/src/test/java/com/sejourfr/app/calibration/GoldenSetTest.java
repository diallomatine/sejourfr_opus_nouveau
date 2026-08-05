package com.sejourfr.app.calibration;

import com.sejourfr.app.enums.NiveauCecrl;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Contrat du corpus de reference. Ne declenche AUCUN appel LLM : c'est un test
 * de coherence du fichier, il tourne dans {@code ./mvnw verify}.
 *
 * <p>Depuis les rubriques v6, {@code note_min}/{@code note_max} ne sont plus des
 * jugements independants : ce sont l'IMAGE MECANIQUE de {@code attendu.niveau}
 * par la table officielle de conversion du TCF IRN. Les figer ici evite qu'une
 * campagne future ne « fasse passer » un cas en elargissant sa fourchette — la
 * seule maniere de la deplacer est de changer le NIVEAU attendu, c'est-a-dire
 * la reference annotee elle-meme.
 */
class GoldenSetTest {

    /**
     * Table officielle TCF IRN. Borne basse = borne basse officielle du palier ;
     * borne haute = derniere note, au dixieme pres (le serveur arrondit
     * {@code note_globale} a une decimale), qui converge encore vers ce palier.
     */
    private static final Map<NiveauCecrl, double[]> TABLE_OFFICIELLE = Map.of(
        NiveauCecrl.A1_NON_ATTEINT, new double[]{0, 0},
        NiveauCecrl.A1, new double[]{1, 1.9},
        NiveauCecrl.A2, new double[]{2, 5.9},
        NiveauCecrl.B1, new double[]{6, 9.9},
        NiveauCecrl.B2, new double[]{10, 20});

    @Test
    void chaque_fourchette_est_l_image_du_niveau_attendu_par_la_table_du_tcf() {
        List<GoldenSet.Cas> corpus = GoldenSet.load();

        assertThat(corpus).hasSize(48);
        for (GoldenSet.Cas cas : corpus) {
            double[] attendu = TABLE_OFFICIELLE.get(cas.attendu().niveau());
            assertThat(attendu).as(cas.id() + " : niveau attendu couvert par la table").isNotNull();
            assertThat(cas.attendu().noteMin()).as(cas.id() + " : note_min").isEqualTo(attendu[0]);
            assertThat(cas.attendu().noteMax()).as(cas.id() + " : note_max").isEqualTo(attendu[1]);
        }
    }

    /**
     * Le corpus couvre les cinq niveaux et garde ses pieges : c'est ce qui rend
     * une campagne comparable a la precedente.
     */
    @Test
    void le_corpus_couvre_les_cinq_niveaux_et_ses_pieges() {
        List<GoldenSet.Cas> corpus = GoldenSet.load();

        assertThat(corpus).extracting(c -> c.attendu().niveau())
            .contains(NiveauCecrl.A1_NON_ATTEINT, NiveauCecrl.A1, NiveauCecrl.A2,
                NiveauCecrl.B1, NiveauCecrl.B2);
        assertThat(corpus.stream().flatMap(c -> c.attendu().pieges().stream()).toList())
            .contains("HORS_SUJET", "TRANSCRIPTION_BRUITEE", "AUTRE_LANGUE",
                "CONSIGNE_RECOPIEE", "QUASI_MUET", "MEMORISE", "IA_GENERE");
        assertThat(corpus.stream().map(GoldenSet.Cas::groupe).distinct().toList())
            .as("les 6 taches EE/EO sont representees")
            .containsExactlyInAnyOrder("EE_T1", "EE_T2", "EE_T3", "EO_T1", "EO_T2", "EO_T3");
    }
}
