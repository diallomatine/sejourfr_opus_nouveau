package com.sejourfr.app.dto;

import jakarta.validation.constraints.Min;

/**
 * Ajustement admin du solde de sessions EO temps réel d'une souscription :
 * pose la valeur absolue {@code remaining} (≥ 0). Sert au support pour offrir /
 * corriger des sessions à un utilisateur.
 */
public record AdminSetRealtimeSessionsRequest(
        @Min(0) int remaining
) {
}
