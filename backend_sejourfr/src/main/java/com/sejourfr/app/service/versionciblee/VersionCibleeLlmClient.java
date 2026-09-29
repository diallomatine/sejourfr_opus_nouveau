package com.sejourfr.app.service.versionciblee;

import java.util.Map;

/**
 * Contrat commun des clients LLM du SECOND appel « version au niveau visé ».
 *
 * <p>Le fournisseur actif est celui de
 * {@code sejourfr.production-evaluation.provider} — règle « un seul correcteur
 * configurable » : la version rendue au candidat et la correction qu'il lit
 * juste au-dessus doivent venir de la même main. Ce qui est propre à cet appel,
 * c'est le contrat de sortie et le budget de tokens
 * ({@code sejourfr.production-evaluation.version-ciblee}).
 *
 * <p><b>Aucun {@code @Retryable} ici, volontairement.</b> Cet appel est
 * best-effort : un échec réseau ne coûte au candidat qu'un bloc absent, jamais
 * sa correction. Rejouer trois fois un appel facultatif dépenserait l'argent du
 * propriétaire pour un confort.
 */
public interface VersionCibleeLlmClient {

    /**
     * Appelle le LLM en forçant une réponse structurée (tool_use / function
     * calling) conforme au tool-schema configuré.
     *
     * @param variante décide du contrat de sortie envoyé : à l'écrit le candidat
     *                 reçoit sa réponse RÉÉCRITE, à l'oral seulement des passages
     *                 REFORMULÉS. Deux sorties différentes, donc deux schémas —
     *                 les fondre en un seul aurait supposé des champs
     *                 facultatifs.
     * @throws com.sejourfr.app.exception.AiEvaluationException sur toute erreur
     *         — le service appelant l'avale, l'évaluation reste valide.
     */
    Outcome produire(String systemPrompt, String userPrompt, VersionCibleeVariante variante);

    /** Modèle effectivement utilisé (logs et suivi de coût). */
    String getModelName();

    /** Version du contrat de sortie chargé. */
    String getToolSchemaVersion();

    /** Sortie brute + consommation, ajoutée aux compteurs de l'évaluation. */
    record Outcome(
            Map<String, Object> sortie,
            Integer inputTokens,
            Integer cachedInputTokens,
            Integer outputTokens,
            Integer costEstimateMicroUsd
    ) {

        /**
         * Tokens d'entree servis par le CACHE DE PREFIXE du fournisseur, sous-ensemble
         * de {@code inputTokens} ; {@code null} quand la reponse ne le dit pas. Ce
         * constructeur a quatre arguments facture alors TOUT au plein tarif :
         * l'hypothese prudente, jamais l'inverse.
         */
        public Outcome(Map<String, Object> sortie, Integer inputTokens,
                       Integer outputTokens, Integer costEstimateMicroUsd) {
            this(sortie, inputTokens, null, outputTokens, costEstimateMicroUsd);
        }

    }
}
