package com.sejourfr.app.enums;

public enum AuthProvider {
    LOCAL("E-mail"),
    GOOGLE("Google"),
    APPLE("Apple");

    /** Libelle de la methode de connexion (ecran admin « Activite »), gele par {@code AnalyticsLabelsTest}. */
    private final String label;

    AuthProvider(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}
