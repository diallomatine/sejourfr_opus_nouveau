package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AdminSubscriptionListResponse;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.service.AdminSubscriptionService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

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
}
