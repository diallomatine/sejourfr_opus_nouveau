package com.sejourfr.app.service.billing;

import java.time.Instant;

/**
 * Ce que le canal de paiement sait d'un achat, au-dela de son montant :
 * transmis par Stripe / Apple / Google a {@link OneTimeAccessService}.
 *
 * @param fraisReelEurCents    frais reel Stripe ({@code balance_transaction.fee})
 *                             en centimes d'euro, ou {@code null} (inconnu, store)
 * @param purchasedAt          date de l'achat donnee par le canal (signee), ou
 *                             {@code null} : l'heure d'ecriture fait alors foi
 * @param purchaseIntentId     identifiant d'intention tel que recu (metadata
 *                             Stripe, champ verify-receipt), ou {@code null}. Non
 *                             fiable : valide par {@link PurchaseIntentService}.
 * @param intentionJugeeA      instant auquel juger l'expiration de l'intention,
 *                             quand il differe de {@code purchasedAt} : pour
 *                             Stripe, la CREATION de la session Checkout
 *                             (controle B — un paiement differe encaisse a J+3
 *                             reste attribue a l'intention posee au clic).
 *                             {@code null} : {@code purchasedAt} fait foi.
 */
public record ContexteAchat(Integer fraisReelEurCents, Instant purchasedAt, String purchaseIntentId,
                            Instant intentionJugeeA) {

    /** Un appelant historique : aucun frais reel, aucune intention. */
    public static final ContexteAchat AUCUN = new ContexteAchat(null, null, null, null);

    /** Canaux dont l'achat et l'intention se jugent au meme instant (stores). */
    public ContexteAchat(Integer fraisReelEurCents, Instant purchasedAt, String purchaseIntentId) {
        this(fraisReelEurCents, purchasedAt, purchaseIntentId, null);
    }
}
