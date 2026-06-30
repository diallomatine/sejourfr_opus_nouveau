package com.sejourfr.app.service;

import com.sejourfr.app.dto.ContactRequest;
import com.sejourfr.app.dto.ContactResponse;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class ContactServiceTest {

    @Mock
    private MailService mailService;
    @Mock
    private ConversationService conversationService;

    @InjectMocks
    private ContactService service;

    @Test
    void submitCreatesConversationTrimsAndLowercasesEmailAndReturnsTicket() {
        ContactResponse res = service.submit(new ContactRequest(
                "  Alice  ", "  Alice@EXAMPLE.com ", "  Sujet  ", "  Mon message  "));

        assertThat(res.ticketId()).startsWith("SF-");

        verify(conversationService).createFromContact(
                eq("Alice"), eq("alice@example.com"), eq("Sujet"), eq("Mon message"));
        verify(mailService).sendContactMessage(eq("Alice"), eq("alice@example.com"), eq("Sujet"), eq("Mon message"));
        verify(mailService).sendContactReceivedEmail(
                eq("alice@example.com"), eq("Alice"), eq("Sujet"), eq("Mon message"), anyString());
    }

    @Test
    void submitStripsCrlfFromHeaderFieldsBeforeRelaying() {
        service.submit(new ContactRequest(
                "Bob\r\nBcc: victim@x.com", "bob@example.com", "Sujet\r\nBcc: x", "Corps libre"));

        ArgumentCaptor<String> name = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> subject = ArgumentCaptor.forClass(String.class);
        verify(mailService).sendContactMessage(name.capture(), eq("bob@example.com"), subject.capture(), eq("Corps libre"));

        assertThat(name.getValue()).doesNotContain("\r", "\n");
        assertThat(subject.getValue()).doesNotContain("\r", "\n");
    }

    @Test
    void submitSucceedsEvenWhenSupportRelayFails() {
        doThrow(new RuntimeException("smtp down"))
                .when(mailService).sendContactMessage(anyString(), anyString(), anyString(), anyString());

        ContactResponse res = service.submit(new ContactRequest(
                "Carol", "carol@example.com", "Sujet", "Message"));

        assertThat(res.ticketId()).startsWith("SF-");
        // L'accusé de réception part malgré l'échec du relai support.
        verify(mailService).sendContactReceivedEmail(
                eq("carol@example.com"), any(), any(), any(), anyString());
    }
}
