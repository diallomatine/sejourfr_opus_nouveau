package com.sejourfr.app.service.email.compose;

import com.sejourfr.app.entity.Conversation;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.MessageManager;
import com.sejourfr.app.service.email.EmailFormats;
import com.sejourfr.app.service.email.EmailKeys;
import com.sejourfr.app.service.email.EmailRequest;
import com.sejourfr.app.service.email.event.ContactReceivedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Les mails du SUPPORT : vers un contact qui n'a pas forcement de compte
 * ({@code userId} nul) — accuse de reception, reponse de l'equipe — et vers un
 * COMPTE, le message libre d'un admin ({@code ADMIN_MESSAGE}).
 */
@Component
@RequiredArgsConstructor
public class SupportEmailComposer {

    private final MessageManager messageManager;

    /**
     * Pas de relance differee possible : le numero de suivi n'est persiste nulle
     * part, l'accuse ne se compose qu'a partir de l'evenement.
     */
    public Optional<EmailRequest> contactReceived(ContactReceivedEvent event) {
        return Optional.of(new EmailRequest(EmailType.CONTACT_RECEIVED, null, event.email(),
                Map.of("firstName", EmailFormats.firstName(event.name()),
                        "greeting", EmailFormats.greeting(event.name()),
                        "subject", nullToEmpty(event.subject()),
                        "message", nullToEmpty(event.message()),
                        "ticketId", nullToEmpty(event.ticketId())),
                EmailKeys.byReference(EmailType.CONTACT_RECEIVED, event.conversationId()),
                event.conversationId(), null, EmailRequest.Origin.EVENT));
    }

    /** Envoi initial et relance differee : tout se relit sur le message et sa conversation. */
    @Transactional(readOnly = true)
    public Optional<EmailRequest> supportReply(UUID messageId, EmailRequest.Origin origin) {
        return messageManager.findById(messageId).flatMap(message -> {
            Conversation c = message.getConversation();
            if (c == null || c.getContactEmail() == null || c.getContactEmail().isBlank()) {
                return Optional.empty();
            }
            return Optional.of(new EmailRequest(EmailType.SUPPORT_REPLY, null, c.getContactEmail(),
                    Map.of("firstName", EmailFormats.firstName(c.getContactName()),
                            "greeting", EmailFormats.greeting(c.getContactName()),
                            "subject", nullToEmpty(c.getSubject()),
                            "reply", nullToEmpty(message.getBody())),
                    EmailKeys.byReference(EmailType.SUPPORT_REPLY, messageId), messageId, null, origin));
        });
    }

    /** Longueur du preheader d'un message d'admin (debut du texte). */
    static final int EXCERPT_MAX = 110;

    /**
     * Envoi initial et relance differee d'un message d'admin : tout se relit sur
     * le message, sa conversation et le compte. Vide si le compte a ete supprime
     * entre-temps — on n'ecrit jamais a une adresse anonymisee.
     */
    @Transactional(readOnly = true)
    public Optional<EmailRequest> adminMessage(UUID messageId, EmailRequest.Origin origin) {
        return messageManager.findById(messageId).flatMap(message -> {
            Conversation c = message.getConversation();
            User user = c == null ? null : c.getUser();
            if (user == null || user.getDeletedAt() != null) {
                return Optional.empty();
            }
            return Optional.of(new EmailRequest(EmailType.ADMIN_MESSAGE, user.getId(), user.getEmail(),
                    adminMessageVariables(user.getFirstName(), c.getSubject(), message.getBody()),
                    EmailKeys.byReference(EmailType.ADMIN_MESSAGE, messageId), messageId, null, origin));
        });
    }

    /**
     * 🛑 Les variables d'un message d'admin, en UN endroit : l'envoi et l'apercu
     * de la console passent par ici. {@code messageHtml} est deja echappe
     * ({@link EmailFormats#multilineHtml}) ; {@code message} sert au texte brut.
     */
    public static Map<String, String> adminMessageVariables(String firstName, String subject, String body) {
        return Map.of("firstName", EmailFormats.firstName(firstName),
                "greeting", EmailFormats.greeting(firstName),
                "subject", nullToEmpty(subject),
                "message", EmailFormats.normalizeLines(body),
                "messageHtml", EmailFormats.multilineHtml(body),
                "excerpt", EmailFormats.excerpt(body, EXCERPT_MAX));
    }

    private static String nullToEmpty(String s) {
        return s == null ? "" : s;
    }
}
