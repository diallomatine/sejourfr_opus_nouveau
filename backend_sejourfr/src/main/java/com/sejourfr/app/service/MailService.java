package com.sejourfr.app.service;

import com.sejourfr.app.service.email.EmailErrors;
import com.sejourfr.app.service.email.MailTemplateRenderer;
import com.sejourfr.app.util.LogMask;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Map;

/**
 * ⚠️ <b>RELIQUAT, supprime en phase 4 du chantier emails</b> avec
 * {@code ExpiryReminderJob}, son seul appelant (arbitrage n°6 : l'ancien rappel
 * d'expiration disparait quand {@code PREMIUM_ENDING_*} est en service).
 *
 * <p>Tous les autres mails passent par le port {@code EmailSender}
 * (docs/regles/emails.md).
 */
@Service
@Slf4j
public class MailService {

    private static final String[] FRENCH_MONTHS = {
            "janvier", "février", "mars", "avril", "mai", "juin",
            "juillet", "août", "septembre", "octobre", "novembre", "décembre"
    };

    private final JavaMailSender mailSender;
    private final MailTemplateRenderer templateRenderer;
    private final String fromAddress;
    private final String appBaseUrl;
    private final String contactAddress;

    public MailService(
            JavaMailSender mailSender,
            MailTemplateRenderer templateRenderer,
            @Value("${sejourfr.mail.from:no-reply@sejourfr.fr}") String fromAddress,
            @Value("${sejourfr.app.base-url:http://localhost:3000}") String appBaseUrl,
            @Value("${sejourfr.contact.to:support@sejourfr.fr}") String contactAddress
    ) {
        this.mailSender = mailSender;
        this.templateRenderer = templateRenderer;
        this.fromAddress = fromAddress;
        this.appBaseUrl = appBaseUrl;
        this.contactAddress = contactAddress;
    }

    private static String formatFrenchDate(Instant t) {
        if (t == null) return "la fin de la période en cours";
        LocalDate d = t.atZone(ZoneId.of("Europe/Paris")).toLocalDate();
        return d.getDayOfMonth() + " " + FRENCH_MONTHS[d.getMonthValue() - 1] + " " + d.getYear();
    }

    /** Rappel « votre accès se termine bientôt » (ancien job, supprimé en phase 4). */
    public void sendAccessExpiringSoonEmail(
            String to, String displayName, String planName, Instant endsAt) {
        String plan = (planName == null || planName.isBlank()) ? "Premium" : planName;
        String greeting = (displayName == null || displayName.isBlank()) ? "à toi" : displayName;
        String body = templateRenderer.render("mail/access-expiring.html", Map.of(
                "greeting", greeting,
                "planName", plan,
                "endsLabel", formatFrenchDate(endsAt),
                "ctaUrl", appBaseUrl + "/paiement"
        ));
        String html = templateRenderer.render("mail/layout.html", Map.of(
                "title", "Votre accès se termine bientôt",
                "preheader", "Votre accès " + plan + " se termine le " + formatFrenchDate(endsAt) + ".",
                "body", body,
                "year", String.valueOf(LocalDate.now(ZoneId.of("Europe/Paris")).getYear()),
                "supportEmail", contactAddress
        ));
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(
                    message, MimeMessageHelper.MULTIPART_MODE_RELATED, StandardCharsets.UTF_8.name());
            helper.setFrom(fromAddress);
            helper.setTo(to);
            helper.setSubject("SejourFR — Votre accès se termine bientôt");
            helper.setText(html, true);
            ClassPathResource logo = new ClassPathResource("static/mail/logo.png");
            if (logo.exists()) {
                helper.addInline("logo", logo, "image/png");
            }
            mailSender.send(message);
            log.info("Rappel d'expiration envoye a {}", LogMask.email(to));
        } catch (MessagingException | RuntimeException e) {
            log.warn("Rappel d'expiration non envoye a {} : {}", LogMask.email(to), EmailErrors.sanitize(e));
        }
    }
}
