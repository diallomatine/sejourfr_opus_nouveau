package com.sejourfr.app.config;

import com.sejourfr.app.service.EvaluationLlmClient;
import com.sejourfr.app.service.OpenAiCompatibleEvalClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import tools.jackson.databind.ObjectMapper;

/**
 * Selectionne le bean {@link EvaluationLlmClient} actif en fonction de
 * {@code sejourfr.production-evaluation.provider} (defaut {@code openai}).
 *
 * <p>Les providers compatibles OpenAI (OpenAI, DeepSeek, ...) partagent un seul
 * client {@link OpenAiCompatibleEvalClient}, instancie une fois par provider
 * avec ses propres reglages. Anthropic a son client dedie ({@code @Service}).
 * Tous sont instancies par Spring (leur {@code @PostConstruct} charge juste le
 * tool schema, sans appel reseau) ; seul celui retourne par
 * {@link #evaluationLlmClient} est injecte dans {@code AiEvaluationService}.
 * Pour switcher : changer la valeur et redemarrer le backend.
 */
@Configuration
public class EvaluationLlmConfig {

    private static final Logger log = LoggerFactory.getLogger(EvaluationLlmConfig.class);

    /** Client OpenAI (gpt-4o-mini par defaut). */
    @Bean("evaluationOpenAiClient")
    public OpenAiCompatibleEvalClient evaluationOpenAiClient(
            ProductionEvaluationProperties props, ObjectMapper objectMapper) {
        return new OpenAiCompatibleEvalClient(props.getOpenai(), "OpenAI", objectMapper);
    }

    /** Client DeepSeek (API compatible OpenAI). */
    @Bean("evaluationDeepSeekClient")
    public OpenAiCompatibleEvalClient evaluationDeepSeekClient(
            ProductionEvaluationProperties props, ObjectMapper objectMapper) {
        return new OpenAiCompatibleEvalClient(props.getDeepseek(), "DeepSeek", objectMapper);
    }

    @Bean
    @Primary
    public EvaluationLlmClient evaluationLlmClient(
            ProductionEvaluationProperties props,
            @Qualifier("evaluationAnthropicClient") EvaluationLlmClient anthropic,
            @Qualifier("evaluationOpenAiClient") EvaluationLlmClient openai,
            @Qualifier("evaluationDeepSeekClient") EvaluationLlmClient deepseek) {
        String provider = props.getProvider() == null ? "" : props.getProvider().trim().toLowerCase();
        EvaluationLlmClient selected = switch (provider) {
            case "openai" -> openai;
            case "anthropic" -> anthropic;
            case "deepseek" -> deepseek;
            default -> throw new IllegalStateException(
                "sejourfr.production-evaluation.provider invalide : '" + props.getProvider()
                    + "'. Valeurs supportees : openai, anthropic, deepseek."
            );
        };
        log.info("Provider LLM eval actif : {} (modele {})", provider, selected.getModelName());
        return selected;
    }
}
