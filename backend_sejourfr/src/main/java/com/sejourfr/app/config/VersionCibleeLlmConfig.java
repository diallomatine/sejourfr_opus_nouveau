package com.sejourfr.app.config;

import com.sejourfr.app.service.versionciblee.VersionCibleeAnthropicClient;
import com.sejourfr.app.service.versionciblee.VersionCibleeLlmClient;
import com.sejourfr.app.service.versionciblee.VersionCibleeOpenAiCompatibleClient;
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
 * Sélectionne le client du SECOND appel « version au niveau visé ».
 *
 * <p><b>Sur la MÊME clé que le reste du projet</b> :
 * {@code sejourfr.production-evaluation.provider}. Règle « un seul correcteur
 * configurable » — deux clés distinctes auraient permis à cette version de
 * tourner sur un modèle différent de celui qui a corrigé la même production,
 * sans que personne ne s'en aperçoive.
 *
 * <p>Ce qui reste propre à la fonctionnalité, c'est
 * {@code sejourfr.production-evaluation.version-ciblee} : contrat de sortie,
 * plafond de tokens, température, coupe-circuit.
 *
 * <p>Le tool-schema est chargé ICI, une fois, et passé aux trois clients : sans
 * ça, une version de schéma absente ne se serait manifestée qu'au premier appel
 * en production, sous la forme d'un bloc silencieusement manquant.
 */
@Configuration
public class VersionCibleeLlmConfig {

    private static final Logger log = LoggerFactory.getLogger(VersionCibleeLlmConfig.class);
    private static final String TOOL_SCHEMA_PATH_FORMAT =
        "prompts/production-version-ciblee-tool-schema-%s.json";

    @Bean
    public VersionCibleeLlmClient versionCibleeLlmClient(ProductionEvaluationProperties props,
                                                         ObjectMapper objectMapper) {
        Map<String, Object> toolSchema = loadToolSchema(
            props.getVersionCiblee().getToolSchemaVersion(), objectMapper);
        VersionCibleeLlmClient selected = select(props, toolSchema, objectMapper);
        log.info("Client « version au niveau vise » actif : {} (modele {}, tool-schema {}, actif={})",
            props.getProvider(), selected.getModelName(), selected.getToolSchemaVersion(),
            props.getVersionCiblee().isEnabled());
        return selected;
    }

    private static VersionCibleeLlmClient select(ProductionEvaluationProperties props,
                                                 Map<String, Object> toolSchema,
                                                 ObjectMapper objectMapper) {
        String provider = props.getProvider() == null ? "" : props.getProvider().trim().toLowerCase();
        return switch (provider) {
            case "openai" -> new VersionCibleeOpenAiCompatibleClient(
                props.getOpenai(), props.getVersionCiblee(), toolSchema, "OpenAI", objectMapper);
            case "deepseek" -> new VersionCibleeOpenAiCompatibleClient(
                props.getDeepseek(), props.getVersionCiblee(), toolSchema, "DeepSeek", objectMapper);
            case "anthropic" -> new VersionCibleeAnthropicClient(
                props.getAnthropic(), props.getVersionCiblee(), toolSchema, objectMapper);
            default -> throw new IllegalStateException(
                "sejourfr.production-evaluation.provider invalide : '" + props.getProvider()
                    + "'. Valeurs supportees : openai, anthropic, deepseek.");
        };
    }

    private static Map<String, Object> loadToolSchema(String version, ObjectMapper objectMapper) {
        String path = String.format(TOOL_SCHEMA_PATH_FORMAT, version);
        try (InputStream is = new ClassPathResource(path).getInputStream()) {
            String json = StreamUtils.copyToString(is, StandardCharsets.UTF_8);
            return objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new IllegalStateException("Tool-schema « version au niveau vise » introuvable ("
                + path + ") — verifier "
                + "sejourfr.production-evaluation.version-ciblee.tool-schema-version", e);
        }
    }
}
