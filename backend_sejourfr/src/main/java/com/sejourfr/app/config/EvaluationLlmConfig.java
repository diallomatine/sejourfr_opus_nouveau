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
 * {@code sejourfr.production-evaluation.provider} (defaut {@code deepseek}).
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

    /** Client OpenAI. Le modele vient de la configuration, jamais d'ici. */
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
        EvaluationLlmClient selected = select(
            props.getProvider(), "sejourfr.production-evaluation.provider",
            anthropic, openai, deepseek);
        log.info("Provider LLM eval actif : {} (modele {})",
            props.getProvider(), selected.getModelName());
        return selected;
    }

    private static EvaluationLlmClient select(String provider, String cleConfig,
                                              EvaluationLlmClient anthropic,
                                              EvaluationLlmClient openai,
                                              EvaluationLlmClient deepseek) {
        String p = provider == null ? "" : provider.trim().toLowerCase();
        return switch (p) {
            case "openai" -> openai;
            case "anthropic" -> anthropic;
            case "deepseek" -> deepseek;
            default -> throw new IllegalStateException(
                cleConfig + " invalide : '" + provider
                    + "'. Valeurs supportees : openai, anthropic, deepseek."
            );
        };
    }
}
