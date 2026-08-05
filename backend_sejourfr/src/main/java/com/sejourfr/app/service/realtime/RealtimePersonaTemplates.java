package com.sejourfr.app.service.realtime;

import com.sejourfr.app.config.RealtimeProperties;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Source UNIQUE des gabarits de persona de l'examinateur temps reel (couche
 * CONDUITE). Charge {@code prompts/realtime-personas-<version>.json}, la version
 * etant pilotee par {@code sejourfr.realtime.persona-version} — meme logique
 * versionnee que {@code production-rubrics} (le SCORING). Externaliser la persona
 * permet de la reecrire/versionner sans toucher au code et garde les prompts
 * provider-agnostic (la config VAD specifique Gemini vit ailleurs).
 *
 * <p>Le fichier porte trois blocs obligatoires, chacun une liste de lignes jointes
 * par des retours a la ligne : {@code regles} (communes T1/T2), {@code t1} et
 * {@code t2}. Les placeholders ({@code {niveauCible}}, {@code {dureeSec}},
 * {@code {contexte}}, {@code {consigne}}) sont substitues par
 * {@link RealtimePersonaBuilder}.
 *
 * <p>Depuis la v2, deux blocs OPTIONNELS portent la fiche de scenario T2
 * ({@code entity/AgentRoleCard}) : {@code t2Fiche} (gabarit du bloc injecte a la
 * place de {@code {ficheScenario}}) et {@code relations} (libelle de registre par
 * {@code enums/AgentRelation}). Absents — c'est le cas de la v1 — le builder rend
 * la T2 exactement comme avant : aucun sujet existant ne se degrade.
 *
 * <p>Fichier absent/illisible = erreur de config bloquante (fail-fast au boot),
 * comme les rubriques : la persona verrouillee dans le token en depend.
 */
@Slf4j
@Component
public class RealtimePersonaTemplates {

    private static final String PATH_FORMAT = "prompts/realtime-personas-%s.json";

    private final RealtimeProperties props;
    private final ObjectMapper objectMapper;

    private String regles = "";
    private String t1 = "";
    private String t2 = "";
    private String t2Fiche = "";
    private Map<String, String> relations = Map.of();

    public RealtimePersonaTemplates(RealtimeProperties props, ObjectMapper objectMapper) {
        this.props = props;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    void load() {
        String version = props.getPersonaVersion();
        String path = String.format(PATH_FORMAT, version);
        try (InputStream is = new ClassPathResource(path).getInputStream()) {
            String json = StreamUtils.copyToString(is, StandardCharsets.UTF_8);
            JsonNode root = objectMapper.readTree(json);
            this.regles = joinLines(root, "regles");
            this.t1 = joinLines(root, "t1");
            this.t2 = joinLines(root, "t2");
            this.t2Fiche = joinOptionalLines(root, "t2Fiche");
            this.relations = readMap(root, "relations");
            log.info("Persona realtime chargee ({}) : regles {} c., t1 {} c., t2 {} c., fiche T2 {} c. ({} registres).",
                    version, regles.length(), t1.length(), t2.length(), t2Fiche.length(), relations.size());
        } catch (Exception e) {
            throw new IllegalStateException(
                    "Persona realtime introuvable/illisible (" + path
                            + ") — verifier sejourfr.realtime.persona-version", e);
        }
    }

    /** Bloc de regles communes aux taches 1 et 2 (avec placeholders). */
    public String regles() {
        return regles;
    }

    /** Gabarit de la tache 1 (entretien dirige), avec placeholders. */
    public String t1() {
        return t1;
    }

    /** Gabarit de la tache 2 (interaction / jeu de role), avec placeholders. */
    public String t2() {
        return t2;
    }

    /**
     * Gabarit du bloc « fiche de scenario » injecte dans la T2. Vide si la version
     * chargee ne le porte pas (v1) : la T2 est alors rendue sans fiche.
     */
    public String t2Fiche() {
        return t2Fiche;
    }

    /** Libelle de registre par {@code AgentRelation}. Vide si la version ne le porte pas. */
    public Map<String, String> relations() {
        return relations;
    }

    private static String joinLines(JsonNode root, String field) {
        JsonNode node = root.get(field);
        if (node == null || !node.isArray() || node.isEmpty()) {
            throw new IllegalStateException("Bloc persona '" + field + "' absent ou vide.");
        }
        List<String> lines = new ArrayList<>();
        node.forEach(line -> lines.add(line.asString()));
        return String.join("\n", lines);
    }

    private static String joinOptionalLines(JsonNode root, String field) {
        JsonNode node = root.get(field);
        return (node == null || !node.isArray() || node.isEmpty()) ? "" : joinLines(root, field);
    }

    private static Map<String, String> readMap(JsonNode root, String field) {
        JsonNode node = root.get(field);
        if (node == null || !node.isObject()) {
            return Map.of();
        }
        Map<String, String> out = new LinkedHashMap<>();
        node.properties().forEach(entry -> out.put(entry.getKey(), entry.getValue().asString()));
        return Map.copyOf(out);
    }
}
