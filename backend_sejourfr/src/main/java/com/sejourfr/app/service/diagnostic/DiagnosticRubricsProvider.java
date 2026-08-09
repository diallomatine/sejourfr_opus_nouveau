package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.config.DiagnosticProperties;
import jakarta.annotation.PostConstruct;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

/** Charge et valide au boot les consignes versionnées du profil diagnostic. */
@Component
public class DiagnosticRubricsProvider {

    private final DiagnosticProperties properties;
    private final ObjectMapper objectMapper;
    private List<Map<String, Object>> sections = List.of();

    public DiagnosticRubricsProvider(DiagnosticProperties properties, ObjectMapper objectMapper) {
        this.properties = properties;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    void load() {
        String version = properties.getAnalysis().getRubricsVersion();
        String path = "prompts/diagnostic-analysis-rubrics-" + version + ".json";
        try (InputStream input = new ClassPathResource(path).getInputStream()) {
            String json = StreamUtils.copyToString(input, StandardCharsets.UTF_8);
            Map<String, Object> root = objectMapper.readValue(
                    json, new TypeReference<Map<String, Object>>() {});
            if (!version.equals(String.valueOf(root.get("rubrics-version")))) {
                throw new IllegalStateException("version de rubriques incohérente");
            }
            String schema = properties.getAnalysis().getToolSchemaVersion();
            if (!schema.equals(String.valueOf(root.get("tool_schema_version")))) {
                throw new IllegalStateException("couplage rubriques/schéma diagnostic incohérent");
            }
            if (!(root.get("sections") instanceof List<?> raw) || raw.isEmpty()) {
                throw new IllegalStateException("sections diagnostic absentes");
            }
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> typed = (List<Map<String, Object>>) (List<?>) raw;
            this.sections = List.copyOf(typed);
        } catch (Exception e) {
            throw new IllegalStateException("Rubriques diagnostic invalides : " + path, e);
        }
    }

    public List<Map<String, Object>> sections() { return sections; }
    public String version() { return properties.getAnalysis().getRubricsVersion(); }
}
