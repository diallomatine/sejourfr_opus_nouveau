package com.sejourfr.app.dto;

import java.time.Instant;
import java.util.List;

/**
 * La fiche admin d'un utilisateur (spec §5). {@code accessVersion} est l'état
 * attendu que la modale d'action renvoie ({@code expectedVersion}) : si l'accès
 * a changé entre-temps (autre admin, webhook), l'action répond 409 (G-11).
 */
public record AdminUserDetailDto(
        AdminUserAccountDto account,
        AdminEffectiveAccessDto effectiveAccess,
        Instant lastActivityAt,
        List<AdminUserAccessDto> accesses,
        List<AdminUserPurchaseDto> purchases,
        List<AdminUserProgressionDto> progression,
        List<AdminAccessHistoryEntryDto> history,
        String accessVersion
) {}
