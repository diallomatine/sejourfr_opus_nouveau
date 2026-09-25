package com.sejourfr.app.service.email;

import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.util.LogMask;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * Une demande d'envoi, telle qu'un composeur la construit a partir de la SOURCE
 * (compte, acces, diagnostic...). C'est la seule entree d'{@link EmailService}.
 *
 * @param userId           compte concerne ; {@code null} pour un visiteur sans
 *                         compte (accuse de contact, reponse du support)
 * @param deduplicationKey cle anti-doublon ({@link EmailKeys}) ; {@code null} =
 *                         aucune protection (aucun type ne s'en passe aujourd'hui)
 * @param referenceId      ce qu'une relance differee relira pour reconstruire
 *                         les variables
 * @param occurredAt       l'instant du fait quand aucune table ne le porte
 */
public record EmailRequest(
        EmailType type,
        UUID userId,
        String recipient,
        Map<String, String> variables,
        String deduplicationKey,
        UUID referenceId,
        Instant occurredAt,
        Origin origin
) {

    /**
     * D'ou vient la demande — ce qui decide si un refus par preference est
     * trace ({@code SKIPPED}) ou simplement ignore (le scheduler exclut deja les
     * desabonnes dans ses requetes, brief §4).
     */
    public enum Origin { EVENT, SCHEDULER, DEFERRED_RETRY }

    public EmailRequest {
        variables = Map.copyOf(variables);
    }

    public EmailRequest withOrigin(Origin newOrigin) {
        return new EmailRequest(type, userId, recipient, variables, deduplicationKey,
                referenceId, occurredAt, newOrigin);
    }

    /** 🛑 Redefini : les variables peuvent contenir une URL a jeton. */
    @Override
    public String toString() {
        return "EmailRequest[type=" + type + ", user=" + userId + ", recipient="
                + LogMask.email(recipient) + ", origin=" + origin + "]";
    }
}
