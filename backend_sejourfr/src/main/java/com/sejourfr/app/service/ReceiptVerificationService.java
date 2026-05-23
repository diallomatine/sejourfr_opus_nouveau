package com.sejourfr.app.service;

import com.sejourfr.app.dto.SubscriptionStatusResponse;
import com.sejourfr.app.dto.VerifyReceiptRequest;
import com.sejourfr.app.service.billing.AppleSubscriptionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.UUID;

/**
 * Point d'entrée central de la validation des reçus IAP. Dispatch vers
 * {@code AppleSubscriptionService} (lot 2) ou {@code GoogleSubscriptionService}
 * (lot 3 — TODO) selon la source.
 *
 * <p>Stripe ne passe PAS par cet endpoint — son flow d'activation est porté
 * par {@code BillingService.handleWebhook} (checkout.session.completed). Un
 * appel verify-receipt avec source=STRIPE est donc rejeté en 400.
 *
 * <p>Sécurité : l'endpoint est authentifié, donc {@code userId} est forcément
 * celui du caller. Le reçu est rattaché à ce user — si un autre user remonte
 * le même {@code originalTransactionId}, le service Apple/Google rejette en 409.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ReceiptVerificationService {

    private final AppleSubscriptionService appleSubscriptionService;
    private final SubscriptionService subscriptionService;

    public SubscriptionStatusResponse verify(UUID userId, VerifyReceiptRequest request) {
        switch (request.source()) {
            case APPLE -> {
                appleSubscriptionService.activateFromReceipt(
                        userId, request.productId(), request.receipt());
                return buildResponse(userId);
            }
            case GOOGLE -> {
                log.warn(
                        "verify-receipt GOOGLE pour user={} productId={} — handler non implémenté (lot 3 TODO)",
                        userId, request.productId()
                );
                throw new ResponseStatusException(
                        HttpStatus.NOT_IMPLEMENTED,
                        "Validation Google Play pas encore implémentée — voir lot 3 du chantier IAP."
                );
            }
            case STRIPE -> throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Stripe ne passe pas par /verify-receipt — utiliser le webhook checkout.session.completed."
            );
        }
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Source de reçu inconnue.");
    }

    private SubscriptionStatusResponse buildResponse(UUID userId) {
        return subscriptionService.currentSubscription(userId)
                .map(SubscriptionStatusResponse::from)
                .orElseGet(SubscriptionStatusResponse::notPremium);
    }
}
