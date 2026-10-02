package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AccessOrigin;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.ProductAccessStatus;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * L'accès d'un compte à UN produit (spec §2.4, §5.2), calculé serveur.
 *
 * <p>Dates (G-7) : {@code endsAt} est la borne EXCLUSIVE ; {@code endDateInclusive}
 * n'est présente que si cette borne tombe à minuit Paris (fin posée par l'admin,
 * « 31/10/2026 inclus ») — une fin d'achat garde son heure réelle et
 * {@code endLabel} l'écrit avec l'heure. Le front affiche, il ne convertit rien.
 */
public record AdminUserAccessDto(
        ModuleAccess product,
        String productLabel,
        ProductAccessStatus status,
        String statusLabel,
        String summary,
        Instant startsAt,
        Instant endsAt,
        LocalDate endDateInclusive,
        String endLabel,
        AccessOrigin origin,
        String originLabel,
        List<AdminAccessAlertDto> alerts,
        List<AdminAccessOperationOptionDto> availableOperations
) {}
