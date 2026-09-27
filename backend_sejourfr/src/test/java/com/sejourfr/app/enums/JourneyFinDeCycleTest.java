package com.sejourfr.app.enums;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class JourneyFinDeCycleTest {

    @Test
    @DisplayName("Cycle de travail ordinaire — il se clot par l'examen blanc complet")
    void cycleOrdinaire() {
        assertThat(JourneyFinDeCycle.de(false, false)).isEqualTo(JourneyFinDeCycle.EXAMEN_COMPLET);
    }

    @Test
    @DisplayName("Cycle d'affinage (D-64) ou cycle de mesure — l'actualisation seule")
    void affinageOuMesure() {
        assertThat(JourneyFinDeCycle.de(true, false)).isEqualTo(JourneyFinDeCycle.ACTUALISATION);
        assertThat(JourneyFinDeCycle.de(false, true)).isEqualTo(JourneyFinDeCycle.ACTUALISATION);
        assertThat(JourneyFinDeCycle.de(true, true)).isEqualTo(JourneyFinDeCycle.ACTUALISATION);
    }
}
