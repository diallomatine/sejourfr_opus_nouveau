package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.util.ProductionTextBounds;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La longueur DEMANDÉE et la longueur ACCEPTÉE du texte modèle écrit
 * (décision du propriétaire du 2026-10-04).
 */
class VersionCibleeLongueurTest {

    /**
     * Milieu de la fourchette arrondi à la dizaine supérieure, ramené dans les
     * bornes. 30–60 → 50 et 40–90 → 70 sont les deux tâches EE réelles.
     */
    @ParameterizedTest
    @CsvSource({
        "30, 60, 50",
        "40, 90, 70",
        "60, 120, 90",
        "50, 50, 50",
        "50, 52, 52",
        "10, 15, 15"
    })
    void laCibleEstLeMilieuArrondiALaDizaineSuperieure(int min, int max, int cible) {
        assertThat(VersionCibleeLongueur.cible(new ProductionTextBounds(min, max))).isEqualTo(cible);
    }

    /** Plafond toléré = mots_max + tolérance ; plancher STRICT. */
    @ParameterizedTest
    @CsvSource({
        "30, 60, 10, 29, false",
        "30, 60, 10, 30, true",
        "30, 60, 10, 61, true",
        "30, 60, 10, 70, true",
        "30, 60, 10, 71, false",
        "40, 90, 10, 39, false",
        "40, 90, 10, 100, true",
        "40, 90, 10, 101, false",
        "30, 60, 0, 60, true",
        "30, 60, 0, 61, false"
    })
    void plancherStrict_plafondTolere(int min, int max, int tolerance, int mots, boolean accepte) {
        assertThat(VersionCibleeLongueur.accepte(mots, new ProductionTextBounds(min, max), tolerance))
            .isEqualTo(accepte);
    }
}
