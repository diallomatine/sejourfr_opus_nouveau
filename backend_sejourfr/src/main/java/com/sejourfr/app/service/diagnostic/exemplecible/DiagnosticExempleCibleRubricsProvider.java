package com.sejourfr.app.service.diagnostic.exemplecible;

import com.sejourfr.app.config.DiagnosticProperties;
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
 * Source UNIQUE des consignes du SECOND appel du diagnostic : charge
 * {@code prompts/diagnostic-exemple-cible-rubrics-<version>.json}.
 *
 * <p>Meme convention maison que {@code DiagnosticRubricsProvider},
 * {@code VersionCibleeRubricsProvider} et
 * {@code CompetenceNiveauViseRubricsProvider} : <b>aucune consigne de contenu en
 * dur dans le Java</b>. Le role, la designation de la phrase par son numero, ce
 * que la reecriture garde du candidat, la regle des segments recopies,
 * l'interdiction de nommer un niveau et celle de vendre un moyen deja acquis
 * vivent dans les {@code commun.sections} ; les plafonds de longueur dans
 * {@code commun.contraintes_longueur} ; les ancres dans {@code commun.few_shot}.
 *
 * <p><b>Fail-fast au demarrage</b>, comme les autres : un fichier absent,
 * illisible, ou qui declare un contrat de sortie different de celui configure
 * fait echouer le boot. Une bascule faite a moitie (consignes v2, tool-schema v1)
 * passerait sinon inaperçue jusqu'a la premiere sortie rejetee — c'est-a-dire
 * jusqu'a un ecran de conversion silencieusement vide.
 */
@Component
public class DiagnosticExempleCibleRubricsProvider {

    private static final Logger log =
        LoggerFactory.getLogger(DiagnosticExempleCibleRubricsProvider.class);
    private static final String PATH_FORMAT = "prompts/diagnostic-exemple-cible-rubrics-%s.json";

    /** Paires consignes -> tool-schema supportees. On versionne, on ne reecrit jamais. */
    private static final Map<String, String> TOOL_SCHEMA_BY_RUBRICS_VERSION = Map.of("v1", "v1");

    /** Ce parcours ne sert que le TCF IRN : aucune autre grille n'est acceptee. */
    private static final String PROFILE_ATTENDU = "TCF_IRN";

    private final DiagnosticProperties props;
    private final ObjectMapper objectMapper;

    private Map<String, Object> commun = Map.of();
    private Map<String, Integer> contraintesLongueur = Map.of();

    public DiagnosticExempleCibleRubricsProvider(DiagnosticProperties props,
                                                 ObjectMapper objectMapper) {
        this.props = props;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    public void load() {
        String version = props.getExempleCible().getRubricsVersion();
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

            log.info("Consignes « avant / apres » du diagnostic chargees ({}) : {} sections, "
                    + "{} ancres, plafonds {} mots, tool-schema {}",
                version, sections.size(), fewShot.size(), contraintesLongueur,
                props.getExempleCible().getToolSchemaVersion());
        } catch (Exception e) {
            throw new IllegalStateException(
                "Consignes « avant / apres » introuvables/illisibles (" + path
                    + ") — verifier sejourfr.diagnostic.exemple-cible.rubrics-version", e);
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
        String configuredSchema = props.getExempleCible().getToolSchemaVersion();
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
        return props.getExempleCible().getRubricsVersion();
    }

    /**
     * Plafonds de longueur EN MOTS, par nom de champ terminal ({@code apport}).
     * Ils viennent du fichier de consignes, pas du code : le jour ou une v2
     * desserre un plafond, elle le fait dans le fichier qui porte deja la consigne
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
