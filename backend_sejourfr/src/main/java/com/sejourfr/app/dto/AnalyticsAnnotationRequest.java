package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AnalyticsAnnotationCategory;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

/**
 * Creation d'un repere depuis la console.
 *
 * <p>Les bornes sont celles de la table ({@code varchar(120)}), pas des
 * conventions : un titre refuse a l'ecriture vaut mieux qu'une violation de
 * contrainte remontee en 500.
 */
public record AnalyticsAnnotationRequest(
        @NotNull(message = "La date du repère est obligatoire.")
        LocalDate occurredOn,

        @NotNull(message = "Le titre est obligatoire.")
        @Size(min = 1, max = 120, message = "Le titre doit tenir en 120 caractères.")
        String title,

        @Size(max = 2000, message = "La description doit tenir en 2000 caractères.")
        String description,

        @NotNull(message = "La catégorie est obligatoire : PRODUIT ou MARKETING.")
        AnalyticsAnnotationCategory category) {
}
