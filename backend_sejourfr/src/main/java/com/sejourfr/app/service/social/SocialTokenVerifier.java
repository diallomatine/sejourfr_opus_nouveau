package com.sejourfr.app.service.social;

/**
 * Valide un ID token externe (Google ou Apple) et retourne l'identite
 * normalisee si tout est OK. Doit verifier au minimum :
 * <ul>
 *   <li>signature RS256 contre le JWKS du provider</li>
 *   <li>issuer attendu</li>
 *   <li>audience presente dans la liste autorisee</li>
 *   <li>token non expire</li>
 * </ul>
 *
 * Toute defaillance leve {@link InvalidSocialTokenException}.
 */
public interface SocialTokenVerifier {

    SocialIdentity verify(String idToken);

    /** false si le verifier n'a pas d'audience configuree → endpoint renvoie 503. */
    boolean isConfigured();
}
