package com.sejourfr.app.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Map;

/**
 * Service d'envoi d'emails.
 * <p>
 * Tous les emails clients sont des templates HTML brandés sous
 * {@code resources/mail/} (logo SejourFR en image inline CID), rendus par
 * {@link MailTemplateRenderer}. En dev on pointe sur un MailHog / Mailtrap
 * (cf. application-dev.yaml) ; un envoi raté est loggé en warn sans propager —
 * un mail ne doit jamais faire échouer la transaction métier qui l'a déclenché.
 * <p>
 * <b>Modèle commercial : achat unique (passes à durée fixe).</b> Le wording
 * client ne parle ni d'« abonnement » ni de « renouvellement automatique ». Le
 * mode abonnement récurrent reste géré, dormant : l'email d'activation s'adapte
 * via le drapeau {@code autoRenew}, et l'email de résiliation n'est déclenché
 * que par les flux abonnement (eux-mêmes dormants).
 */
@Service
public class MailService {

    private static final Logger log = LoggerFactory.getLogger(MailService.class);
    private static final String[] FRENCH_MONTHS = {
            "janvier", "février", "mars", "avril", "mai", "juin",
            "juillet", "août", "septembre", "octobre", "novembre", "décembre"
    };

    private final JavaMailSender mailSender;
    private final MailTemplateRenderer templateRenderer;
    private final String fromAddress;
    private final String appBaseUrl;
    private final String contactAddress;
    private final String backendBaseUrl;

    public MailService(
            JavaMailSender mailSender,
            MailTemplateRenderer templateRenderer,
            @Value("${sejourfr.mail.from:no-reply@sejourfr.fr}") String fromAddress,
            @Value("${sejourfr.app.base-url:http://localhost:3000}") String appBaseUrl,
            @Value("${sejourfr.contact.to:support@sejourfr.fr}") String contactAddress,
            @Value("${sejourfr.backend.base-url:http://localhost:8080}") String backendBaseUrl
    ) {
        this.mailSender = mailSender;
        this.templateRenderer = templateRenderer;
        this.fromAddress = fromAddress;
        this.appBaseUrl = appBaseUrl;
        this.contactAddress = contactAddress;
        this.backendBaseUrl = backendBaseUrl;
    }

    private static String displayNameOrFallback(String displayName) {
        if (displayName == null || displayName.isBlank()) return "à toi";
        return displayName;
    }

    private static String planOrFallback(String planName) {
        return (planName == null || planName.isBlank()) ? "Premium" : planName;
    }

    private static String formatFrenchDate(Instant t) {
        if (t == null) return "la fin de la période en cours";
        LocalDate d = t.atZone(ZoneId.of("Europe/Paris")).toLocalDate();
        return d.getDayOfMonth() + " " + FRENCH_MONTHS[d.getMonthValue() - 1] + " " + d.getYear();
    }

    /** Wording « réactivation » côté store, propre à la source de l'abonnement (flux dormant). */
    private static String reactivateHint(String source) {
        return switch (source == null ? "" : source) {
            case "APPLE" -> "Vous pouvez réactiver votre abonnement depuis Réglages → [votre nom] → Abonnements.";
            case "GOOGLE" -> "Vous pouvez réactiver votre abonnement depuis Play Store → Abonnements.";
            default -> "Vous pouvez réactiver votre abonnement à tout moment depuis votre profil.";
        };
    }

    // ------------------------------------------------------------------------
    // Authentification — mot de passe & email
    // ------------------------------------------------------------------------

    /**
     * Email de bienvenue envoyé une fois, juste après la création d'un compte
     * (inscription locale ou premier sign-in social). Best-effort / {@code @Async} :
     * un envoi raté ne doit jamais faire échouer l'inscription.
     */
    @Async
    public void sendWelcomeEmail(String to, String displayName) {
        String body = templateRenderer.render("welcome.html", Map.of(
                "greeting", displayNameOrFallback(displayName),
                "ctaUrl", appBaseUrl
        ));
        String html = renderLayout(
                "Bienvenue sur SejourFR",
                "Votre compte est créé — commencez votre entraînement civique et TCF.",
                body);
        sendHtmlWithLogo(to, "SejourFR — Bienvenue 👋", html);
    }

    public void sendPasswordResetEmail(String to, String token) {
        String link = appBaseUrl + "/reinitialiser-mot-de-passe?token=" + token;
        String body = templateRenderer.render("password-reset.html", Map.of("ctaUrl", link));
        String html = renderLayout(
                "Réinitialisation de votre mot de passe",
                "Réinitialisez votre mot de passe SejourFR — lien valable 1 heure.",
                body);
        // sendHtmlWithLogo log warn sans propager : pour des raisons de sécurité,
        // on ne révèle jamais si l'email existe ou non côté client.
        sendHtmlWithLogo(to, "SejourFR — Réinitialisation de votre mot de passe", html);
    }

