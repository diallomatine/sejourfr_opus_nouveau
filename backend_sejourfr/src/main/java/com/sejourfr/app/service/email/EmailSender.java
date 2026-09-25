package com.sejourfr.app.service.email;

import com.sejourfr.app.enums.EmailProvider;

/**
 * <b>Le port d'envoi</b>. Aujourd'hui {@link SpringMailEmailSender} (gabarit local
 * + rendu), demain {@code BrevoEmailSender} (templateId + params).
 *
 * <p>🛑 Passer a Brevo ne change QUE l'implementation de ce port et la
 * configuration des gabarits : ni les regles d'envoi, ni le scheduler, ni les
 * evenements, ni les preferences, ni le desabonnement, ni l'anti-doublon.
 *
 * <p>🛑 {@code JavaMailSender} n'est appele nulle part ailleurs que dans
 * l'implementation Spring Mail.
 */
public interface EmailSender {

    EmailProvider provider();

    /**
     * Envoie un mail client. Une seule tentative : la relance vit dans
     * {@link EmailService}.
     *
     * @return l'identifiant du message chez le provider, ou {@code null}
     * @throws EmailSendException si l'envoi a echoue
     */
    String send(EmailMessage message);

    /**
     * Relaie un message du formulaire de contact vers le support, en
     * synchrone.
     *
     * @throws EmailSendException si l'envoi a echoue — l'appelant decide
     */
    void relayToSupport(SupportRelayMessage message);
}
