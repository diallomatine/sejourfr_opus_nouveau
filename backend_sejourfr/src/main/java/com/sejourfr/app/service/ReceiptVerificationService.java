package com.sejourfr.app.service;

import com.sejourfr.app.dto.SubscriptionStatusResponse;
import com.sejourfr.app.dto.VerifyReceiptRequest;
import com.sejourfr.app.enums.SubscriptionSource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.UUID;

/**
 * Point d'entrée central de la validation des reçus IAP. Dispatch vers
 * {@code AppleReceiptVerifier} ou {@code GoogleReceiptVerifier} selon la
 * source. Scaffold en lot 1 : la vraie validation arrive en lots 2 (Apple) et
 * 3 (Google). En attendant, l'endpoint renvoie 501 {@code NOT_IMPLEMENTED}
 * pour que l'app mobile sache explicitement qu'il ne faut pas encore appeler.
 *
 * <p>Quand un reçu est valide, ce service :
 * <ol>
 *   <li>Re-valide le reçu côté store (jamais confiance au client).</li>
 *   <li>Upsert dans {@code user_subscriptions} sur la clé
 *       {@code (source, original_transaction_id)}.</li>
 *   <li>Renvoie le statut Premium agrégé via {@code SubscriptionService}.</li>
 * </ol>
 */
@Service
@Slf4j
public class ReceiptVerificationService {

    public SubscriptionStatusResponse verify(UUID userId, VerifyReceiptRequest request) {
        if (request.source() == SubscriptionSource.STRIPE) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Stripe ne passe pas par /verify-receipt — utiliser le webhook checkout.session.completed."
            );
        }
        log.warn(
                "verify-receipt appelé pour user={} source={} productId={} — handler non implémenté (lot {} TODO)",
                userId,
                request.source(),
                request.productId(),
                request.source() == SubscriptionSource.APPLE ? "2 (Apple)" : "3 (Google)"
        );
        throw new ResponseStatusException(
                HttpStatus.NOT_IMPLEMENTED,
                "Validation " + request.source() + " pas encore implémentée — voir lots 2 (Apple) et 3 (Google) du chantier IAP."
        );
    }
}
