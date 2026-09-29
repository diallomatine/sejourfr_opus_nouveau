package com.sejourfr.app.service;

import com.sejourfr.app.dto.ContactRequest;
import com.sejourfr.app.dto.ContactResponse;
import com.sejourfr.app.service.email.EmailSendException;
import com.sejourfr.app.service.email.EmailSender;
import com.sejourfr.app.service.email.SupportRelayMessage;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class ContactServiceTest {

    @Mock
    private EmailSender emailSender;
    @Mock
    private ConversationService conversationService;

    @InjectMocks
    private ContactService service;

    @Test
    void submitCreatesConversationWithTicketAndRelaysToSupport() {
        ContactResponse res = service.submit(new ContactRequest(
                "  Alice  ", "  Alice@EXAMPLE.com ", "  Sujet  ", "  Mon message  "));

        assertThat(res.ticketId()).startsWith("SF-");
        // La conversation porte le numero de suivi : c'est sa transaction qui
        // publie l'accuse de reception (CONTACT_RECEIVED), envoye apres commit.
        verify(conversationService).createFromContact(
                eq("Alice"), eq("alice@example.com"), eq("Sujet"), eq("Mon message"), eq(res.ticketId()));
        ArgumentCaptor<SupportRelayMessage> relay = ArgumentCaptor.forClass(SupportRelayMessage.class);
        verify(emailSender).relayToSupport(relay.capture());
        assertThat(relay.getValue().replyTo()).isEqualTo("alice@example.com");
        assertThat(relay.getValue().subject()).isEqualTo("[Contact SejourFR] Sujet");
        assertThat(relay.getValue().textBody()).contains("Alice <alice@example.com>").contains("Mon message");
    }

    @Test
    void submitStripsCrlfFromHeaderFieldsBeforeRelaying() {
        service.submit(new ContactRequest(
                "Bob\r\nBcc: victim@x.com", "bob@example.com", "Sujet\r\nBcc: x", "Corps libre"));

        ArgumentCaptor<SupportRelayMessage> relay = ArgumentCaptor.forClass(SupportRelayMessage.class);
        verify(emailSender).relayToSupport(relay.capture());
        assertThat(relay.getValue().subject()).doesNotContain("\r", "\n");
        assertThat(relay.getValue().textBody().lines().filter(l -> l.startsWith("De ")).findFirst().orElseThrow())
                .doesNotContain("\r");
    }

    @Test
    void submitSucceedsEvenWhenSupportRelayFails() {
        doThrow(new EmailSendException("smtp down")).when(emailSender).relayToSupport(any());

        ContactResponse res = service.submit(new ContactRequest(
                "Carol", "carol@example.com", "Sujet", "Message"));

        // La demande est deja dans la boite admin (l'autorite) : le candidat ne
        // doit pas la renvoyer. L'accuse de reception part quand meme.
        assertThat(res.ticketId()).startsWith("SF-");
        verify(conversationService).createFromContact(
                eq("Carol"), eq("carol@example.com"), eq("Sujet"), eq("Message"), eq(res.ticketId()));
    }
}
