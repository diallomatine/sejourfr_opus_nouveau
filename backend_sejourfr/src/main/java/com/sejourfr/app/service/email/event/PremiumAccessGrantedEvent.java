package com.sejourfr.app.service.email.event;

import com.sejourfr.app.util.LogMask;

import java.util.UUID;

/**
 * Un acces Premium vient d'etre ACCORDE — le systeme le considere comme ouvert
 * (arbitrage n°20). {@code extension} = l'achat prolonge un acces en cours
 * ({@code PREMIUM_ACCESS_EXTENDED}), sinon c'est le premier acces
 * ({@code PREMIUM_ACCESS_STARTED}, arbitrage n°4).
 *
 * @param accessId {@code user_subscriptions.id} — une ligne par achat
 */
public record PremiumAccessGrantedEvent(UUID userId, String email, UUID accessId, boolean extension) {

    @Override
    public String toString() {
        return "PremiumAccessGrantedEvent[user=" + userId + ", email=" + LogMask.email(email)
                + ", access=" + accessId + ", extension=" + extension + "]";
    }
}
