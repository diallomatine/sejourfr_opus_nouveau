package com.sejourfr.app.service.adminproduction;

import com.sejourfr.app.enums.AdminProductionContexte;
import com.sejourfr.app.enums.AdminProductionStatutIa;
import com.sejourfr.app.enums.EtatSignalement;
import com.sejourfr.app.enums.MotifSignalement;
import org.junit.jupiter.api.Test;

import java.util.Arrays;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Libellés servis à la console « Productions IA », gelés : l'admin les
 * affiche tels quels, il n'en tient aucune copie.
 */
class AdminProductionLabelsTest {

    @Test
    void motifs_de_signalement() {
        assertThat(Arrays.stream(MotifSignalement.values()).map(MotifSignalement::label)).containsExactly(
                "Niveau incohérent", "Score incohérent", "Feedback incorrect",
                "Réponse mal comprise par l'IA", "Problème de transcription", "Autre");
    }

    @Test
    void statuts_ia() {
        assertThat(Arrays.stream(AdminProductionStatutIa.values()).map(AdminProductionStatutIa::label))
                .containsExactly("En cours", "Évaluée", "Non évaluable", "Échec");
    }

    @Test
    void etats_de_signalement_et_contextes() {
        assertThat(Arrays.stream(EtatSignalement.values()).map(EtatSignalement::label))
                .containsExactly("Non signalée", "Signalée", "Vérifiée", "Retiré");
        assertThat(AdminProductionContexte.of(true, true)).isEqualTo(AdminProductionContexte.EXAMEN_COMPLET);
        assertThat(AdminProductionContexte.of(false, true)).isEqualTo(AdminProductionContexte.EXAMEN_BLANC);
        assertThat(AdminProductionContexte.of(false, false)).isEqualTo(AdminProductionContexte.ENTRAINEMENT);
    }
}
