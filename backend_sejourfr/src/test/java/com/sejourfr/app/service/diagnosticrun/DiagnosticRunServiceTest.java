package com.sejourfr.app.service.diagnosticrun;

import com.sejourfr.app.enums.DiagnosticRunType;
import com.sejourfr.app.manager.DiagnosticRunManager;
import com.sejourfr.app.util.JetonSecret;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La règle d'appartenance d'une run (« jamais crue sur parole ») : le compte
 * porteur, ou le jeton valide et, si les deux sont connus, le même identifiant
 * de mesure.
 */
class DiagnosticRunServiceTest {

    private static final Instant NOW = Instant.parse("2026-09-25T10:00:00Z");
    private static final String JETON = JetonSecret.tirer(32);

    private static DiagnosticRunManager.State run(UUID userId, UUID anon, Instant expire) {
        return new DiagnosticRunManager.State(UUID.randomUUID(), DiagnosticRunType.QUICK_TCF, anon, userId, null,
                JetonSecret.sha256Hex(JETON), expire, null);
    }

    @Test
    @DisplayName("Run portée : seul son compte, ou un visiteur déconnecté muni du jeton")
    void runPortee() {
        UUID porteur = UUID.randomUUID();
        DiagnosticRunManager.State r = run(porteur, null, NOW.plus(Duration.ofDays(1)));
        assertThat(DiagnosticRunService.appartient(r, porteur, null, null, NOW)).isTrue();
        // Un autre compte, meme avec le jeton, n'ecrit pas sur la run d'un tiers.
        assertThat(DiagnosticRunService.appartient(r, UUID.randomUUID(), null, JETON, NOW)).isFalse();
        assertThat(DiagnosticRunService.appartient(r, null, null, JETON, NOW)).isTrue();
    }

    @Test
    @DisplayName("Run sans porteur : le jeton, non expiré, et le même identifiant s'il est connu")
    void runSansPorteur() {
        UUID anon = UUID.randomUUID();
        DiagnosticRunManager.State r = run(null, anon, NOW.plus(Duration.ofDays(1)));
        assertThat(DiagnosticRunService.appartient(r, null, anon, JETON, NOW)).isTrue();
        assertThat(DiagnosticRunService.appartient(r, null, null, JETON, NOW)).isTrue();
        assertThat(DiagnosticRunService.appartient(r, UUID.randomUUID(), anon, JETON, NOW)).isTrue();
        assertThat(DiagnosticRunService.appartient(r, null, UUID.randomUUID(), JETON, NOW)).isFalse();
        assertThat(DiagnosticRunService.appartient(r, null, anon, "faux", NOW)).isFalse();
        assertThat(DiagnosticRunService.appartient(r, UUID.randomUUID(), anon, null, NOW)).isFalse();

        DiagnosticRunManager.State expiree = run(null, anon, NOW.minusSeconds(1));
        assertThat(DiagnosticRunService.appartient(expiree, null, anon, JETON, NOW)).isFalse();
    }
}
