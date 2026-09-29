package com.sejourfr.app.service.competence.niveauvise;

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
 * Source UNIQUE des consignes du SECOND appel du module Competences : charge
 * {@code prompts/competence-niveau-vise-rubrics-<version>.json}.
 *
 * <p>Meme convention maison que {@code CompetenceRubricsProvider} et
 * {@code VersionCibleeRubricsProvider} : <b>aucune consigne de contenu en dur
 * dans le Java</b>. Le role, ce que l'exemple cible garde du candidat, la regle
 * des segments recopies, la forme des leviers, l'interdiction de vendre un
 * moyen deja acquis et la regle d'accentuation vivent dans les
 * {@code commun.sections} ; les plafonds de longueur dans
 * {@code commun.contraintes_longueur} ; les ancres dans {@code commun.few_shot}.
 *
 * <p><b>Fail-fast au demarrage</b>, comme les autres : un fichier absent,
 * illisible, ou qui declare un contrat de sortie different de celui configure
 * fait echouer le boot. Une bascule faite a moitie (consignes v2, tool-schema
 * v1) passerait sinon inapercue jusqu'a la premiere sortie rejetee.
 */
@Component
public class CompetenceNiveauViseRubricsProvider {

    private static final Logger log =
        LoggerFactory.getLogger(CompetenceNiveauViseRubricsProvider.class);
    private static final String PATH_FORMAT = "prompts/competence-niveau-vise-rubrics-%s.json";

    /**
     * Paires consignes -> tool-schema supportees. On versionne, on ne reecrit
     * jamais : v1 reste chargeable au bit pres, c'est le retour arriere
     * ({@code COMPETENCE_NIVEAU_VISE_RUBRICS_VERSION=v1} +
     * {@code COMPETENCE_NIVEAU_VISE_TOOL_SCHEMA_VERSION=v1}), sans migration.
     */
    private static final Map<String, String> TOOL_SCHEMA_BY_RUBRICS_VERSION =
        Map.of("v1", "v1", "v2", "v2", "v3", "v3");

    /** Ce module ne sert que le TCF IRN : aucune autre grille n'est acceptee. */
    private static final String PROFILE_ATTENDU = "TCF_IRN";

    private final CompetenceProperties props;
    private final ObjectMapper objectMapper;

    private Map<String, Object> commun = Map.of();
    private Map<String, Integer> contraintesLongueur = Map.of();
    private boolean marqueursDuPalierExiges;
    private boolean leviersPortentUnProcede;

    public CompetenceNiveauViseRubricsProvider(CompetenceProperties props,
                                               ObjectMapper objectMapper) {
        this.props = props;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    public void load() {
        String version = props.getNiveauVise().getRubricsVersion();
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
            String schema = TOOL_SCHEMA_BY_RUBRICS_VERSION.get(version);
            this.marqueursDuPalierExiges =
                CompetenceNiveauViseFields.porteLesMarqueursDuPalier(schema);
            this.leviersPortentUnProcede =
                CompetenceNiveauViseFields.porteLeProcedeDesLeviers(schema);
            if (marqueursDuPalierExiges) {
                validateMarqueursPalier(communMap.get("marqueurs_palier"));
            }
            this.commun = Map.copyOf(communMap);

            log.info("Consignes « pour viser » chargees ({}) : {} sections, {} ancres, "
                    + "plafonds {} mots, marqueurs de palier {}, procede des leviers {}, "
                    + "tool-schema {}",
                version, sections.size(), fewShot.size(), contraintesLongueur,
                marqueursDuPalierExiges, leviersPortentUnProcede,
                props.getNiveauVise().getToolSchemaVersion());
        } catch (Exception e) {
            throw new IllegalStateException(
                "Consignes « pour viser » introuvables/illisibles (" + path
                    + ") — verifier sejourfr.competences.niveau-vise.rubrics-version", e);
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
        String configuredSchema = props.getNiveauVise().getToolSchemaVersion();
        if (configuredSchema != null && !configuredSchema.isBlank()
                && !expectedSchema.equals(configuredSchema)) {
            throw new IllegalStateException("contrat consignes/tool-schema incompatible : consignes "
                + configuredVersion + " -> " + expectedSchema + ", config -> " + configuredSchema);
        }
    }

    /**
     * LA TABLE DES MARQUEURS EST OPPOSEE AU BOOT, jamais deduite a l'execution.
     *
     * <p>{@link MarqueurPalier} et {@code commun.marqueurs_palier} disent la meme
     * chose a deux endroits : le procede que le modele peut declarer, et le palier
     * a partir duquel il prouve quelque chose. Une divergence — un procede ajoute
     * d'un cote seulement, un palier deplace — ferait purger en silence des
     * marqueurs que la grille vient d'autoriser. Elle fait donc echouer le
     * demarrage, comme toute paire de contrat de ce depot : <b>jamais de repli
     * muet</b>.
     */
    private static void validateMarqueursPalier(Object node) {
        if (!(node instanceof Map<?, ?> m) || m.isEmpty()) {
            throw new IllegalStateException("bloc 'commun.marqueurs_palier' absent ou vide");
        }
        Map<String, String> declares = new LinkedHashMap<>();
        m.forEach((cle, valeur) -> declares.put(String.valueOf(cle), String.valueOf(valeur)));
        Map<String, String> attendus = MarqueurPalier.table();
        if (!attendus.equals(declares)) {
            throw new IllegalStateException("table des marqueurs de palier incoherente : grille="
                + declares + ", enum MarqueurPalier=" + attendus);
        }
    }

    /**
     * Le contrat actif exige-t-il que le palier soit DEMONTRE par des marqueurs
     * recopies du texte modele ? Faux sous v1 : tout ce qui les entoure reste
     * inerte, c'est ce qui garde le retour arriere reel.
     */
    public boolean marqueursDuPalierExiges() {
        return marqueursDuPalierExiges;
    }

    /**
     * Le contrat actif exige-t-il que chaque levier nomme le PROCEDE de langue
     * qu'il met en œuvre ? Vrai a partir de v3.
     *
     * <p><b>Ce booleen n'autorise jamais une purge.</b> Il ouvre trois choses, et
     * trois seulement : le procede est demande dans le prompt, admis par le
     * validateur comme une cle du contrat, et son anomalie est comptee. Un levier
     * dont le procede manque, est inconnu ou sur-vend le palier cible reste
     * <b>servi tel quel</b> — les leviers portent le bloc entier, les purger sur
     * ce motif viderait l'ecran du candidat pour une etiquette.
     */
    public boolean leviersPortentUnProcede() {
        return leviersPortentUnProcede;
    }

    /** Bloc {@code commun} complet (sections, plafonds, ancres). */
    public Map<String, Object> getCommun() {
        return commun;
    }

    /** Version des consignes actives. */
    public String getVersion() {
        return props.getNiveauVise().getRubricsVersion();
    }

    /**
     * Plafonds de longueur EN MOTS, par nom de champ terminal ({@code action},
     * {@code exemple}, {@code apport}, {@code formule}, {@code explication}).
     * Ils viennent du fichier de consignes, pas du code : le jour ou une v2
     * desserre un plafond, elle le fait dans le fichier qui porte deja la
     * consigne correspondante, et les deux ne peuvent pas diverger.
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
