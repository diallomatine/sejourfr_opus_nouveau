package com.sejourfr.app.enums;

/**
 * Nature commerciale d'un {@link com.sejourfr.app.entity.Plan} :
 * <ul>
 *   <li>{@code SUBSCRIPTION} : abonnement récurrent (lots 2/3/4 — conservé,
 *       dormant tant que {@code billing.mode = ONE_TIME}).</li>
 *   <li>{@code ONE_TIME} : pass d'accès à durée fixe, payé une fois, sans
 *       reconduction. L'accès court {@code duration_days} jours après paiement
 *       puis expire (l'utilisateur rachète s'il veut continuer).</li>
 * </ul>
 *
 * <p>Le passage d'un mode à l'autre est piloté par le flag {@code billing.mode}
 * + le drapeau {@code is_active} des plans : les deux jeux de plans coexistent
 * en base, on n'en supprime jamais. Cf. CLAUDE.md racine § Paiements (Lot 5).
 */
public enum PlanPurchaseType {
    SUBSCRIPTION,
    ONE_TIME
}
