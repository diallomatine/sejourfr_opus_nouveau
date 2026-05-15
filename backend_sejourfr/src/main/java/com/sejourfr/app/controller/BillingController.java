package com.sejourfr.app.controller;

import com.sejourfr.app.dto.BillingCheckoutRequest;
import com.sejourfr.app.dto.BillingCheckoutResponse;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.BillingService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/billing")
public class BillingController {

    private final BillingService billingService;
    private final CurrentUser currentUser;

    public BillingController(BillingService billingService, CurrentUser currentUser) {
        this.billingService = billingService;
        this.currentUser = currentUser;
    }

    @PostMapping("/create-checkout-session")
    public BillingCheckoutResponse createCheckoutSession(
            @Valid @RequestBody BillingCheckoutRequest req
    ) {
        return billingService.createCheckoutSession(currentUser.getId(), req.plan());
    }

    /**
     * Endpoint signé par Stripe (vérification HMAC via Stripe-Signature).
     * Pas d'auth utilisateur : Stripe est l'appelant, identifié par signature.
     */
    @PostMapping("/webhook")
    public ResponseEntity<Void> handleWebhook(
            @RequestBody String payload,
            @RequestHeader("Stripe-Signature") String signature
    ) {
        billingService.handleWebhook(payload, signature);
        return ResponseEntity.ok().build();
    }
}
