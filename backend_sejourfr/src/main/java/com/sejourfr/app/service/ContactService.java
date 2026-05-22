package com.sejourfr.app.service;

import com.sejourfr.app.dto.ContactRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Service du formulaire de contact. Relaye le message vers l'adresse support
 * (configurée via {@code sejourfr.contact.to}, défaut {@code hello@sejourfr.fr}).
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

    public void submit(ContactRequest req) {
        log.info("Contact form submission from {} : '{}'", req.email(), req.subject());
        mailService.sendContactMessage(
                sanitizeHeader(req.name().trim()),
                req.email().trim().toLowerCase(),
                sanitizeHeader(req.subject().trim()),
                req.message().trim()
        );
    }

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
}
