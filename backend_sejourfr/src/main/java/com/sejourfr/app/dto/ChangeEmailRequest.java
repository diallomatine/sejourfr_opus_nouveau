package com.sejourfr.app.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Payload pour POST /api/me/change-email-request. L'email n'est pas mis à
 * jour immédiatement : on envoie un mail de vérification au nouvel email, et
 * la mise à jour effective se fait quand le user clique sur le lien (cf.
 * {@code AuthController#confirmEmailChange}). Le mot de passe courant est
 * exigé pour éviter qu'une session volée serve à voler l'identité.
 */
public record ChangeEmailRequest(
        @NotBlank @Email @Size(max = 255) String newEmail,
        @NotBlank String currentPassword
) {}
