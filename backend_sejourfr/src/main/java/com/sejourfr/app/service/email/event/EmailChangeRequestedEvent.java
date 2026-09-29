package com.sejourfr.app.service.email.event;

import com.sejourfr.app.util.LogMask;

import java.util.UUID;

/**
 * Une demande de changement d'adresse : le lien part vers la NOUVELLE adresse.
 * 🛑 Porte le jeton BRUT : {@link #toString()} ne l'imprime jamais.
 *
 * @param requestId {@code email_change_tokens.id}
 */
public record EmailChangeRequestedEvent(UUID userId, String newEmail, UUID requestId, String rawToken,
                                        long expiresInMinutes) {

    @Override
    public String toString() {
        return "EmailChangeRequestedEvent[user=" + userId + ", newEmail=" + LogMask.email(newEmail)
                + ", request=" + requestId + "]";
    }
}
