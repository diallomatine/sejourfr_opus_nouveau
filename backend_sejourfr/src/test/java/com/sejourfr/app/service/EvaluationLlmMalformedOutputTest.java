package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.exception.AiEvaluationTransientException;
import org.junit.jupiter.api.Test;
import org.springframework.retry.annotation.Retryable;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.json.JsonMapper;

import java.util.Arrays;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Une reponse du correcteur dont la FORME est cassee (pas de tool_call,
 * arguments vides ou JSON illisible) doit etre traitee comme TRANSITOIRE, donc
 * rejouee par le {@code @Retryable} du client — pas comme un echec definitif.
 *
 * <p>Vecu le 2026-08-06 : la tache 2 d'un examen blanc EO a ete perdue
 * definitivement parce que le modele avait glisse des caracteres arabes au
 * milieu de {@code scores_criteres}
 * ({@code tool_call.arguments non desorialisable}). Une session d'examen
 * n'autorise qu'UNE soumission par tache : un seul echantillon malforme
 * detruisait une production que le candidat ne peut pas refaire.
 */
class EvaluationLlmMalformedOutputTest {

    private static final ObjectMapper MAPPER = JsonMapper.builder().build();

    private static OpenAiCompatibleEvalClient deepSeekClient() {
        ProductionEvaluationProperties.DeepSeek settings = new ProductionEvaluationProperties.DeepSeek();
        settings.setApiKey("test-key");
        settings.setApiUrl("http://localhost:9999");
        settings.setModel("deepseek-v4-flash");
        settings.setTimeoutSec(5);
        settings.setPromptVersion("v5");
        return new OpenAiCompatibleEvalClient(settings, "DeepSeek", MAPPER);
    }

    private static JsonNode reponse(String toolCallArguments) {
        return MAPPER.readTree("""
            {
              "choices": [{
                "finish_reason": "tool_calls",
                "message": {
                  "tool_calls": [{
                    "function": {"name": "submit_evaluation", "arguments": %s}
                  }]
                }
              }]
            }
            """.formatted(toolCallArguments));
    }

    @Test
    void un_json_illisible_est_transitoire_donc_rejoue() {
        // Reproduction litterale de l'incident : le modele sort de la chaine et
        // ecrit en arabe au milieu de scores_criteres.
        JsonNode response = reponse("\"{\\\"scores_criteres\\\": [{\\\"code\\\": \\\"lexique\\\"د\"");

        assertThatThrownBy(() -> deepSeekClient().parseFunctionCallOutcome(response))
            .isInstanceOf(AiEvaluationTransientException.class)
            .hasMessageContaining("non desorialisable");
    }

    @Test
    void des_arguments_vides_sont_transitoires() {
        assertThatThrownBy(() -> deepSeekClient().parseFunctionCallOutcome(reponse("\"\"")))
            .isInstanceOf(AiEvaluationTransientException.class)
            .hasMessageContaining("tool_call.arguments vide");
    }

    @Test
    void une_sortie_tronquee_sans_tool_call_est_transitoire() {
        JsonNode response = MAPPER.readTree("""
            {"choices": [{"finish_reason": "length", "message": {"content": "..."}}]}
            """);

        assertThatThrownBy(() -> deepSeekClient().parseFunctionCallOutcome(response))
            .isInstanceOf(AiEvaluationTransientException.class)
            .hasMessageContaining("finish_reason=length");
    }

    @Test
    void une_reponse_bien_formee_reste_exploitee() {
        JsonNode response = reponse("\"{\\\"note_globale\\\": 9}\"");

        assertThat(deepSeekClient().parseFunctionCallOutcome(response).feedback())
            .containsEntry("note_globale", 9);
    }

    /**
     * Le type ne suffit pas : c'est {@code retryFor} qui fait effectivement
     * rejouer l'appel. Les deux moities de la garantie sont verrouillees
     * ensemble, sinon un {@code retryFor} restreint la casserait en silence.
     */
    @Test
    void les_deux_clients_rejouent_bien_les_erreurs_transitoires() throws Exception {
        for (Class<?> client : new Class<?>[] {
                OpenAiCompatibleEvalClient.class, EvaluationAnthropicClient.class }) {
            Retryable retryable = client
                .getDeclaredMethod("evaluate", String.class, String.class)
                .getAnnotation(Retryable.class);
            assertThat(retryable).as("@Retryable sur %s", client.getSimpleName()).isNotNull();
            assertThat(Arrays.asList(retryable.retryFor()))
                .as("retryFor de %s", client.getSimpleName())
                .contains(AiEvaluationTransientException.class);
            assertThat(retryable.maxAttempts()).isGreaterThan(1);
        }
    }

    /**
     * Le message du dernier echec doit rester lisible APRES les retries : c'est
     * lui qui distingue « fournisseur indisponible » de « sortie malformee »
     * dans la ventilation des motifs de perte du banc de mesure.
     */
    @Test
    void le_message_final_conserve_la_cause() {
        assertThatThrownBy(() -> deepSeekClient().recover(
                new AiEvaluationTransientException("tool_call.arguments non desorialisable : boom"),
                "sys", "user"))
            .hasMessageContaining("non desorialisable")
            .hasMessageContaining("indisponible apres plusieurs tentatives");
    }
}
