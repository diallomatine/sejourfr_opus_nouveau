package com.sejourfr.app.util;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * L'exigence produit : <b>brancher un modele qui n'existe pas encore ne doit
 * demander aucune modification de code</b>. Ces tests la verifient sur des
 * modeles volontairement INCONNUS de tout raccourci du projet — si l'un d'eux
 * passait grace a une liste de noms, l'exigence ne serait pas tenue.
 */
class ChatCompletionDialectNegotiatorTest {

    /** Corps 400 reel d'OpenAI sur un modele qui refuse max_tokens. */
    private static final String ERREUR_PLAFOND = """
        {"error":{"message":"Unsupported parameter: 'max_tokens' is not supported with this model. \
        Use 'max_completion_tokens' instead.","type":"invalid_request_error",\
        "param":"max_tokens","code":"unsupported_parameter"}}""";

    /** Corps 400 reel d'OpenAI sur un modele a temperature figee. */
    private static final String ERREUR_TEMPERATURE = """
        {"error":{"message":"Unsupported value: 'temperature' does not support 0 with this model. \
        Only the default (1) value is supported.","type":"invalid_request_error",\
        "param":"temperature","code":"unsupported_value"}}""";

    private static ChatCompletionDialectNegotiator neuf(String modele) {
        return new ChatCompletionDialectNegotiator("Test", modele, "auto", "auto");
    }

    @Test
    void un_modele_inconnu_qui_refuse_max_tokens_aboutit_sans_intervention() {
        ChatCompletionDialectNegotiator n = neuf("modele-du-futur-2030");
        ChatCompletionDialect essai = n.forme();
        assertThat(essai.maxTokensParam()).isEqualTo("max_tokens");

        assertThat(n.adapte(essai, ERREUR_PLAFOND)).isTrue();
        assertThat(n.forme().maxTokensParam()).isEqualTo("max_completion_tokens");
        assertThat(n.forme().sendTemperature()).isTrue();
    }

    @Test
    void un_modele_inconnu_qui_refuse_temperature_0_aboutit_sans_intervention() {
        ChatCompletionDialectNegotiator n = neuf("modele-du-futur-2030");

        assertThat(n.adapte(n.forme(), ERREUR_TEMPERATURE)).isTrue();
        assertThat(n.forme().sendTemperature()).isFalse();
        // Le plafond n'a pas bouge : on ne corrige que ce qui est refuse.
        assertThat(n.forme().maxTokensParam()).isEqualTo("max_tokens");
    }

    @Test
    void le_nom_de_remplacement_est_LU_dans_le_message_pas_devine() {
        // Un futur renommage vers un nom qu'aucune liste du projet ne connait.
        String erreur = """
            {"error":{"message":"Unsupported parameter: 'max_tokens' is not supported with this \
            model. Use 'max_output_tokens' instead.","param":"max_tokens",\
            "code":"unsupported_parameter"}}""";
        ChatCompletionDialectNegotiator n = neuf("modele-du-futur-2030");

        assertThat(n.adapte(n.forme(), erreur)).isTrue();
        assertThat(n.forme().maxTokensParam())
            .as("c'est l'API qui nomme le remplacant, pas le code")
            .isEqualTo("max_output_tokens");
    }

    @Test
    void sans_suggestion_on_bascule_sur_l_autre_nom_connu() {
        String erreur = """
            {"error":{"message":"Unsupported parameter: 'max_tokens' is not supported with this \
            model.","param":"max_tokens","code":"unsupported_parameter"}}""";
        ChatCompletionDialectNegotiator n = neuf("modele-du-futur-2030");

        assertThat(n.adapte(n.forme(), erreur)).isTrue();
        assertThat(n.forme().maxTokensParam()).isEqualTo("max_completion_tokens");
    }

    @Test
    void la_forme_n_est_negociee_qu_une_fois() {
        ChatCompletionDialectNegotiator n = neuf("modele-du-futur-2030");
        assertThat(n.adapte(n.forme(), ERREUR_PLAFOND)).isTrue();

        ChatCompletionDialect apresNegociation = n.forme();
        // Le meme 400 rejoue ne doit plus rien changer, et surtout pas revenir
        // en arriere : le surcout est paye une fois par demarrage.
        assertThat(n.adapte(apresNegociation, ERREUR_PLAFOND)).isFalse();
        assertThat(n.forme()).isEqualTo(apresNegociation);
    }

    @Test
    void deux_appels_concurrents_ne_se_marchent_pas_dessus() {
        ChatCompletionDialectNegotiator n = neuf("modele-du-futur-2030");
        ChatCompletionDialect formeInitiale = n.forme();

        assertThat(n.adapte(formeInitiale, ERREUR_PLAFOND)).isTrue();
        // Le 2e appel etait parti avec l'ancienne forme : on lui dit de rejouer,
        // sans renegocier une 2e fois.
        assertThat(n.adapte(formeInitiale, ERREUR_PLAFOND)).isTrue();
        assertThat(n.forme().maxTokensParam()).isEqualTo("max_completion_tokens");
    }

