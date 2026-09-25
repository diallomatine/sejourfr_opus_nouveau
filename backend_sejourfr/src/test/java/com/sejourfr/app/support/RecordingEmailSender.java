package com.sejourfr.app.support;

import com.sejourfr.app.enums.EmailProvider;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.service.email.EmailMessage;
import com.sejourfr.app.service.email.EmailSendException;
import com.sejourfr.app.service.email.EmailSender;
import com.sejourfr.app.service.email.SupportRelayMessage;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Le port d'envoi des tests d'integration : il ENREGISTRE au lieu d'envoyer.
 * Aucun test ne touche un SMTP, et aucun ne peut atteindre une vraie adresse.
 *
 * <p>{@link #failNext(int)} simule une panne SMTP courte (les N prochains envois
 * echouent) ; {@link #reset()} est a appeler en {@code @AfterEach}.
 */
public class RecordingEmailSender implements EmailSender {

    private final List<EmailMessage> sent = new CopyOnWriteArrayList<>();
    private final List<SupportRelayMessage> relayed = new CopyOnWriteArrayList<>();
    private final AtomicInteger failures = new AtomicInteger();
    private volatile boolean relayFails;

    @Override
    public EmailProvider provider() {
        return EmailProvider.SPRING_MAIL;
    }

    @Override
    public String send(EmailMessage message) {
        if (failures.getAndUpdate(n -> Math.max(0, n - 1)) > 0) {
            throw new EmailSendException("MailSendException: SMTP indisponible (simule)");
        }
        sent.add(message);
        return null;
    }

    @Override
    public void relayToSupport(SupportRelayMessage message) {
        if (relayFails) {
            throw new EmailSendException("MailSendException: SMTP indisponible (simule)");
        }
        relayed.add(message);
    }

    public void failNext(int count) {
        failures.set(count);
    }

    public void failRelay(boolean fails) {
        this.relayFails = fails;
    }

    public List<EmailMessage> sent() {
        return List.copyOf(sent);
    }

    public List<EmailMessage> sentTo(String recipient) {
        return sent.stream().filter(m -> m.recipient().equalsIgnoreCase(recipient)).toList();
    }

    public List<EmailMessage> sentOfType(EmailType type) {
        return sent.stream().filter(m -> m.type() == type).toList();
    }

    public List<SupportRelayMessage> relayed() {
        return List.copyOf(relayed);
    }

    public void reset() {
        sent.clear();
        relayed.clear();
        failures.set(0);
        relayFails = false;
    }
}
