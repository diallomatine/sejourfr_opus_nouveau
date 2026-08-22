package com.sejourfr.app.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/**
 * Connexion locale.
 *
 * <p><b>{@code anonymousId} est FACULTATIF</b> : c'est l'identifiant de mesure
 * d'audience du visiteur, envoyé pour rattacher son parcours <i>avant</i>
 * compte au compte qui vient de naître (cf.
 * {@code AnalyticsIdentityService}). Absent — navigation privée, stockage
 * bloqué, client qui ne l'envoie pas encore —, on ne fait rien : une mesure
 * d'audience ne conditionne jamais l'accès à son propre compte.
 */
public record LoginRequest(
        @Email(message = "Email invalide")
        @NotBlank(message = "Email requis")
        String email,

        @NotBlank(message = "Mot de passe requis")
        String password,

        String anonymousId
) {}
