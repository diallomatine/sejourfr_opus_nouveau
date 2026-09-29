package com.sejourfr.app.config;

import com.sejourfr.app.service.competence.CompetenceAnalysisLlmClient;
import com.sejourfr.app.service.competence.CompetenceAnthropicClient;
import com.sejourfr.app.service.competence.CompetenceOpenAiCompatibleClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import tools.jackson.databind.ObjectMapper;

/**
 * Selectionne le client d'analyse ciblee actif.
 *
 * <p><b>Sur la MEME cle que le reste du projet</b> :
 * {@code sejourfr.production-evaluation.provider}. C'est la regle « un seul
 * correcteur configurable » — deux cles distinctes auraient permis a l'analyse
 * de competence de tourner sur un modele different de celui des productions
 * completes sans que personne ne s'en apercoive, et les retours vus par un meme
 * candidat n'auraient plus eu la meme main.
 *
 * <p>Ce qui reste propre au module, c'est {@code sejourfr.competences.analysis}
 * : contrat de sortie, plafond de tokens, temperature. Un retour arriere sur la
 * grille des productions completes n'emporte donc pas l'analyse ciblee, et
 * inversement.
 *
 * <p>Les trois clients sont instancies au boot (leur {@code @PostConstruct} ne
 * fait que charger le tool-schema, sans appel reseau) ; seul celui retourne par
 * {@link #competenceAnalysisLlmClient} est injecte dans le service.
 */
@Configuration
public class CompetenceLlmConfig {

    private static final Logger log = LoggerFactory.getLogger(CompetenceLlmConfig.class);

    @Bean("competenceAnthropicClient")
    public CompetenceAnalysisLlmClient competenceAnthropicClient(
            ProductionEvaluationProperties evalProps, CompetenceProperties props,
            ObjectMapper objectMapper) {
        return new CompetenceAnthropicClient(
            evalProps.getAnthropic(), props.getAnalysis(), objectMapper);
    }

    @Bean("competenceOpenAiClient")
    public CompetenceAnalysisLlmClient competenceOpenAiClient(
            ProductionEvaluationProperties evalProps, CompetenceProperties props,
            ObjectMapper objectMapper) {
        return new CompetenceOpenAiCompatibleClient(
            evalProps.getOpenai(), props.getAnalysis(), "OpenAI", objectMapper);
    }

    @Bean("competenceDeepSeekClient")
    public CompetenceAnalysisLlmClient competenceDeepSeekClient(
            ProductionEvaluationProperties evalProps, CompetenceProperties props,
            ObjectMapper objectMapper) {
        return new CompetenceOpenAiCompatibleClient(
            evalProps.getDeepseek(), props.getAnalysis(), "DeepSeek", objectMapper);
    }

    @Bean
    @Primary
    public CompetenceAnalysisLlmClient competenceAnalysisLlmClient(
            ProductionEvaluationProperties evalProps,
            @Qualifier("competenceAnthropicClient") CompetenceAnalysisLlmClient anthropic,
            @Qualifier("competenceOpenAiClient") CompetenceAnalysisLlmClient openai,
            @Qualifier("competenceDeepSeekClient") CompetenceAnalysisLlmClient deepseek) {
        CompetenceAnalysisLlmClient selected = select(
            evalProps.getProvider(), anthropic, openai, deepseek);
        log.info("Provider LLM analyse competence actif : {} (modele {}, tool-schema {})",
            evalProps.getProvider(), selected.getModelName(), selected.getToolSchemaVersion());
        return selected;
    }

    private static CompetenceAnalysisLlmClient select(String provider,
                                                      CompetenceAnalysisLlmClient anthropic,
                                                      CompetenceAnalysisLlmClient openai,
                                                      CompetenceAnalysisLlmClient deepseek) {
        String p = provider == null ? "" : provider.trim().toLowerCase();
        return switch (p) {
            case "openai" -> openai;
            case "anthropic" -> anthropic;
            case "deepseek" -> deepseek;
            default -> throw new IllegalStateException(
                "sejourfr.production-evaluation.provider invalide : '" + provider
                    + "'. Valeurs supportees : openai, anthropic, deepseek.");
        };
    }
}
