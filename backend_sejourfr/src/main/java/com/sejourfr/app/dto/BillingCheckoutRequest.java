package com.sejourfr.app.dto;

import com.sejourfr.app.enums.BillingPlan;
import jakarta.validation.constraints.NotNull;

public record BillingCheckoutRequest(
        @NotNull BillingPlan plan
) {}
