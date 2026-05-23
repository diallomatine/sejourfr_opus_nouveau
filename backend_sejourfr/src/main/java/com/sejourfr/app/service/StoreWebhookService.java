package com.sejourfr.app.service;

import com.sejourfr.app.service.billing.AppleSubscriptionService;
import com.sejourfr.app.service.billing.GoogleSubscriptionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Dispatcher des notifications serveur-à-serveur des stores.
 * <ul>
 *   <li>Apple : App Store Server Notifications V2 (JWS signé) — délégué à
 *       {@link AppleSubscriptionService}.</li>
 *   <li>Google : Real-time Developer Notifications via Pub/Sub (Bearer JWT
 *       signé Service Account) — délégué à {@link GoogleSubscriptionService}.</li>
 * </ul>
 *
 * <p>Vérification d'authenticité + idempotence vivent dans les services
 * spécialisés ; ici on ne fait que router. Les controllers retournent 200 vite
 * (attendu des stores) ; en cas d'échec d'auth ou de validation, les services
 * lèvent une {@code ResponseStatusException} (401/400/502) pour que le store
 * retente.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StoreWebhookService {

    private final AppleSubscriptionService appleSubscriptionService;
    private final GoogleSubscriptionService googleSubscriptionService;

    public void handleAppleNotification(String payload) {
        appleSubscriptionService.handleNotification(payload);
    }

    public void handleGoogleNotification(String authHeader, String payload) {
        googleSubscriptionService.handleNotification(authHeader, payload);
    }
}
