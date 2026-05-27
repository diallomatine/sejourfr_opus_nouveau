package com.sejourfr.app.dto;

import java.util.UUID;

/**
 * Support visuel d'une situation. {@code type} vaut IMAGE (alors {@code imageUrl}
 * pointe une ressource R2) ou SVG (alors {@code inlineSvg} embarque le markup).
 */
public record ProductionSituationMediaDto(
        UUID id,
        String type,
        String imageUrl,
        String inlineSvg,
        String legende,
        String altText
) {
}