    /**
     * Envoie le lien de confirmation au NOUVEL email (pas à l'ancien — on doit
     * prouver que le user contrôle bien le nouveau). Le lien pointe vers le
     * backend qui appliquera le changement et rendra une page de confirmation.
     */
    public void sendEmailChangeConfirmation(String to, String token) {
        String link = backendBaseUrl + "/api/auth/confirm-email-change?token=" + token;
        String body = templateRenderer.render("email-change.html", Map.of("ctaUrl", link));
        String html = renderLayout(
                "Confirmez votre nouvel email",
                "Confirmez votre nouvelle adresse email SejourFR — lien valable 1 heure.",
                body);
        sendHtmlWithLogo(to, "SejourFR — Confirmez votre nouvel email", html);
    }

    // ------------------------------------------------------------------------
    // Accès Premium — activation / rappel d'expiration / résiliation (dormant)
    // ------------------------------------------------------------------------

    /**
     * Email envoyé juste après l'activation d'un accès Premium. Une seule fois
     * par achat (les éventuels renouvellements du mode dormant n'en renvoient pas).
     *
     * @param planName  nom commercial du Plan (ex: « Intégral · 3 mois »)
     * @param endsAt    fin de l'accès (achat unique) ou prochain renouvellement
     * @param autoRenew {@code false} en achat unique (wording « sans
     *                  renouvellement automatique ») ; {@code true} pour un
     *                  abonnement récurrent (flux dormant)
     */
    @Async
    public void sendSubscriptionActivatedEmail(
            String to, String displayName, String planName, Instant endsAt, boolean autoRenew) {
        String plan = planOrFallback(planName);
        String accessIntro = autoRenew
                ? "Votre accès est renouvelé automatiquement. Prochain renouvellement le"
                : "Achat unique, sans abonnement ni renouvellement automatique : votre accès reste ouvert jusqu'au";
        String body = templateRenderer.render("access-activated.html", Map.of(
                "greeting", displayNameOrFallback(displayName),
                "planName", plan,
                "accessIntro", accessIntro,
                "endsLabel", formatFrenchDate(endsAt),
                "ctaUrl", appBaseUrl
        ));
        String html = renderLayout(
                "Votre accès Premium est activé",
                "Votre accès " + plan + " est activé. Tout est débloqué, c'est parti.",
                body);
        sendHtmlWithLogo(to, "SejourFR — Votre accès Premium est activé", html);
    }

    /**
     * Email envoyé quand un achat <b>prolonge</b> un accès déjà en cours (les
     * durées se cumulent). Wording distinct du premier achat
     * ({@link #sendSubscriptionActivatedEmail}) : on rassure sur le cumul plutôt
     * que de souhaiter la bienvenue.
     */
    @Async
    public void sendAccessExtendedEmail(
            String to, String displayName, String planName, Instant endsAt) {
        String plan = planOrFallback(planName);
        String body = templateRenderer.render("access-extended.html", Map.of(
                "greeting", displayNameOrFallback(displayName),
                "planName", plan,
                "endsLabel", formatFrenchDate(endsAt),
                "ctaUrl", appBaseUrl
        ));
        String html = renderLayout(
                "Votre accès a été prolongé",
                "Votre accès " + plan + " est prolongé jusqu'au " + formatFrenchDate(endsAt) + ".",
                body);
        sendHtmlWithLogo(to, "SejourFR — Votre accès a été prolongé", html);
    }

    /**
     * Rappel « votre accès se termine bientôt » pour un pass achat unique (lot 5).
     * Incite au ré-achat — pas d'abonnement, donc aucun renouvellement automatique.
     */
    public void sendAccessExpiringSoonEmail(
            String to, String displayName, String planName, Instant endsAt) {
        String plan = planOrFallback(planName);
        String body = templateRenderer.render("access-expiring.html", Map.of(
                "greeting", displayNameOrFallback(displayName),
                "planName", plan,
                "endsLabel", formatFrenchDate(endsAt),
                "ctaUrl", appBaseUrl + "/paiement"
        ));
        String html = renderLayout(
                "Votre accès se termine bientôt",
                "Votre accès " + plan + " se termine le " + formatFrenchDate(endsAt) + ".",
                body);
        sendHtmlWithLogo(to, "SejourFR — Votre accès se termine bientôt", html);
    }

