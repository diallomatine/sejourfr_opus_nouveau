package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AdminSubscriptionDto;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.util.ReferenceExterne;
import org.springframework.stereotype.Component;

/**
 * DTO admin d'une souscription. 🛑 Les identifiants de paiement
 * ({@code original_transaction_id} = purchaseToken Google / id Stripe,
 * {@code external_transaction_id}) sortent TRONQUÉS (spec admin §9) : la
 * console sert à reconnaître un achat, pas à exposer un jeton de paiement.
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
                ReferenceExterne.tronquer(sub.getExternalTransactionId()),
                ReferenceExterne.tronquer(sub.getOriginalTransactionId()),
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
