package com.sejourfr.app.service.email.compose;

import com.sejourfr.app.entity.Conversation;
import com.sejourfr.app.entity.Message;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.MessageManager;
import com.sejourfr.app.service.email.EmailRequest;
import com.sejourfr.app.service.email.event.ContactReceivedEvent;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class SupportEmailComposerTest {

    private final MessageManager messages = mock(MessageManager.class);
    private final SupportEmailComposer composer = new SupportEmailComposer(messages);

    @Test
    void accuseSansCompte() {
        UUID conv = UUID.randomUUID();

        EmailRequest r = composer.contactReceived(new ContactReceivedEvent(conv, "v@example.com", "", "Sujet",
                "Corps", "SF-ABC123")).orElseThrow();

        assertThat(r.userId()).isNull();
        assertThat(r.type()).isEqualTo(EmailType.CONTACT_RECEIVED);
        assertThat(r.variables()).containsEntry("greeting", "Bonjour").containsEntry("ticketId", "SF-ABC123");
    }

    @Test
    void reponseRelueSurLeMessage() {
        UUID id = UUID.randomUUID();
        Conversation c = new Conversation();
        c.setContactEmail("v@example.com");
        c.setContactName("Val");
        c.setSubject("Question");
        Message m = new Message();
        m.setConversation(c);
        m.setBody("Réponse");
        when(messages.findById(id)).thenReturn(Optional.of(m));

        EmailRequest r = composer.supportReply(id, EmailRequest.Origin.EVENT).orElseThrow();

        assertThat(r.recipient()).isEqualTo("v@example.com");
        assertThat(r.deduplicationKey()).isEqualTo("SUPPORT_REPLY:" + id);
        assertThat(r.variables()).containsEntry("reply", "Réponse").containsEntry("greeting", "Bonjour Val");
    }

    @Test
    void uneConversationInAppNEnvoieRien() {
        UUID id = UUID.randomUUID();
        Message m = new Message();
        m.setConversation(new Conversation());
        when(messages.findById(id)).thenReturn(Optional.of(m));

        assertThat(composer.supportReply(id, EmailRequest.Origin.EVENT)).isEmpty();
    }
}
