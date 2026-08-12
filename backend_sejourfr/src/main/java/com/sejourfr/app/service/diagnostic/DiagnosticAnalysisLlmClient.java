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
            Integer outputTokens,
            Integer costEstimateCents
    ) {}
}
