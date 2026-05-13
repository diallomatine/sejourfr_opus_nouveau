package com.sejourfr.app.security.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
        @Email(message = "Email invalide")
        @NotBlank(message = "Email requis")
        String email,

        @NotBlank(message = "Mot de passe requis")
        String password
) {}
