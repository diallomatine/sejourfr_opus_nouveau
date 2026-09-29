package com.sejourfr.app.service;

import com.sejourfr.app.dto.ContactRequest;
import com.sejourfr.app.dto.ContactResponse;
import com.sejourfr.app.service.email.EmailErrors;
import com.sejourfr.app.service.email.EmailSender;
import com.sejourfr.app.service.email.SupportRelayMessage;
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

    private final EmailSender emailSender;
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

    private static String relayBody(String name, String email, String subject, String message) {
        return """
                Nouveau message via le formulaire de contact SejourFR.

                De      : %s <%s>
                Sujet   : %s

                --------
                %s
                --------
                """.formatted(name, email, subject, message);
    }

    public ContactResponse submit(ContactRequest req) {
        String ticketId = generateTicketId();
        String name = req.name().trim();
        String email = req.email().trim().toLowerCase();
        String subject = req.subject().trim();
        String message = req.message().trim();

        log.info("Contact form submission from {} : '{}' (ticket {})", LogMask.email(email), subject, ticketId);

        // Source de vérité : la demande atterrit dans la boite de réception admin.
        // Sa transaction publie l'accusé de réception (CONTACT_RECEIVED), envoyé
        // à l'expéditeur APRÈS le commit.
        conversationService.createFromContact(name, email, subject, message, ticketId);

        // Relais vers l'équipe : SYNCHRONE, par le port d'envoi, sans ligne
        // email_deliveries (le destinataire n'est pas un utilisateur). Le port
        // remonte l'échec, absorbé ICI délibérément : la conversation enregistrée
        // fait foi, le visiteur voit un succès, et un incident SMTP ne doit pas
        // provoquer un second envoi du formulaire (B-1, arbitré : statu quo).
        try {
            emailSender.relayToSupport(new SupportRelayMessage(
                    email, "[Contact SejourFR] " + sanitizeHeader(subject),
                    relayBody(sanitizeHeader(name), email, sanitizeHeader(subject), message)));
            log.info("Contact relaye au support depuis {} (ticket {})", LogMask.email(email), ticketId);
        } catch (RuntimeException e) {
            log.warn("Contact support notification failed (ticket {}) : {}", ticketId,
                    EmailErrors.sanitize(e));
        }

        return new ContactResponse(ticketId);
    }
}
