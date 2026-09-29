package com.sejourfr.app.service.email;

import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.util.LogMask;

import java.time.Instant;
import java.util.UUID;

/**
 * Ce qu'on sait d'un mail evenementiel AU MOMENT DU COMMIT, sans lecture en
 * base : de quoi tracer une ligne FAILED si l'executor refuse la tache ou si
 * la composition echoue (complement E). Jamais de jeton ici.
 */
public record EmailIntent(EmailType type, UUID userId, String recipient,
                          String deduplicationKey, UUID referenceId, Instant occurredAt) {

    @Override
    public String toString() {
        return "EmailIntent[type=" + type + ", user=" + userId + ", recipient="
                + LogMask.email(recipient) + "]";
    }
}
