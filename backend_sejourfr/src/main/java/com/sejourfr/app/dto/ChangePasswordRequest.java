package com.sejourfr.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Payload pour POST /api/me/change-password. L'ancien mot de passe est
 * requis pour empêcher qu'une session volée serve à se réapproprier le compte
 * sans connaître les credentials. La taille minimale colle au RegisterRequest
 * historique pour rester cohérent.
 */
public record ChangePasswordRequest(
        @NotBlank String currentPassword,
        @NotBlank @Size(min = 8, max = 128) String newPassword
) {}
