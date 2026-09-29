package com.sejourfr.app.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * Payload pour POST /api/auth/logout. Le client envoie son refresh token
 * courant ; le backend le révoque côté serveur (table {@code refresh_tokens}).
 * Idempotent — un token déjà invalide / expiré renvoie 204 sans erreur.
 */
public record LogoutRequest(
        @NotBlank String refreshToken
) {}
