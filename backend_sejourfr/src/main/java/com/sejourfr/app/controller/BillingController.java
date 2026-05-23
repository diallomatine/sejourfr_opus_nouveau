package com.sejourfr.app.controller;

import com.sejourfr.app.dto.BillingCheckoutResponse;
import com.sejourfr.app.dto.PlanPublicResponse;
import com.sejourfr.app.dto.SubscriptionStatusResponse;
import com.sejourfr.app.dto.VerifyReceiptRequest;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.BillingPlan;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.BillingService;
import com.sejourfr.app.service.ReceiptVerificationService;
import com.sejourfr.app.service.SubscriptionService;
import jakarta.validation.Valid;
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
    private final SubscriptionService subscriptionService;
    private final ReceiptVerificationService receiptVerificationService;
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
     * Statut Premium agrégé toutes sources confondues (Stripe + Apple + Google).
     * Lu par les 3 fronts au démarrage et après chaque action de paiement.
     *
     * <p>Anti-double-paiement : un utilisateur déjà Premium via Stripe verra
     * {@code isPremium=true} avec {@code source=STRIPE} — l'app mobile doit
     * alors masquer le bouton d'achat IAP. Inversement après un achat sur
     * iOS, l'app web verra {@code source=APPLE} et ne proposera plus Stripe.
     */
    @GetMapping("/subscription-status")
    public SubscriptionStatusResponse getSubscriptionStatus() {
        return subscriptionService.currentSubscription(currentUser.getId())
                .map(this::toStatusResponse)
                .orElseGet(SubscriptionStatusResponse::notPremium);
    }

    private SubscriptionStatusResponse toStatusResponse(UserSubscription sub) {
        return new SubscriptionStatusResponse(
                true,
                sub.getSource(),
                sub.getProductId(),
                sub.getEndsAt(),
                sub.getStatus(),
                sub.getPlan().getModuleAccess(),
                sub.isAutoRenew()
        );
    }

    /**
     * Validation d'un reçu d'achat IAP (Apple StoreKit ou Google Play). Appelé
     * par l'app mobile après un achat réussi. Le backend re-valide auprès du
     * store (jamais confiance au client) avant de marquer Premium.
     *
     * <p>Lot 1 = scaffold qui renvoie 501 — l'app mobile NE doit PAS encore
     * appeler. Sera implémenté en lots 2 (Apple) et 3 (Google).
     */
    @PostMapping("/verify-receipt")
    public SubscriptionStatusResponse verifyReceipt(@Valid @RequestBody VerifyReceiptRequest request) {
        return receiptVerificationService.verify(currentUser.getId(), request);
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
