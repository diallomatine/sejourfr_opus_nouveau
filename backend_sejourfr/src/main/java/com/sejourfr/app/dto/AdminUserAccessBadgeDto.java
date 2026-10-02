package com.sejourfr.app.dto;

import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.ProductAccessStatus;

/** Badge « Intégral · Actif » de la liste admin. */
public record AdminUserAccessBadgeDto(
        ModuleAccess product,
        String productLabel,
        ProductAccessStatus status,
        String statusLabel
) {}