    /**
     * Email envoyé quand un abonnement récurrent (flux dormant) bascule en
     * {@code CANCELED} : auto-renew désactivé, l'accès reste ouvert jusqu'à
     * {@code endsAt}. Non envoyé sur expiration naturelle ni remboursement.
     */
    @Async
    public void sendSubscriptionCanceledEmail(
            String to, String displayName, String planName, Instant endsAt, String source) {
        String plan = planOrFallback(planName);
        String body = templateRenderer.render("subscription-canceled.html", Map.of(
                "greeting", displayNameOrFallback(displayName),
                "planName", plan,
                "endsLabel", formatFrenchDate(endsAt),
                "ctaUrl", appBaseUrl,
                "reactivateHint", reactivateHint(source)
        ));
        String html = renderLayout(
                "Résiliation enregistrée",
                "Votre accès reste ouvert jusqu'au " + formatFrenchDate(endsAt) + ".",
                body);
        sendHtmlWithLogo(to, "SejourFR — Résiliation enregistrée", html);
    }

    // ------------------------------------------------------------------------
    // Rendu & envoi
    // ------------------------------------------------------------------------

    /** Injecte un fragment de contenu dans le layout commun (logo, footer, etc.). */
    private String renderLayout(String title, String preheader, String bodyHtml) {
        return templateRenderer.render("layout.html", Map.of(
                "title", title,
                "preheader", preheader,
                "body", bodyHtml,
                "year", String.valueOf(LocalDate.now(ZoneId.of("Europe/Paris")).getYear()),
                "supportEmail", contactAddress
        ));
    }

    /**
     * Envoie un email HTML avec le logo SejourFR en image inline (Content-ID
     * « logo »), lu depuis {@code static/mail/logo.png}. Un échec est loggé en
     * warn sans propager.
     */
    private void sendHtmlWithLogo(String to, String subject, String html) {
        sendHtmlWithLogo(to, subject, html, null);
    }

    private void sendHtmlWithLogo(String to, String subject, String html, String replyTo) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(
                    message, MimeMessageHelper.MULTIPART_MODE_RELATED,
                    StandardCharsets.UTF_8.name()
            );
            helper.setFrom(fromAddress);
            helper.setTo(to);
            if (replyTo != null && !replyTo.isBlank()) {
                helper.setReplyTo(replyTo);
            }
            helper.setSubject(subject);
            helper.setText(html, true);

            ClassPathResource logo = new ClassPathResource("static/mail/logo.png");
            if (logo.exists()) {
                helper.addInline("logo", logo, "image/png");
            } else {
                log.warn("Logo introuvable à static/mail/logo.png — mail envoyé sans logo.");
            }

            mailSender.send(message);
            log.info("HTML mail '{}' sent to {}", subject, to);
        } catch (MessagingException | RuntimeException e) {
            log.warn("Failed to send HTML mail '{}' to {} : {}", subject, to, e.getMessage());
        }
    }

    /**
     * Relaie un message du formulaire de contact vers l'adresse support.
     * {@code replyTo} = email de l'expéditeur pour répondre directement.
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

    /**
     * Accusé de réception envoyé à l'expéditeur du formulaire de contact, avec
     * son numéro de suivi et un rappel de son message. Best-effort et
     * {@code @Async} : son échec ne doit pas faire échouer la soumission (le
     * relai vers le support, lui, est critique). Brandé comme les autres mails
     * clients (layout + logo).
     */
    /**
     * Réponse de l'équipe support à un message du formulaire de contact, envoyée
     * à l'expéditeur. {@code Reply-To} pointe vers l'adresse support pour que sa
     * réponse éventuelle y revienne. Best-effort / {@code @Async}.
     */
    @Async
    public void sendConversationReplyEmail(
            String to, String contactName, String subject, String replyBody) {
        String body = templateRenderer.render("conversation-reply.html", Map.of(
                "greeting", displayNameOrFallback(contactName),
                "subject", subject == null ? "" : subject,
                "reply", replyBody
        ));
        String html = renderLayout(
                "Réponse à votre message",
                "Notre équipe a répondu à votre demande.",
                body);
        sendHtmlWithLogo(to, "SejourFR — Réponse à votre message", html, contactAddress);
    }

    @Async
    public void sendContactReceivedEmail(
            String to, String senderName, String subject, String message, String ticketId) {
        String body = templateRenderer.render("contact-received.html", Map.of(
                "greeting", displayNameOrFallback(senderName),
                "subject", subject,
                "message", message,
                "ticketId", ticketId
        ));
        String html = renderLayout(
                "Votre message a bien été reçu",
                "Nous avons bien reçu votre message — réponse sous 24 h ouvrées.",
                body);
        sendHtmlWithLogo(to, "SejourFR — Votre message a bien été reçu", html);
    }
}
