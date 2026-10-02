package com.sejourfr.app.util;

import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;

import static org.assertj.core.api.Assertions.assertThat;

/** Conversion date métier ⇄ instant, Europe/Paris (spec §2.5, G-7). */
class DateMetierParisTest {

    private static final ZoneId PARIS = ZoneId.of("Europe/Paris");
    private static final Instant NOW = LocalDateTime.of(2026, 10, 2, 14, 37).atZone(PARIS).toInstant();

    @Test
    void finInclusePoseLaBorneExclusiveALendemainMinuitParis() {
        assertThat(DateMetierParis.finExclusive(LocalDate.of(2026, 10, 31)))
                .isEqualTo(LocalDateTime.of(2026, 11, 1, 0, 0).atZone(PARIS).toInstant());
        // Heure d'été : minuit Paris = 22:00 UTC.
        assertThat(DateMetierParis.finExclusive(LocalDate.of(2026, 7, 14)))
                .isEqualTo(Instant.parse("2026-07-14T22:00:00Z"));
    }

    @Test
    void debutAujourdhuiEstMaintenant_debutFuturEstMinuitParis() {
        assertThat(DateMetierParis.debut(LocalDate.of(2026, 10, 2), NOW)).isEqualTo(NOW);
        assertThat(DateMetierParis.debut(LocalDate.of(2026, 10, 15), NOW))
                .isEqualTo(LocalDateTime.of(2026, 10, 15, 0, 0).atZone(PARIS).toInstant());
    }

    @Test
    void laDateIncluseNExisteQuePourUneBorneAMinuit() {
        assertThat(DateMetierParis.finIncluse(DateMetierParis.finExclusive(LocalDate.of(2026, 10, 31))))
                .contains(LocalDate.of(2026, 10, 31));
        assertThat(DateMetierParis.finIncluse(NOW)).isEmpty();
        assertThat(DateMetierParis.finIncluse(null)).isEmpty();
    }

    @Test
    void libelleDeFin_dateIncluseOuHeureReelleDeLAchat() {
        assertThat(DateMetierParis.libelleFin(DateMetierParis.finExclusive(LocalDate.of(2026, 10, 31))))
                .isEqualTo("31/10/2026 inclus");
        assertThat(DateMetierParis.libelleFin(NOW)).isEqualTo("02/10/2026 à 14:37");
    }

    @Test
    void referenceExterneTronquee() {
        assertThat(ReferenceExterne.tronquer("GPA.1234-5678-9012-34567890abcdef")).isEqualTo("GPA.1234…cdef");
        assertThat(ReferenceExterne.tronquer("cs_test_12345")).isEqualTo("cs_t…");
        assertThat(ReferenceExterne.tronquer("abc")).isEqualTo("a…");
        assertThat(ReferenceExterne.tronquer(null)).isNull();
    }
}
