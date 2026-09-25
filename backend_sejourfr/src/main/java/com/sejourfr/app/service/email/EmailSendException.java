package com.sejourfr.app.service.email;

/**
 * Un envoi a echoue. Le message est deja ASSAINI ({@link EmailErrors#sanitize}) :
 * adresses masquees, jetons retires, tronque.
 */
public class EmailSendException extends RuntimeException {

    public EmailSendException(String sanitizedMessage) {
        super(sanitizedMessage);
    }
}
