package com.sejourfr.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * {@code POST /api/admin/users/{userId}/messages[/preview]} : le message libre
 * d'un admin a un compte. Bornes revérifiées apres nettoyage par le service.
 */
public record AdminUserMessageRequest(
        @NotBlank(message = "L'objet est requis")
        @Size(min = 3, max = 150, message = "L'objet doit faire entre 3 et 150 caractères")
        String subject,
        @NotBlank(message = "Le message est requis")
        @Size(max = 5000, message = "Le message ne peut pas dépasser 5000 caractères")
        String body
) {}
