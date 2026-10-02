package com.sejourfr.app.util;

/**
 * Référence de paiement TRONQUÉE pour l'affichage admin (spec §9) : un
 * identifiant complet (purchaseToken Google, id de session / payment intent
 * Stripe, transaction Apple) ne sort jamais vers un écran. On garde de quoi
 * le reconnaître et le rapprocher dans la console du fournisseur.
 */
public final class ReferenceExterne {

    private ReferenceExterne() {}

    public static String tronquer(String reference) {
        if (reference == null || reference.isBlank()) return null;
        if (reference.length() <= 8) return reference.charAt(0) + "…";
        if (reference.length() <= 16) return reference.substring(0, 4) + "…";
        return reference.substring(0, 8) + "…" + reference.substring(reference.length() - 4);
    }
}
