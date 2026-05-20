package com.sejourfr.app.config;

import com.sejourfr.app.service.EvaluationLlmClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

/**
 * Selectionne le bean {@link EvaluationLlmClient} actif en fonction de
 * {@code sejourfr.production-evaluation.provider} (defaut {@code openai}).
 *
 * <p>Les deux clients (Anthropic + OpenAI) sont toujours instancies par
 * Spring (leur {@code @PostConstruct} charge juste le tool schema, sans
 * appel reseau). Seul celui retourne par {@link #evaluationLlmClient} est
 * injecte dans {@code AiEvaluationService}. Pour switcher de provider :
 * changer la valeur et redemarrer le backend.
 */
@Configuration
public class EvaluationLlmConfig {

    private static final Logger log = LoggerFactory.getLogger(EvaluationLlmConfig.class);

    @Bean
    @Primary
    public EvaluationLlmClient evaluationLlmClient(
            ProductionEvaluationProperties props,
            @Qualifier("evaluationAnthropicClient") EvaluationLlmClient anthropic,
            @Qualifier("evaluationOpenAiClient") EvaluationLlmClient openai) {
        String provider = props.getProvider() == null ? "" : props.getProvider().trim().toLowerCase();
        EvaluationLlmClient selected = switch (provider) {
            case "openai" -> openai;
            case "anthropic" -> anthropic;
            default -> throw new IllegalStateException(
                "sejourfr.production-evaluation.provider invalide : '" + props.getProvider()
                    + "'. Valeurs supportees : openai, anthropic."
            );
        };
        log.info("Provider LLM eval actif : {} (modele {})", provider, selected.getModelName());
        return selected;
    }
}
