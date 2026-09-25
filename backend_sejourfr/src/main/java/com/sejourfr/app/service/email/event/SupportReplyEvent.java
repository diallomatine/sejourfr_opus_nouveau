package com.sejourfr.app.service.email.event;

import com.sejourfr.app.util.LogMask;

import java.util.UUID;

/** L'equipe a repondu a une conversation issue du formulaire de contact. */
public record SupportReplyEvent(UUID messageId, String email) {

    @Override
    public String toString() {
        return "SupportReplyEvent[message=" + messageId + ", email=" + LogMask.email(email) + "]";
    }
}
