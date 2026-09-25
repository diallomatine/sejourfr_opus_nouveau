package com.sejourfr.app.service.email.event;

import com.sejourfr.app.util.LogMask;

import java.util.UUID;

/**
 * Un message du formulaire de contact est enregistre : accuse de reception a
 * l'expediteur, qui n'a pas forcement de compte. Le contenu voyage dans
 * l'evenement parce que le numero de suivi n'est persiste nulle part.
 */
public record ContactReceivedEvent(UUID conversationId, String email, String name, String subject,
                                   String message, String ticketId) {

    @Override
    public String toString() {
        return "ContactReceivedEvent[conversation=" + conversationId + ", email=" + LogMask.email(email)
                + ", ticket=" + ticketId + "]";
    }
}
