package com.sejourfr.app.service.email.compose;

import com.sejourfr.app.entity.Conversation;
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
 * Les mails du SUPPORT, vers un contact qui n'a pas forcement de compte
 * ({@code userId} nul) : accuse de reception, reponse de l'equipe.
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

    private static String nullToEmpty(String s) {
        return s == null ? "" : s;
    }
}
