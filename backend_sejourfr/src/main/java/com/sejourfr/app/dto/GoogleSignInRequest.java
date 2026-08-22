package com.sejourfr.app.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * Payload envoye par les clients (web GIS, mobile google_sign_in) apres
 * authentification cote Google. Le backend valide ce JWT contre les JWKS
 * Google avant d'ouvrir une session.
 *
 * <p><b>{@code anonymousId} est FACULTATIF</b> : c'est l'identifiant de mesure
 * d'audience du visiteur, envoyé pour rattacher son parcours <i>avant</i>
 * compte au compte qui vient de naître (cf.
 * {@code AnalyticsIdentityService}). Absent — navigation privée, stockage
 * bloqué, client qui ne l'envoie pas encore —, on ne fait rien : une mesure
 * d'audience ne conditionne jamais l'accès à son propre compte.
 */
public record GoogleSignInRequest(
        @NotBlank(message = "idToken requis")
        String idToken,

        String anonymousId
) {}
