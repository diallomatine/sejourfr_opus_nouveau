package com.sejourfr.app.enums;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le pas de la courbe est choisi par le SERVEUR (brief §51).
 *
 * <p>Il decide du nombre de points, donc du sens de la courbe : deux ecrans qui
 * choisiraient chacun le leur afficheraient deux courbes differentes pour la
 * meme periode.
 */
class AnalyticsGrainTest {

    @Test
    @DisplayName("Une journée se lit à l'heure : elle n'a pas de « jour » à montrer")
    void journeeEnHeures() {
        assertThat(AnalyticsGrain.pour(1)).isEqualTo(AnalyticsGrain.HOUR);
        // Une amplitude nulle ou negative n'existe pas (une fenetre couvre au
        // minimum la journee courante) : on ne leve pas pour autant.
        assertThat(AnalyticsGrain.pour(0)).isEqualTo(AnalyticsGrain.HOUR);
    }

    @Test
    @DisplayName("De 2 à 45 jours, une barre par jour")
    void semainesEtMoisEnJours() {
        assertThat(AnalyticsGrain.pour(2)).isEqualTo(AnalyticsGrain.DAY);
        assertThat(AnalyticsGrain.pour(7)).isEqualTo(AnalyticsGrain.DAY);
        assertThat(AnalyticsGrain.pour(30)).isEqualTo(AnalyticsGrain.DAY);
        assertThat(AnalyticsGrain.pour(45)).isEqualTo(AnalyticsGrain.DAY);
    }

    /** Au-dela, une serie journaliere devient un peigne ou le bruit couvre la tendance. */
    @Test
    @DisplayName("Au-delà de 45 jours, une barre par semaine")
    void longuePeriodeEnSemaines() {
        assertThat(AnalyticsGrain.pour(46)).isEqualTo(AnalyticsGrain.WEEK);
        assertThat(AnalyticsGrain.pour(90)).isEqualTo(AnalyticsGrain.WEEK);
        assertThat(AnalyticsGrain.pour(365)).isEqualTo(AnalyticsGrain.WEEK);
    }

    @Test
    @DisplayName("Chaque pas nomme son unité SQL, et une seule fois")
    void uniteSql() {
        assertThat(AnalyticsGrain.HOUR.getSqlUnit()).isEqualTo("hour");
        assertThat(AnalyticsGrain.DAY.getSqlUnit()).isEqualTo("day");
        assertThat(AnalyticsGrain.WEEK.getSqlUnit()).isEqualTo("week");
    }
}
