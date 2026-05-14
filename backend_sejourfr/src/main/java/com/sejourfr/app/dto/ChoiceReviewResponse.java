package com.sejourfr.app.dto;

import java.util.UUID;

/**
 * Représentation d'un choix pour l'écran de révision : inclut le flag
 * {@code correct}, contrairement à {@link ChoicePublicResponse}. Ne doit
 * être renvoyé que pour une question que l'utilisateur a déjà tentée.
 */
public record ChoiceReviewResponse(
        UUID id,
        String label,
        int displayOrder,
        boolean correct
) {}
