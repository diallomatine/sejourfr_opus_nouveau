package com.sejourfr.app.enums;

import java.util.Locale;

/**
 * Nature d'un passage dans le tunnel diagnostic ({@code diagnostic_run.diagnostic_type},
 * {@code analytics_event.diagnostic_type}, {@code users.signup_diagnostic_type}).
 *
 * <p>🛑 <b>Ce n'est pas {@link AnalyticsDiagnosticType}</b> : celui-la est la
 * <i>variante choisie</i> par le visiteur (propriete d'evenement historique,
 * RAPID / COMPLETE), celui-ci est la <i>session reellement ouverte</i>.
 *
 * <p>Le tunnel TCF du dashboard ne lit que {@link #QUICK_TCF} (arbitrage Q2) ;
 * {@link #FULL_TCF} existe pour l'activite (« diagnostics complets soumis »).
 */
public enum DiagnosticRunType {
    QUICK_TCF,
    FULL_TCF,
    CIVIQUE;

    /**
     * Valeur recue d'un client, normalisee.
     *
     * @throws IllegalArgumentException valeur inconnue, avec un message nomme
     */
    public static DiagnosticRunType parseOrThrow(String raw) {
        String value = raw == null ? "" : raw.trim().toUpperCase(Locale.ROOT);
        for (DiagnosticRunType type : values()) {
            if (type.name().equals(value)) return type;
        }
        throw new IllegalArgumentException("Valeur invalide pour « diagnosticType » : « " + raw
                + " ». Attendu : l'une de [QUICK_TCF, FULL_TCF, CIVIQUE].");
    }
}
