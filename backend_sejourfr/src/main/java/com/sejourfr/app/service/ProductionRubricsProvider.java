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
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

/**
 * Source UNIQUE et exclusive du "comment noter" propre a chaque tache : charge
 * le fichier {@code prompts/production-rubrics-<version>.json} (criteres + poids,
 * bareme, descripteurs par niveau, consignes correcteur), indexe par
 * {@code (epreuve, tache)}.
 *
 * <p>Plus aucun fallback vers {@code production_tasks.criteres_evaluation} : la
 * notation vit a 100 % dans le fichier. Ajuster le bareme = editer le JSON, zero
 * migration. La coherence (toutes les taches actives couvertes, poids = 1, codes
 * canoniques) est verifiee au demarrage par {@link ProductionRubricsValidator}.
 *
 * <p>Format attendu (v2+) : un objet racine {@code {rubrics-version, rubrics:{...}}}
 * dont la map {@code rubrics} associe une cle plate {@code <EPREUVE>_T<n>}
 * (ex: {@code EE_T1}, {@code EO_T3}) a sa rubrique. La cle de lookup est derivee
 * de {@code (epreuve, tacheNumero)} : on retire le prefixe {@code TCF_} de
 * l'epreuve puis on suffixe {@code _T<n>}.
 */
@Component
public class ProductionRubricsProvider {

    private static final Logger log = LoggerFactory.getLogger(ProductionRubricsProvider.class);
    private static final String PATH_FORMAT = "prompts/production-rubrics-%s.json";

    private final ProductionEvaluationProperties props;
    private final ObjectMapper objectMapper;
    /** Cle "EE_T1" -> rubrique de la tache. */
    private Map<String, Map<String, Object>> rubrics = Map.of();

    public ProductionRubricsProvider(ProductionEvaluationProperties props, ObjectMapper objectMapper) {
        this.props = props;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    void load() {
        String version = props.getRubricsVersion();
        String path = String.format(PATH_FORMAT, version);
        Map<String, Map<String, Object>> built = new LinkedHashMap<>();
        try (InputStream is = new ClassPathResource(path).getInputStream()) {
            String json = StreamUtils.copyToString(is, StandardCharsets.UTF_8);
            Map<String, Object> root = objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
            if (!(root.get("rubrics") instanceof Map<?, ?> rubricsNode)) {
                throw new IllegalStateException("cle racine 'rubrics' absente ou invalide");
            }
            for (Map.Entry<?, ?> entry : rubricsNode.entrySet()) {
                if (entry.getValue() instanceof Map<?, ?> rubric) {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> r = (Map<String, Object>) rubric;
                    built.put(entry.getKey().toString(), r);
                }
            }
            if (built.isEmpty()) {
                throw new IllegalStateException("aucune rubrique chargee");
            }
            this.rubrics = Map.copyOf(built);
            log.info("Rubriques production chargees ({}) : {} taches", version, rubrics.size());
        } catch (Exception e) {
            // La notation n'a plus de fallback DB : un fichier absent/illisible est
            // une erreur de config bloquante (fail-fast au demarrage).
            throw new IllegalStateException(
                "Rubriques production introuvables/illisibles (" + path
                    + ") — verifier sejourfr.production-evaluation.rubrics-version", e);
        }
    }

    /** Rubrique fixe d'une tache, vide si absente. */
    public Optional<Map<String, Object>> find(EpreuveType epreuve, int tacheNumero) {
        if (epreuve == null) return Optional.empty();
        return Optional.ofNullable(rubrics.get(key(epreuve, tacheNumero)));
    }

    /** Vue immuable de toutes les rubriques chargees (cle -> rubrique), pour la validation au boot. */
    public Map<String, Map<String, Object>> all() {
        return rubrics;
    }

    /**
     * Cle de lookup derivee de {@code (epreuve, tache)} : {@code TCF_EE} + tache 1
     * -> {@code EE_T1}. On retire le prefixe {@code TCF_} s'il est present.
     */
    static String key(EpreuveType epreuve, int tacheNumero) {
        String name = epreuve.name();
        String prefix = name.startsWith("TCF_") ? name.substring(4) : name;
        return prefix + "_T" + tacheNumero;
    }
}
