package com.sejourfr.app.service.email;

/**
 * Un envoi a echoue. Le message est deja ASSAINI ({@link EmailErrors#sanitize}) :
 * adresses masquees, jetons retires, tronque.
 *
 * <p>{@link #recipientRejected()} distingue un echec PROPRE AU DESTINATAIRE
 * (adresse illisible, refus SMTP 5xx sur l'adresse) — definitif, inutile de
 * reessayer — d'un echec SYSTEMIQUE (limite de debit, connexion, auth), le cas
 * par defaut.
 */
public class EmailSendException extends RuntimeException {

    private final boolean recipientRejected;

    public EmailSendException(String sanitizedMessage) {
        this(sanitizedMessage, false);
    }

    public EmailSendException(String sanitizedMessage, boolean recipientRejected) {
        super(sanitizedMessage);
        this.recipientRejected = recipientRejected;
    }

    public boolean recipientRejected() {
        return recipientRejected;
    }
}
