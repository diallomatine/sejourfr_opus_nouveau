package com.sejourfr.app.controller;

import com.sejourfr.app.dto.BillingCheckoutResponse;
import com.sejourfr.app.dto.PlanPublicResponse;
import com.sejourfr.app.enums.BillingPlan;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.BillingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;
import java.util.List;

@RestController
@RequestMapping("/api/billing")
@RequiredArgsConstructor
public class BillingController {

    private final BillingService billingService;
    private final CurrentUser currentUser;

    /**
     * Liste publique des plans actifs : prix, prix original (offre de lancement),
     * duree, module debloque. Consomme par la section Tarifs de la landing.
     * Pas d'auth requise — donc a whitelister dans SecurityConfig.
     */
    @GetMapping("/plans")
    public List<PlanPublicResponse> listPlans() {
        return billingService.listPublicPlans();
    }

    /**
     * Renvoie l'URL du paiement Stripe (Checkout Session ou Payment Link selon
     * config) pour le plan demande, enrichie d'un client_reference_id (= user_id)
     * pour retrouver l'utilisateur lors du webhook checkout.session.completed.
     */
    @GetMapping("/payment-link")
    public BillingCheckoutResponse getPaymentLink(@RequestParam("plan") BillingPlan plan) {
        return billingService.getPaymentLink(currentUser.getId(), plan);
    }

    /**
     * Endpoint signé par Stripe (vérification HMAC via Stripe-Signature).
     * Pas d'auth utilisateur : Stripe est l'appelant, identifié par signature.
     *
     * <p>Body en {@code byte[]} puis décodé UTF-8 explicitement plutôt que
     * {@code @RequestBody String} : Spring choisit le charset selon le
     * Content-Type, et un mismatch (proxy qui reformate, charset par défaut
     * non UTF-8) casserait la signature HMAC sur des caractères non-ASCII.
     * Pattern recommandé par les exemples officiels Stripe Java.
     */
    @PostMapping("/webhook")
    @ResponseStatus(HttpStatus.OK)
    public void handleWebhook(
            @RequestBody byte[] payloadBytes,
            @RequestHeader("Stripe-Signature") String signature) {
        String payload = new String(payloadBytes, StandardCharsets.UTF_8);
        billingService.handleWebhook(payload, signature);
    }
}
