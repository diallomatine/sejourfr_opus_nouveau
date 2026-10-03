package com.sejourfr.app.enums;

import com.sejourfr.app.util.AnalyticsPaths;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le registre des ecrans de reference ({@code SCREEN_VIEWED}) : gabarits seuls,
 * en minuscules (la normalisation les y ramene), sans doublon par front, tous
 * admis par l'allowlist. Les fronts en tiennent une copie ecrite a la main
 * (contrat : {@code docs/admin/activites/decisions-implementation.md}).
 */
class TrackedScreenTest {

    /** Segments litteraux en minuscules, ou {@code :param} en minuscules — jamais un identifiant. */
    private static final Pattern GABARIT = Pattern.compile("^/([a-z0-9-]+|:[a-z]+)?(/([a-z0-9-]+|:[a-z]+))*$");

    @Test
    @DisplayName("36 écrans, des gabarits en minuscules, admis par l'allowlist")
    void gabarits() {
        assertThat(TrackedScreen.values()).hasSize(36);
        for (TrackedScreen screen : TrackedScreen.values()) {
            assertThat(screen.getWebPath() != null || screen.getAppPath() != null).as(screen.name()).isTrue();
            assertThat(screen.getLabel()).as(screen.name()).isNotBlank();
            for (String path : new String[]{screen.getWebPath(), screen.getAppPath()}) {
                if (path == null) continue;
                assertThat(path).as(screen.name()).matches(GABARIT);
                assertThat(AnalyticsPaths.isKnown(path)).as(path).isTrue();
                assertThat(AnalyticsPaths.normalizeOrThrow(path)).isEqualTo(path);
            }
        }
    }

    @Test
    @DisplayName("Un chemin ne désigne qu'un écran par front")
    void aucunDoublonParFront() {
        for (boolean app : new boolean[]{false, true}) {
            Set<String> vus = new HashSet<>();
            for (TrackedScreen screen : TrackedScreen.values()) {
                String path = app ? screen.getAppPath() : screen.getWebPath();
                if (path != null) assertThat(vus.add(path)).as(path).isTrue();
            }
        }
    }

    @Test
    @DisplayName("Les chemins historiques de l'entonnoir restent admis")
    void historiquesAdmis() {
        for (String path : List.of("/", "/reussir", "/diagnostic", "/diagnostic/resultat", "/diagnostic-civique",
                "/diagnostic-civique/resultat", "/plan", "/plan/debloquer", "/tarifs", "/paiement", "/connexion",
                "/inscription", "/dashboard", "/entrainement", "/examens-blancs", "/competences", "/profil",
                "/home", "/target-path", "/paywall")) {
            assertThat(AnalyticsPaths.isKnown(path)).as(path).isTrue();
        }
    }

    @Test
    @DisplayName("Le libellé se lit sur le chemin du bon front")
    void libelleParFront() {
        assertThat(TrackedScreen.byPath("/dashboard", false)).contains(TrackedScreen.ACCUEIL);
        assertThat(TrackedScreen.byPath("/home", true)).contains(TrackedScreen.ACCUEIL);
        assertThat(TrackedScreen.byPath("/home", false)).isEmpty();
    }
}
