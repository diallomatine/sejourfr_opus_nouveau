package com.sejourfr.app.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.config.YamlPropertiesFactoryBean;
import org.springframework.core.io.ClassPathResource;

import java.util.List;
import java.util.Properties;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FIGE le fait que les URLs publiques des liens d'email sont pilotables par
 * variable d'environnement <b>dans le fichier de base</b>, pas seulement dans le
 * profil {@code prod}.
 *
 * <p>Motif, vecu en production : le mail de bienvenue envoyait « Commencer mon
 * entrainement » vers {@code http://localhost:3000}. La cause n'etait pas dans
 * {@code MailService} — {@code sejourfr.app.base-url} n'existait que dans
 * {@code application-prod.yaml}. Une instance demarree sans ce profil ignorait
 * donc {@code APP_BASE_URL}, meme correctement posee dans l'environnement, et
 * retombait sur le defaut Java du {@code @Value} (localhost). Une URL de lien
 * d'email ne doit jamais dependre du profil actif : elle depend de
 * l'environnement.
 *
 * <p>{@code sejourfr.backend.base-url}, lui, n'etait declare <b>nulle part</b> :
 * le lien de confirmation de changement d'email pointait sur
 * {@code localhost:8080} y compris en production.
 */
class MailLinkBaseUrlsTest {

    /** Cle YAML -> variable d'environnement qui doit la piloter. */
    private static final List<String[]> CLES_PILOTEES = List.of(
        new String[] {"sejourfr.app.base-url", "APP_BASE_URL"},
        new String[] {"sejourfr.backend.base-url", "BACKEND_BASE_URL"},
        new String[] {"sejourfr.stripe.app-base-url", "APP_BASE_URL"});

    private static Properties yaml(String fichier) {
        YamlPropertiesFactoryBean yaml = new YamlPropertiesFactoryBean();
        yaml.setResources(new ClassPathResource(fichier));
        Properties props = yaml.getObject();
        assertThat(props).isNotNull();
        return props;
    }

    @Test
    void le_fichier_de_base_lit_les_urls_publiques_dans_l_environnement() {
        Properties base = yaml("application.yaml");

        for (String[] cle : CLES_PILOTEES) {
            assertThat(base.getProperty(cle[0]))
                .as("%s doit etre declare dans application.yaml, sinon la variable %s "
                    + "est ignoree des qu'on demarre sans le profil prod", cle[0], cle[1])
                .isNotNull()
                .startsWith("${" + cle[1] + ":");
        }
    }

    @Test
    void le_profil_prod_ne_retombe_jamais_sur_localhost() {
        Properties prod = yaml("application-prod.yaml");

        for (String[] cle : CLES_PILOTEES) {
            String valeur = prod.getProperty(cle[0]);
            assertThat(valeur)
                .as("%s doit etre declare dans application-prod.yaml", cle[0])
                .isNotNull()
                .startsWith("${" + cle[1] + ":");
            assertThat(valeur)
                .as("%s : un repli sur localhost enverrait un lien mort a un vrai "
                    + "utilisateur", cle[0])
                .doesNotContain("localhost");
        }
    }
}
