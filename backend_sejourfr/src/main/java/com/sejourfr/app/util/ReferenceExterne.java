package com.sejourfr.app.util;

import com.sejourfr.app.enums.SubscriptionSource;

/**
 * Identifiants de paiement affichés dans l'admin (D-33, révise D-12) : les
 * identifiants Stripe (session, payment intent, abonnement) et Apple
 * (transaction, transaction d'origine) sortent ENTIERS — ce sont des clés de
 * rapprochement avec la console du fournisseur, pas des secrets. Seul le
 * {@code purchaseToken} Google (porté par {@code original_transaction_id} d'un
 * achat Google) reste TRONQUÉ : c'est un jeton qui permet d'interroger l'API
 * Play. L'{@code orderId} Google (« GPA.… », {@code external_transaction_id})
 * sort entier. Une seule règle, pour la console Abonnements et la fiche
 * utilisateur.
 */
public final class ReferenceExterne {

    private ReferenceExterne() {}

    /** {@code original_transaction_id} d'un achat : tronqué pour un purchaseToken Google, entier sinon. */
    public static String identifiantOrigine(SubscriptionSource source, String reference) {
        return source == SubscriptionSource.GOOGLE ? tronquer(reference) : vide(reference);
    }

    /** {@code external_transaction_id} d'un achat (id Stripe, transaction Apple, orderId Google) : entier. */
    public static String identifiantTransaction(String reference) {
        return vide(reference);
    }

    /** « 8 premiers…4 derniers », plus court pour une chaîne courte. */
    public static String tronquer(String reference) {
        if (reference == null || reference.isBlank()) return null;
        if (reference.length() <= 8) return reference.charAt(0) + "…";
        if (reference.length() <= 16) return reference.substring(0, 4) + "…";
        return reference.substring(0, 8) + "…" + reference.substring(reference.length() - 4);
    }

    private static String vide(String reference) {
        return reference == null || reference.isBlank() ? null : reference;
    }
}
