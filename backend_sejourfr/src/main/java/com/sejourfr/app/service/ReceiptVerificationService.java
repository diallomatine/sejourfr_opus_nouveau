package com.sejourfr.app.service;

import com.sejourfr.app.dto.SubscriptionStatusResponse;
import com.sejourfr.app.dto.VerifyReceiptRequest;
import com.sejourfr.app.service.billing.AppleSubscriptionService;
import com.sejourfr.app.service.billing.GoogleSubscriptionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.UUID;

/**
 * Point d'entrée central de la validation des reçus IAP. Dispatch vers
 * {@link AppleSubscriptionService} (lot 2) ou {@link GoogleSubscriptionService}
 * (lot 3) selon la source.
 *
 * <p>Stripe ne passe PAS par cet endpoint — son flow d'activation est porté
 * par {@code BillingService.handleWebhook} (checkout.session.completed). Un
 * appel verify-receipt avec source=STRIPE est donc rejeté en 400.
 *
 * <p>Sécurité : l'endpoint est authentifié, donc {@code userId} est forcément
 * celui du caller. Le reçu est rattaché à ce user — si un autre user remonte
 * le même {@code originalTransactionId} (Apple) ou {@code purchaseToken}
 * (Google), le service spécialisé rejette en 409.
 */
@Service
@RequiredArgsConstructor
public class ReceiptVerificationService {

    private final AppleSubscriptionService appleSubscriptionService;
    private final GoogleSubscriptionService googleSubscriptionService;
    private final SubscriptionService subscriptionService;

    public SubscriptionStatusResponse verify(UUID userId, VerifyReceiptRequest request) {
        switch (request.source()) {
            case APPLE -> appleSubscriptionService.activateFromReceipt(
                    userId, request.productId(), request.receipt());
            case GOOGLE -> googleSubscriptionService.activateFromReceipt(
                    userId, request.productId(), request.receipt());
            case STRIPE -> throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Stripe ne passe pas par /verify-receipt — utiliser le webhook checkout.session.completed."
            );
        }
        return buildResponse(userId);
    }

    private SubscriptionStatusResponse buildResponse(UUID userId) {
        return subscriptionService.currentSubscription(userId)
                .map(SubscriptionStatusResponse::from)
                .orElseGet(SubscriptionStatusResponse::notPremium);
    }
}
