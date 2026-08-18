package com.sejourfr.app.util;

import com.sejourfr.app.enums.ClientPlatform;

/**
 * Contexte declare par l'appelant : sur quelle plateforme il est, et par quel
 * reseau il est arrive. Jamais nul en tant qu'objet — l'absence d'information
 * se dit {@link ClientPlatform#UNKNOWN} + {@link TrafficSource#DIRECT}, pas par
 * une reference nulle qu'il faudrait tester partout.
 *
 * @param platform plateforme declaree
 * @param source   provenance normalisee par {@link TrafficSource}
 */
public record ClientContext(ClientPlatform platform, String source) {

    /** Contexte d'un appel qui n'a rien declare. */
    public static ClientContext unknown() {
        return new ClientContext(ClientPlatform.UNKNOWN, TrafficSource.DIRECT);
    }
}
