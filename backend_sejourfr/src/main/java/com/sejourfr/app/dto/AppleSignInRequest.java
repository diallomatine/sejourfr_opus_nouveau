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
 */
public record AppleSignInRequest(
        @NotBlank(message = "identityToken requis")
        String identityToken,

        String firstName,
        String lastName
) {}
