package com.sejourfr.app.enums;

import java.util.Locale;

/**
 * Filtre « type » du dashboard « Suivi » : une seule vue a la fois (Q13).
 *
 * <p>{@link #TCF} lit {@link DiagnosticRunType#QUICK_TCF} seulement (Q2) ;
 * {@link #ALL} compte des <b>personnes distinctes</b> (une personne qui fait TCF et
 * Civique compte une fois).
 */
public enum SuiviTypeFilter {
    ALL,
    TCF,
    CIVIQUE;

    /**
     * @throws IllegalArgumentException (→ 400) valeur inconnue
     */
    public static SuiviTypeFilter parse(String raw) {
        if (raw == null || raw.isBlank()) return ALL;
        String value = raw.trim().toUpperCase(Locale.ROOT);
        for (SuiviTypeFilter type : values()) {
            if (type.name().equals(value)) return type;
        }
        throw new IllegalArgumentException("Valeur invalide pour « type » : « " + raw
                + " ». Attendu : ALL, TCF ou CIVIQUE.");
    }
}
