package com.sejourfr.app.dto;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Une ligne de la liste admin « Utilisateurs » (spec §4). Tout est servi :
 * statuts, « prochaine fin » (la plus proche parmi les produits actifs) et son
 * libellé. {@code lastActivityAt} = dernière activité d'entraînement (vue V073),
 * {@code null} si aucune. {@code manualAccess} : une décision admin non terminée.
 */
public record AdminUserListItemDto(
        UUID id,
        String displayName,
        String email,
        Instant createdAt,
        AdminEffectiveAccessDto effectiveAccess,
        List<AdminUserAccessBadgeDto> accesses,
        Instant nextEndsAt,
        LocalDate nextEndDateInclusive,
        String nextEndLabel,
        Instant lastActivityAt,
        String accountStatus,
        String accountStatusLabel,
        boolean manualAccess
) {}
