package com.sejourfr.app.enums;

import java.util.Locale;

/**
 * Qui a clos une session EO temps réel (V090). Déclaré par le client à la
 * clôture ; {@code null} = client qui ne le déclare pas, ou session jamais close.
 */
public enum RealtimeEndCause {
    /** Le chrono de la tâche est arrivé à échéance. */
    TIME_UP,
    /** Le candidat a cliqué « Terminer l'oral ». */
    USER_FINISH,
    /** Le transport est tombé et la reprise n'a pas abouti. */
    CONNECTION_LOST,
    /** Erreur fatale côté client (micro perdu…) : session close sans notation. */
    ERROR;

    /** Valeur déclarée, ou {@code null} si absente ou inconnue (client plus récent). */
    public static RealtimeEndCause parse(String raw) {
        if (raw == null || raw.isBlank()) return null;
        try {
            return valueOf(raw.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
