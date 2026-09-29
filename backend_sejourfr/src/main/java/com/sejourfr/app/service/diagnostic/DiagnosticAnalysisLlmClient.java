package com.sejourfr.app.service.diagnostic;

import java.util.Map;

/** Client structuré du profil Diagnostic/observations du Plan. */
public interface DiagnosticAnalysisLlmClient {

    Outcome analyse(String systemPrompt, String userPrompt);

    String getModelName();

    String getToolSchemaVersion();

    record Outcome(
            Map<String, Object> analysis,
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
        public Outcome(Map<String, Object> analysis, Integer inputTokens,
                       Integer outputTokens, Integer costEstimateMicroUsd) {
            this(analysis, inputTokens, null, outputTokens, costEstimateMicroUsd);
        }
    }
}
