package com.sejourfr.app.service.email;

import com.sejourfr.app.config.EmailProperties;
import com.sejourfr.app.enums.EmailType;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.config.YamlPropertiesFactoryBean;
import org.springframework.boot.context.properties.bind.Binder;
import org.springframework.boot.context.properties.source.MapConfigurationPropertySource;
import org.springframework.core.io.ClassPathResource;

import java.util.EnumSet;
import java.util.Properties;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 🛑 Chaque {@link EmailType} a son gabarit dans {@code application.yaml} — sujet,
 * fichiers {@code .html} et {@code .txt} — et aucun gabarit client ne parle
 * d'« offre », de prix ni de remise (brief §9). Garde-fou de la decision D-9 :
 * la table des gabarits n'a pas de defaut Java.
 */
class EmailTemplatesConfiguredTest {

    /** Seule la table des gabarits est liee : le reste du YAML porte des ${...} d'environnement. */
    private static EmailProperties bind() {
        YamlPropertiesFactoryBean yaml = new YamlPropertiesFactoryBean();
        yaml.setResources(new ClassPathResource("application.yaml"));
        Properties props = yaml.getObject();
        assertThat(props).isNotNull();
        EmailProperties p = new EmailProperties();
        p.setTemplates(new java.util.EnumMap<>(new Binder(new MapConfigurationPropertySource(props))
                .bind("sejourfr.email.templates", org.springframework.boot.context.properties.bind.Bindable
                        .mapOf(EmailType.class, EmailProperties.Template.class)).get()));
        return p;
    }

    @Test
    void chaqueTypeEstDecrit() {
        EmailProperties p = bind();
        MailTemplateRenderer renderer = new MailTemplateRenderer();

        assertThat(p.getTemplates().keySet()).containsExactlyInAnyOrderElementsOf(EnumSet.allOf(EmailType.class));
        p.getTemplates().forEach((type, t) -> {
            assertThat(t.getSubject()).as("sujet de %s", type).isNotBlank();
            assertThat(renderer.exists(t.getLocalTemplate() + ".html")).as("html de %s", type).isTrue();
            assertThat(renderer.exists(t.getLocalTemplate() + ".txt")).as("txt de %s", type).isTrue();
            assertThat(t.getBrevoTemplateId()).as("aucun id Brevo avant la bascule").isNull();
        });
    }

    @Test
    void lesMailsEngagementNeVendentRien() {
        EmailProperties p = bind();
        MailTemplateRenderer renderer = new MailTemplateRenderer();
        p.getTemplates().forEach((type, t) -> {
            if (type.category() != com.sejourfr.app.enums.EmailCategory.ENGAGEMENT) return;
            String texte = (t.getSubject() + t.getPreheader()
                    + renderer.renderText(t.getLocalTemplate() + ".html", java.util.Map.of())
                    + renderer.renderText(t.getLocalTemplate() + ".txt", java.util.Map.of())).toLowerCase();
            assertThat(texte).as("gabarit %s", type)
                    .doesNotContain("€").doesNotContain("offre").doesNotContain("remise")
                    .doesNotContain("promo").doesNotContain("/paiement").doesNotContain("abonnement");
        });
    }

    /**
     * Revue du proprietaire : aucun delai ecrit en dur (« dans 7 jours », « une
     * semaine »…) dans un mail ENGAGEMENT. Un rappel peut partir un jour de
     * rattrapage, un pass peut avoir ete prolonge : la vraie date
     * ({@code accessEndDate}) est la seule autorite.
     */
    @Test
    void aucunDelaiEcritEnDur() {
        java.util.regex.Pattern delai = java.util.regex.Pattern.compile(
                "(\\d+\\s*(jour|jours|semaine|semaines|mois|h|heures))|semaine|demain|dans \\d");
        EmailProperties p = bind();
        MailTemplateRenderer renderer = new MailTemplateRenderer();
        p.getTemplates().forEach((type, t) -> {
            if (type.category() != com.sejourfr.app.enums.EmailCategory.ENGAGEMENT) return;
            String texte = (t.getSubject() + " " + t.getPreheader() + " "
                    + renderer.renderText(t.getLocalTemplate() + ".html", java.util.Map.of()) + " "
                    + renderer.renderText(t.getLocalTemplate() + ".txt", java.util.Map.of())).toLowerCase();
            assertThat(delai.matcher(texte).find()).as("delai en dur dans %s", type).isFalse();
        });
        assertThat(p.getTemplates().get(EmailType.PREMIUM_ENDING_7_DAYS).getSubject()).contains("{{accessEndDate}}");
        assertThat(p.getTemplates().get(EmailType.PREMIUM_ENDING_2_DAYS).getSubject()).contains("{{accessEndDate}}");
    }
}
