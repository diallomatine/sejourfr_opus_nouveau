package com.sejourfr.app.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * Payload envoye par les clients (web GIS, mobile google_sign_in) apres
 * authentification cote Google. Le backend valide ce JWT contre les JWKS
 * Google avant d'ouvrir une session.
 */
public record GoogleSignInRequest(
        @NotBlank(message = "idToken requis")
        String idToken
) {}
