package com.sejourfr.app.service.email.event;

import com.sejourfr.app.util.LogMask;

import java.time.Instant;
import java.util.UUID;

/**
 * Le changement d'adresse est EFFECTIF : l'ANCIENNE adresse est prevenue
 * (arbitrage n°10, finding S7) — une prise de controle ne doit pas etre
 * invisible pour sa victime.
 */
public record EmailChangedEvent(UUID userId, String oldEmail, String newEmail, UUID requestId, Instant changedAt) {

    @Override
    public String toString() {
        return "EmailChangedEvent[user=" + userId + ", old=" + LogMask.email(oldEmail)
                + ", new=" + LogMask.email(newEmail) + "]";
    }
}
