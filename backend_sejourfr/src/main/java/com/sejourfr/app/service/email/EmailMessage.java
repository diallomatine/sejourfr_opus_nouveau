package com.sejourfr.app.service.email;

import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.util.LogMask;

import java.util.Map;

/**
 * Ce que le port d'envoi recoit : un destinataire, un type, des variables.
 *
 * <p>🛑 Pas de sujet ici : chez Brevo il vit dans le template, et le rendu local
 * le lit dans la configuration. Les variables sont <b>plates</b>, en camelCase,
 * stables : ce sont les futurs {@code params} Brevo.
 *
 * <p>🛑 {@link #toString()} est redefini : les variables peuvent porter une URL a
 * jeton (reset, changement d'email, desabonnement) et le {@code toString} d'un
 * record imprime tout. Rien de ce message ne doit finir dans un log.
 *
 * @param unsubscribeUrl         page de desabonnement (pied des mails ENGAGEMENT),
 *                               {@code null} pour un mail REQUIRED
 * @param oneClickUnsubscribeUrl cible des en-tetes {@code List-Unsubscribe}
 *                               (RFC 8058), {@code null} pour un mail REQUIRED
 */
public record EmailMessage(
        String recipient,
        EmailType type,
        Map<String, String> variables,
        String unsubscribeUrl,
        String oneClickUnsubscribeUrl
) {

    public EmailMessage {
        variables = Map.copyOf(variables);
    }

    @Override
    public String toString() {
        return "EmailMessage[type=" + type + ", recipient=" + LogMask.email(recipient) + "]";
    }
}
