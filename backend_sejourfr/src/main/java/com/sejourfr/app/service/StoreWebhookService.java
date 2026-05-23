package com.sejourfr.app.service;

import com.sejourfr.app.service.billing.AppleSubscriptionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Dispatcher des notifications serveur-à-serveur des stores.
 * <ul>
 *   <li>Apple : App Store Server Notifications V2 (JWS signé) — délégué à
 *       {@link AppleSubscriptionService}.</li>
 *   <li>Google : Real-time Developer Notifications via Pub/Sub — lot 3 TODO.</li>
 * </ul>
 *
 * <p>Idempotence + verification d'authenticité vivent dans les services
 * spécialisés. Ici on ne fait que router et logger les erreurs en
 * non-bloquant — l'endpoint retourne 200 vite, comme attendu par les stores,
 * sauf en cas de problème dur (vérification signature KO ou exception
 * inattendue) où on remonte un 4xx pour que le store retente.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StoreWebhookService {

    /** Tronque les payloads loggés — un JWS Apple complet fait plusieurs KB. */
    private static final int LOG_PREVIEW_CHARS = 200;

    private final AppleSubscriptionService appleSubscriptionService;

    public void handleAppleNotification(String payload) {
        appleSubscriptionService.handleNotification(payload);
    }

    public void handleGoogleNotification(String payload) {
        log.warn(
                "Google RTDN reçu — handler scaffold (lot 3 TODO). Payload preview: {}",
                preview(payload)
        );
    }

    private String preview(String payload) {
        if (payload == null) return "<null>";
        if (payload.length() <= LOG_PREVIEW_CHARS) return payload;
        return payload.substring(0, LOG_PREVIEW_CHARS) + "...[+" + (payload.length() - LOG_PREVIEW_CHARS) + " chars]";
    }
}
