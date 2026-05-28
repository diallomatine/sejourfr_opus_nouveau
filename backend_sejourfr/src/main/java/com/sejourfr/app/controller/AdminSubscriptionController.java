package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AdminSubscriptionListResponse;
import com.sejourfr.app.dto.CancelSubscriptionResponse;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.service.AdminSubscriptionService;
import com.sejourfr.app.service.billing.SubscriptionCancellationService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Console admin : liste paginée des UserSubscription avec filtres.
 *
 * <p>Sécurité : {@code /api/admin/**} → ROLE_ADMIN (cf. SecurityConfig).
 */
@RestController
@RequestMapping("/api/admin/subscriptions")
@RequiredArgsConstructor
public class AdminSubscriptionController {

    private final AdminSubscriptionService adminSubscriptionService;
    private final SubscriptionCancellationService subscriptionCancellationService;

    @GetMapping
    public AdminSubscriptionListResponse list(
            @RequestParam(required = false) SubscriptionSource source,
            @RequestParam(required = false) SubscriptionStatus status,
            @RequestParam(required = false) ModuleAccess moduleAccess,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "25") int size) {
        return adminSubscriptionService.list(source, status, moduleAccess, search, page, size);
    }

    /**
     * Annulation admin / support d'une souscription précise. Stripe est
     * effectivement résiliée côté serveur ({@code action=DONE}). Apple et
     * Google renvoient {@code action=REDIRECT} : les stores n'autorisent
     * l'annulation que par l'utilisateur depuis ses Settings. L'UI admin
     * affiche alors l'URL à communiquer au client.
     */
    @PostMapping("/{id}/cancel")
    public CancelSubscriptionResponse cancel(@PathVariable UUID id) {
        return subscriptionCancellationService.cancelSubscriptionById(id);
    }
}
