package com.sejourfr.app.dto;

import com.sejourfr.app.entity.AnalyticsAnnotation;
import com.sejourfr.app.enums.AnalyticsAnnotationCategory;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Un repere pose sur la courbe : « le 12, trois videos publiees ».
 *
 * <p>C'est de la donnee <b>editoriale</b>. Elle n'explique rien toute seule, mais
 * elle rend un pic lisible mieux que n'importe quelle statistique de plus — et
 * sans elle, un ecart s'attribue au hasard ou au produit sans qu'on puisse
 * trancher.
 */
public record AnalyticsAnnotationDto(
        UUID id,
        LocalDate occurredOn,
        String title,
        String description,
        AnalyticsAnnotationCategory category) {

    public static AnalyticsAnnotationDto from(AnalyticsAnnotation entity) {
        return new AnalyticsAnnotationDto(
                entity.getId(), entity.getOccurredOn(), entity.getTitle(),
                entity.getDescription(), entity.getCategory());
    }
}
