package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

public record QuestionWriteRequest(
        @NotNull(message = "Le module est requis")
        Module module,

        @NotNull(message = "Le theme est requis")
        UUID themeId,

        UUID passageId,
        UUID mediaId,

        @NotNull(message = "La difficulte est requise")
        Difficulty difficulty,

        @NotNull(message = "Le type de question est requis")
        QuestionType questionType,

        @NotBlank(message = "L'enonce est requis")
        String statement,

        String explanation,

        Boolean active,

        @NotNull(message = "Les choix sont requis")
        @Size(min = 2, max = 6, message = "Une question doit avoir entre 2 et 6 choix")
        @Valid
        List<ChoiceWriteRequest> choices
) {}
