package com.sejourfr.app.service;

import com.sejourfr.app.dto.ContactRequest;
import com.sejourfr.app.dto.ContactResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Service du formulaire de contact. Relaye le message vers l'adresse support
 * (configurée via {@code sejourfr.contact.to}, défaut {@code support@sejourfr.fr}).
 *
 * <p>Pas de persistance : pour cette itération on traite le message comme
 * un email transitoire. Si on veut un suivi côté admin plus tard, on
 * ajoutera une entité {@code ContactMessage} + un controller admin pour la
 * liste.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class ContactService {

    private final MailService mailService;

    /**
     * Défense en profondeur contre l'injection de headers SMTP : on retire
     * tout CR/LF d'une valeur user-controlled susceptible de finir dans un
     * header de mail (sujet, display name d'un Reply-To, etc.).
     *
     * <p>Jakarta Mail encode normalement les headers, mais ne stripe pas
     * activement les CR/LF — si un futur changement déplace `subject` ou
     * `name` vers un header brut, on évite la classe de bug "BCC silencieux
     * via Subject: foo\r\nBcc: victim@x.com". Le `message` reste libre
     * (corps du mail, pas un header).
     */
    private static String sanitizeHeader(String value) {
        return value.replace("\r", " ").replace("\n", " ");
    }

    /** Référence courte à citer dans l'échange mail (ex: {@code SF-1A2B3C}). */
    private static String generateTicketId() {
        return "SF-" + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
    }

    public ContactResponse submit(ContactRequest req) {
        String ticketId = generateTicketId();
        String name = req.name().trim();
        String email = req.email().trim().toLowerCase();
        String subject = req.subject().trim();
        String message = req.message().trim();

        log.info("Contact form submission from {} : '{}' (ticket {})", email, subject, ticketId);

        // Critique : le message DOIT arriver au support (lève si l'envoi échoue).
        mailService.sendContactMessage(sanitizeHeader(name), email, sanitizeHeader(subject), message);

        // Best-effort : accusé de réception à l'expéditeur (async, n'échoue pas
        // la soumission si le SMTP de cet envoi-là flanche).
        mailService.sendContactReceivedEmail(email, name, subject, message, ticketId);

        return new ContactResponse(ticketId);
    }
}
