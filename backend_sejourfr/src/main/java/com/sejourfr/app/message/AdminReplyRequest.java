package com.sejourfr.app.message;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminReplyRequest(
        @NotBlank(message = "Le contenu du message est requis")
        @Size(max = 10000)
        String body
) {}
