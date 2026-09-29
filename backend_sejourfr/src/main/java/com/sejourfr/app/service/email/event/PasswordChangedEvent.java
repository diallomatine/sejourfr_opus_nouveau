package com.sejourfr.app.service.email.event;

import com.sejourfr.app.util.LogMask;

import java.time.Instant;
import java.util.UUID;

/**
 * Le mot de passe a change — changement connecte OU reinitialisation appliquee
 * (arbitrage n°8 : un reset EST un changement, et c'est le cas d'une prise de
 * controle). {@code eventId} est tire a la publication : aucune table
 * n'enregistre un changement de mot de passe.
 */
public record PasswordChangedEvent(UUID userId, String email, UUID eventId, Instant changedAt) {

    @Override
    public String toString() {
        return "PasswordChangedEvent[user=" + userId + ", email=" + LogMask.email(email)
                + ", event=" + eventId + "]";
    }
}
