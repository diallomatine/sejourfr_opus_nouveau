package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.config.ProductionEvaluationProperties;
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
import java.util.List;
import java.util.Map;

/**
 * Source UNIQUE des consignes du second appel : charge
 * {@code prompts/production-version-ciblee-rubrics-<version>.json}.
 *
 * <p>Même convention maison que {@code ProductionRubricsProvider} et
 * {@code CompetenceRubricsProvider} : <b>aucune consigne de contenu en dur dans
 * le Java</b>. Le rôle, ce que la version réécrite conserve du candidat, ce
 * qu'on n'écrit jamais, la forme des leviers et la règle d'accentuation vivent
 * dans les {@code commun.sections} ; les plafonds de longueur dans
 * {@code commun.contraintes_longueur} ; les ancres dans {@code commun.few_shot}.
 *
 * <p><b>Fail-fast au démarrage</b>, comme les deux autres : un fichier absent,
 * illisible, ou qui déclare un contrat de sortie différent de celui configuré
 * fait échouer le boot. Une bascule de version faite à moitié (consignes v2,
 * tool-schema v1) passerait sinon inaperçue jusqu'à la première sortie rejetée.
 *
 * <p>Le tool-schema, lui, est chargé par {@code VersionCibleeLlmConfig} et passé
 * aux clients — exactement comme côté productions et compétences.
 */
@Component
public class VersionCibleeRubricsProvider {

    private static final Logger log = LoggerFactory.getLogger(VersionCibleeRubricsProvider.class);
    private static final String PATH_FORMAT = "prompts/production-version-ciblee-rubrics-%s.json";

    /** Paires consignes -> tool-schema supportées. On versionne, on ne réécrit jamais. */
    private static final Map<String, String> TOOL_SCHEMA_BY_RUBRICS_VERSION = Map.of("v1", "v1");

    /** Ce module ne sert que le TCF IRN : aucune autre grille n'est acceptée. */
    private static final String PROFILE_ATTENDU = "TCF_IRN";

    private final ProductionEvaluationProperties props;
    private final ObjectMapper objectMapper;

    private Map<String, Object> commun = Map.of();
    private Map<String, Integer> contraintesLongueur = Map.of();

    public VersionCibleeRubricsProvider(ProductionEvaluationProperties props,
                                        ObjectMapper objectMapper) {
        this.props = props;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    void load() {
        String version = props.getVersionCiblee().getRubricsVersion();
        String path = String.format(PATH_FORMAT, version);
        try (InputStream is = new ClassPathResource(path).getInputStream()) {
            String json = StreamUtils.copyToString(is, StandardCharsets.UTF_8);
            Map<String, Object> root = objectMapper.readValue(
                json, new TypeReference<Map<String, Object>>() {});

            validateDeclaredContract(root, version);

            if (!(root.get("commun") instanceof Map<?, ?> communNode)) {
                throw new IllegalStateException("cle racine 'commun' absente ou invalide");
            }
            @SuppressWarnings("unchecked")
            Map<String, Object> communMap = (Map<String, Object>) communNode;

            if (!(communMap.get("sections") instanceof List<?> sections) || sections.isEmpty()) {
                throw new IllegalStateException("aucune section de consignes chargee");
            }
            if (!(communMap.get("few_shot") instanceof List<?> fewShot) || fewShot.isEmpty()) {
                throw new IllegalStateException("aucune ancre few-shot chargee");
            }

            this.contraintesLongueur = resolveContraintes(communMap.get("contraintes_longueur"));
            this.commun = Map.copyOf(communMap);

            log.info("Consignes « version au niveau vise » chargees ({}) : {} sections, {} ancres, "
                    + "plafonds {} mots, tool-schema {}",
                version, sections.size(), fewShot.size(), contraintesLongueur,
                props.getVersionCiblee().getToolSchemaVersion());
        } catch (Exception e) {
            throw new IllegalStateException(
                "Consignes « version au niveau vise » introuvables/illisibles (" + path
                    + ") — verifier sejourfr.production-evaluation.version-ciblee.rubrics-version", e);
        }
    }

    private void validateDeclaredContract(Map<String, Object> root, String configuredVersion) {
        if (!configuredVersion.equals(String.valueOf(root.get("rubrics-version")))) {
            throw new IllegalStateException("version de consignes incoherente : config="
                + configuredVersion + ", fichier=" + root.get("rubrics-version"));
        }
        String expectedSchema = TOOL_SCHEMA_BY_RUBRICS_VERSION.get(configuredVersion);
        if (expectedSchema == null) {
            throw new IllegalStateException(
                "version de consignes sans contrat de sortie supporte : " + configuredVersion);
        }
        Object declaredSchema = root.get("tool_schema_version");
        if (declaredSchema != null && !expectedSchema.equals(declaredSchema.toString())) {
            throw new IllegalStateException("declaration tool-schema incoherente : consignes "
                + configuredVersion + " -> " + declaredSchema + ", matrice -> " + expectedSchema);
        }
        if (!PROFILE_ATTENDU.equals(String.valueOf(root.get("profile")))) {
            throw new IllegalStateException(
                "profil de consignes non supporte : " + root.get("profile"));
        }
        String configuredSchema = props.getVersionCiblee().getToolSchemaVersion();
        if (configuredSchema != null && !configuredSchema.isBlank()
                && !expectedSchema.equals(configuredSchema)) {
            throw new IllegalStateException("contrat consignes/tool-schema incompatible : consignes "
                + configuredVersion + " -> " + expectedSchema + ", config -> " + configuredSchema);
        }
    }

    /** Bloc {@code commun} complet (sections, plafonds, ancres). */
    public Map<String, Object> getCommun() {
        return commun;
    }

    /** Version des consignes actives. */
    public String getVersion() {
        return props.getVersionCiblee().getRubricsVersion();
    }

    /**
     * Plafonds de longueur EN MOTS, par clé de sortie. Ils viennent du fichier
     * de consignes, pas du code : le jour où une v2 desserre un plafond, elle le
     * fait dans le fichier qui porte déjà la consigne correspondante, et les deux
     * ne peuvent pas diverger.
     */
    public Map<String, Integer> contraintesLongueur() {
        return contraintesLongueur;
    }

    private static Map<String, Integer> resolveContraintes(Object node) {
        if (!(node instanceof Map<?, ?> m) || m.isEmpty()) {
            throw new IllegalStateException("bloc 'commun.contraintes_longueur' absent ou vide");
        }
        Map<String, Integer> out = new LinkedHashMap<>();
        for (Map.Entry<?, ?> e : m.entrySet()) {
            if (!(e.getValue() instanceof Number n) || n.intValue() <= 0) {
                throw new IllegalStateException(
                    "plafond de longueur invalide pour '" + e.getKey() + "' : " + e.getValue());
            }
            out.put(e.getKey().toString(), n.intValue());
        }
        return Map.copyOf(out);
    }
}
