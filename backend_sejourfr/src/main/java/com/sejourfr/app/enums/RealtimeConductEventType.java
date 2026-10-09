package com.sejourfr.app.enums;

import java.util.Locale;

/** Événement de conduite d'une session EO temps réel (V090, {@code realtime_session_events}). */
public enum RealtimeConductEventType {
    /** Le client a envoyé une relance sur silence. */
    SILENCE_RELANCE,
    /** Fin de temps douce : le candidat a fini sa phrase après l'échéance ({@code value_ms} = grâce utilisée). */
    TIMEUP_GRACE,
    /** Reprise après coupure, contexte restauré par le handle du fournisseur (tracé serveur). */
    RESUME_WITH_HANDLE,
    /** Reprise après coupure SANS handle : conversation neuve côté fournisseur (tracé serveur). */
    RESUME_WITHOUT_HANDLE;

    /** Types que seul le CLIENT peut déclarer ; les reprises sont tracées par le serveur. */
    public boolean declarableParLeClient() {
        return this == SILENCE_RELANCE || this == TIMEUP_GRACE;
    }

    /** Valeur déclarée, ou {@code null} si absente ou inconnue. */
    public static RealtimeConductEventType parse(String raw) {
        if (raw == null || raw.isBlank()) return null;
        try {
            return valueOf(raw.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
