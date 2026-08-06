package com.sejourfr.app.service.competence;

import java.util.Map;

/**
 * Contrat commun aux clients LLM de l'analyse ciblee. Permet de changer de
 * fournisseur sans toucher {@code CompetenceAnalysisServiceImpl}.
 *
 * <p>Le fournisseur actif est celui de
 * {@code sejourfr.production-evaluation.provider} — la regle « un seul
 * correcteur configurable » du projet vaut aussi ici. Ce qui est propre a
 * l'analyse ciblee, c'est le CONTRAT DE SORTIE (outil
 * {@code submit_competence_analysis}, cinq champs courts) et le budget de
 * tokens, tous deux pilotes par {@code sejourfr.competences.analysis}.
 */
public interface CompetenceAnalysisLlmClient {

    /**
     * Appelle le correcteur avec les prompts de
     * {@link CompetenceAnalysisPromptBuilder}. Doit forcer une sortie
     * structuree via tool_use / function calling — jamais de texte libre.
     *
     * @throws com.sejourfr.app.exception.AiEvaluationException erreur 4xx non
     *         recuperable ou reponse mal formee
     */
    Outcome analyse(String systemPrompt, String userPrompt);

    /** Modele effectivement appele, persiste dans {@code user_skill_attempts.ai_model}. */
    String getModelName();

    /** Version du contrat de sortie, persistee dans {@code user_skill_attempts.prompt_version}. */
    String getToolSchemaVersion();

    /**
     * Sortie BRUTE du correcteur (aucune validation faite ici) + consommation.
     * Le cout est calcule par le client : le tarif depend du fournisseur.
     */
    record Outcome(
            Map<String, Object> analysis,
            Integer inputTokens,
            Integer outputTokens,
            Integer costEstimateCents
    ) {}
}
