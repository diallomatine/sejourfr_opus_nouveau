package com.sejourfr.app.enums;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

/** Bornes des bandes qualitatives affichees a la place du {@code note_sur_20}. */
class BandeCritereTest {

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
        assertThat(BandeCritere.of(new BigDecimal(note))).isEqualTo(attendue);
    }

    @Test
    void of_noteAbsente_retourneNull() {
        assertThat(BandeCritere.of(null)).isNull();
    }
}
