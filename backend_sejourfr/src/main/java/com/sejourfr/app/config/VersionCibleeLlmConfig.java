package com.sejourfr.app.config;

import com.sejourfr.app.service.versionciblee.VersionCibleeAnthropicClient;
import com.sejourfr.app.service.versionciblee.VersionCibleeContrat;
import com.sejourfr.app.service.versionciblee.VersionCibleeLlmClient;
import com.sejourfr.app.service.versionciblee.VersionCibleeOpenAiCompatibleClient;
import com.sejourfr.app.service.versionciblee.VersionCibleeTools;
import com.sejourfr.app.service.versionciblee.VersionCibleeVariante;
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
import java.util.EnumMap;
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
    /**
     * Contrat de sortie propre a l'ORAL : on n'y reecrit pas la production, on
     * reformule des passages designes par leur numero. Il n'existe qu'a partir
     * du contrat qui l'ouvre ({@link VersionCibleeContrat#oral()}).
     */
    private static final String TOOL_SCHEMA_ORAL_PATH_FORMAT =
        "prompts/production-version-ciblee-tool-schema-oral-%s.json";

    @Bean
    public VersionCibleeLlmClient versionCibleeLlmClient(ProductionEvaluationProperties props,
                                                         ObjectMapper objectMapper) {
        VersionCibleeTools tools = loadTools(
            props.getVersionCiblee().getToolSchemaVersion(), objectMapper);
        VersionCibleeLlmClient selected = select(props, tools, objectMapper);
        log.info("Client « version au niveau vise » actif : {} (modele {}, tool-schema {}, "
                + "variantes {}, actif={})",
            props.getProvider(), selected.getModelName(), selected.getToolSchemaVersion(),
            tools.schemas().keySet(), props.getVersionCiblee().isEnabled());
        return selected;
    }

    /**
     * Charge UN schema par variante existante. Un fichier absent fait echouer le
     * boot : sans ça, l'absence ne se manifesterait qu'au premier appel en
     * production, sous la forme d'un bloc silencieusement manquant.
     */
    private static VersionCibleeTools loadTools(String version, ObjectMapper objectMapper) {
        VersionCibleeContrat contrat = VersionCibleeContrat.of(version);
        Map<VersionCibleeVariante, Map<String, Object>> schemas =
            new EnumMap<>(VersionCibleeVariante.class);
        schemas.put(VersionCibleeVariante.ECRIT,
            loadToolSchema(TOOL_SCHEMA_PATH_FORMAT, version, objectMapper));
        if (contrat.oral()) {
            schemas.put(VersionCibleeVariante.ORAL,
                loadToolSchema(TOOL_SCHEMA_ORAL_PATH_FORMAT, version, objectMapper));
        }
        return new VersionCibleeTools(contrat, schemas);
    }

    private static VersionCibleeLlmClient select(ProductionEvaluationProperties props,
                                                 VersionCibleeTools tools,
                                                 ObjectMapper objectMapper) {
        String provider = props.getProvider() == null ? "" : props.getProvider().trim().toLowerCase();
        return switch (provider) {
            case "openai" -> new VersionCibleeOpenAiCompatibleClient(
                props.getOpenai(), props.getVersionCiblee(), tools, "OpenAI", objectMapper);
            case "deepseek" -> new VersionCibleeOpenAiCompatibleClient(
                props.getDeepseek(), props.getVersionCiblee(), tools, "DeepSeek", objectMapper);
            case "anthropic" -> new VersionCibleeAnthropicClient(
                props.getAnthropic(), props.getVersionCiblee(), tools, objectMapper);
            default -> throw new IllegalStateException(
                "sejourfr.production-evaluation.provider invalide : '" + props.getProvider()
                    + "'. Valeurs supportees : openai, anthropic, deepseek.");
        };
    }

    private static Map<String, Object> loadToolSchema(String pathFormat, String version,
                                                      ObjectMapper objectMapper) {
        String path = String.format(pathFormat, version);
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
