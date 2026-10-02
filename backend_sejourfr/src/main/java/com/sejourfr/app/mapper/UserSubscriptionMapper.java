package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AdminSubscriptionDto;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.util.ReferenceExterne;
import org.springframework.stereotype.Component;

/**
 * DTO admin d'une souscription. 🛑 Identifiants de paiement (D-33, révise
 * D-12) : Stripe et Apple entiers ; seul le purchaseToken Google
 * ({@code original_transaction_id} d'un achat Google) sort TRONQUÉ
 * ({@link ReferenceExterne}).
 */
@Component
public class UserSubscriptionMapper {

    public AdminSubscriptionDto toAdminDto(UserSubscription sub) {
        User user = sub.getUser();
        Plan plan = sub.getPlan();
        return new AdminSubscriptionDto(
                sub.getId(),
                user.getId(),
                user.getEmail(),
                user.getFirstName(),
                user.getLastName(),
                sub.getSource(),
                sub.getStatus(),
                ReferenceExterne.identifiantTransaction(sub.getExternalTransactionId()),
                ReferenceExterne.identifiantOrigine(sub.getSource(), sub.getOriginalTransactionId()),
                sub.getProductId(),
                sub.isAutoRenew(),
                sub.getStartsAt(),
                sub.getEndsAt(),
                sub.getUpdatedAt(),
                sub.getPurchasedAt(),
                plan != null ? plan.getId() : null,
                plan != null ? plan.getCode() : null,
                plan != null ? plan.getName() : null,
                plan != null ? plan.getModuleAccess() : null,
                plan != null ? plan.getPrice() : null,
                sub.getRealtimeEoSessionsRemaining()
        );
    }
}
