package com.sejourfr.app.service.email.event;

import com.sejourfr.app.util.LogMask;

import java.util.UUID;

/** Un compte vient d'etre cree (inscription locale ou premier sign-in social). */
public record AccountCreatedEvent(UUID userId, String email) {

    @Override
    public String toString() {
        return "AccountCreatedEvent[user=" + userId + ", email=" + LogMask.email(email) + "]";
    }
}
