package com.sejourfr.app.service.diagnosticcivique;

import com.sejourfr.app.enums.CivicExamFormat;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La projection d'un diagnostic sur l'échelle de l'examen réel (20_ §4.4).
 *
 * <p>🛑 Elle est calculée **côté serveur** et nulle part ailleurs : ni écrite en
 * dur dans une maquette, ni recalculée par un front. Deux calculs de la même
 * chose finissent par afficher deux nombres.
 */
class CivicExamFormatTest {

    @Test
    @DisplayName("L'exemple de la spec : 18 / 24 → 30 / 40")
    void exempleDeLaSpec() {
        assertThat(CivicExamFormat.projection(18, 24)).isEqualTo(30);
    }

    @Test
    @DisplayName("🛑 Aucune question posée ⇒ null, jamais 0 sur 40")
    void aucuneQuestionPoseeNeDonnePasZero() {
        // « On n'a rien mesuré » ne se dit pas « vous auriez 0 sur 40 ».
        assertThat(CivicExamFormat.projection(0, 0)).isNull();
    }

    @Test
    @DisplayName("Le format officiel est du code, pas un réglage")
    void formatOfficiel() {
        assertThat(CivicExamFormat.QUESTIONS).isEqualTo(40);
        assertThat(CivicExamFormat.SEUIL_REUSSITE).isEqualTo(32);
    }

    @Test
    @DisplayName("Tout raté projette 0 — et c'est une vraie mesure, elle")
    void toutRate() {
        assertThat(CivicExamFormat.projection(0, 24)).isZero();
    }
}
