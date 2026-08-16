package com.sejourfr.app.service.diagnostic.exemplecible;

import java.util.Map;

/**
 * Contrat commun des clients LLM du SECOND appel du diagnostic, « avant /
 * apres ».
 *
 * <p>Le fournisseur actif est celui de
 * {@code sejourfr.production-evaluation.provider} — regle « un seul correcteur
 * configurable » : l'analyse que le candidat lit juste au-dessus et la phrase
 * reecrite doivent venir de la meme main. Ce qui est propre a cet appel, c'est le
 * contrat de sortie et le budget de tokens
 * ({@code sejourfr.diagnostic.exemple-cible}).
 *
 * <p><b>Aucun {@code @Retryable} ici, volontairement.</b> Cet appel est
 * best-effort : un echec reseau ne coute au candidat qu'un bloc absent, jamais son
 * diagnostic. Rejouer trois fois un appel facultatif depenserait l'argent du
 * proprietaire pour un confort.
 */
public interface DiagnosticExempleCibleLlmClient {

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

    /** Sortie brute + consommation, ajoutee aux compteurs de l'analyse. */
    record Outcome(
            Map<String, Object> sortie,
            Integer inputTokens,
            Integer outputTokens,
            Integer costEstimateCents
    ) {
    }
}
