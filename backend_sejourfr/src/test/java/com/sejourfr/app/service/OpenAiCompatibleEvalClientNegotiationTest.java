package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * NEGOCIATION DE FORME de bout en bout, contre un vrai serveur HTTP qui renvoie
 * les corps 400 REELS d'OpenAI.
 *
 * <p>C'est ce test qui verifie l'exigence produit : brancher un modele que le
 * code ne connait pas doit aboutir <b>sans intervention humaine ni
 * recompilation</b>. Les modeles utilises ici sont volontairement inventes — si
 * le test passait grace a une liste de noms en dur, il ne prouverait rien.
 */
class OpenAiCompatibleEvalClientNegotiationTest {

    private static final ObjectMapper OM = new ObjectMapper();

    private static final String REFUS_MAX_TOKENS = """
        {"error":{"message":"Unsupported parameter: 'max_tokens' is not supported with this model. \
        Use 'max_completion_tokens' instead.","type":"invalid_request_error",\
        "param":"max_tokens","code":"unsupported_parameter"}}""";

    private static final String REFUS_TEMPERATURE = """
        {"error":{"message":"Unsupported value: 'temperature' does not support 0 with this model. \
        Only the default (1) value is supported.","type":"invalid_request_error",\
        "param":"temperature","code":"unsupported_value"}}""";

    private static final String REFUS_METIER = """
        {"error":{"message":"Invalid schema for function 'submit_evaluation'.",\
        "type":"invalid_request_error","param":"tools[0].function.parameters",\
        "code":"invalid_function_parameters"}}""";

    private static final String SUCCES = """
        {"choices":[{"finish_reason":"tool_calls","message":{"tool_calls":[{"function":{\
        "name":"submit_evaluation","arguments":"{\\"note_globale\\":10}"}}]}}],\
        "usage":{"prompt_tokens":100,"completion_tokens":50}}""";

    private HttpServer serveur;
    /** Reponses a servir, dans l'ordre. */
    private final List<String[]> scenario = new ArrayList<>();
    /** Corps recus, pour verifier ce qui a REELLEMENT ete envoye. */
    private final List<String> recus = new CopyOnWriteArrayList<>();

    @BeforeEach
    void demarre() throws IOException {
        serveur = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        serveur.createContext("/chat/completions", echange -> {
            try (InputStream is = echange.getRequestBody()) {
                recus.add(new String(is.readAllBytes(), StandardCharsets.UTF_8));
            }
            int index = Math.min(recus.size() - 1, scenario.size() - 1);
            String[] reponse = scenario.get(index);
            byte[] corps = reponse[1].getBytes(StandardCharsets.UTF_8);
            echange.getResponseHeaders().add("Content-Type", "application/json");
            echange.sendResponseHeaders(Integer.parseInt(reponse[0]), corps.length);
            try (OutputStream os = echange.getResponseBody()) {
                os.write(corps);
            }
        });
        serveur.start();
    }

    @AfterEach
    void arrete() {
        serveur.stop(0);
    }

    private void repond(String statut, String corps) {
        scenario.add(new String[] {statut, corps});
    }

