package com.sejourfr.app.service.email.event;

import com.sejourfr.app.util.LogMask;

import java.util.UUID;

/**
 * Une demande de reinitialisation. 🛑 Porte le jeton BRUT, qui n'existe qu'en
 * memoire (la base n'en garde que le hache) : {@link #toString()} ne l'imprime
 * jamais, et rien ne doit serialiser cet evenement.
 *
 * @param resetRequestId   {@code password_reset_tokens.id} — une demande = un mail
 * @param expiresInMinutes lu sur la duree de vie du jeton, jamais recopie dans le gabarit
 */
public record PasswordResetRequestedEvent(UUID userId, String email, UUID resetRequestId, String rawToken,
                                          long expiresInMinutes) {

    @Override
    public String toString() {
        return "PasswordResetRequestedEvent[user=" + userId + ", email=" + LogMask.email(email)
                + ", request=" + resetRequestId + "]";
    }
}
