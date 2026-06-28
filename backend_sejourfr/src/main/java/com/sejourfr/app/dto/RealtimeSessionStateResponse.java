package com.sejourfr.app.dto;

import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.enums.RealtimeSessionStatus;

import java.util.UUID;

/**
 * Etat d'une session temps reel renvoye apres {@code finish} (ou consultation).
 * Le transcript n'est pas expose ici (il sert a la notation cote serveur).
 */
public record RealtimeSessionStateResponse(
        UUID sessionId,
        RealtimeSessionStatus status,
        int tacheNumero,
        int sessionsRemaining
) {
    public static RealtimeSessionStateResponse of(RealtimeSession s, int sessionsRemaining) {
        return new RealtimeSessionStateResponse(
                s.getId(), s.getStatus(), s.getTacheNumero(), sessionsRemaining);
    }
}
