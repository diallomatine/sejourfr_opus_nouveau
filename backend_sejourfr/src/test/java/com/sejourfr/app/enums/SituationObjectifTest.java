package com.sejourfr.app.enums;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/** La situation du niveau estime par rapport a l'objectif, lue chez {@code TcfDomaine}. */
class SituationObjectifTest {

    @Test
    @DisplayName("Atteint ou dépassé, un palier, plusieurs paliers")
    void lesTroisSituations() {
        assertThat(SituationObjectif.de(NiveauCecrl.B2, TargetLevel.B2))
                .isEqualTo(SituationObjectif.OBJECTIF_ATTEINT);
        assertThat(SituationObjectif.de(NiveauCecrl.C1, TargetLevel.B2))
                .isEqualTo(SituationObjectif.OBJECTIF_ATTEINT);
        assertThat(SituationObjectif.de(NiveauCecrl.B1, TargetLevel.B2))
                .isEqualTo(SituationObjectif.UN_PALIER_SOUS_OBJECTIF);
        assertThat(SituationObjectif.de(NiveauCecrl.A2, TargetLevel.B2))
                .isEqualTo(SituationObjectif.PLUSIEURS_PALIERS_SOUS_OBJECTIF);
        assertThat(SituationObjectif.de(NiveauCecrl.A1_NON_ATTEINT, TargetLevel.A2))
                .isEqualTo(SituationObjectif.PLUSIEURS_PALIERS_SOUS_OBJECTIF);
        assertThat(SituationObjectif.de(NiveauCecrl.A1, TargetLevel.A2))
                .isEqualTo(SituationObjectif.UN_PALIER_SOUS_OBJECTIF);
    }

    @Test
    @DisplayName("🛑 null = inconnu : niveau non évaluable ou objectif absent ⇒ null, jamais un verdict")
    void inconnuDonneNull() {
        assertThat(SituationObjectif.de(null, TargetLevel.B2)).isNull();
        assertThat(SituationObjectif.de(NiveauCecrl.B1, null)).isNull();
    }
}
