package com.sejourfr.app.controller;

import com.sejourfr.app.service.StoreWebhookService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;

/**
 * Webhooks serveur-à-serveur des stores mobiles. Endpoints publics
 * (whitelistés dans {@code SecurityConfig}) — l'authentification se fait par
 * vérification de signature/authenticité dans le service, pas par JWT
 * applicatif.
 *
 * <p>Les payloads sont lus en {@code byte[]} puis décodés UTF-8 explicitement :
 * un mismatch de charset casserait la vérif HMAC/JWS sur des caractères
 * non-ASCII.
 */
@RestController
@RequestMapping("/api/billing/webhooks")
@RequiredArgsConstructor
public class BillingWebhookController {

    private final StoreWebhookService storeWebhookService;

    /**
     * App Store Server Notifications V2. Le body est un JWS signé par Apple
     * (signedPayload), vérifié contre la chaîne de certifs Apple par
     * {@code AppleSubscriptionService}.
     */
    @PostMapping("/apple")
    @ResponseStatus(HttpStatus.OK)
    public void handleApple(@RequestBody byte[] payloadBytes) {
        String payload = new String(payloadBytes, StandardCharsets.UTF_8);
        storeWebhookService.handleAppleNotification(payload);
    }

    /**
     * Google Real-time Developer Notifications, livrées via Cloud Pub/Sub
     * (push subscription). L'authenticité est portée par un Bearer JWT
     * Google dans le header {@code Authorization}, signé par le Service
     * Account configuré sur la push subscription. Le body contient un
     * {@code message.data} en base64 décodé en JSON par le service.
     */
    @PostMapping("/google")
    @ResponseStatus(HttpStatus.OK)
    public void handleGoogle(
            @RequestBody byte[] payloadBytes,
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        String payload = new String(payloadBytes, StandardCharsets.UTF_8);
        storeWebhookService.handleGoogleNotification(authorization, payload);
    }
}
