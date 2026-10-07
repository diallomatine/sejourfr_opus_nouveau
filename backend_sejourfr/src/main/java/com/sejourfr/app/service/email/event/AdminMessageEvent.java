package com.sejourfr.app.service.email.event;

import com.sejourfr.app.util.LogMask;

import java.util.UUID;

/**
 * Un admin a ecrit a un COMPTE ({@code ADMIN_MESSAGE}) : premier message d'une
 * conversation ouverte depuis la console, ou reponse dans une conversation
 * rattachee a un compte.
 */
public record AdminMessageEvent(UUID messageId, UUID userId, String email) {

    @Override
    public String toString() {
        return "AdminMessageEvent[message=" + messageId + ", user=" + userId
                + ", email=" + LogMask.email(email) + "]";
    }
}
