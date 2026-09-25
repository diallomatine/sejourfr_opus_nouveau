package com.sejourfr.app.service.email;

import com.sejourfr.app.config.EmailProperties;
import com.sejourfr.app.enums.EmailType;
import jakarta.mail.BodyPart;
import jakarta.mail.Multipart;
import jakarta.mail.Part;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.mail.MailSendException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.JavaMailSenderImpl;

import java.io.IOException;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Le rendu et la mise en forme MIME du provider Spring Mail : multipart HTML +
 * texte, layout commun, logo par URL, desabonnement et {@code List-Unsubscribe}
 * SEULEMENT pour un mail ENGAGEMENT. {@link JavaMailSender} est mocke.
 */
class SpringMailEmailSenderTest {

    private JavaMailSender javaMailSender;
    private SpringMailEmailSender sender;

    @BeforeEach
    void setUp() {
        javaMailSender = mock(JavaMailSender.class);
        when(javaMailSender.createMimeMessage()).thenAnswer(inv -> new JavaMailSenderImpl().createMimeMessage());
        EmailProperties props = EmailTestFixtures.properties();
        props.setFrom("SejourFR <no-reply@sejourfr.fr>");
        props.setReplyTo("support@sejourfr.fr");
        props.setLogoUrl("https://sejourfr.fr/logo_sejourFR.png");
        sender = new SpringMailEmailSender(javaMailSender, new MailTemplateRenderer(),
                new EmailTemplateResolver(props), props,
                Clock.fixed(Instant.parse("2026-09-25T08:00:00Z"), ZoneOffset.UTC), "support@sejourfr.fr");
        sender.verifierGabarits();
    }

    private MimeMessage sent() {
        ArgumentCaptor<MimeMessage> captor = ArgumentCaptor.forClass(MimeMessage.class);
        verify(javaMailSender).send(captor.capture());
        MimeMessage m = captor.getValue();
        try {
            m.saveChanges();
        } catch (jakarta.mail.MessagingException e) {
            throw new IllegalStateException(e);
        }
        return m;
    }

    private static List<String> parts(Part part, String mime) throws Exception {
        List<String> out = new ArrayList<>();
        if (part.isMimeType(mime)) {
            out.add((String) part.getContent());
        } else if (part.getContent() instanceof Multipart mp) {
            for (int i = 0; i < mp.getCount(); i++) {
                BodyPart bp = mp.getBodyPart(i);
                out.addAll(parts(bp, mime));
            }
        }
        return out;
    }

    @Test
    void unMailRequiredEstMultipartSansDesabonnement() throws Exception {
        sender.send(new EmailMessage("alice@example.com", EmailType.WELCOME,
                Map.of("firstName", "Alice", "greeting", "Bonjour Alice", "appUrl", "https://sejourfr.fr/dashboard"),
                null, null));

        MimeMessage m = sent();
        assertThat(m.getSubject()).isEqualTo("Bienvenue sur SejourFR");
        assertThat(m.getFrom()[0].toString()).contains("SejourFR").contains("no-reply@sejourfr.fr");
        assertThat(m.getReplyTo()[0].toString()).isEqualTo("support@sejourfr.fr");
        assertThat(m.getHeader("List-Unsubscribe")).isNull();
        List<String> html = parts(m, "text/html");
        List<String> text = parts(m, "text/plain");
        assertThat(html).hasSize(1);
        assertThat(text).hasSize(1);
        assertThat(html.getFirst()).contains("Bonjour Alice").contains("https://sejourfr.fr/logo_sejourFR.png")
                .contains("https://sejourfr.fr/dashboard").doesNotContain("Ne plus recevoir")
                .doesNotContain("{{").doesNotContain("cid:");
        assertThat(text.getFirst()).contains("Bonjour Alice").doesNotContain("<p").doesNotContain("{{");
    }

    @Test
    void unMailEngagementPorteLeDesabonnementEtLesEntetesRfc8058() throws Exception {
        sender.send(new EmailMessage("alice@example.com", EmailType.DIAGNOSTIC_PLAN_READY,
                Map.of("firstName", "Alice", "greeting", "Bonjour Alice", "diagnosticType", "TCF",
                        "planUrl", "https://sejourfr.fr/plan?module=TCF", "prioritiesIntro", "Vos premières priorités :",
                        "priority1", "Organiser un texte", "priority2", "", "priority3", ""),
                "https://api/unsub?token=T", "https://api/one-click?token=T"));

        MimeMessage m = sent();
        assertThat(m.getHeader("List-Unsubscribe")[0]).isEqualTo("<https://api/one-click?token=T>");
        assertThat(m.getHeader("List-Unsubscribe-Post")[0]).isEqualTo("List-Unsubscribe=One-Click");
        String html = parts(m, "text/html").getFirst();
        assertThat(html).contains("Ne plus recevoir les conseils et rappels d'entraînement")
                .contains("https://api/unsub?token=T").contains("Organiser un texte");
        assertThat(parts(m, "text/plain").getFirst()).contains("https://api/unsub?token=T");
    }

