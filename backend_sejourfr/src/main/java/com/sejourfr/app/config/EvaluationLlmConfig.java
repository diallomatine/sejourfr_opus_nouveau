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
        EvaluationLlmClient selected = select(
            props.getProvider(), "sejourfr.production-evaluation.provider",
            anthropic, openai, deepseek);
        log.info("Provider LLM eval actif : {} (modele {})",
            props.getProvider(), selected.getModelName());
        return selected;
    }

    /**
     * Client de la SECONDE PASSE d'evaluation (zone floue). Provider dedie via
     * {@code sejourfr.production-evaluation.seconde-passe.provider} ; vide, on
     * retombe sur le provider principal. Le bean existe toujours, meme drapeau
     * eteint (il n'ouvre aucune connexion tant qu'on ne l'appelle pas).
     */
    @Bean("evaluationSecondePasseClient")
    public EvaluationLlmClient evaluationSecondePasseClient(
            ProductionEvaluationProperties props,
            @Qualifier("evaluationAnthropicClient") EvaluationLlmClient anthropic,
            @Qualifier("evaluationOpenAiClient") EvaluationLlmClient openai,
            @Qualifier("evaluationDeepSeekClient") EvaluationLlmClient deepseek) {
        String configure = props.getSecondePasse().getProvider();
        boolean dedie = configure != null && !configure.isBlank();
        EvaluationLlmClient selected = select(
            dedie ? configure : props.getProvider(),
            "sejourfr.production-evaluation.seconde-passe.provider",
            anthropic, openai, deepseek);

        if (props.getSecondePasse().isEnabled()) {
            if (!dedie) {
                log.warn("Seconde passe activee SANS provider dedie : elle interrogera deux fois {} "
                        + "a temperature 0, ce qui n'apporte presque rien. Renseigner "
                        + "sejourfr.production-evaluation.seconde-passe.provider.",
                    selected.getModelName());
            } else {
                log.info("Seconde passe activee : provider {} (modele {})", configure, selected.getModelName());
            }
        }
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
