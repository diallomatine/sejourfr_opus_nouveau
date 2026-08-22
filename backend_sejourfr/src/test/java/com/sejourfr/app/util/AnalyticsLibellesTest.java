package com.sejourfr.app.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Les libelles que le serveur pose sur l'ecran Analytics.
 *
 * <p>🛑 Le test qui compte : <b>« direct » et « inconnu » ne se confondent
 * jamais</b> (brief §84). Le premier est une provenance <i>observee</i> —
 * personne n'a clique de lien —, le second est une <i>absence
 * d'observation</i>. Les fondre gonflerait le direct de tout l'historique
 * anterieur a la mesure, et effacerait le seul signal qui dit « on ne sait
 * pas ».
 */
class AnalyticsLibellesTest {

    @Test
    @DisplayName("« direct » et « inconnu » sont deux libellés différents, et ils le restent")
    void directNEstPasInconnu() {
        String direct = AnalyticsLibelles.source(TrafficSource.DIRECT);
        String inconnu = AnalyticsLibelles.source(TrafficSource.UNKNOWN);

        assertThat(direct).isEqualTo("Accès direct");
        assertThat(inconnu).isEqualTo("Inconnu");
        assertThat(direct).isNotEqualTo(inconnu);
    }

    /**
     * Une provenance absente n'est pas « direct » : c'est le cas des comptes
     * anterieurs a la mesure, et le dire est plus utile que de les ranger dans
     * un canal ou ils n'ont jamais mis les pieds.
     */
    @Test
    @DisplayName("Une provenance absente se rend « inconnu », jamais « direct »")
    void provenanceAbsente() {
        assertThat(AnalyticsLibelles.source(null)).isEqualTo("Inconnu");
        assertThat(AnalyticsLibelles.source("  ")).isEqualTo("Inconnu");
    }

    @Test
    @DisplayName("Une provenance hors table est rendue telle quelle, jamais réécrite")
    void provenanceHorsTable() {
        assertThat(AnalyticsLibelles.source("autre")).isEqualTo("Autre réseau");
        assertThat(AnalyticsLibelles.source("linkedin")).isEqualTo("linkedin");
    }

    @Test
    @DisplayName("Un pays absent est « Inconnu », jamais un pays plausible")
    void paysInconnu() {
        assertThat(AnalyticsLibelles.pays(null)).isEqualTo("Inconnu");
        assertThat(AnalyticsLibelles.pays(AnalyticsLibelles.PAYS_INCONNU)).isEqualTo("Inconnu");
        assertThat(AnalyticsLibelles.pays("FR")).isEqualTo("France");
    }

    @Test
    @DisplayName("Un appareil illisible retombe sur « Inconnu », sans lever")
    void appareilInconnu() {
        assertThat(AnalyticsLibelles.appareil("MOBILE_WEB")).isEqualTo("Mobile (web)");
        assertThat(AnalyticsLibelles.appareil("N_IMPORTE_QUOI")).isEqualTo("Inconnu");
        assertThat(AnalyticsLibelles.appareil(null)).isEqualTo("Inconnu");
    }

    @Test
    @DisplayName("Un contexte d'inscription porte toujours son libellé et son explication")
    void contexteEtIndice() {
        assertThat(AnalyticsLibelles.contexte("AFTER_DIAGNOSTIC"))
                .isEqualTo("Après les productions");
        assertThat(AnalyticsLibelles.indiceContexte("AFTER_DIAGNOSTIC")).isNotBlank();
        assertThat(AnalyticsLibelles.contexte("INEXISTANT")).isEqualTo("Autre");
        assertThat(AnalyticsLibelles.indiceContexte(null)).isNotBlank();
    }

    @Test
    @DisplayName("Un format de diagnostic non déclaré ne devient pas « rapide »")
    void formatNonDeclare() {
        assertThat(AnalyticsLibelles.diagnostic("RAPID")).isEqualTo("Diagnostic rapide");
        assertThat(AnalyticsLibelles.diagnostic("COMPLETE")).isEqualTo("Diagnostic complet");
        assertThat(AnalyticsLibelles.diagnostic("UNKNOWN")).isEqualTo("Format non déclaré");
        assertThat(AnalyticsLibelles.diagnostic(null)).isEqualTo("Format non déclaré");
    }
}
