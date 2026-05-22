package com.sejourfr.app.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

/**
 * Service d'envoi d'emails.
 *
 * En dev : on s'attend à pointer sur un MailHog ou un Mailtrap local
 * (cf. application-dev.yaml). Si JavaMailSender n'est pas configuré,
 * on log juste le mail sans l'envoyer — utile pour les tests locaux.
 */
@Service
public class MailService {

    private static final Logger log = LoggerFactory.getLogger(MailService.class);

    private final JavaMailSender mailSender;
    private final String fromAddress;
    private final String appBaseUrl;
    private final String contactAddress;
    private final String backendBaseUrl;

    public MailService(
            JavaMailSender mailSender,
            @Value("${sejourfr.mail.from:no-reply@sejourfr.fr}") String fromAddress,
            @Value("${sejourfr.app.base-url:http://localhost:3000}") String appBaseUrl,
            @Value("${sejourfr.contact.to:hello@sejourfr.fr}") String contactAddress,
            @Value("${sejourfr.backend.base-url:http://localhost:8080}") String backendBaseUrl
    ) {
        this.mailSender = mailSender;
        this.fromAddress = fromAddress;
        this.appBaseUrl = appBaseUrl;
        this.contactAddress = contactAddress;
        this.backendBaseUrl = backendBaseUrl;
    }

    public void sendPasswordResetEmail(String to, String token) {
        String link = appBaseUrl + "/reset-password?token=" + token;
        String body = """
                Bonjour,

                Vous avez demandé la réinitialisation de votre mot de passe SejourFR.

                Cliquez sur le lien suivant (valable 1 heure) :
                %s

                Si vous n'êtes pas à l'origine de cette demande, vous pouvez
                ignorer cet email — votre mot de passe reste inchangé.

                — L'équipe SejourFR
                """.formatted(link);

        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromAddress);
            message.setTo(to);
            message.setSubject("SejourFR — Réinitialisation de votre mot de passe");
            message.setText(body);
            mailSender.send(message);
            log.info("Password reset email sent to {}", to);
        } catch (Exception e) {
            // On log mais on ne lève pas : pour des raisons de sécurité, on ne
            // veut pas que le client puisse déduire si l'email existe ou non.
            log.warn("Failed to send password reset email to {} : {}", to, e.getMessage());
        }
    }

    /**
     * Envoie le lien de confirmation au NOUVEL email (pas à l'ancien — on
     * doit prouver que le user contrôle bien le nouveau). Le lien pointe
     * directement vers le backend qui appliquera le changement et rendra une
     * page HTML statique de confirmation.
     */
    public void sendEmailChangeConfirmation(String to, String token) {
        String link = backendBaseUrl + "/api/auth/confirm-email-change?token=" + token;
        String body = """
                Bonjour,

                Vous avez demandé à changer l'email associé à votre compte SejourFR.

                Cliquez sur le lien suivant (valable 1 heure) pour confirmer
                ce nouvel email :
                %s

                Si vous n'êtes pas à l'origine de cette demande, ignorez cet
                email — votre compte reste accessible avec son adresse actuelle.

                — L'équipe SejourFR
                """.formatted(link);

        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromAddress);
            message.setTo(to);
            message.setSubject("SejourFR — Confirmez votre nouvel email");
            message.setText(body);
            mailSender.send(message);
            log.info("Email change confirmation sent to {}", to);
        } catch (Exception e) {
            log.warn("Failed to send email change confirmation to {} : {}", to, e.getMessage());
        }
    }

    /**
     * Relaie un message du formulaire de contact (web ou mobile) vers
     * l'adresse support. `replyTo` est positionné sur l'email de l'expéditeur
     * pour que répondre depuis l'inbox support tombe directement chez la
     * bonne personne.
     */
    public void sendContactMessage(String senderName, String senderEmail, String subject, String message) {
        String body = """
                Nouveau message via le formulaire de contact SejourFR.

                De      : %s <%s>
                Sujet   : %s

                --------
                %s
                --------
                """.formatted(senderName, senderEmail, subject, message);

        try {
            SimpleMailMessage mail = new SimpleMailMessage();
            mail.setFrom(fromAddress);
            mail.setTo(contactAddress);
            mail.setReplyTo(senderEmail);
            mail.setSubject("[Contact SejourFR] " + subject);
            mail.setText(body);
            mailSender.send(mail);
            log.info("Contact message relayed from {} to {}", senderEmail, contactAddress);
        } catch (Exception e) {
            log.error("Failed to relay contact message from {} : {}", senderEmail, e.getMessage());
            throw new IllegalStateException("Impossible d'envoyer votre message. Réessayez plus tard.", e);
        }
    }
}
