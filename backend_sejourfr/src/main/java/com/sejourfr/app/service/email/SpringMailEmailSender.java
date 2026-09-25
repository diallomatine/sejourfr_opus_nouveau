package com.sejourfr.app.service.email;

import com.sejourfr.app.config.EmailProperties;
import com.sejourfr.app.enums.EmailProvider;
import com.sejourfr.app.enums.EmailType;
import jakarta.annotation.PostConstruct;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;

/**
 * L'implementation Spring Mail du port d'envoi — <b>le seul endroit du depot qui
 * appelle {@link JavaMailSender}</b>.
 *
 * <p>Elle porte ce qu'un provider comme Brevo fait lui-meme : resoudre le
 * gabarit local, le rendre dans le layout commun (logo par URL absolue,
 * contenu, pied, bloc de desabonnement SEULEMENT pour un mail ENGAGEMENT),
 * produire un multipart HTML + texte brut, et poser les en-tetes
 * {@code List-Unsubscribe} (RFC 8058).
 *
 * <p>Une seule tentative par appel : la relance vit dans {@link EmailService}.
 */
@Component
@ConditionalOnProperty(name = "sejourfr.email.provider", havingValue = "spring-mail", matchIfMissing = true)
public class SpringMailEmailSender implements EmailSender {

    static final String LAYOUT = "email/layout";
    static final String UNSUBSCRIBE_FRAGMENT = "email/fragments/unsubscribe";

    private final JavaMailSender mailSender;
    private final MailTemplateRenderer renderer;
    private final EmailTemplateResolver templates;
    private final EmailProperties properties;
    private final Clock clock;
    private final String supportAddress;

    public SpringMailEmailSender(JavaMailSender mailSender,
                                 MailTemplateRenderer renderer,
                                 EmailTemplateResolver templates,
                                 EmailProperties properties,
                                 Clock clock,
                                 @Value("${sejourfr.contact.to:support@sejourfr.fr}") String supportAddress) {
        this.mailSender = mailSender;
        this.renderer = renderer;
        this.templates = templates;
        this.properties = properties;
        this.clock = clock;
        this.supportAddress = supportAddress;
    }

    /** Un gabarit configure dont le fichier manque echoue au demarrage, pas au premier envoi. */
    @PostConstruct
    void verifierGabarits() {
        for (String base : new String[]{LAYOUT, UNSUBSCRIBE_FRAGMENT}) {
            exigerFichiers(base, "layout");
        }
        for (Map.Entry<EmailType, EmailProperties.Template> e : templates.all().entrySet()) {
            String local = e.getValue().getLocalTemplate();
            if (local == null || local.isBlank()) {
                throw new IllegalStateException("local-template absent pour " + e.getKey());
            }
            exigerFichiers(local, e.getKey().name());
        }
    }

    private void exigerFichiers(String base, String type) {
        for (String ext : new String[]{".html", ".txt"}) {
            if (!renderer.exists(base + ext)) {
                throw new IllegalStateException("Gabarit " + base + ext + " introuvable (" + type + ")");
            }
        }
    }

    @Override
    public EmailProvider provider() {
        return EmailProvider.SPRING_MAIL;
    }

    @Override
    public String send(EmailMessage message) {
        Rendered rendered = render(message);
        try {
            MimeMessage mime = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(
                    mime, MimeMessageHelper.MULTIPART_MODE_MIXED_RELATED, StandardCharsets.UTF_8.name());
            helper.setFrom(properties.getFrom());
            helper.setReplyTo(properties.getReplyTo());
            helper.setTo(message.recipient());
            helper.setSubject(rendered.subject());
            helper.setText(rendered.text(), rendered.html());
            if (message.oneClickUnsubscribeUrl() != null) {
                mime.setHeader("List-Unsubscribe", "<" + message.oneClickUnsubscribeUrl() + ">");
                mime.setHeader("List-Unsubscribe-Post", "List-Unsubscribe=One-Click");
            }
            mailSender.send(mime);
            return null;
        } catch (MessagingException | MailException e) {
            throw new EmailSendException(EmailErrors.sanitize(e));
        }
    }

    @Override
    public void relayToSupport(SupportRelayMessage message) {
        try {
            SimpleMailMessage mail = new SimpleMailMessage();
            mail.setFrom(properties.getFrom());
            mail.setTo(supportAddress);
            mail.setReplyTo(message.replyTo());
            mail.setSubject(message.subject());
            mail.setText(message.textBody());
            mailSender.send(mail);
        } catch (MailException e) {
            throw new EmailSendException(EmailErrors.sanitize(e));
        }
    }

    /** Le rendu complet d'un message : sujet, HTML dans le layout, texte dans le layout. */
    public record Rendered(String subject, String html, String text) {}

    /** Public pour que les tests verifient qu'aucun gabarit ne laisse de placeholder. */
    public Rendered render(EmailMessage message) {
        EmailProperties.Template template = templates.resolve(message.type());
        Map<String, String> vars = message.variables();
        String subject = renderer.renderInline(template.getSubject(), vars);

        String bodyHtml = renderer.render(template.getLocalTemplate() + ".html", vars);
        String bodyText = renderer.renderText(template.getLocalTemplate() + ".txt", vars);

        String unsubscribeHtml = "";
        String unsubscribeText = "";
        if (message.unsubscribeUrl() != null) {
            Map<String, String> u = Map.of("unsubscribeUrl", message.unsubscribeUrl());
            unsubscribeHtml = renderer.render(UNSUBSCRIBE_FRAGMENT + ".html", u);
            unsubscribeText = renderer.renderText(UNSUBSCRIBE_FRAGMENT + ".txt", u);
        }

        Map<String, String> layout = new HashMap<>();
        layout.put("subject", subject);
        layout.put("preheader", renderer.renderInline(template.getPreheader(), vars));
        layout.put("logoUrl", properties.getLogoUrl());
        layout.put("supportEmail", supportAddress);
        layout.put("year", String.valueOf(LocalDate.now(clock.withZone(EmailFormats.PARIS)).getYear()));

        Map<String, String> htmlLayout = new HashMap<>(layout);
        htmlLayout.put("body", bodyHtml);
        htmlLayout.put("unsubscribeBlock", unsubscribeHtml);
        Map<String, String> textLayout = new HashMap<>(layout);
        textLayout.put("body", bodyText.strip());
        textLayout.put("unsubscribeBlock", unsubscribeText.strip());

        return new Rendered(subject,
                renderer.render(LAYOUT + ".html", htmlLayout),
                renderer.renderText(LAYOUT + ".txt", textLayout));
    }
}
