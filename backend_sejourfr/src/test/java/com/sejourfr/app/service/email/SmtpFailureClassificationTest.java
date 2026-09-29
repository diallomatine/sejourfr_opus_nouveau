package com.sejourfr.app.service.email;

import jakarta.mail.Address;
import jakarta.mail.MessagingException;
import jakarta.mail.SendFailedException;
import jakarta.mail.internet.AddressException;
import jakarta.mail.internet.InternetAddress;
import org.eclipse.angus.mail.smtp.SMTPAddressFailedException;
import org.eclipse.angus.mail.smtp.SMTPSendFailedException;
import org.junit.jupiter.api.Test;
import org.springframework.mail.MailAuthenticationException;
import org.springframework.mail.MailSendException;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Classement d'un echec SMTP : PROPRE AU DESTINATAIRE (la campagne continue)
 * ou SYSTEMIQUE (elle s'arrete). En cas de doute : systemique.
 */
class SmtpFailureClassificationTest {

    private static MailSendException rcptRefused(int code, String reply) throws Exception {
        InternetAddress bad = new InternetAddress("bob@example.fr");
        SMTPAddressFailedException rcpt = new SMTPAddressFailedException(bad, "RCPT TO:<bob@example.fr>", code, reply);
        SendFailedException invalid = new SendFailedException("Invalid Addresses", rcpt,
                new Address[0], new Address[0], new Address[]{bad});
        return new MailSendException(Map.of(new Object(), invalid));
    }

    @Test
    void refus5xxSurLAdresseEstPropreAuDestinataire() throws Exception {
        assertThat(SpringMailEmailSender.recipientRejected(rcptRefused(550, "550 5.1.1 User unknown"))).isTrue();
        assertThat(SpringMailEmailSender.recipientRejected(rcptRefused(553, "553 5.1.3 Bad address"))).isTrue();
        assertThat(SpringMailEmailSender.recipientRejected(rcptRefused(501, "501 5.1.3 Bad syntax"))).isTrue();
    }

    @Test
    void adresseIllisibleEstPropreAuDestinataire() {
        assertThat(SpringMailEmailSender.recipientRejected(new AddressException("Illegal address", "bob@"))).isTrue();
    }

    @Test
    void limiteDeDebitEstSystemique() throws Exception {
        SMTPSendFailedException mailFrom = new SMTPSendFailedException("MAIL FROM", 450,
                "450 4.7.1 <s@sejourfr.fr>: max 240 mails per sender 1h", null, null, null, null);
        assertThat(SpringMailEmailSender.recipientRejected(new MailSendException(Map.of(new Object(), mailFrom))))
                .isFalse();
        // Meme posee sur l'adresse, une limite 4xx n'est pas la faute du destinataire.
        assertThat(SpringMailEmailSender.recipientRejected(
                rcptRefused(450, "450 4.7.1 max 240 mails per sender 1h"))).isFalse();
        assertThat(SpringMailEmailSender.recipientRejected(
                rcptRefused(550, "550 5.7.1 max 240 mails per sender 1h"))).isFalse();
    }

    @Test
    void connexionEtAuthSontSystemiques() {
        assertThat(SpringMailEmailSender.recipientRejected(new MailSendException("Mail server connection failed",
                new MessagingException("Couldn't connect to host, port: mail.sejourfr.fr, 587")))).isFalse();
        assertThat(SpringMailEmailSender.recipientRejected(
                new MailAuthenticationException("535 5.7.8 Authentication failed"))).isFalse();
        assertThat(SpringMailEmailSender.recipientRejected(new RuntimeException("boom"))).isFalse();
    }
}
