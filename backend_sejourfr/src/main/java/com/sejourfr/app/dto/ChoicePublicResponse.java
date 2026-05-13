package com.sejourfr.app.dto;

import java.util.UUID;

/**
 * Représentation publique d'un choix (côté utilisateur).
 *
 * - 'correct' n'est jamais renvoyé tant que l'attempt n'est pas terminé,
 *   sauf en TRAINING après soumission de la réponse, où on le renvoie
 *   via {@link AnswerResultResponse} pour afficher la correction.
 */
public record ChoicePublicResponse(
        UUID id,
        String label,
        int displayOrder
) {}
