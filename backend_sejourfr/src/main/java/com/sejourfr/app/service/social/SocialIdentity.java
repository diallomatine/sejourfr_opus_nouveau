package com.sejourfr.app.service.social;

import com.sejourfr.app.enums.AuthProvider;

/**
 * Identite normalisee extraite d'un ID token Google/Apple, avant de
 * find-or-create un User local.
 *
 * @param provider       provider d'origine (GOOGLE ou APPLE).
 * @param providerUserId "sub" du JWT (id stable cote provider).
 * @param email          email valide et verifie (Google = email_verified=true,
 *                       Apple = toujours verifie meme si relay).
 * @param firstName      prenom si dispo (Google le donne dans le JWT, Apple
 *                       seulement lors du premier consent — passe par le client).
 * @param lastName       nom si dispo (idem).
 */
public record SocialIdentity(
        AuthProvider provider,
        String providerUserId,
        String email,
        String firstName,
        String lastName
) {}
