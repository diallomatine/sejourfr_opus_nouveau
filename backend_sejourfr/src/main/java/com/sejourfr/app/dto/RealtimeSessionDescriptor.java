package com.sejourfr.app.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.UUID;

/**
 * Reponse au demarrage d'une session temps reel. Schema (A) : le client se
 * connecte LUI-MEME au WebSocket du fournisseur avec {@code ephemeralToken}.
 * La persona n'est jamais renvoyee (verrouillee dans le token cote serveur).
 *
 * <p>{@code mode=ASYNC_FALLBACK} signale au client de faire l'epreuve en mode
 * classique (enregistrement) : quota epuise, pass non eligible, ou temps reel
 * non configure. Dans ce cas les champs de connexion sont nuls — le candidat
 * n'est jamais bloque.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record RealtimeSessionDescriptor(
        String mode,                  // "REALTIME" | "ASYNC_FALLBACK"
        UUID sessionId,
        String provider,
        String model,
        String wsEndpoint,
        String ephemeralToken,
        String inputAudioMimeType,
        Integer inputSampleRate,
        Integer outputSampleRate,
        String voice,
        int tacheNumero,
        Integer targetDurationSec,
        int sessionsRemaining
) {
    public static final String MODE_REALTIME = "REALTIME";
    public static final String MODE_ASYNC_FALLBACK = "ASYNC_FALLBACK";

    public static RealtimeSessionDescriptor asyncFallback(int tacheNumero,
                                                          Integer targetDurationSec,
                                                          int sessionsRemaining) {
        return new RealtimeSessionDescriptor(
                MODE_ASYNC_FALLBACK, null, null, null, null, null, null, null, null, null,
                tacheNumero, targetDurationSec, sessionsRemaining);
    }
}
