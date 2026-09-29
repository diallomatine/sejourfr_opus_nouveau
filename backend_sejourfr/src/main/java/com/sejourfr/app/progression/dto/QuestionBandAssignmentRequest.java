package com.sejourfr.app.progression.dto;

import com.sejourfr.app.enums.DifficultyBand;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.util.List;
import java.util.UUID;

/**
 * Un lot de bandes à poser (V4.2 §7).
 *
 * <p>Le tagging se fait <b>hors application</b> — export CSV, travail au calme,
 * réimport. Ce DTO est le chemin de retour, et il est volontairement minuscule :
 * un identifiant, une bande. Rien qui puisse modifier autre chose qu'une bande.
 *
 * @param band {@code null} <b>dé-tague</b> la question. C'est un cas légitime :
 *        se rendre compte qu'un tag était faux et le retirer vaut mieux que de
 *        le remplacer par un autre tag douteux. Une série contenant une question
 *        dé-taguée redevient simplement {@code UNCALIBRATED}.
 */
public record QuestionBandAssignmentRequest(
        @NotEmpty(message = "Aucune affectation fournie")
        List<Affectation> affectations
) {

    public record Affectation(
            @NotNull(message = "questionId requis") UUID questionId,
            DifficultyBand band
    ) {}
}
