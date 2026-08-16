package com.sejourfr.app.calibration;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.config.EvaluationConfigFixture;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.service.competence.CompetenceAnalysisLlmClient;
import com.sejourfr.app.service.competence.CompetenceAnthropicClient;
import com.sejourfr.app.service.competence.CompetenceOpenAiCompatibleClient;
import tools.jackson.databind.ObjectMapper;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Cablage du banc « Competences » sur la configuration REELLE, exactement comme
 * {@link CalibrationEnv} le fait pour les productions completes :
 * {@code application.yaml} + environnement du processus + {@code .env} local,
 * sans contexte Spring ni base de donnees.
 *
 * <p><b>Le provider et le modele ne sont JAMAIS surchargeables</b> : ils
 * viennent de {@code sejourfr.production-evaluation}, la meme cle que le
 * runtime (regle « un seul correcteur configurable »). Seules les versions de
 * consignes et de contrat de sortie du module se surchargent, parce que c'est
 * precisement ce qu'une campagne compare.
 *
 * <p>Aucune valeur de cle d'API n'est jamais journalisee.
 */
final class CompetenceCalibrationEnv {

    /** Prefixe de configuration du module de micro-entrainement. */
    static final String PREFIXE = "sejourfr.competences";

    private CompetenceCalibrationEnv() {
    }

    /**
     * {@code sejourfr.competences} tel que le backend le lit, la version de
     * consignes et celle du contrat de sortie pouvant etre imposees par la
     * campagne ({@code -Dcalibration.rubrics}, {@code -Dcalibration.schema}).
     */
    static CompetenceProperties competences(String rubricsVersion, String toolSchemaVersion) {
        Map<String, Object> overrides = new LinkedHashMap<>();
        if (rubricsVersion != null) overrides.put("COMPETENCE_RUBRICS_VERSION", rubricsVersion);
        if (toolSchemaVersion != null) overrides.put("COMPETENCE_TOOL_SCHEMA_VERSION", toolSchemaVersion);
        return EvaluationConfigFixture.resolue(PREFIXE, new CompetenceProperties(), overrides);
    }

    /** Le bloc qui porte le fournisseur, le modele et ses tarifs. Jamais surcharge. */
    static ProductionEvaluationProperties correcteur() {
        return EvaluationConfigFixture.resolue();
    }

    /**
     * Client d'analyse ciblee du provider actif, cable exactement comme
     * {@code CompetenceLlmConfig} : meme classe, memes reglages, meme
     * tool-schema.
     */
    static CompetenceAnalysisLlmClient client(ProductionEvaluationProperties evalProps,
                                              CompetenceProperties props,
                                              ObjectMapper objectMapper) {
        String provider = evalProps.getProvider() == null ? "" : evalProps.getProvider().trim().toLowerCase();
        CompetenceAnalysisLlmClient client = switch (provider) {
            case "deepseek" -> {
                exigeCle(evalProps.getDeepseek().isConfigured(), "DeepSeek");
                yield new CompetenceOpenAiCompatibleClient(
                    evalProps.getDeepseek(), props.getAnalysis(), "DeepSeek", objectMapper);
            }
            case "openai" -> {
                exigeCle(evalProps.getOpenai().isConfigured(), "OpenAI");
                yield new CompetenceOpenAiCompatibleClient(
                    evalProps.getOpenai(), props.getAnalysis(), "OpenAI", objectMapper);
            }
            case "anthropic" -> new CompetenceAnthropicClient(
                evalProps.getAnthropic(), props.getAnalysis(), objectMapper);
            default -> throw new IllegalStateException(
                "sejourfr.production-evaluation.provider invalide : '" + evalProps.getProvider() + "'");
        };
        CalibrationEnv.postConstruct(client, "loadToolSchema");
        return client;
    }

    private static void exigeCle(boolean configured, String label) {
        if (!configured) {
            throw new IllegalStateException("Cle API absente pour le provider " + label
                + " — renseigner .env avant de lancer le banc.");
        }
    }
}
