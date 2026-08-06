package com.sejourfr.app.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.config.YamlPropertiesFactoryBean;
import org.springframework.core.io.ClassPathResource;

import java.util.Map;
import java.util.Properties;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FIGE le couple « modele correcteur ⇄ tarif ».
 *
 * <p>Le cout estime d'une correction est <b>persiste</b> dans
 * {@code ai_evaluations} : un tarif faux y reste faux pour toujours, et il
 * n'existe aucun moyen de le recalculer a posteriori (les tokens sont stockes,
 * le prix du jour ne l'est pas). Le defaut vecu : le bloc {@code openai} portait
 * encore les tarifs de gpt-4o-mini (0,15 / 0,60) alors qu'on s'appretait a
 * appeler gpt-5.4, soit un facteur 17 en entree et 25 en sortie.
 *
 * <p>Ce test echoue donc des qu'on change {@code model} sans changer les deux
 * tarifs dans la meme passe. Ajouter un modele = ajouter sa ligne ici, avec le
 * prix RELEVE sur la page tarifaire du fournisseur — jamais de memoire.
 */
class EvaluationPricingTest {

    /** USD / 1M tokens {input, output}, releves le 2026-08-07. */
    private static final Map<String, double[]> TARIFS_OPENAI = Map.of(
        "gpt-5.5", new double[] {5.00, 30.00},
        "gpt-5.4", new double[] {2.50, 15.00},
        "gpt-5.4-mini", new double[] {0.75, 4.50},
        "gpt-5.2", new double[] {1.75, 14.00},
        "gpt-4o-mini", new double[] {0.15, 0.60});

    /** USD / 1M tokens {input, output} — tarif public DeepSeek. */
    private static final Map<String, double[]> TARIFS_DEEPSEEK = Map.of(
        "deepseek-v4-flash", new double[] {0.27, 1.10});

    private static final Pattern PLACEHOLDER = Pattern.compile("^\\$\\{[^:}]+:(.*)}$");

    private static Properties applicationYaml() {
        YamlPropertiesFactoryBean yaml = new YamlPropertiesFactoryBean();
        yaml.setResources(new ClassPathResource("application.yaml"));
        Properties props = yaml.getObject();
        assertThat(props).isNotNull();
        return props;
    }

    /** Valeur effective d'une propriete, placeholder {@code ${VAR:defaut}} resolu a son defaut. */
    private static String valeur(Properties yaml, String cle) {
        String brut = yaml.getProperty(cle);
        assertThat(brut).as("propriete absente : %s", cle).isNotNull();
        Matcher m = PLACEHOLDER.matcher(brut.strip());
        return m.matches() ? m.group(1).strip() : brut.strip();
    }

    private static void verifie(Properties yaml, String prefixe, Map<String, double[]> tarifs) {
        String modele = valeur(yaml, prefixe + ".model");
        assertThat(tarifs)
            .as("%s.model = '%s' : tarif inconnu. Relever le prix reel chez le fournisseur "
                + "et l'ajouter a EvaluationPricingTest — un cout invente est persiste tel quel.",
                prefixe, modele)
            .containsKey(modele);

        double[] attendu = tarifs.get(modele);
        assertThat(Double.parseDouble(valeur(yaml, prefixe + ".cost-per-million-input-tokens")))
            .as("%s : tarif d'entree incoherent avec le modele %s", prefixe, modele)
            .isEqualTo(attendu[0]);
        assertThat(Double.parseDouble(valeur(yaml, prefixe + ".cost-per-million-output-tokens")))
            .as("%s : tarif de sortie incoherent avec le modele %s", prefixe, modele)
            .isEqualTo(attendu[1]);
    }

    @Test
    void le_tarif_openai_correspond_au_modele_openai_configure() {
        verifie(applicationYaml(), "sejourfr.production-evaluation.openai", TARIFS_OPENAI);
    }

    @Test
    void le_tarif_deepseek_correspond_au_modele_deepseek_configure() {
        verifie(applicationYaml(), "sejourfr.production-evaluation.deepseek", TARIFS_DEEPSEEK);
    }
}
