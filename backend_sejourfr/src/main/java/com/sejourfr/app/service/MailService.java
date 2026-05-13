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

    public MailService(
            JavaMailSender mailSender,
            @Value("${sejourfr.mail.from:no-reply@sejourfr.fr}") String fromAddress,
            @Value("${sejourfr.app.base-url:http://localhost:3000}") String appBaseUrl
    ) {
        this.mailSender = mailSender;
        this.fromAddress = fromAddress;
        this.appBaseUrl = appBaseUrl;
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
}
