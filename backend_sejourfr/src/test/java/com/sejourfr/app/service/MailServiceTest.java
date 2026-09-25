package com.sejourfr.app.service;

import com.sejourfr.app.service.email.MailTemplateRenderer;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.mail.MailSendException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.JavaMailSenderImpl;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** Le reliquat de MailService : l'ancien rappel d'expiration, supprime en phase 4. */
class MailServiceTest {

    @Test
    void leRappelDExpirationPartEtUnEchecNePropagePas() throws Exception {
        JavaMailSender sender = mock(JavaMailSender.class);
        when(sender.createMimeMessage()).thenAnswer(inv -> new JavaMailSenderImpl().createMimeMessage());
        MailService service = new MailService(sender, new MailTemplateRenderer(),
                "no-reply@sejourfr.fr", "https://sejourfr.fr", "support@sejourfr.fr");

        service.sendAccessExpiringSoonEmail("a@b.fr", "Ana", "Intégral", Instant.parse("2026-10-20T10:00:00Z"));

        ArgumentCaptor<MimeMessage> captor = ArgumentCaptor.forClass(MimeMessage.class);
        verify(sender).send(captor.capture());
        assertThat(captor.getValue().getSubject()).contains("se termine bientôt");

        doThrow(new MailSendException("down")).when(sender).send(any(MimeMessage.class));
        assertThatCode(() -> service.sendAccessExpiringSoonEmail("a@b.fr", null, null, null))
                .doesNotThrowAnyException();
    }
}
