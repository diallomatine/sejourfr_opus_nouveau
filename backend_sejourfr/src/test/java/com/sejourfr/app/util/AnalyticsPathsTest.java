package com.sejourfr.app.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/** L'allowlist de chemins : ce qu'elle normalise, ce qu'elle refuse. */
class AnalyticsPathsTest {

    @Test
    @DisplayName("La query-string et le fragment sont retirés : ils portent les UTM, parfois un jeton")
    void queryEtFragmentRetires() {
        assertThat(AnalyticsPaths.normalizeOrThrow("/reussir?utm_source=tiktok&utm_content=v12"))
                .isEqualTo("/reussir");
        assertThat(AnalyticsPaths.normalizeOrThrow("/plan#section")).isEqualTo("/plan");
    }

    @Test
    @DisplayName("Casse et slash final sont normalisés : une seule dimension par écran")
    void casseEtSlashFinal() {
        assertThat(AnalyticsPaths.normalizeOrThrow("/Diagnostic/")).isEqualTo("/diagnostic");
        assertThat(AnalyticsPaths.normalizeOrThrow("  /TARIFS  ")).isEqualTo("/tarifs");
        assertThat(AnalyticsPaths.normalizeOrThrow("/")).isEqualTo("/");
    }

    @Test
    @DisplayName("Absent est un cas normal : tous les événements ne portent pas d'écran")
    void absentEstNormal() {
        assertThat(AnalyticsPaths.normalizeOrThrow(null)).isNull();
        assertThat(AnalyticsPaths.normalizeOrThrow("   ")).isNull();
    }

    /**
     * Un chemin hors liste n'est pas rangé en silence dans un fourre-tout :
     * c'est un front qui instrumente un écran non déclaré, et il doit
     * l'apprendre tout de suite. Le message nomme les valeurs acceptées.
     */
    @Test
    @DisplayName("Un chemin hors allowlist est refusé en nommant les valeurs acceptées")
    void horsAllowlistRefuse() {
        assertThatThrownBy(() -> AnalyticsPaths.normalizeOrThrow("/diagnostic/3f2a-1234"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("path")
                .hasMessageContaining("/diagnostic/3f2a-1234")
                .hasMessageContaining("/reussir");
    }

    @Test
    @DisplayName("Un identifiant dans le chemin ne peut donc jamais être stocké")
    void aucunIdentifiantStocke() {
        assertThat(AnalyticsPaths.isKnown("/plan/f47ac10b-58cc-4372-a567-0e02b2c3d479")).isFalse();
        assertThat(AnalyticsPaths.isKnown("/reussir")).isTrue();
    }
}
