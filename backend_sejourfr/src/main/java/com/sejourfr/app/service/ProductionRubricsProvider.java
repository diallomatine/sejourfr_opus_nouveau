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
    /** Passage note -> niveau EFFECTIF : bloc {@code commun.niveau} du fichier, sinon la config. */
    private ProductionEvaluationProperties.NiveauCecrl niveauCecrl;

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
            this.niveauCecrl = resolveNiveau(communMap.get("niveau"));
            log.info("Rubriques production chargees ({}) : {} sections communes, {} taches, "
                    + "niveau depuis {} (criteres {}, seuils B2={} B1={} A2={})",
                version, sectionCount(), rubrics.size(),
                communMap.get("niveau") instanceof Map<?, ?> ? "le fichier" : "la config",
                niveauCecrl.getSourceCriteres(), niveauCecrl.getSeuilB2(),
                niveauCecrl.getSeuilB1(), niveauCecrl.getSeuilA2());
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

    /**
     * Reglages EFFECTIFS du passage note -> niveau (criteres porteurs + seuils).
     *
     * <p>Les criteres qui portent le niveau sont une propriete de la GRILLE, pas
     * du deploiement : une grille v4.2 derive le niveau de
     * {@code lexique+morphosyntaxe+coherence}, une grille v5 (celle du TCF) le
     * derive des QUATRE criteres equiponderes, donc de la note elle-meme. Le
     * fichier de rubriques peut donc declarer son propre bloc
     * {@code commun.niveau} ({@code source_criteres}, {@code seuil_b2},
     * {@code seuil_b1}, {@code seuil_a2}) ; a defaut on retombe sur
     * {@code sejourfr.production-evaluation.niveau-cecrl}.
     *
     * <p>C'est ce qui permet a {@code EVAL_RUBRICS_VERSION} <b>seule</b> de
     * suffire pour revenir a une version anterieure : sans ce mecanisme, revenir
     * a v4.2 avec les seuils de v5 en config donnerait des niveaux faux.
     */
    public ProductionEvaluationProperties.NiveauCecrl niveauCecrl() {
        return niveauCecrl == null ? props.getNiveauCecrl() : niveauCecrl;
    }

    /** Fusionne le bloc {@code commun.niveau} du fichier avec la config (le fichier gagne). */
    private ProductionEvaluationProperties.NiveauCecrl resolveNiveau(Object node) {
        ProductionEvaluationProperties.NiveauCecrl base = props.getNiveauCecrl();
        if (!(node instanceof Map<?, ?> m)) return base;
        ProductionEvaluationProperties.NiveauCecrl out = new ProductionEvaluationProperties.NiveauCecrl();
        out.setPoidsTaches(base.getPoidsTaches());
        out.setSourceCriteres(codes(m.get("source_criteres"), base.getSourceCriteres()));
        out.setSeuilB2(nombre(m.get("seuil_b2"), base.getSeuilB2()));
        out.setSeuilB1(nombre(m.get("seuil_b1"), base.getSeuilB1()));
        out.setSeuilA2(nombre(m.get("seuil_a2"), base.getSeuilA2()));
        return out;
    }

    private static java.util.List<String> codes(Object raw, java.util.List<String> defaut) {
        if (!(raw instanceof java.util.List<?> l) || l.isEmpty()) return defaut;
        return l.stream().filter(java.util.Objects::nonNull).map(Object::toString).toList();
    }

    private static double nombre(Object raw, double defaut) {
        return raw instanceof Number n ? n.doubleValue() : defaut;
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
