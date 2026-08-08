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
    private static final Map<String, String> TOOL_SCHEMA_BY_RUBRICS_VERSION = Map.ofEntries(
        Map.entry("v3", "v2"),
        Map.entry("v4", "v2"),
        Map.entry("v4.1", "v2"),
        Map.entry("v4.2", "v2"),
        Map.entry("v5", "v3"),
        Map.entry("v6", "v3"),
        Map.entry("v7", "v4"),
        Map.entry("v8", "v5"),
        // v9 ne touche a AUCUN champ de sortie (elle ne change que les deux
        // sections orales du prompt) : elle reste donc sur le contrat v5.
        Map.entry("v9", "v5"),
        // v10 et v11 non plus : elles n'ajoutent qu'une regle de LANGUE dans la
        // section orale des artefacts (asymetrique EE/EO). Meme contrat v5.
        // v11 SUCCEDE a v10 : meme regle, un tiers du texte en moins, sanction
        // enoncee avant tolerance. v10 est conservee chargeable — c'est elle
        // qu'a mesuree la campagne du 2026-08-07.
        Map.entry("v10", "v5"),
        Map.entry("v11", "v5"),
        // v12 = v9 au bit pres pour tout ce qui note ; elle ne change que la
        // FORME DE LA PREUVE (numero de segment au lieu d'une citation
        // recopiee), donc elle exige le contrat de sortie v6. v9/v5 reste
        // chargeable et activable : c'est le retour arriere, sans migration.
        Map.entry("v12", "v6"),
        // v13 = v12 au bit pres, PLUS une section : le francais rendu au
        // candidat doit etre ACCENTUE (et ce qui est cite, recopie tel quel).
        // Rien de ce qui note ne bouge. Le contrat de sortie v7 est celui de
        // v6 avec ses descriptions accentuees et la meme reserve de citation :
        // aucun champ ajoute, aucun champ retire.
        Map.entry("v13", "v7")
    );

    /**
     * Versions qui declarent le profil strict TCF IRN : {@code profile} et
     * {@code niveau_max} y sont verifies au chargement.
     */
    private static final java.util.Set<String> PROFILS_TCF_IRN =
        java.util.Set.of("v7", "v8", "v9", "v10", "v11", "v12", "v13");

    private final ProductionEvaluationProperties props;
    private final ObjectMapper objectMapper;
    /** Bloc {@code commun} (sections + few_shot), global a toutes les taches. */
    private Map<String, Object> commun = Map.of();
    /** Cle "EE_T1" -> rubrique de la tache. */
    private Map<String, Map<String, Object>> rubrics = Map.of();
    /** Passage note -> niveau EFFECTIF : bloc {@code commun.niveau} du fichier, sinon la config. */
    private ProductionEvaluationProperties.NiveauCecrl niveauCecrl;
    /** Garde-fou de couplage EFFECTIF : bloc {@code commun.couplage} du fichier, sinon la config. */
    private ProductionEvaluationProperties.Couplage couplage;
    /** Plafonds de niveau EFFECTIFS : bloc {@code commun.plafonds} du fichier, sinon la config. */
    private ProductionEvaluationProperties.Plafonds plafonds;
    /** Bandes qualitatives EFFECTIVES : bloc {@code commun.bandes_criteres} du fichier, sinon la config. */
    private ProductionEvaluationProperties.BandesCriteres bandesCriteres;

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

            validateDeclaredContract(root, version);

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
            this.couplage = resolveCouplage(communMap.get("couplage"));
            this.plafonds = resolvePlafonds(communMap.get("plafonds"));
            this.bandesCriteres = resolveBandes(communMap.get("bandes_criteres"));
            log.info("Rubriques production chargees ({}) : {} sections communes, {} taches, "
                    + "niveau depuis {} (criteres {}, seuils B2={} B1={} A2={}), "
                    + "couplage ecart-max={}, bandes criteres {}/{}/{}",
                version, sectionCount(), rubrics.size(),
                communMap.get("niveau") instanceof Map<?, ?> ? "le fichier" : "la config",
                niveauCecrl.getSourceCriteres(), niveauCecrl.getSeuilB2(),
                niveauCecrl.getSeuilB1(), niveauCecrl.getSeuilA2(),
                couplage.getEcartMax(), bandesCriteres.getTresBonneMaitrise(),
                bandesCriteres.getSatisfaisant(), bandesCriteres.getEnCoursAcquisition());
        } catch (Exception e) {
            // Source unique des instructions : un fichier absent/illisible est une
            // erreur de config bloquante (fail-fast au demarrage).
            throw new IllegalStateException(
                "Rubriques production introuvables/illisibles (" + path
                    + ") — verifier sejourfr.production-evaluation.rubrics-version", e);
        }
    }

    /**
     * Verifie la paire rubriques/tool-schema avant la premiere evaluation.
     * Les fichiers historiques ne declaraient pas ce lien, donc la matrice
     * reste explicite ici : v3-v4.2 -> v2, v5-v6 -> v3, v7 -> v4,
     * v8/v9/v10/v11 -> v5, v12 -> v6, v13 -> v7.
     */
    private void validateDeclaredContract(Map<String, Object> root, String configuredVersion) {
        if (!configuredVersion.equals(String.valueOf(root.get("rubrics-version")))) {
            throw new IllegalStateException("version de rubriques incoherente : config="
                + configuredVersion + ", fichier=" + root.get("rubrics-version"));
        }

        String expectedSchema = TOOL_SCHEMA_BY_RUBRICS_VERSION.get(configuredVersion);
        if (expectedSchema == null) {
            throw new IllegalStateException("version de rubriques sans contrat de sortie supporte : "
                + configuredVersion);
        }

        Object declaredSchema = root.get("tool_schema_version");
        if (declaredSchema != null && !expectedSchema.equals(declaredSchema.toString())) {
            throw new IllegalStateException("declaration tool-schema incoherente : rubriques "
                + configuredVersion + " -> " + declaredSchema + ", matrice -> " + expectedSchema);
        }

        if (PROFILS_TCF_IRN.contains(configuredVersion)) {
            Object profile = root.get("profile");
            if (!"TCF_IRN".equals(String.valueOf(profile))) {
                throw new IllegalStateException("profil de rubriques non supporte : " + profile);
            }
            if (!"B2".equals(String.valueOf(root.get("niveau_max")))) {
                throw new IllegalStateException("le profil TCF IRN doit etre plafonne a B2");
            }
        }

        String activeSchema = activePromptVersion();
        // Les tests unitaires construisent parfois les proprietes sans passer
        // par le binder YAML. En production la valeur est toujours renseignee.
        if (activeSchema != null && !activeSchema.isBlank() && !expectedSchema.equals(activeSchema)) {
            throw new IllegalStateException("contrat rubriques/tool-schema incompatible : rubriques "
                + configuredVersion + " -> " + expectedSchema + ", provider "
                + props.getProvider() + " -> " + activeSchema);
        }
    }

    private String activePromptVersion() {
        String provider = props.getProvider() == null ? "" : props.getProvider().trim().toLowerCase();
        return switch (provider) {
            case "anthropic" -> props.getAnthropic().getPromptVersion();
            case "openai" -> props.getOpenai().getPromptVersion();
            case "deepseek" -> props.getDeepseek().getPromptVersion();
            default -> null; // EvaluationLlmConfig produira l'erreur de provider explicite.
        };
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
     * <p>C'est ce qui evite une troisieme bascule de configuration lors du
     * retour a une version anterieure : la paire rubriques/tool-schema suffit.
     * Sans ce mecanisme, revenir a v4.2 avec les seuils de v5 en config
     * donnerait des niveaux faux.
     */
    public ProductionEvaluationProperties.NiveauCecrl niveauCecrl() {
        return niveauCecrl == null ? props.getNiveauCecrl() : niveauCecrl;
    }

    /**
     * Garde-fou de couplage EFFECTIF. Le coupe-circuit ({@code enabled}) et les
     * listes de codes restent du ressort du deploiement ; seul {@code ecart_max}
     * est une propriete de l'ECHELLE, donc de la grille : +4 sur une echelle ou
     * le B2 commence a 16 et +1 sur celle du TCF concedent la meme protection.
     */
    public ProductionEvaluationProperties.Couplage couplage() {
        return couplage == null ? props.getCouplage() : couplage;
    }

    /**
     * Plafonds de niveau EFFECTIFS. Leurs seuils se lisent sur la note d'un
     * critere : ils suivent donc l'echelle de la grille, pas le deploiement.
     */
    public ProductionEvaluationProperties.Plafonds plafonds() {
        return plafonds == null ? props.getPlafonds() : plafonds;
    }

    /**
     * Bandes qualitatives EFFECTIVES affichees aux candidats a la place du
     * nombre. Memes bornes que les paliers de la grille active : les laisser en
     * dur ferait afficher « en cours d'acquisition » a un bon B1 des que
     * l'echelle change.
     */
    public ProductionEvaluationProperties.BandesCriteres bandesCriteres() {
        return bandesCriteres == null ? props.getBandesCriteres() : bandesCriteres;
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

    /** Fusionne {@code commun.couplage} avec la config : seul {@code ecart_max} vient du fichier. */
    private ProductionEvaluationProperties.Couplage resolveCouplage(Object node) {
        ProductionEvaluationProperties.Couplage base = props.getCouplage();
        if (!(node instanceof Map<?, ?> m)) return base;
        ProductionEvaluationProperties.Couplage out = new ProductionEvaluationProperties.Couplage();
        out.setEnabled(base.isEnabled());
        out.setCriteresRealisation(base.getCriteresRealisation());
        out.setCriteresLangue(base.getCriteresLangue());
        out.setEcartMax(nombre(m.get("ecart_max"), base.getEcartMax()));
        return out;
    }

    /** Fusionne {@code commun.plafonds} avec la config : seuls les SEUILS viennent du fichier. */
    private ProductionEvaluationProperties.Plafonds resolvePlafonds(Object node) {
        ProductionEvaluationProperties.Plafonds base = props.getPlafonds();
        if (!(node instanceof Map<?, ?> m)) return base;
        ProductionEvaluationProperties.Plafonds out = new ProductionEvaluationProperties.Plafonds();
        out.setEnabled(base.isEnabled());
        out.setPrisePositionNiveauMax(base.getPrisePositionNiveauMax());
        out.setConduiteEchangeNiveauMax(base.getConduiteEchangeNiveauMax());
        out.setPrisePositionSeuil(nombre(m.get("prise_position_seuil"), base.getPrisePositionSeuil()));
        out.setConduiteEchangeSeuil(nombre(m.get("conduite_echange_seuil"), base.getConduiteEchangeSeuil()));
        return out;
    }

    /** Fusionne {@code commun.bandes_criteres} avec la config (le fichier gagne). */
    private ProductionEvaluationProperties.BandesCriteres resolveBandes(Object node) {
        ProductionEvaluationProperties.BandesCriteres base = props.getBandesCriteres();
        if (!(node instanceof Map<?, ?> m)) return base;
        ProductionEvaluationProperties.BandesCriteres out = new ProductionEvaluationProperties.BandesCriteres();
        out.setTresBonneMaitrise(nombre(m.get("tres_bonne_maitrise"), base.getTresBonneMaitrise()));
        out.setSatisfaisant(nombre(m.get("satisfaisant"), base.getSatisfaisant()));
        out.setEnCoursAcquisition(nombre(m.get("en_cours_acquisition"), base.getEnCoursAcquisition()));
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
