package com.sejourfr.app.service;

import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit. Renderer réel (lit les templates du classpath), JavaMailSender mocké
 * (aucun envoi réseau). On vérifie destinataires / sujets / Reply-To et le
 * contenu des messages texte.
 */
@ExtendWith(MockitoExtension.class)
class MailServiceTest {

    private static final String FROM = "no-reply@sejourfr.fr";
    private static final String APP_URL = "https://app.sejourfr.fr";
    private static final String CONTACT = "support@sejourfr.fr";
    private static final String BACKEND_URL = "https://api.sejourfr.fr";

    @Mock
    private JavaMailSender mailSender;

    private MailService mailService;

    @BeforeEach
    void setUp() {
        mailService = new MailService(
                mailSender, new MailTemplateRenderer(), FROM, APP_URL, CONTACT, BACKEND_URL);
    }

    private MimeMessage stubMimeMessage() {
        MimeMessage message = new MimeMessage((Session) null);
        when(mailSender.createMimeMessage()).thenReturn(message);
        return message;
    }

    @Test
    void sendPasswordResetEmailTargetsRecipientWithExpectedSubject() throws Exception {
        MimeMessage message = stubMimeMessage();

        mailService.sendPasswordResetEmail("user@example.com", "tok123");

        verify(mailSender).send(message);
        assertThat(message.getAllRecipients()[0].toString()).isEqualTo("user@example.com");
        assertThat(message.getSubject()).contains("Réinitialisation");
        assertThat(message.getFrom()[0].toString()).isEqualTo(FROM);
    }

    @Test
    void sendWelcomeEmailUsesWelcomeSubject() throws Exception {
        MimeMessage message = stubMimeMessage();

        mailService.sendWelcomeEmail("new@example.com", "Alice");

        verify(mailSender).send(message);
        assertThat(message.getAllRecipients()[0].toString()).isEqualTo("new@example.com");
        assertThat(message.getSubject()).contains("Bienvenue");
    }

    @Test
    void sendSubscriptionActivatedEmailUsesActivationSubject() throws Exception {
        MimeMessage message = stubMimeMessage();

        mailService.sendSubscriptionActivatedEmail(
                "buyer@example.com", "Bob", "Intégral · 3 mois", Instant.now(), false);

        verify(mailSender).send(message);
        assertThat(message.getAllRecipients()[0].toString()).isEqualTo("buyer@example.com");
        assertThat(message.getSubject()).contains("accès Premium");
    }

    @Test
    void sendConversationReplyEmailSetsSupportReplyTo() throws Exception {
        MimeMessage message = stubMimeMessage();

        mailService.sendConversationReplyEmail(
                "contact@example.com", "Carol", "Ma question", "Voici la réponse.");

        verify(mailSender).send(message);
        assertThat(message.getAllRecipients()[0].toString()).isEqualTo("contact@example.com");
        assertThat(message.getReplyTo()[0].toString()).isEqualTo(CONTACT);
    }

    @Test
    void sendContactMessageRelaysToSupportWithSenderReplyTo() {
        mailService.sendContactMessage("Dan", "dan@example.com", "Bug", "Quelque chose ne va pas.");

        ArgumentCaptor<SimpleMailMessage> captor = ArgumentCaptor.forClass(SimpleMailMessage.class);
        verify(mailSender).send(captor.capture());

        SimpleMailMessage sent = captor.getValue();
        assertThat(sent.getTo()).containsExactly(CONTACT);
        assertThat(sent.getReplyTo()).isEqualTo("dan@example.com");
        assertThat(sent.getFrom()).isEqualTo(FROM);
        assertThat(sent.getSubject()).isEqualTo("[Contact SejourFR] Bug");
        assertThat(sent.getText()).contains("Dan", "dan@example.com", "Quelque chose ne va pas.");
    }

    @Test
    void sendContactMessageWrapsSmtpFailureInIllegalState() {
        doThrow(new RuntimeException("smtp down"))
                .when(mailSender).send(any(SimpleMailMessage.class));

        assertThatThrownBy(() ->
                mailService.sendContactMessage("Eve", "eve@example.com", "Sujet", "Message"))
                .isInstanceOf(IllegalStateException.class);
    }
}
