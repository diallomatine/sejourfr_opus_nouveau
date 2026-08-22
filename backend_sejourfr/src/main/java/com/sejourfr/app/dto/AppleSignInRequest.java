package com.sejourfr.app.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * Payload envoye par le client iOS apres "Sign in with Apple".
 * <p>
 * Apple ne renvoie le nom/email qu'une seule fois (lors du premier consent),
 * via les champs `fullName.givenName` / `fullName.familyName` du framework
 * AuthenticationServices. On les fait donc passer dans la requete pour
 * peupler le profil a la creation — le JWT lui ne contient que l'email
 * (parfois relayed) et le sub.
 *
 * <p><b>{@code anonymousId} est FACULTATIF</b> : c'est l'identifiant de mesure
 * d'audience du visiteur, envoyé pour rattacher son parcours <i>avant</i>
 * compte au compte qui vient de naître (cf.
 * {@code AnalyticsIdentityService}). Absent — navigation privée, stockage
 * bloqué, client qui ne l'envoie pas encore —, on ne fait rien : une mesure
 * d'audience ne conditionne jamais l'accès à son propre compte.
 */
public record AppleSignInRequest(
        @NotBlank(message = "identityToken requis")
        String identityToken,

        String firstName,
        String lastName,

        String anonymousId
) {}
