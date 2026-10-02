package com.sejourfr.app.enums;

/**
 * Statut d'accès d'un compte à UN produit (spec §2.4), calculé par le serveur
 * ({@code AccesEffectifResolver.etat}) et servi tel quel à l'admin : le front
 * ne le recalcule jamais.
 */
public enum ProductAccessStatus {
    ACTIVE("Actif"),
    SCHEDULED("Programmé"),
    REVOKED("Révoqué"),
    EXPIRED("Expiré"),
    NONE("Aucun");

    private final String label;

    ProductAccessStatus(String label) {
        this.label = label;
    }

    public String label() {
        return label;
    }
}
