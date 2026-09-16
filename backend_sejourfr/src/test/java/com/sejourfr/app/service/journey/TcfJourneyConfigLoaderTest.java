package com.sejourfr.app.service.journey;

import com.sejourfr.app.enums.JourneyLotSelectionStrategy;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * La configuration du parcours se charge, ou le demarrage echoue.
 *
 * <p>🛑 Ce test est le garde-fou de l'invariant « <b>aucune valeur de file en
 * dur</b> » : si quelqu'un remet un plafond dans le Java, il n'aura pas d'entree
 * ici et la config cessera d'etre l'autorite sans que rien ne le signale.
 */
class TcfJourneyConfigLoaderTest {

    @Test
    @DisplayName("La version livree se charge et porte toutes ses valeurs")
    void laVersionLivreeSeCharge() {
        TcfJourneyConfig config = TcfJourneyConfigLoader.load(1);

        assertThat(config.journeyConfigVersion()).isEqualTo(1);
        assertThat(config.maxPrioritiesPerLot()).isPositive();
        assertThat(config.trainSeriesQuota()).isPositive();
        assertThat(config.lotSelectionStrategy())
                .isEqualTo(JourneyLotSelectionStrategy.TOP_SEVERITY);
        assertThat(config.display().recentCompletedVisible()).isNotNegative();
        assertThat(config.display().upcomingVisible()).isPositive();
    }

    /**
     * R2 — le lot retient <b>3</b> priorites par epreuve, et D-5 clot une etape
     * de comprehension apres <b>2</b> series. Ces deux chiffres sont ceux que le
     * proprietaire a tranches : les verrouiller ici evite qu'un reglage
     * d'affichage les deplace par ricochet.
     */
    @Test
    @DisplayName("Les deux valeurs arbitrees sont celles du 2026-09-17")
    void lesDeuxValeursArbitreesSontCellesDuJour() {
        TcfJourneyConfig config = TcfJourneyConfigLoader.load(1);

        assertThat(config.maxPrioritiesPerLot()).isEqualTo(3);
        assertThat(config.trainSeriesQuota()).isEqualTo(2);
    }

    /** Une version absente ne demarre pas en silence sur des valeurs par defaut. */
    @Test
    @DisplayName("Une version inconnue fait echouer le demarrage")
    void uneVersionInconnueFaitEchouerLeDemarrage() {
        assertThatThrownBy(() -> TcfJourneyConfigLoader.load(999))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("tcf-journey-config-v999.json");
    }
}
