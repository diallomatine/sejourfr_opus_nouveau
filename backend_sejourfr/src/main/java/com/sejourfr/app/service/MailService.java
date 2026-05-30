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
        String link = appBaseUrl + "/reinitialiser-mot-de-passe?token=" + token;
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

    // ------------------------------------------------------------------------
    // Emails Premium : activation + résiliation. HTML avec logo inline (CID).
    // ------------------------------------------------------------------------

    /**
     * Email de confirmation envoyé juste après l'activation Premium. Une seule
     * fois par souscription — les renouvellements n'envoient pas de mail
     * (sinon on spam à chaque cycle).
     *
     * @param displayName prénom/nom de l'utilisateur (fallback "à toi" si vide)
     * @param planName    nom commercial du Plan (ex: "Intégral · trimestriel")
     * @param endsAt      fin de période courante (date de prochain renouvellement)
     * @param source      Stripe / Apple / Google — détermine le wording
     *                    « gestion » (page web vs Settings du store)
     */
    @Async
    public void sendSubscriptionActivatedEmail(
            String to, String displayName, String planName,
            Instant endsAt, String source) {
        String greet = displayNameOrFallback(displayName);
        String endsLabel = formatFrenchDate(endsAt);
        String manageHint = manageHint(source);
        String html = htmlLayout(
                "Votre accès Premium est activé",
                """
                <p style="margin:0 0 16px;font-size:15px;color:#0F1839;line-height:1.55;">
                  Bonjour %s,
                </p>
                <p style="margin:0 0 16px;font-size:15px;color:#0F1839;line-height:1.55;">
                  Votre abonnement <strong>%s</strong> est désormais actif. Tous les modules
                  inclus sont débloqués sur le web et l'application mobile.
                </p>
                <p style="margin:0 0 24px;font-size:15px;color:#0F1839;line-height:1.55;">
                  <strong>Prochain renouvellement automatique :</strong> %s.
                </p>
                <p style="margin:0 0 24px;">
                  <a href="%s" style="display:inline-block;padding:13px 22px;border-radius:10px;background:#1E3A8C;color:#ffffff;text-decoration:none;font-weight:700;font-size:14px;">
                    Reprendre mon entraînement
                  </a>
                </p>
                <p style="margin:0 0 8px;font-size:13px;color:#6B7299;line-height:1.55;">
                  %s
                </p>
                """.formatted(
                        escape(greet),
                        escape(planName),
                        escape(endsLabel),
                        appBaseUrl,
                        manageHint
                )
        );
        sendHtmlWithLogo(to, "SejourFR — Bienvenue dans Premium", html);
    }

    /**
     * Rappel « votre accès se termine bientôt » pour un pass one-time (lot 5).
     * Incite au ré-achat — pas d'abonnement, donc pas de renouvellement auto.
     */
    public void sendAccessExpiringSoonEmail(
            String to, String displayName, String planName, Instant endsAt) {
        String greet = displayNameOrFallback(displayName);
        String endsLabel = formatFrenchDate(endsAt);
        String html = htmlLayout(
                "Votre accès se termine bientôt",
                """
                <p style="margin:0 0 16px;font-size:15px;color:#0F1839;line-height:1.55;">
                  Bonjour %s,
                </p>
                <p style="margin:0 0 16px;font-size:15px;color:#0F1839;line-height:1.55;">
                  Votre accès <strong>%s</strong> se termine le <strong>%s</strong>. Comme
                  il s'agit d'un achat unique, il n'y a aucun renouvellement automatique :
                  pour continuer à vous entraîner après cette date, il vous suffit de
                  reprendre un accès quand vous le souhaitez.
                </p>
                <p style="margin:0 0 24px;">
                  <a href="%s/paiement" style="display:inline-block;padding:13px 22px;border-radius:10px;background:#1E3A8C;color:#ffffff;text-decoration:none;font-weight:700;font-size:14px;">
                    Prolonger mon accès
                  </a>
                </p>
                <p style="margin:0 0 8px;font-size:13px;color:#6B7299;line-height:1.55;">
                  Vos données (favoris, erreurs, progression) restent sur votre compte —
                  vous les retrouverez si vous reprenez un accès plus tard.
                </p>
                """.formatted(
                        escape(greet),
                        escape(planName),
                        escape(endsLabel),
                        appBaseUrl
                )
        );
        sendHtmlWithLogo(to, "SejourFR — Votre accès se termine bientôt", html);
    }

    /**
     * Email envoyé quand une souscription bascule en {@code CANCELED} (auto-renew
     * désactivé). Ne pas envoyer sur expiration naturelle ou refund — ces cas
     * ont leur propre sémantique.
     *
     * <p>Le texte précise que l'accès Premium reste ouvert jusqu'à {@code endsAt}
     * (cancel_at_period_end côté Stripe, idem côté store pour Apple/Google).
     */
    @Async
    public void sendSubscriptionCanceledEmail(
            String to, String displayName, String planName,
            Instant endsAt, String source) {
        String greet = displayNameOrFallback(displayName);
        String endsLabel = formatFrenchDate(endsAt);
        String reactivateHint = reactivateHint(source);
        String html = htmlLayout(
                "Résiliation enregistrée",
                """
                <p style="margin:0 0 16px;font-size:15px;color:#0F1839;line-height:1.55;">
                  Bonjour %s,
                </p>
                <p style="margin:0 0 16px;font-size:15px;color:#0F1839;line-height:1.55;">
                  Nous avons bien enregistré la résiliation de votre abonnement
                  <strong>%s</strong>. Le renouvellement automatique est désactivé.
                </p>
                <p style="margin:0 0 24px;font-size:15px;color:#0F1839;line-height:1.55;">
                  <strong>Votre accès Premium reste ouvert jusqu'au %s.</strong>
                  Continuez d'utiliser l'app comme avant d'ici là.
                </p>
                <p style="margin:0 0 24px;">
                  <a href="%s" style="display:inline-block;padding:13px 22px;border-radius:10px;background:#1E3A8C;color:#ffffff;text-decoration:none;font-weight:700;font-size:14px;">
                    Continuer mon entraînement
                  </a>
                </p>
                <p style="margin:0 0 8px;font-size:13px;color:#6B7299;line-height:1.55;">
                  %s
                </p>
                """.formatted(
                        escape(greet),
                        escape(planName),
                        escape(endsLabel),
                        appBaseUrl,
                        reactivateHint
                )
        );
        sendHtmlWithLogo(to, "SejourFR — Résiliation enregistrée", html);
    }

    // ------------------------------------------------------------------------
    // Helpers HTML — layout commun avec logo en image inline (CID).
    // ------------------------------------------------------------------------

    /**
     * Envoie un email HTML avec le logo SejourFR attaché en image inline
     * (Content-ID "logo"). Le logo est lu depuis {@code static/mail/logo.png}
     * dans le classpath. Si le mail échoue, on log warn sans propager — un
     * mail raté ne doit pas faire échouer la transaction métier qui l'a déclenché.
     */
    private void sendHtmlWithLogo(String to, String subject, String html) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(
                    message, MimeMessageHelper.MULTIPART_MODE_RELATED,
                    StandardCharsets.UTF_8.name()
            );
            helper.setFrom(fromAddress);
            helper.setTo(to);
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
     * Layout commun à tous les emails Premium : bandeau logo, titre, contenu
     * passé en paramètre, footer signature. Inline CSS uniquement — Gmail /
     * Outlook ne respectent pas {@code <style>} dans le head.
     */
    private String htmlLayout(String title, String contentHtml) {
        return """
                <!DOCTYPE html>
                <html lang="fr"><head><meta charset="UTF-8"></head>
                <body style="margin:0;padding:0;background:#F4F6FC;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;">
                  <table role="presentation" width="100%%" cellpadding="0" cellspacing="0" style="background:#F4F6FC;padding:32px 16px;">
                    <tr><td align="center">
                      <table role="presentation" width="100%%" cellpadding="0" cellspacing="0" style="max-width:560px;background:#ffffff;border-radius:16px;overflow:hidden;border:1px solid #E4E7F2;">
                        <tr><td style="padding:24px 28px 18px;border-bottom:1px solid #EEF0F8;">
                          <table role="presentation" cellpadding="0" cellspacing="0">
                            <tr>
                              <td style="vertical-align:middle;padding-right:12px;">
                                <img src="cid:logo" alt="SejourFR" width="36" height="36" style="display:block;border:0;border-radius:50%%;"/>
                              </td>
                              <td style="vertical-align:middle;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;font-size:18px;font-weight:700;color:#0F1839;letter-spacing:-0.01em;">
                                Sejour<span style="color:#E1372F;">FR</span>
                              </td>
                            </tr>
                          </table>
                        </td></tr>
                        <tr><td style="padding:24px 28px 8px;">
                          <h1 style="margin:0 0 16px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;font-size:22px;font-weight:600;color:#0F1839;letter-spacing:-0.015em;line-height:1.25;">
                            %s
                          </h1>
                          %s
                        </td></tr>
                        <tr><td style="padding:18px 28px 26px;border-top:1px solid #EEF0F8;font-size:12px;color:#9CA2BD;line-height:1.5;">
                          — L'équipe SejourFR<br/>
                          Vous recevez cet email car votre compte SejourFR est rattaché à cette adresse.
                        </td></tr>
                      </table>
                    </td></tr>
                  </table>
                </body></html>
                """.formatted(escape(title), contentHtml);
    }

    private static String displayNameOrFallback(String displayName) {
        if (displayName == null || displayName.isBlank()) return "à toi";
        return displayName;
    }

    /** Wording « gestion » côté store, propre à la source de l'abo. */
    private static String manageHint(String source) {
        return switch (source) {
            case "STRIPE" -> "Vous pouvez gérer ou résilier votre abonnement à tout moment depuis votre profil.";
            case "APPLE" -> "Votre abonnement est géré par Apple — vous pouvez le résilier à tout moment depuis Réglages → [votre nom] → Abonnements.";
            case "GOOGLE" -> "Votre abonnement est géré par Google Play — vous pouvez le résilier à tout moment depuis Play Store → Abonnements.";
            default -> "Vous pouvez gérer votre abonnement depuis votre profil.";
        };
    }

    /** Wording « réactivation » côté store, propre à la source de l'abo. */
    private static String reactivateHint(String source) {
        return switch (source) {
            case "STRIPE" -> "Vous pouvez réactiver votre abonnement à tout moment depuis votre profil.";
            case "APPLE" -> "Vous pouvez réactiver votre abonnement depuis Réglages → [votre nom] → Abonnements.";
            case "GOOGLE" -> "Vous pouvez réactiver votre abonnement depuis Play Store → Abonnements.";
            default -> "Vous pouvez réactiver votre abonnement à tout moment depuis votre profil.";
        };
    }

    private static final String[] FRENCH_MONTHS = {
            "janvier", "février", "mars", "avril", "mai", "juin",
            "juillet", "août", "septembre", "octobre", "novembre", "décembre"
    };

    private static String formatFrenchDate(Instant t) {
        if (t == null) return "la fin de la période en cours";
        LocalDate d = t.atZone(ZoneId.of("Europe/Paris")).toLocalDate();
        return d.getDayOfMonth() + " " + FRENCH_MONTHS[d.getMonthValue() - 1] + " " + d.getYear();
    }

    /** Échappement HTML basique pour les données dynamiques injectées. */
    private static String escape(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
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
