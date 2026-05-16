package com.sejourfr.app.controller;

import com.sejourfr.app.dto.BillingCheckoutResponse;
import com.sejourfr.app.enums.BillingPlan;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.BillingService;
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

    /**
     * Renvoie l'URL du Stripe Payment Link correspondant au plan demandé,
     * enrichie d'un client_reference_id (= user_id) pour retrouver
     * l'utilisateur lors du webhook checkout.session.completed.
     * Le front redirige ensuite directement vers cette URL.
     */
    @GetMapping("/payment-link")
    public BillingCheckoutResponse getPaymentLink(@RequestParam("plan") BillingPlan plan) {
        return billingService.getPaymentLink(currentUser.getId(), plan);
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
