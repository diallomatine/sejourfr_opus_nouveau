package com.sejourfr.app.config;

import com.sejourfr.app.config.EvaluationConfigFixture.BlocProvider;
import com.sejourfr.app.util.ChatCompletionDialect;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import java.util.LinkedHashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

/**
 * PREUVE de l'exigence du proprietaire, formulee deux fois : <b>changer de LLM
 * ou de modele ne doit demander aucune modification de code ni de recompilation.
 * Une ligne de {@code .env}, un redemarrage, ca marche.</b>
 *
 * <p>Deux portes doivent rester fermees pour que ce soit vrai :
 * <ul>
 *   <li>la <b>forme de la requete</b> ({@code max_tokens} contre
 *       {@code max_completion_tokens}, {@code temperature} envoyee ou omise) —
 *       negociee avec le fournisseur, cf. {@code ChatCompletionDialectNegotiator} ;</li>
 *   <li>la <b>configuration</b> : modele et tarifs. C'est cette porte-ci que ce
 *       test verrouille. Elle a deja ete forcee par des tests qui figeaient le
 *       provider actif et une table fermee de tarifs : le build passait au rouge
 *       parce qu'on avait change une ligne de {@code .env}, alors que rien
 *       n'etait casse.</li>
 * </ul>
 *
 * <p>Le scenario joue ci-dessous est volontairement le pire : un modele qui
 * n'existe chez personne, sur chacun des trois providers, avec des tarifs
 * inventes. Rien de tout cela n'apparait dans un fichier {@code .java} ni dans
 * un {@code .yaml} — uniquement dans des variables simulees.
 */
class EvaluationProviderSwapTest {

    /** Un nom qu'aucune heuristique du code ne peut connaitre, par construction. */
    private static final String MODELE_INEDIT = "modele-qui-n-existe-pas-encore-2027";
    private static final double COUT_ENTREE = 1.23;
    private static final double COUT_SORTIE = 4.56;

    private static Map<String, Object> bascule(String provider) {
        Map<String, Object> env = new LinkedHashMap<>();
        env.put("EVAL_LLM_PROVIDER", provider);
        env.put(EvaluationConfigFixture.varModele(provider), MODELE_INEDIT);
        env.put(EvaluationConfigFixture.varCoutEntree(provider), String.valueOf(COUT_ENTREE));
        env.put(EvaluationConfigFixture.varCoutSortie(provider), String.valueOf(COUT_SORTIE));
        return env;
    }

    @ParameterizedTest
    @ValueSource(strings = {"openai", "deepseek", "anthropic"})
    void quatre_variables_suffisent_a_brancher_un_modele_inedit(String provider) {
        ProductionEvaluationProperties props = EvaluationConfigFixture.avec(bascule(provider));

        assertThat(props.getProvider())
            .as("EVAL_LLM_PROVIDER doit suffire a designer le correcteur")
            .isEqualTo(provider);

        BlocProvider bloc = EvaluationConfigFixture.blocActif(props);
        assertThat(bloc.provider()).isEqualTo(provider);
        assertThat(bloc.modele())
            .as("EVAL_%s_MODEL doit suffire a imposer un modele inconnu du code",
                provider.toUpperCase(java.util.Locale.ROOT))
            .isEqualTo(MODELE_INEDIT);
        assertThat(bloc.coutEntree()).isEqualTo(COUT_ENTREE);
        assertThat(bloc.coutSortie()).isEqualTo(COUT_SORTIE);
    }

    @ParameterizedTest
    @ValueSource(strings = {"openai", "deepseek", "anthropic"})
    void la_configuration_obtenue_reste_coherente_donc_le_build_reste_vert(String provider) {
        ProductionEvaluationProperties props = EvaluationConfigFixture.avec(bascule(provider));

        // Les memes regles que EvaluationPricingTest applique a la configuration
        // livree : elles portent sur une COHERENCE, donc elles passent sur un
        // modele qu'aucune table ne connait.
        for (String p : EvaluationConfigFixture.PROVIDERS) {
            EvaluationPricingTest.verifieTarif(EvaluationConfigFixture.bloc(props, p));
        }

        // Le reste du bloc actif doit rester exploitable : sans plafond de sortie
        // ni contrat de sortie, la bascule serait verte mais inutilisable.
        assertThat(EvaluationConfigFixture.versionPromptActive(props)).isNotBlank();
        assertThat(props.getRubricsVersion()).isNotBlank();
    }

    @ParameterizedTest
    @ValueSource(strings = {"openai", "deepseek"})
    void la_forme_de_requete_d_un_modele_inedit_est_negociee_jamais_devinee_en_dur(String provider) {
        ProductionEvaluationProperties props = EvaluationConfigFixture.avec(bascule(provider));
        ProductionEvaluationProperties.ChatCompletionSettings settings = "openai".equals(provider)
            ? props.getOpenai() : props.getDeepseek();

        // `auto` = le client demande la forme au fournisseur au premier 400 et la
        // memorise. Figer l'une de ces deux cles sur une valeur en dur
        // reintroduirait le probleme : un nouveau modele exigerait du code.
        assertThat(settings.getSendTemperature())
            .as("%s : la temperature doit rester negociee (auto)", provider)
            .isEqualTo(ChatCompletionDialect.AUTO);
        assertThat(settings.getMaxTokensParam())
            .as("%s : le nom du champ de plafond doit rester negocie (auto)", provider)
            .isEqualTo(ChatCompletionDialect.AUTO);

        // Et l'heuristique de depart ne doit pas rejeter un nom inconnu : elle
        // propose une forme, le fournisseur la corrige si besoin.
        assertThatCode(() -> ChatCompletionDialect.premiereForme(MODELE_INEDIT))
            .doesNotThrowAnyException();
        assertThat(ChatCompletionDialect.premiereForme(MODELE_INEDIT).maxTokensParam()).isNotBlank();
    }

    @Test
    void aucun_nom_de_modele_n_est_ecrit_dans_le_code_de_production() {
        // La configuration livree ne doit venir que d'application.yaml : si un
        // bloc portait encore un modele par defaut en dur dans le POJO, une
        // bascule par .env resterait vraie mais le rollback « supprimer la
        // variable » rendrait un modele fantome.
        ProductionEvaluationProperties nu = new ProductionEvaluationProperties();

        assertThat(nu.getOpenai().getModel()).isNull();
        assertThat(nu.getDeepseek().getModel()).isNull();
        assertThat(nu.getAnthropic().getModel()).isNull();
    }
}
