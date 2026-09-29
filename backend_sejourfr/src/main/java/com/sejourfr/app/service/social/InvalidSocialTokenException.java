package com.sejourfr.app.service.social;

/**
 * Levee par les {@link SocialTokenVerifier} quand l'ID token est invalide,
 * mal signe, expire, ou que l'audience n'est pas autorisee.
 * <p>
 * Capturee par {@code SocialAuthController} et traduite en HTTP 401.
 */
public class InvalidSocialTokenException extends RuntimeException {
    public InvalidSocialTokenException(String message) {
        super(message);
    }

    public InvalidSocialTokenException(String message, Throwable cause) {
        super(message, cause);
    }
}
