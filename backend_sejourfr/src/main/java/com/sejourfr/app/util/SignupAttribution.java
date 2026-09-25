package com.sejourfr.app.util;

import com.sejourfr.app.entity.User;

/**
 * <b>Autorite unique</b> de la provenance posee sur un compte a sa creation :
 * inscription locale et premier sign-in social (Google, Apple). Elle vivait en
 * deux copies (AuthService, SocialAuthService) ; une troisieme colonne
 * ({@code signup_anonymous_id}, V074) aurait fait trois endroits a tenir
 * alignes.
 *
 * <p>Posee <b>une fois, a la creation, jamais reecrite</b> : la provenance d'une
 * acquisition est celle du jour ou elle a eu lieu. Le contexte d'inscription
 * ({@code signup_context}, {@code signup_diagnostic_*}) s'ajoute ici au lot 2,
 * dans la transaction d'auth, en meme temps que le claim de la run.
 */
public final class SignupAttribution {

    private SignupAttribution() {
    }

    /**
     * @param declaredAnonymousId {@code anonymousId} du corps de la requete
     *                            d'auth ; prime sur l'en-tete
     */
    public static void stamp(User user, ClientContext client, String declaredAnonymousId) {
        ClientContext ctx = client == null ? ClientContext.unknown() : client;
        user.setSignupSource(ctx.source());
        user.setSignupPlatform(ctx.platform());
        user.setSignupAnonymousId(ctx.anonymousIdPreferring(declaredAnonymousId));
    }
}
