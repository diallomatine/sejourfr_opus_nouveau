package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.enums.EpreuveType;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

/**
 * Source UNIQUE du "comment noter" propre a chaque tache : charge le fichier
 * {@code prompts/production-rubrics-<version>.json} (criteres + bareme +
 * descripteurs par niveau + consignes correcteur, par {@code (epreuve, tache)}).
 *
 * <p>Pendant per-tache des regles GLOBALES du system prompt. Si le fichier est
 * absent / une tache manque, {@link EvaluationPromptBuilder} retombe sur l'ancien
 * {@code production_tasks.criteres_evaluation} (DB) — d'ou la reversibilite.
 */
@Component
public class ProductionRubricsProvider {

    private static final Logger log = LoggerFactory.getLogger(ProductionRubricsProvider.class);
    private static final String PATH_FORMAT = "prompts/production-rubrics-%s.json";

    private final ProductionEvaluationProperties props;
    private final ObjectMapper objectMapper;
    /** Cle "TCF_EO:1" -> rubrique de la tache. */
    private Map<String, Map<String, Object>> rubrics = Map.of();

    public ProductionRubricsProvider(ProductionEvaluationProperties props, ObjectMapper objectMapper) {
        this.props = props;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    void load() {
        String version = props.getRubricsVersion();
        String path = String.format(PATH_FORMAT, version);
        Map<String, Map<String, Object>> built = new HashMap<>();
        try (InputStream is = new ClassPathResource(path).getInputStream()) {
            String json = StreamUtils.copyToString(is, StandardCharsets.UTF_8);
            Map<String, Object> root = objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
            for (Map.Entry<String, Object> epreuveEntry : root.entrySet()) {
                if (!(epreuveEntry.getValue() instanceof Map<?, ?> tasks)) continue; // skip "_doc"
                for (Map.Entry<?, ?> taskEntry : tasks.entrySet()) {
                    if (taskEntry.getValue() instanceof Map<?, ?> rubric) {
                        @SuppressWarnings("unchecked")
                        Map<String, Object> r = (Map<String, Object>) rubric;
                        built.put(key(epreuveEntry.getKey(), taskEntry.getKey().toString()), r);
                    }
                }
            }
            this.rubrics = Map.copyOf(built);
            log.info("Rubriques production chargees ({}) : {} taches", version, rubrics.size());
        } catch (Exception e) {
            log.warn("Rubriques production introuvables/illisibles ({}) — fallback DB criteres_evaluation ({})",
                path, e.getMessage());
            this.rubrics = Map.of();
        }
    }

    /** Rubrique fixe d'une tache, vide si absente (→ fallback DB cote builder). */
    public Optional<Map<String, Object>> find(EpreuveType epreuve, int tacheNumero) {
        if (epreuve == null) return Optional.empty();
        return Optional.ofNullable(rubrics.get(key(epreuve.name(), String.valueOf(tacheNumero))));
    }

    private static String key(Object epreuve, String tache) {
        return epreuve + ":" + tache;
    }
}
