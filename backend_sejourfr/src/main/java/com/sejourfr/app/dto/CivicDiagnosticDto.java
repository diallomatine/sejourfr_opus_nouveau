package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.TcfDiagnosticStatus;

import java.time.Instant;
import java.util.UUID;

/**
 * L'etat d'un diagnostic civique (ecran d'accueil et reprise).
 *
 * <p>🛑 <b>Aucun score, aucun etat de theme.</b> Comme au TCF, le resultat est
 * le moment de conversion : le diluer en cours de passation le detruit. Le
 * detail n'arrive que sur {@link CivicDiagnosticResultDto}.
 *
 * @param attemptId l'attempt a ouvrir dans le runner de questions existant.
 *                  🛑 Aucun ecran de passation n'est cree pour le diagnostic —
 *                  un second runner divergerait du premier
 * @param repondues questions deja repondues, pour afficher « 12 sur 24 »
 */
public record CivicDiagnosticDto(
        UUID sessionId,
        UUID attemptId,
        TcfDiagnosticStatus status,
        Difficulty mention,
        int total,
        int repondues,
        Instant startedAt,
        Instant completedAt
) {
}