    @Test
    void lePreheaderEtLeSujetSubstituentLesVariables() throws Exception {
        SpringMailEmailSender.Rendered r = sender.render(new EmailMessage("a@b.fr",
                EmailType.DIAGNOSTIC_PLAN_READY, Map.of("diagnosticType", "civique"), null, null));

        assertThat(r.html()).contains("Diagnostic civique terminé");
    }

    @Test
    void unEchecSmtpDevientUneEmailSendExceptionAssainie() {
        doThrow(new MailSendException("refused bob@victime.fr")).when(javaMailSender).send(any(MimeMessage.class));

        assertThatThrownBy(() -> sender.send(new EmailMessage("bob@victime.fr", EmailType.WELCOME,
                Map.of(), null, null)))
                .isInstanceOf(EmailSendException.class)
                .hasMessageNotContaining("bob@victime.fr");
    }

    @Test
    void leRelaisSupportEstSynchroneEtPropage() {
        sender.relayToSupport(new SupportRelayMessage("dan@example.com", "[Contact SejourFR] Bug", "Corps"));
        ArgumentCaptor<SimpleMailMessage> captor = ArgumentCaptor.forClass(SimpleMailMessage.class);
        verify(javaMailSender).send(captor.capture());
        assertThat(captor.getValue().getTo()).containsExactly("support@sejourfr.fr");
        assertThat(captor.getValue().getReplyTo()).isEqualTo("dan@example.com");

        doThrow(new MailSendException("down")).when(javaMailSender).send(any(SimpleMailMessage.class));
        assertThatThrownBy(() -> sender.relayToSupport(new SupportRelayMessage("d@e.fr", "s", "b")))
                .isInstanceOf(EmailSendException.class);
    }

    @Test
    void unGabaritConfigureSansFichierEchoueAuDemarrage() throws IOException {
        EmailProperties props = EmailTestFixtures.properties();
        props.getTemplates().get(EmailType.WELCOME).setLocalTemplate("email/nexiste-pas");
        SpringMailEmailSender s = new SpringMailEmailSender(javaMailSender, new MailTemplateRenderer(),
                new EmailTemplateResolver(props), props, Clock.systemUTC(), "support@sejourfr.fr");

        assertThatThrownBy(s::verifierGabarits).isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("email/nexiste-pas");
    }

    /** Revue D-17 : sans priorite, le bloc disparait ENTIER, en HTML comme en texte. */
    @Test
    void sansPrioriteLeBlocEstAbsentDesDeuxParties() {
        java.util.Map<String, String> vars = new java.util.HashMap<>(Map.of("firstName", "Alice",
                "greeting", "Bonjour Alice", "diagnosticType", "TCF", "planUrl", "https://sejourfr.fr/plan?module=TCF"));
        vars.putAll(Map.of("prioritiesIntro", "", "priority1", "", "priority2", "", "priority3", ""));

        SpringMailEmailSender.Rendered vide = sender.render(new EmailMessage("a@b.fr",
                EmailType.DIAGNOSTIC_PLAN_READY, vars, null, null));

        assertThat(vide.html()).doesNotContain("priorités").doesNotContain("font-weight:700;\"></p>")
                .doesNotContain("{{").contains("Voir mon plan");
        assertThat(vide.text()).doesNotContain("priorités").doesNotContain("\n\n\n")
                .contains("Voir mon plan");

        vars.putAll(Map.of("prioritiesIntro", "Vos premières priorités :", "priority1", "Organiser un texte",
                "priority2", "Argumenter"));
        SpringMailEmailSender.Rendered deux = sender.render(new EmailMessage("a@b.fr",
                EmailType.DIAGNOSTIC_PLAN_READY, vars, null, null));

        assertThat(deux.html()).contains("Vos premières priorités :").contains("Organiser un texte")
                .contains("Argumenter").doesNotContain("font-weight:700;\"></p>");
        assertThat(deux.text()).contains("Vos premières priorités :\nOrganiser un texte\nArgumenter\n");
    }

    @Test
    void unMailRequiredNeGardeAucuneTraceDuBlocDeDesabonnement() {
        SpringMailEmailSender.Rendered r = sender.render(new EmailMessage("a@b.fr", EmailType.WELCOME,
                Map.of("firstName", "", "greeting", "Bonjour", "appUrl", "https://sejourfr.fr"), null, null));

        assertThat(r.html()).doesNotContain("unsubscribe").doesNotContain("rappels d'entraînement");
        assertThat(r.text()).doesNotContain("\n\n\n");
    }
}
