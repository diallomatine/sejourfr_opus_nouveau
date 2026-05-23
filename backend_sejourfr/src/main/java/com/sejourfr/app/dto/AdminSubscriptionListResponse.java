package com.sejourfr.app.dto;

import java.util.List;

/**
 * Réponse paginée d'une liste de UserSubscriptions admin. {@code total} = nombre
 * total d'éléments matchant les filtres (toutes pages), pas seulement la page
 * courante.
 */
public record AdminSubscriptionListResponse(
        List<AdminSubscriptionDto> items,
        long total,
        int page,
        int size
) {
}
