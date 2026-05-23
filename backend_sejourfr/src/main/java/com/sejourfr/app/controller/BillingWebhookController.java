package com.sejourfr.app.controller;

import com.sejourfr.app.service.StoreWebhookService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;

/**
 * Webhooks serveur-à-serveur des stores mobiles. Endpoints publics
 * (whitelistés dans {@code SecurityConfig}) — l'authentification se fait par
 * vérification de signature/authenticité dans le service, pas par JWT.
 *
 * <p>Les payloads sont lus en {@code byte[]} puis décodés UTF-8 explicitement,
 * comme le webhook Stripe : un mismatch de charset casserait la vérif HMAC/JWS
 * sur des caractères non-ASCII.
 *
 * <p>Lot 1 = scaffold (accuse réception, log, ne touche pas la DB). Les vraies
 * implémentations arrivent en lots 2 (Apple) et 3 (Google).
 */
@RestController
@RequestMapping("/api/billing/webhooks")
@RequiredArgsConstructor
public class BillingWebhookController {

    private final StoreWebhookService storeWebhookService;

    /**
     * App Store Server Notifications V2. Le body est un JWS signé par Apple
     * (signedPayload), qu'il faudra vérifier contre la chaîne de certifs
     * Apple avant tout side-effect. Cf. lot 2.
     */
    @PostMapping("/apple")
    @ResponseStatus(HttpStatus.OK)
    public void handleApple(@RequestBody byte[] payloadBytes) {
        String payload = new String(payloadBytes, StandardCharsets.UTF_8);
        storeWebhookService.handleAppleNotification(payload);
    }

    /**
     * Google Real-time Developer Notifications, arrivées via Pub/Sub. Le body
     * contient un {@code message.data} en base64 à décoder, dont la signature
     * d'authenticité Pub/Sub doit être vérifiée. Cf. lot 3.
     */
    @PostMapping("/google")
    @ResponseStatus(HttpStatus.OK)
    public void handleGoogle(@RequestBody byte[] payloadBytes) {
        String payload = new String(payloadBytes, StandardCharsets.UTF_8);
        storeWebhookService.handleGoogleNotification(payload);
    }
}
