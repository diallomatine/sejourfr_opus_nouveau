package com.sejourfr.app.question;

import jakarta.validation.constraints.NotBlank;

public record ChoiceWriteRequest(
        @NotBlank(message = "Le libelle du choix est requis")
        String label,
        boolean correct,
        int displayOrder
) {}
