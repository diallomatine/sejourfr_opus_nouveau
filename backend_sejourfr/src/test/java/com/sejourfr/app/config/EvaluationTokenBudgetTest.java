package com.sejourfr.app.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.config.YamlPropertiesFactoryBean;
import org.springframework.core.io.ClassPathResource;

import java.util.List;
import java.util.Properties;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FIGE le plafond de tokens de SORTIE du correcteur, et la raison de sa valeur.
 *
 * <p>Ce plafond n'est pas un reglage de confort : quand il est atteint, le
 * fournisseur coupe la reponse en plein JSON ({@code finish_reason=length}), le
 * {@code tool_call} devient indeserialisable et la <b>soumission echoue</b> —
 * le candidat ne voit pas sa note. Il etait a 2000 depuis mai 2026, avant que le
 * contrat de sortie strict n'ajoute QUATRE citations litterales (une par
 * critere). Mesure du diagnostic : ~1500 tokens pour une correction ecrite,
 * 1800-2000 pour une correction orale — donc le plafond etait atteint ou frole
 * sur presque toutes les corrections orales. Le meme appel a 4000 passe
 * (~2300 tokens produits).
 *
 * <p>C'est un PLAFOND, pas une consommation : on ne paie que les tokens
 * reellement produits. Le relever ne coute rien sur les corrections courtes.
 *
 * <p>Les trois providers partagent la meme valeur : changer de correcteur
 * ({@code EVAL_LLM_PROVIDER}) ne doit jamais changer, en douce, la longueur de
 * reponse autorisee.
 */
class EvaluationTokenBudgetTest {

    /** Marge mesuree : sortie orale la plus longue observee ~2300 tokens. */
    private static final int PLAFOND_ATTENDU = 4000;

    private static final List<String> CLES_MAX_TOKENS = List.of(
        "sejourfr.production-evaluation.openai.max-tokens",
        "sejourfr.production-evaluation.anthropic.max-tokens",
        "sejourfr.production-evaluation.deepseek.max-tokens");

    private static Properties applicationYaml() {
        YamlPropertiesFactoryBean yaml = new YamlPropertiesFactoryBean();
        yaml.setResources(new ClassPathResource("application.yaml"));
        Properties props = yaml.getObject();
        assertThat(props).isNotNull();
        return props;
    }

    @Test
    void les_trois_correcteurs_plafonnent_leur_sortie_a_4000_tokens() {
        Properties yaml = applicationYaml();

        for (String cle : CLES_MAX_TOKENS) {
            assertThat(yaml.getProperty(cle))
                .as("%s : une sortie coupee = une soumission perdue, pas une reponse tronquee", cle)
                .isEqualTo(String.valueOf(PLAFOND_ATTENDU));
        }
    }

    @Test
    void aucun_correcteur_ne_plafonne_plus_bas_qu_un_autre() {
        Properties yaml = applicationYaml();

        assertThat(CLES_MAX_TOKENS.stream().map(yaml::getProperty).distinct())
            .as("changer de provider ne doit pas changer la longueur de reponse autorisee")
            .hasSize(1);
    }

    @Test
    void le_plafond_couvre_la_sortie_orale_la_plus_longue_mesuree() {
        // 2300 tokens mesures sur une correction orale complete (4 citations
        // litterales incluses). En dessous de cette valeur, le banc reperd des
        // cas EO en troncature JSON.
        assertThat(PLAFOND_ATTENDU).isGreaterThan(2300);
    }
}
