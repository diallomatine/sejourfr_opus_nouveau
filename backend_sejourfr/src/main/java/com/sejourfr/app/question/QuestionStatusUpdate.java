package com.sejourfr.app.question;

import jakarta.validation.constraints.NotNull;

public record QuestionStatusUpdate(
        @NotNull(message = "Le statut actif est requis")
        Boolean active
) {}
