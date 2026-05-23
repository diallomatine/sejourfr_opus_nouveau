package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AdminSubscriptionDto;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import org.springframework.stereotype.Component;

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
                sub.getExternalTransactionId(),
                sub.getOriginalTransactionId(),
                sub.getProductId(),
                sub.isAutoRenew(),
                sub.getStartsAt(),
                sub.getEndsAt(),
                sub.getUpdatedAt(),
                plan != null ? plan.getId() : null,
                plan != null ? plan.getCode() : null,
                plan != null ? plan.getName() : null,
                plan != null ? plan.getModuleAccess() : null,
                plan != null ? plan.getPrice() : null
        );
    }
}
