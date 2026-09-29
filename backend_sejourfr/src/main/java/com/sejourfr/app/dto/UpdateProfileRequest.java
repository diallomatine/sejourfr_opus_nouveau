package com.sejourfr.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Payload pour PATCH /api/me/profile. Met à jour le prénom et le nom de
 * l'utilisateur connecté. L'email + le mot de passe ont leurs propres
 * endpoints (workflow de vérification).
 */
public record UpdateProfileRequest(
        @NotBlank @Size(max = 120) String firstName,
        @NotBlank @Size(max = 120) String lastName
) {}
