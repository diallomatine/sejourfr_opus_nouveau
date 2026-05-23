package com.sejourfr.app.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Scaffold du traitement des notifications serveur-à-serveur des stores.
 * <ul>
 *   <li>Apple : App Store Server Notifications V2 (JWS signé) — lot 2.</li>
 *   <li>Google : Real-time Developer Notifications via Pub/Sub — lot 3.</li>
 * </ul>
 *
 * <p>En lot 1 on n'a PAS la signature/auth en place — donc on log le payload
 * (tronqué) et on renvoie 200 vite pour que les stores ne le retentent pas en
 * boucle, MAIS on ne touche pas {@code user_subscriptions}. Les lots 2/3
 * remplaceront ces méthodes par la vraie chaîne :
 * <ol>
 *   <li>Vérification signature / authenticité.</li>
 *   <li>Idempotence via {@code processed_external_events}.</li>
 *   <li>Re-fetch d'état côté API store (le webhook dit "ça a changé", on
 *       confirme avant d'écrire).</li>
 *   <li>Upsert UserSubscription sur {@code (source, original_transaction_id)}.</li>
 * </ol>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StoreWebhookService {

    /** Tronque les payloads loggés — un JWS Apple complet fait plusieurs KB. */
    private static final int LOG_PREVIEW_CHARS = 200;

    public void handleAppleNotification(String payload) {
        log.warn(
                "Apple ASSN V2 reçu — handler scaffold (lot 2 TODO). Payload preview: {}",
                preview(payload)
        );
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
