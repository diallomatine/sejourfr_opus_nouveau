package com.sejourfr.app.mapper;

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
                p.getDurationDays()
        );
    }
}
