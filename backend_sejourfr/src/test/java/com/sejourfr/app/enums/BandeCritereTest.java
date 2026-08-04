package com.sejourfr.app.enums;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Bornes des bandes qualitatives affichees a la place du {@code note_sur_20}.
 *
 * <p>Elles suivent l'ECHELLE de la grille active : celle des grilles v3-v5
 * (16-20 / 11-15 / 6-10 / 1-5) est le defaut de la config, celle de v6 (echelle
 * du TCF : 10-20 / 6-9 / 2-5 / 1) est declaree par le fichier de rubriques.
 */
class BandeCritereTest {

    private static ProductionEvaluationProperties.BandesCriteres bornes(double haute, double moyenne, double basse) {
        ProductionEvaluationProperties.BandesCriteres b = new ProductionEvaluationProperties.BandesCriteres();
        b.setTresBonneMaitrise(haute);
        b.setSatisfaisant(moyenne);
        b.setEnCoursAcquisition(basse);
        return b;
    }

    /** Bornes historiques (v3 a v5), qui restent le defaut de la configuration. */
    @ParameterizedTest
    @CsvSource({
        "20, TRES_BONNE_MAITRISE",
        "16, TRES_BONNE_MAITRISE",
        "15.9, SATISFAISANT",
        "15, SATISFAISANT",
        "11, SATISFAISANT",
        "10.5, EN_COURS_ACQUISITION",
        "10, EN_COURS_ACQUISITION",
        "6, EN_COURS_ACQUISITION",
        "5.5, FRAGILE",
        "5, FRAGILE",
        "1, FRAGILE",
        "0.5, FRAGILE",
        "0, NON_EVALUABLE"
    })
    void of_mappeChaqueBande(String note, BandeCritere attendue) {
        assertThat(BandeCritere.of(new BigDecimal(note), new ProductionEvaluationProperties.BandesCriteres()))
            .isEqualTo(attendue);
    }

    /**
     * Sur l'echelle du TCF, un critere a 8 est un BON B1 et un critere a 12 un
     * B2 confirme. Avec les bornes de v5 laissees en dur, ils s'afficheraient
     * « en cours d'acquisition » et « satisfaisant » : c'est le bug que ces
     * bornes reglables evitent.
     */
    @ParameterizedTest
    @CsvSource({
        "20, TRES_BONNE_MAITRISE",
        "12, TRES_BONNE_MAITRISE",
        "10, TRES_BONNE_MAITRISE",
        "9.75, SATISFAISANT",
        "9, SATISFAISANT",
        "6, SATISFAISANT",
        "5.75, EN_COURS_ACQUISITION",
        "5, EN_COURS_ACQUISITION",
        "2, EN_COURS_ACQUISITION",
        "1.75, FRAGILE",
        "1, FRAGILE",
        "0, NON_EVALUABLE"
    })
    void of_suitLesBornesDeLaGrilleActive(String note, BandeCritere attendue) {
        assertThat(BandeCritere.of(new BigDecimal(note), bornes(10, 6, 2))).isEqualTo(attendue);
    }

    @Test
    void of_noteAbsente_retourneNull() {
        assertThat(BandeCritere.of(null, new ProductionEvaluationProperties.BandesCriteres())).isNull();
    }

    /** Le 0 vaut NON_EVALUABLE quelle que soit l'echelle : c'est le hors-sujet. */
    @Test
    void of_zero_estNonEvaluableSurLesDeuxEchelles() {
        assertThat(BandeCritere.of(BigDecimal.ZERO, new ProductionEvaluationProperties.BandesCriteres()))
            .isEqualTo(BandeCritere.NON_EVALUABLE);
        assertThat(BandeCritere.of(BigDecimal.ZERO, bornes(10, 6, 2)))
            .isEqualTo(BandeCritere.NON_EVALUABLE);
    }
}
