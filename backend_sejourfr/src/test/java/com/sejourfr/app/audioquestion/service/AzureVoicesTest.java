package com.sejourfr.app.audioquestion.service;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AzureVoicesTest {

    @Test
    void whitelist_contient_les_14_voix_fr_fr() {
        assertThat(AzureVoices.ALLOWED).hasSize(14);
    }

    @Test
    void whitelist_contient_les_voix_attendues() {
        assertThat(AzureVoices.ALLOWED).contains(
            "fr-FR-DeniseNeural",
            "fr-FR-EloiseNeural",
            "fr-FR-VivienneNeural",
            "fr-FR-HenriNeural",
            "fr-FR-ClaudeNeural"
        );
    }

    @Test
    void whitelist_rejette_une_voix_hors_catalogue() {
        assertThat(AzureVoices.ALLOWED)
            .doesNotContain("fr-FR-FakeNeural", "en-US-JennyNeural");
    }

    @Test
    void whitelist_est_immuable() {
        assertThatThrownBy(() -> AzureVoices.ALLOWED.add("fr-FR-FakeNeural"))
            .isInstanceOf(UnsupportedOperationException.class);
    }
}
