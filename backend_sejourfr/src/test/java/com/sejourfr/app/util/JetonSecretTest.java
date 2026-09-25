package com.sejourfr.app.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class JetonSecretTest {

    @Test
    @DisplayName("Un jeton de 32 octets fait 43 caractères base64url, et ne se répète pas")
    void tirage() {
        Set<String> vus = new HashSet<>();
        for (int i = 0; i < 100; i++) {
            String jeton = JetonSecret.tirer(32);
            assertThat(jeton).hasSize(43).matches("[A-Za-z0-9_-]+");
            assertThat(vus.add(jeton)).isTrue();
        }
    }

    @Test
    @DisplayName("SHA-256 hexadécimal minuscule, format historique des jetons de réinitialisation")
    void hash() {
        assertThat(JetonSecret.sha256Hex("abc"))
                .isEqualTo("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    }

    @Test
    @DisplayName("Correspondance : le bon jeton seulement ; absent, vide ou faux ne correspond à rien")
    void correspondance() {
        String jeton = JetonSecret.tirer(32);
        String hash = JetonSecret.sha256Hex(jeton);
        assertThat(JetonSecret.correspond(jeton, hash)).isTrue();
        assertThat(JetonSecret.correspond(" " + jeton + " ", hash)).isTrue();
        assertThat(JetonSecret.correspond(JetonSecret.tirer(32), hash)).isFalse();
        assertThat(JetonSecret.correspond(null, hash)).isFalse();
        assertThat(JetonSecret.correspond("", hash)).isFalse();
        assertThat(JetonSecret.correspond(jeton, null)).isFalse();
    }
}
