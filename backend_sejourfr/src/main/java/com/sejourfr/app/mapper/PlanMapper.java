package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AdminPlanDto;
import com.sejourfr.app.dto.PlanPublicResponse;
import com.sejourfr.app.entity.Plan;
import org.springframework.stereotype.Component;

@Component
public class PlanMapper {

    /** Vue publique d'un plan pour la landing (section Tarifs). */
    public PlanPublicResponse toPublicResponse(Plan p) {
        return new PlanPublicResponse(
                p.getCode(),
                p.getName(),
                p.getBillingCycle(),
                p.getPrice(),
                p.getOriginalPrice(),
                p.getModuleAccess(),
                p.getDurationDays(),
                p.getRealtimeEoSessions(),
                p.getPurchaseType(),
                p.getAppleProductId(),
                p.getGoogleProductId()
        );
    }

    /** Vue admin : expose tous les champs éditables (store IDs, active flag, id interne). */
    public AdminPlanDto toAdminDto(Plan p) {
        return new AdminPlanDto(
                p.getId(),
                p.getCode(),
                p.getName(),
                p.getBillingCycle(),
                p.getPrice(),
                p.getOriginalPrice(),
                p.getModuleAccess(),
                p.getDurationDays(),
                p.getPurchaseType(),
                p.isActive(),
                p.getStripePriceId(),
                p.getAppleProductId(),
                p.getGoogleProductId()
        );
    }
}
