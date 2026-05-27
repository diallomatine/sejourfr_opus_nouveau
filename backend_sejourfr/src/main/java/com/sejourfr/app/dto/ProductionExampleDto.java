package com.sejourfr.app.dto;

import java.util.List;
import java.util.UUID;

/**
 * Reponse modele d'une situation. {@code audioUrl} est renseigne pour l'EO,
 * NULL pour l'EE. {@code planPoints} alimente le "plan rapide" en check-list.
 */
public record ProductionExampleDto(
        UUID id,
        String titre,
        String resume,
        String contenu,
        String explications,
        String audioUrl,
        List<String> planPoints,
        String niveauIndicatif
) {
}
