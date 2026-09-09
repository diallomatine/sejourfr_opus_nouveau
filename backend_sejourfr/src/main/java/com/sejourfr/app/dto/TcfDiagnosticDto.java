package com.sejourfr.app.dto;

import com.sejourfr.app.enums.TcfDiagnosticStatus;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * L'etat d'un diagnostic TCF et de ses 4 sections (ecran d'accueil, 30_ §5.1).
 *
 * <p>{@code repriseEcoulee} dit que le delai de reprise est passe — pas que le
 * diagnostic est perdu : les sections realisees comptent toujours, et le
 * candidat peut demander son resultat sur ce qui existe.
 */
public record TcfDiagnosticDto(
        UUID sessionId,
        TcfDiagnosticStatus status,
        Instant startedAt,
        Instant expiresAt,
        Instant completedAt,
        boolean repriseEcoulee,
        List<TcfDiagnosticSectionDto> sections
) {
}