    @Test
    void un_400_metier_ne_declenche_JAMAIS_de_renegociation() {
        ChatCompletionDialectNegotiator n = neuf("modele-du-futur-2030");
        ChatCompletionDialect avant = n.forme();

        String schemaRefuse = """
            {"error":{"message":"Invalid schema for function 'submit_evaluation': \
            'additionalProperties' is required to be supplied and to be false.",\
            "type":"invalid_request_error","param":"tools[0].function.parameters",\
            "code":"invalid_function_parameters"}}""";
        String contenuRefuse = """
            {"error":{"message":"Invalid 'messages[1].content': string too long.",\
            "type":"invalid_request_error","param":"messages[1].content",\
            "code":"string_above_max_length"}}""";
        String modeleInconnuCoteApi = """
            {"error":{"message":"The model 'gpt-99' does not exist or you do not have access to it.",\
            "type":"invalid_request_error","param":"model","code":"model_not_found"}}""";

        assertThat(n.adapte(avant, schemaRefuse)).isFalse();
        assertThat(n.adapte(avant, contenuRefuse)).isFalse();
        assertThat(n.adapte(avant, modeleInconnuCoteApi)).isFalse();
        assertThat(n.adapte(avant, "")).isFalse();
        assertThat(n.forme()).isEqualTo(avant);
    }

    @Test
    void un_message_metier_citant_temperature_sans_marqueur_de_forme_ne_bascule_pas() {
        ChatCompletionDialectNegotiator n = neuf("modele-du-futur-2030");
        ChatCompletionDialect avant = n.forme();

        assertThat(n.adapte(avant, """
            {"error":{"message":"Invalid 'messages[1].content': le candidat parle de temperature",\
            "param":"messages[1].content","code":"invalid_value"}}""")).isFalse();
        assertThat(n.forme()).isEqualTo(avant);
    }

    @Test
    void la_negociation_est_bornee() {
        ChatCompletionDialectNegotiator n = neuf("modele-du-futur-2030");

        // Les deux seuls noms proposables sont epuisables ; ensuite le 400 doit
        // remonter, pas boucler.
        assertThat(n.adapte(n.forme(), ERREUR_PLAFOND)).isTrue();
        String refusDuSecond = """
            {"error":{"message":"Unsupported parameter: 'max_completion_tokens' is not supported \
            with this model.","param":"max_completion_tokens","code":"unsupported_parameter"}}""";
        assertThat(n.adapte(n.forme(), refusDuSecond)).isFalse();
    }

    @Test
    void deepseek_n_est_jamais_renegocie_puisqu_il_ne_refuse_rien() {
        // Voie de PRODUCTION historique : forme d'essai correcte du premier coup,
        // aucun aller-retour supplementaire.
        ChatCompletionDialectNegotiator n = neuf("deepseek-v4-flash");

        assertThat(n.forme()).isEqualTo(new ChatCompletionDialect("max_tokens", true));
    }

    @Test
    void la_config_reprend_la_main_et_desactive_la_negociation() {
        ChatCompletionDialectNegotiator force =
            new ChatCompletionDialectNegotiator("Test", "gpt-5.4", "max_tokens", "auto");

        assertThat(force.forme().maxTokensParam()).isEqualTo("max_tokens");
        assertThat(force.adapte(force.forme(), ERREUR_PLAFOND))
            .as("une valeur imposee en config n'est pas ecrasee par la negociation")
            .isFalse();
    }

    @Test
    void la_config_peut_demander_de_ne_pas_envoyer_temperature_du_tout() {
        // Valeur distincte de 0 et de 1 : « ne pas envoyer le champ ».
        ChatCompletionDialectNegotiator n =
            new ChatCompletionDialectNegotiator("Test", "gpt-5.4", "auto", "false");

        assertThat(n.forme().sendTemperature()).isFalse();
    }

    @Test
    void une_valeur_de_config_absurde_echoue_au_demarrage() {
        assertThatThrownBy(() ->
            new ChatCompletionDialectNegotiator("Test", "gpt-5.4", "auto", "peut-etre"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("send-temperature invalide");
    }

    @Test
    void le_raccourci_par_famille_evite_un_aller_retour_sans_etre_le_seul_chemin() {
        // Raccourci : gpt-5.x part directement sur le bon nom…
        assertThat(neuf("gpt-5.4").forme().maxTokensParam()).isEqualTo("max_completion_tokens");
        assertThat(neuf("gpt-4o-mini").forme().maxTokensParam()).isEqualTo("max_tokens");
        // …et son absence de correspondance ne casse rien : cf. les tests sur
        // « modele-du-futur-2030 » ci-dessus, qui aboutissent par negociation.
        assertThat(neuf("mistral-large-3").forme().maxTokensParam()).isEqualTo("max_tokens");
    }
}
