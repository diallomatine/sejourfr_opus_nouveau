package com.sejourfr.app.service.competence.niveauvise;

import java.util.Map;

/**
 * Contrat commun des clients LLM du SECOND appel « pour viser X » du module
 * Competences.
 *
 * <p>Le fournisseur actif est celui de
 * {@code sejourfr.production-evaluation.provider} — regle « un seul correcteur
 * configurable » : le plan d'action et l'analyse que le candidat lit juste
 * au-dessus doivent venir de la meme main. Ce qui est propre a cet appel, c'est
 * le contrat de sortie et le budget de tokens
 * ({@code sejourfr.competences.niveau-vise}).
 *
 * <p><b>Aucun {@code @Retryable} ici, volontairement.</b> Cet appel est
 * best-effort : un echec reseau ne coute au candidat qu'un bloc absent, jamais
 * son analyse. Rejouer trois fois un appel facultatif depenserait l'argent du
 * proprietaire pour un confort.
 */
public interface CompetenceNiveauViseLlmClient {

    /**
     * Appelle le LLM en forçant une reponse structuree (tool_use / function
     * calling) conforme au tool-schema configure.
     *
     * @throws com.sejourfr.app.exception.AiEvaluationException sur toute erreur
     *         — le service appelant l'avale, l'analyse reste valide.
     */
    Outcome produire(String systemPrompt, String userPrompt);

    /** Modele effectivement utilise (logs et suivi de cout). */
    String getModelName();

    /** Version du contrat de sortie charge. */
    String getToolSchemaVersion();

    /** Sortie brute + consommation, ajoutee aux compteurs de la tentative. */
    record Outcome(
            Map<String, Object> sortie,
            Integer inputTokens,
            Integer outputTokens,
            Integer costEstimateCents
    ) {
    }
}
