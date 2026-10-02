package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AdminAccessOperationType;
import com.sejourfr.app.enums.ModuleAccess;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Une entrée de l'historique admin (spec §5.6) : une action = une entrée, même
 * quand elle a écrit plusieurs décisions (correction de produit). {@code changes}
 * = une phrase par produit dont l'état a changé (« Civique : Actif jusqu'au … →
 * Révoqué depuis le … »), photo prise à l'instant de l'action.
 */
public record AdminAccessHistoryEntryDto(
        UUID operationId,
        Instant createdAt,
        UUID adminId,
        String adminEmail,
        AdminAccessOperationType operation,
        String operationLabel,
        ModuleAccess product,
        String productLabel,
        ModuleAccess fromProduct,
        String fromProductLabel,
        String reason,
        List<String> changes
) {}