    private OpenAiCompatibleEvalClient client(String modele) {
        ProductionEvaluationProperties.OpenAi s = new ProductionEvaluationProperties.OpenAi();
        s.setApiKey("cle-de-test");
        s.setApiUrl("http://127.0.0.1:" + serveur.getAddress().getPort() + "/chat/completions");
        s.setModel(modele);
        s.setMaxTokens(4000);
        s.setTemperature(0);
        s.setTimeoutSec(10);
        s.setPromptVersion("v5");
        OpenAiCompatibleEvalClient c = new OpenAiCompatibleEvalClient(s, "OpenAI", OM);
        try {
            c.loadToolSchema();
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
        return c;
    }

    @Test
    void un_modele_inconnu_qui_refuse_max_tokens_finit_par_repondre() {
        repond("400", REFUS_MAX_TOKENS);
        repond("200", SUCCES);

        var outcome = client("modele-du-futur-2030").evaluate("system", "user");

        assertThat(outcome.inputTokens()).isEqualTo(100);
        assertThat(recus).hasSize(2);
        assertThat(recus.get(0)).contains("\"max_tokens\":4000").doesNotContain("max_completion_tokens");
        assertThat(recus.get(1)).contains("\"max_completion_tokens\":4000").doesNotContain("\"max_tokens\"");
        // Le PLAFOND n'a pas change de valeur, seulement de nom.
        assertThat(recus.get(1)).contains("4000");
    }

    @Test
    void un_modele_inconnu_qui_refuse_temperature_0_finit_par_repondre() {
        repond("400", REFUS_TEMPERATURE);
        repond("200", SUCCES);

        client("modele-du-futur-2030").evaluate("system", "user");

        assertThat(recus).hasSize(2);
        assertThat(recus.get(0)).contains("\"temperature\":0");
        // On OMET le champ, on n'envoie pas 1 : envoyer 1 reviendrait a choisir
        // en douce une notation non deterministe.
        assertThat(recus.get(1)).doesNotContain("temperature");
    }

    @Test
    void les_deux_refus_s_enchainent_sur_un_meme_modele() {
        repond("400", REFUS_MAX_TOKENS);
        repond("400", REFUS_TEMPERATURE);
        repond("200", SUCCES);

        client("modele-du-futur-2030").evaluate("system", "user");

        assertThat(recus).hasSize(3);
        assertThat(recus.get(2)).contains("max_completion_tokens").doesNotContain("temperature");
    }

    @Test
    void la_forme_negociee_est_memorisee_pour_les_appels_suivants() {
        repond("400", REFUS_MAX_TOKENS);
        repond("200", SUCCES);
        OpenAiCompatibleEvalClient client = client("modele-du-futur-2030");

        client.evaluate("system", "user");
        client.evaluate("system", "user");
        client.evaluate("system", "user");

        // 2 appels pour le premier (dont le 400), puis 1 seul par appel suivant :
        // le surcout est paye une fois par demarrage, pas a chaque correction.
        assertThat(recus).hasSize(4);
        assertThat(recus.subList(1, 4)).allSatisfy(c ->
            assertThat(c).contains("max_completion_tokens"));
    }

    @Test
    void un_400_metier_remonte_immediatement_sans_renegociation() {
        repond("400", REFUS_METIER);
        repond("200", SUCCES);

        assertThatThrownBy(() -> client("modele-du-futur-2030").evaluate("system", "user"))
            .isInstanceOf(AiEvaluationException.class)
            .hasMessageContaining("4xx");

        // UN seul appel : masquer une vraie erreur derriere une boucle de
        // reessais serait pire que l'erreur elle-meme.
        assertThat(recus).hasSize(1);
    }

    @Test
    void deepseek_repond_du_premier_coup_sans_aller_retour_supplementaire() {
        repond("200", SUCCES);

        ProductionEvaluationProperties.DeepSeek s = new ProductionEvaluationProperties.DeepSeek();
        s.setApiKey("cle-de-test");
        s.setApiUrl("http://127.0.0.1:" + serveur.getAddress().getPort() + "/chat/completions");
        s.setModel("deepseek-v4-flash");
        s.setMaxTokens(4000);
        s.setTemperature(0);
        s.setTimeoutSec(10);
        s.setDisableThinking(true);
        s.setPromptVersion("v5");
        OpenAiCompatibleEvalClient client = new OpenAiCompatibleEvalClient(s, "DeepSeek", OM);
        try {
            client.loadToolSchema();
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }

        client.evaluate("system", "user");

        assertThat(recus).hasSize(1);
        assertThat(recus.get(0))
            .contains("\"max_tokens\":4000")
            .contains("\"temperature\":0")
            .contains("\"thinking\"");
    }
}
