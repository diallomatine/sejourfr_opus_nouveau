package com.sejourfr.app.enums;

/**
 * Statuts possibles d'un {@code UserSubscription}, harmonisés entre les 3
 * sources (Stripe, Apple, Google). Les noms restent côté backend ; chaque
 * source mappe ses propres events vers ce vocabulaire commun.
 *
 * <ul>
 *   <li>{@code ACTIVE}   — accès Premium ouvert.</li>
 *   <li>{@code TRIAL}    — période d'essai en cours (Apple introductory offer,
 *       Google free trial). Accès Premium ouvert, traité comme ACTIVE par
 *       l'agrégateur.</li>
 *   <li>{@code IN_GRACE} — l'abonnement a expiré mais le store offre une
 *       période de grâce avant de couper (renouvellement raté, problème de
 *       paiement). Accès Premium ouvert pendant la grâce.</li>
 *   <li>{@code PENDING}  — achat en attente de validation (validation parentale
 *       Apple « Ask to Buy », paiement différé Google). PAS de Premium tant
 *       que non confirmé.</li>
 *   <li>{@code CANCELED} — l'utilisateur a annulé. L'accès peut rester ouvert
 *       jusqu'à {@code ends_at} (auto_renew=false), puis bascule EXPIRED.</li>
 *   <li>{@code EXPIRED}  — fin de validité atteinte, plus de Premium.</li>
 *   <li>{@code REFUNDED} — remboursement consommateur (Apple REFUND, Google
 *       REVOKED). Premium retiré immédiatement, indépendamment de
 *       {@code ends_at}.</li>
 * </ul>
 *
 * <p>L'agrégateur {@code SubscriptionStatusService} considère Premium ouvert
 * pour {@code ACTIVE}, {@code TRIAL}, {@code IN_GRACE} (et {@code CANCELED}
 * tant que {@code ends_at} est dans le futur).
 */
public enum SubscriptionStatus {
    ACTIVE,
    TRIAL,
    IN_GRACE,
    PENDING,
    CANCELED,
    EXPIRED,
    REFUNDED
}
