package com.sejourfr.app.config;

import com.sejourfr.app.service.diagnostic.exemplecible.DiagnosticExempleCibleAnthropicClient;
import com.sejourfr.app.service.diagnostic.exemplecible.DiagnosticExempleCibleLlmClient;
import com.sejourfr.app.service.diagnostic.exemplecible.DiagnosticExempleCibleOpenAiCompatibleClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.util.StreamUtils;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Map;

/**
 * Selectionne le client du SECOND appel du diagnostic, « avant / apres ».
 *
 * <p><b>Sur la MEME cle que le reste du projet</b> :
 * {@code sejourfr.production-evaluation.provider}. Regle « un seul correcteur
 * configurable » — deux cles distinctes auraient permis a cette reecriture de
 * tourner sur un modele different de celui qui a analyse la meme production, sans
 * que personne ne s'en aperçoive.
 *
 * <p>Ce qui reste propre a la fonctionnalite, c'est
 * {@code sejourfr.diagnostic.exemple-cible} : contrat de sortie, plafond de
 * tokens, temperature, coupe-circuit.
 *
 * <p>Le tool-schema est charge ICI, une fois, au BOOT, et passe au client : sans
 * ça, une version de schema absente ne se serait manifestee qu'au premier appel
 * en production, sous la forme d'un bloc silencieusement manquant sur l'ecran de
 * conversion.
 */
@Configuration
public class DiagnosticExempleCibleLlmConfig {

    private static final Logger log =
        LoggerFactory.getLogger(DiagnosticExempleCibleLlmConfig.class);
    private static final String TOOL_SCHEMA_PATH_FORMAT =
        "prompts/diagnostic-exemple-cible-tool-schema-%s.json";

    @Bean
    public DiagnosticExempleCibleLlmClient diagnosticExempleCibleLlmClient(
            ProductionEvaluationProperties evalProps, DiagnosticProperties props,
            ObjectMapper objectMapper) {
        Map<String, Object> toolSchema = loadToolSchema(
            props.getExempleCible().getToolSchemaVersion(), objectMapper);
        DiagnosticExempleCibleLlmClient selected =
            select(evalProps, props, toolSchema, objectMapper);
        log.info("Client « avant / apres » (diagnostic) actif : {} (modele {}, tool-schema {}, "
                + "actif={})",
            evalProps.getProvider(), selected.getModelName(), selected.getToolSchemaVersion(),
            props.getExempleCible().isEnabled());
        return selected;
    }

    private static DiagnosticExempleCibleLlmClient select(ProductionEvaluationProperties evalProps,
                                                          DiagnosticProperties props,
                                                          Map<String, Object> toolSchema,
                                                          ObjectMapper objectMapper) {
        String provider = evalProps.getProvider() == null
            ? "" : evalProps.getProvider().trim().toLowerCase();
        return switch (provider) {
            case "openai" -> new DiagnosticExempleCibleOpenAiCompatibleClient(
                evalProps.getOpenai(), props.getExempleCible(), toolSchema, "OpenAI", objectMapper);
            case "deepseek" -> new DiagnosticExempleCibleOpenAiCompatibleClient(
                evalProps.getDeepseek(), props.getExempleCible(), toolSchema, "DeepSeek",
                objectMapper);
            case "anthropic" -> new DiagnosticExempleCibleAnthropicClient(
                evalProps.getAnthropic(), props.getExempleCible(), toolSchema, objectMapper);
            default -> throw new IllegalStateException(
                "sejourfr.production-evaluation.provider invalide : '" + evalProps.getProvider()
                    + "'. Valeurs supportees : openai, anthropic, deepseek.");
        };
    }

    private static Map<String, Object> loadToolSchema(String version, ObjectMapper objectMapper) {
        String path = String.format(TOOL_SCHEMA_PATH_FORMAT, version);
        try (InputStream is = new ClassPathResource(path).getInputStream()) {
            String json = StreamUtils.copyToString(is, StandardCharsets.UTF_8);
            return objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new IllegalStateException("Tool-schema « avant / apres » introuvable (" + path
                + ") — verifier sejourfr.diagnostic.exemple-cible.tool-schema-version", e);
        }
    }
}
