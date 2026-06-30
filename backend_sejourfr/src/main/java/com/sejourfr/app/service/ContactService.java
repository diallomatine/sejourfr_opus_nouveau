package com.sejourfr.app.service;

import com.sejourfr.app.dto.ContactRequest;
import com.sejourfr.app.dto.ContactResponse;
import com.sejourfr.app.util.LogMask;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Service du formulaire de contact. Chaque soumission devient une
 * <b>conversation</b> dans la boite de réception admin ({@code /conversations})
 * — c'est la source de vérité. En plus, deux emails best-effort : une
 * notification à l'équipe support et un accusé de réception à l'expéditeur.
 * La réponse de l'admin (depuis la console) repart par email au contact.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class ContactService {

    private final MailService mailService;
    private final ConversationService conversationService;

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

        log.info("Contact form submission from {} : '{}' (ticket {})", LogMask.email(email), subject, ticketId);

        // Source de vérité : la demande atterrit dans la boite de réception admin.
        conversationService.createFromContact(name, email, subject, message);

        // Notification best-effort à l'équipe (la boite admin reste l'autorité,
        // donc un échec SMTP ici ne doit pas faire échouer la soumission).
        try {
            mailService.sendContactMessage(sanitizeHeader(name), email, sanitizeHeader(subject), message);
        } catch (RuntimeException e) {
            log.warn("Contact support notification failed (ticket {}) : {}", ticketId, e.getMessage());
        }

        // Best-effort : accusé de réception à l'expéditeur (async).
        mailService.sendContactReceivedEmail(email, name, subject, message, ticketId);

        return new ContactResponse(ticketId);
    }
}
