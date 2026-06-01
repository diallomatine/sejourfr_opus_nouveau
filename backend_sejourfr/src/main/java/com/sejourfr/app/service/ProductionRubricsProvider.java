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
 * Source UNIQUE de TOUTES les instructions a l'IA d'evaluation : charge le
 * fichier {@code prompts/production-rubrics-<version>.json} (v3+).
 *
 * <p>Deux blocs :
 * <ul>
 *   <li>{@code commun} : le GLOBAL — {@code sections} (liste ordonnee
 *       {@code {titre, contenu}}) + {@code few_shot} (ancres de calibration).
 *       Rendu tel quel dans le system prompt par {@link EvaluationPromptBuilder}.</li>
 *   <li>{@code rubrics.<EE|EO>_T<n>} : le PAR-TACHE — {@code criteres} (+poids+label),
 *       {@code bareme_note}, {@code descripteurs} A1-C2, {@code consignes_correcteur}.</li>
 * </ul>
 *
 * <p>Le code ne fait que RENDRE ce fichier : aucune instruction de notation en
 * dur, plus aucun fallback DB {@code criteres_evaluation}. La cle de tache est
 * derivee de {@code (epreuve, tacheNumero)} : on retire le prefixe {@code TCF_}
 * puis on suffixe {@code _T<n>} ({@code TCF_EE} + 1 -> {@code EE_T1}). Coherence
 * verifiee au boot par {@link ProductionRubricsValidator}. Le tool-schema (contrat
 * de sortie) reste un fichier separe, hors de ce provider.
 */
@Component
public class ProductionRubricsProvider {

    private static final Logger log = LoggerFactory.getLogger(ProductionRubricsProvider.class);
    private static final String PATH_FORMAT = "prompts/production-rubrics-%s.json";

    private final ProductionEvaluationProperties props;
    private final ObjectMapper objectMapper;
    /** Bloc {@code commun} (sections + few_shot), global a toutes les taches. */
    private Map<String, Object> commun = Map.of();
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

            if (!(root.get("commun") instanceof Map<?, ?> communNode)) {
                throw new IllegalStateException("cle racine 'commun' absente ou invalide");
            }
            @SuppressWarnings("unchecked")
            Map<String, Object> communMap = (Map<String, Object>) communNode;

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
            this.commun = Map.copyOf(communMap);
            this.rubrics = Map.copyOf(built);
            log.info("Rubriques production chargees ({}) : {} sections communes, {} taches",
                version, sectionCount(), rubrics.size());
        } catch (Exception e) {
            // Source unique des instructions : un fichier absent/illisible est une
            // erreur de config bloquante (fail-fast au demarrage).
            throw new IllegalStateException(
                "Rubriques production introuvables/illisibles (" + path
                    + ") — verifier sejourfr.production-evaluation.rubrics-version", e);
        }
    }

    /** Bloc {@code commun} (global) : {@code sections} + {@code few_shot}. */
    public Map<String, Object> getCommun() {
        return commun;
    }

    /** Rubrique d'une tache (cle {@code <EE|EO>_T<n>}), vide si absente. */
    public Optional<Map<String, Object>> getTask(EpreuveType epreuve, int tacheNumero) {
        if (epreuve == null) return Optional.empty();
        return Optional.ofNullable(rubrics.get(key(epreuve, tacheNumero)));
    }

    /** Alias historique de {@link #getTask(EpreuveType, int)}. */
    public Optional<Map<String, Object>> find(EpreuveType epreuve, int tacheNumero) {
        return getTask(epreuve, tacheNumero);
    }

    /** Vue immuable de toutes les rubriques chargees (cle -> rubrique), pour la validation au boot. */
    public Map<String, Map<String, Object>> all() {
        return rubrics;
    }

    private int sectionCount() {
        return commun.get("sections") instanceof java.util.List<?> l ? l.size() : 0;
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
