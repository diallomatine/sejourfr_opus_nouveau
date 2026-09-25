package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.PurchaseOrigin;

import java.util.UUID;

/**
 * L'attribution d'un achat, lue sur une {@code purchase_intent} consommee
 * (Q12). {@code diagnosticRunId} n'est pose que pour
 * {@link PurchaseOrigin#DIAGNOSTIC_PLAN} : un achat venu d'un autre CTA
 * n'entre pas dans le tunnel, meme si le candidat a un parcours.
 */
public record AttributionAchat(PurchaseOrigin origin, UUID purchaseIntentId,
                               UUID journeyId, UUID diagnosticRunId) {

    public static final AttributionAchat INCONNUE =
            new AttributionAchat(PurchaseOrigin.UNKNOWN, null, null, null);

    public void appliquerA(UserSubscription sub) {
        sub.setOrigin(origin);
        sub.setPurchaseIntentId(purchaseIntentId);
        sub.setJourneyId(journeyId);
        sub.setDiagnosticRunId(diagnosticRunId);
    }
}
