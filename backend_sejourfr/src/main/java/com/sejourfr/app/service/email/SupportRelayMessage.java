package com.sejourfr.app.service.email;

import com.sejourfr.app.util.LogMask;

/**
 * Le relais du formulaire de contact vers l'adresse support : texte brut,
 * synchrone, et son echec REMONTE a l'appelant (arbitrage n°9). Pas de ligne
 * {@code email_deliveries} : le destinataire n'est pas un utilisateur.
 *
 * @param replyTo adresse de l'expediteur, pour repondre directement
 */
public record SupportRelayMessage(String replyTo, String subject, String textBody) {

    @Override
    public String toString() {
        return "SupportRelayMessage[replyTo=" + LogMask.email(replyTo) + "]";
    }
}
