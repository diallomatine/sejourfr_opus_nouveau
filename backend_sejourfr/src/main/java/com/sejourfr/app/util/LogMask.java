package com.sejourfr.app.util;

/**
 * Masque les donnees sensibles (PII, tokens) avant de les ecrire dans les logs.
 * Conserve juste assez d'information pour correler des lignes sans exposer la
 * valeur reutilisable. RGPD : les logs ne doivent pas contenir d'email en clair
 * ni de token de paiement.
 */
public final class LogMask {

    private LogMask() {
    }

    /** {@code karim.test@sejourfr.fr} → {@code k***@sejourfr.fr}. */
    public static String email(String email) {
        if (email == null || email.isBlank()) return "(absent)";
        int at = email.indexOf('@');
        if (at <= 0) return "***";
        String head = email.substring(0, 1);
        return head + "***" + email.substring(at);
    }

    /** Token long (purchaseToken, refresh…) → 6 premiers caracteres + longueur. */
    public static String token(String token) {
        if (token == null || token.isBlank()) return "(absent)";
        if (token.length() <= 8) return "***";
        return token.substring(0, 6) + "…(" + token.length() + ")";
    }
}
