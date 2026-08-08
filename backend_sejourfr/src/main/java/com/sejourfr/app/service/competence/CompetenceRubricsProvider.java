package com.sejourfr.app.service.competence;

import com.sejourfr.app.config.CompetenceProperties;
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
 * Source UNIQUE des consignes envoyees au correcteur de l'analyse ciblee :
 * charge {@code prompts/competence-analysis-rubrics-<version>.json}.
 *
 * <p>Meme convention maison que {@code ProductionRubricsProvider} : <b>aucune
 * regle de notation en dur dans le code Java</b>. Les quinze regles de
 * comportement et les interdictions vivent dans les {@code commun.sections}, les
 * plafonds de longueur dans {@code commun.contraintes_longueur}, la definition
 * des trois verdicts dans {@code commun.statuts}, les ancres dans
 * {@code commun.few_shot}. Le code ne fait que rendre et verifier.
 *
 * <p><b>Fail-fast au demarrage.</b> Un fichier absent, illisible, ou qui declare
 * un contrat different de celui configure fait echouer le boot. La consequence
 * de l'alternative serait pire : un backend qui demarre et qui note des
 * candidats avec des consignes qui ne sont pas celles qu'on croit.
 *
 * <p>Le contrat de sortie (tool-schema) reste un fichier separe, charge par les
 * clients LLM — exactement comme cote productions.
 */
@Component
public class CompetenceRubricsProvider {

    private static final Logger log = LoggerFactory.getLogger(CompetenceRubricsProvider.class);
    private static final String PATH_FORMAT = "prompts/competence-analysis-rubrics-%s.json";

    /**
     * Paires rubriques -> tool-schema supportees. v2 = v1 pour tout ce qui
     * juge, plus une exigence de FORME (le francais rendu au candidat est
     * accentue ; ce qui est cite reste tel quel) ; son contrat de sortie v2 est
     * celui de v1 avec ses descriptions accentuees, sans un champ de plus ni de
     * moins. v1/v1 reste chargeable : c'est le retour arriere.
     */
    private static final Map<String, String> TOOL_SCHEMA_BY_RUBRICS_VERSION =
        Map.of("v1", "v1", "v2", "v2");

    /** Le module ne sert que le TCF IRN : aucune autre grille n'est acceptee. */
    private static final String PROFILE_ATTENDU = "TCF_IRN";

    private final CompetenceProperties props;
    private final ObjectMapper objectMapper;

    /** Bloc {@code commun} du fichier, immuable une fois charge. */
    private Map<String, Object> commun = Map.of();
    /** Plafonds de longueur, en MOTS, par cle de sortie. */
    private Map<String, Integer> contraintesLongueur = Map.of();

    public CompetenceRubricsProvider(CompetenceProperties props, ObjectMapper objectMapper) {
        this.props = props;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    void load() {
        String version = props.getAnalysis().getRubricsVersion();
        String path = String.format(PATH_FORMAT, version);
        try (InputStream is = new ClassPathResource(path).getInputStream()) {
            String json = StreamUtils.copyToString(is, StandardCharsets.UTF_8);
            Map<String, Object> root = objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});

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

            log.info("Consignes d'analyse de competence chargees ({}) : {} sections, {} ancres, "
                    + "plafonds {} mots, tool-schema {}",
                version, sections.size(), fewShot.size(), contraintesLongueur,
                props.getAnalysis().getToolSchemaVersion());
        } catch (Exception e) {
            throw new IllegalStateException(
                "Consignes d'analyse de competence introuvables/illisibles (" + path
                    + ") — verifier sejourfr.competences.analysis.rubrics-version", e);
        }
    }

    /**
     * Verifie que le fichier charge est bien celui que la configuration croit
     * charger, et qu'il va avec le contrat de sortie configure. Sans ce
     * controle, une bascule de version faite a moitie (rubriques v2, tool-schema
     * v1) passerait inapercue jusqu'a la premiere sortie rejetee en production.
     */
    private void validateDeclaredContract(Map<String, Object> root, String configuredVersion) {
        if (!configuredVersion.equals(String.valueOf(root.get("rubrics-version")))) {
            throw new IllegalStateException("version de consignes incoherente : config="
                + configuredVersion + ", fichier=" + root.get("rubrics-version"));
        }

        String expectedSchema = TOOL_SCHEMA_BY_RUBRICS_VERSION.get(configuredVersion);
        if (expectedSchema == null) {
            throw new IllegalStateException("version de consignes sans contrat de sortie supporte : "
                + configuredVersion);
        }

        Object declaredSchema = root.get("tool_schema_version");
        if (declaredSchema != null && !expectedSchema.equals(declaredSchema.toString())) {
            throw new IllegalStateException("declaration tool-schema incoherente : consignes "
                + configuredVersion + " -> " + declaredSchema + ", matrice -> " + expectedSchema);
        }

        if (!PROFILE_ATTENDU.equals(String.valueOf(root.get("profile")))) {
            throw new IllegalStateException("profil de consignes non supporte : " + root.get("profile"));
        }

        String configuredSchema = props.getAnalysis().getToolSchemaVersion();
        if (configuredSchema != null && !configuredSchema.isBlank()
                && !expectedSchema.equals(configuredSchema)) {
            throw new IllegalStateException("contrat consignes/tool-schema incompatible : consignes "
                + configuredVersion + " -> " + expectedSchema + ", config -> " + configuredSchema);
        }
    }

    /** Bloc {@code commun} complet (sections, statuts, few-shot, plafonds). */
    public Map<String, Object> getCommun() {
        return commun;
    }

    /** Version des consignes actives, persistee sur chaque tentative analysee. */
    public String getVersion() {
        return props.getAnalysis().getRubricsVersion();
    }

    /**
     * Plafonds de longueur EN MOTS, par cle de sortie ({@code verdict},
     * {@code success_point}, {@code improvement_priority}). Ils viennent du
     * fichier de consignes, pas du code : le jour ou une v2 assouplit le
     * verdict, elle le fait dans le fichier qui porte deja la consigne
     * correspondante, et les deux ne peuvent pas diverger.
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
