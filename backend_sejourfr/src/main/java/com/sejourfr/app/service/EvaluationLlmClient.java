package com.sejourfr.app.service;

import java.util.Map;

/**
 * Contrat commun pour les clients LLM d'evaluation des productions (EO/EE).
 * Permet de swap Anthropic ↔ OpenAI ↔ autre provider sans toucher
 * {@link AiEvaluationService}. Le provider actif est selectionne par
 * {@code sejourfr.production-evaluation.provider} via la {@code @Bean @Primary}
 * de {@code EvaluationLlmConfig}.
 *
 * <p>Tous les clients renvoient le meme JSON structure (cf. tool schema
 * versionne {@code prompts/production-evaluation-tool-schema-<version>.json}) ;
 * la structure active est ensuite validee cote serveur avant normalisation.
 */
public interface EvaluationLlmClient {

    /**
     * Appelle le LLM avec les prompts construits par {@link EvaluationPromptBuilder}.
     * Doit forcer une reponse structuree via tool_use / function calling.
     *
     * @throws com.sejourfr.app.exception.AiEvaluationException si erreur 4xx
     *         non recuperable ou reponse mal formee
     */
    Outcome evaluate(String systemPrompt, String userPrompt);

    /**
     * Nom du modele effectivement utilise (ex: "claude-sonnet-4-5",
     * "gpt-4o-mini"). Persiste dans {@code ai_evaluations.modele_utilise}.
     */
    String getModelName();

    /**
     * Version du contrat de sortie/tool-schema utilise. Persiste historiquement dans
     * {@code ai_evaluations.prompt_version}.
     */
    String getPromptVersion();

    /**
     * Resultat d'une evaluation : feedback JSON deja parse + tokens consommes
     * + cout estime (centimes EUR/USD selon config). Le cout est calcule par
     * le client lui-meme car le tarif depend du provider et du modele.
     */
    record Outcome(
            Map<String, Object> feedback,
            Integer inputTokens,
            Integer outputTokens,
            Integer costEstimateCents
    ) {}
}
