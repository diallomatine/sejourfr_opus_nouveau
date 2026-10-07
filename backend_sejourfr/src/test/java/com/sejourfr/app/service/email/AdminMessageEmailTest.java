package com.sejourfr.app.service.email;

import com.sejourfr.app.config.EmailProperties;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.service.email.compose.SupportEmailComposer;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mail.javamail.JavaMailSender;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

/**
 * Le gabarit {@code ADMIN_MESSAGE} (D-58) rendu dans le layout commun : le texte
 * libre de l'admin est ECHAPPE en HTML, ses sauts de ligne preserves, le texte
 * brut reste lisible, et ni lien de desabonnement ni placeholder ne subsistent.
 */
class AdminMessageEmailTest {

    private static final String CORPS = "Voici <script>alert('x')</script> & co.\r\nLigne deux\n\nNouveau paragraphe : https://sejourfr.fr/aide";

    private SpringMailEmailSender sender;

    @BeforeEach
    void setUp() {
        EmailProperties props = EmailTestFixtures.properties();
        props.setFrom("SejourFR <no-reply@sejourfr.fr>");
        props.setReplyTo("support@sejourfr.fr");
        props.setLogoUrl("https://sejourfr.fr/logo_sejourFR.png");
        EmailProperties.Template t = new EmailProperties.Template();
        t.setSubject("{{subject}}");
        t.setPreheader("{{excerpt}}");
        t.setLocalTemplate("email/admin-message");
        props.getTemplates().put(EmailType.ADMIN_MESSAGE, t);
        sender = new SpringMailEmailSender(mock(JavaMailSender.class), new MailTemplateRenderer(),
                new EmailTemplateResolver(props), props,
                Clock.fixed(Instant.parse("2026-10-07T08:00:00Z"), ZoneOffset.UTC), "support@sejourfr.fr");
        sender.verifierGabarits();
    }

    private SpringMailEmailSender.Rendered render(String firstName, String subject, String body) {
        return sender.render(new EmailMessage("alice@example.com", EmailType.ADMIN_MESSAGE,
                SupportEmailComposer.adminMessageVariables(firstName, subject, body), null, null));
    }

    @Test
    void htmlEchappeEtSautsDeLignePreserves() {
        SpringMailEmailSender.Rendered r = render("Alice", "Votre accès <TCF>", CORPS);

        assertThat(r.subject()).isEqualTo("Votre accès <TCF>");
        assertThat(r.html())
                .doesNotContain("<script>")
                .contains("Voici &lt;script&gt;alert(&#39;x&#39;)&lt;/script&gt; &amp; co.<br/>")
                .contains("Ligne deux<br/>\n<br/>\nNouveau paragraphe")
                .contains("Votre accès &lt;TCF&gt;")
                .contains("Bonjour Alice,")
                .contains("Message de l'équipe SejourFR")
                .contains("L'équipe SejourFR")
                .contains("mailto:support@sejourfr.fr")
                .contains("https://sejourfr.fr/logo_sejourFR.png")
                .doesNotContain("Ne plus recevoir")
                .doesNotContain("{{");
        assertThat(r.html()).as("aucun lien fabrique a partir du texte")
                .doesNotContain("href=\"https://sejourfr.fr/aide");
    }

    @Test
    void texteBrutLisibleSansBalise() {
        SpringMailEmailSender.Rendered r = render(null, "Objet", CORPS);

        assertThat(r.text())
                .contains("Bonjour,")
                .contains("Voici <script>alert('x')</script> & co.\nLigne deux\n\nNouveau paragraphe")
                .contains("L'équipe SejourFR")
                .contains("Écrivez-nous à support@sejourfr.fr")
                .doesNotContain("<br/>")
                .doesNotContain("\r")
                .doesNotContain("{{");
    }

    @Test
    void preheaderEstLeDebutDuMessageSurUneLigne() {
        String long_ = "Mot ".repeat(60);
        SpringMailEmailSender.Rendered r = render("Alice", "Objet", "Premier\nmessage " + long_);

        String excerpt = EmailFormats.excerpt("Premier\nmessage " + long_, 110);
        assertThat(excerpt).startsWith("Premier message Mot").endsWith("…").hasSizeLessThanOrEqualTo(111);
        assertThat(r.html()).contains(excerpt);
    }

    @Test
    void formatsDuTexteLibre() {
        assertThat(EmailFormats.multilineHtml(" a\r\nb\rc ")).isEqualTo("a<br/>\nb<br/>\nc");
        assertThat(EmailFormats.multilineHtml(null)).isEmpty();
        assertThat(EmailFormats.excerpt("court", 110)).isEqualTo("court");
    }
}
