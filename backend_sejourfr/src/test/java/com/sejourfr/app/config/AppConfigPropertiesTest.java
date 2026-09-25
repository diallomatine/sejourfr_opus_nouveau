package com.sejourfr.app.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/** Contrôle G (option a) : un seuil mal écrit fait échouer le démarrage, un seuil vide ne bloque personne. */
class AppConfigPropertiesTest {

    private static AppConfigProperties avec(String ios, String android) {
        AppConfigProperties p = new AppConfigProperties();
        p.getMinSupportedVersion().setIos(ios);
        p.getMinSupportedVersion().setAndroid(android);
        return p;
    }

    @Test
    @DisplayName("Vide ou absent ⇒ null (aucune exigence) ; MAJOR.MINOR.PATCH accepté")
    void valeursAdmises() {
        AppConfigProperties vide = avec("", null);
        vide.verifier();
        assertThat(vide.getMinSupportedVersion().getIos()).isNull();

        AppConfigProperties posee = avec("2.5.0", " 10.0.12 ");
        posee.verifier();
        assertThat(posee.getMinSupportedVersion().getAndroid()).isEqualTo("10.0.12");
    }

    @Test
    @DisplayName("Format illisible ⇒ échec au démarrage")
    void formatIllisible() {
        for (String faux : new String[]{"2.5", "2.5.0+57", "v2.5.0", "latest"}) {
            assertThatThrownBy(() -> avec(faux, null).verifier())
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("min-supported-version.ios");
        }
    }
}
