package com.sejourfr.app.config;

import org.springframework.boot.context.properties.bind.Bindable;
import org.springframework.boot.context.properties.bind.Binder;
import org.springframework.boot.context.properties.bind.PropertySourcesPlaceholdersResolver;
import org.springframework.boot.context.properties.source.ConfigurationPropertySources;
import org.springframework.boot.env.YamlPropertySourceLoader;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.MutablePropertySources;
import org.springframework.core.env.PropertySource;
import org.springframework.core.env.SystemEnvironmentPropertySource;
import org.springframework.core.io.ClassPathResource;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Resolution de {@code sejourfr.production-evaluation} EXACTEMENT comme le
 * runtime la fait — variables du processus, puis {@code .env} local, puis les
 * defauts d'{@code application.yaml} — sans demarrer de contexte Spring ni de
 * base.
 *
 * <p>Point unique pour tous les tests qui parlent du correcteur (banc de
 * calibration, coherence des tarifs, preuve de bascule de modele). Ils doivent
 * lire la configuration par le MEME chemin que le backend, sinon ils
 * verrouillent une realite qui n'est pas celle qui tournera.
 *
 * <p>Aucune valeur de cle d'API n'est jamais exposee ici : seul le fait qu'une
 * cle soit presente peut etre observe, via {@code isConfigured()}.
 */
public final class EvaluationConfigFixture {

    /** Les providers que {@code EvaluationLlmConfig} sait cabler. */
    public static final List<String> PROVIDERS = List.of("openai", "anthropic", "deepseek");

    /** Prefixe de configuration d'un bloc provider. */
    public static final String PREFIXE = "sejourfr.production-evaluation";

    private static final Pattern DOTENV_LINE = Pattern.compile("^([A-Za-z_][A-Za-z0-9_]*)=(.*)$");

    private EvaluationConfigFixture() {
    }

    /**
     * Vue uniforme d'un bloc provider. Les trois blocs n'ont pas de type commun
     * ({@code Anthropic} ne parle pas Chat Completions), mais ils portent tous
     * ces quatre informations — les seules dont parlent les tests de coherence.
     */
    public record BlocProvider(String provider, String modele, double coutEntree, double coutSortie,
                               boolean cleRenseignee) {
    }

    /** Configuration EFFECTIVE : processus + {@code .env} + {@code application.yaml}. */
    public static ProductionEvaluationProperties resolue() {
        return resolue(Map.of());
    }

    /**
     * Configuration effective, avec des surcharges prioritaires sur tout le
     * reste (le banc s'en sert pour imposer une version de rubriques).
     */
    public static ProductionEvaluationProperties resolue(Map<String, Object> surcharges) {
        MutablePropertySources sources = new MutablePropertySources();
        sources.addFirst(new MapPropertySource("surcharges", new LinkedHashMap<>(surcharges)));
        sources.addLast(new SystemEnvironmentPropertySource(
            "system-environment", new LinkedHashMap<>(System.getenv())));
        sources.addLast(new MapPropertySource("dotenv", new LinkedHashMap<>(dotenv())));
        ajouteYaml(sources);
        return lie(sources);
    }

    /**
     * Meme resolution (processus + {@code .env} + {@code application.yaml}) sur
     * un AUTRE prefixe de configuration.
     *
     * <p>Extrait a la deuxieme occurrence : le banc du module « Competences »
     * lit {@code sejourfr.competences}, mais il choisit son fournisseur dans
     * {@code sejourfr.production-evaluation} (regle « un seul correcteur
     * configurable »). Les deux blocs doivent donc etre resolus par la MEME
     * mecanique — deux chemins de lecture differents, et le banc finirait par
     * mesurer un correcteur qui n'est pas celui du runtime.
     *
     * @param cible instance a remplir, rendue telle quelle apres liaison.
     */
    public static <T> T resolue(String prefixe, T cible, Map<String, Object> surcharges) {
        MutablePropertySources sources = new MutablePropertySources();
        sources.addFirst(new MapPropertySource("surcharges", new LinkedHashMap<>(surcharges)));
        sources.addLast(new SystemEnvironmentPropertySource(
            "system-environment", new LinkedHashMap<>(System.getenv())));
        sources.addLast(new MapPropertySource("dotenv", new LinkedHashMap<>(dotenv())));
        ajouteYaml(sources);
        new Binder(ConfigurationPropertySources.from(sources),
            new PropertySourcesPlaceholdersResolver(sources))
            .bind(prefixe, Bindable.ofInstance(cible));
        return cible;
    }

    /**
     * Les DEFAUTS LIVRES : {@code application.yaml} seul, sans aucune surcharge
     * locale. Sert de reference pour repondre a « ce modele vient-il du yaml ou
     * d'ailleurs ? ».
     */
    public static ProductionEvaluationProperties defautsYaml() {
        return avec(Map.of());
    }

    /**
     * {@code application.yaml} + des variables d'environnement SIMULEES. Aucune
     * variable reelle n'est lue : c'est ce qui permet de prouver qu'un modele
     * inconnu se branche par la seule configuration.
     */
    public static ProductionEvaluationProperties avec(Map<String, Object> variables) {
        MutablePropertySources sources = new MutablePropertySources();
        sources.addFirst(new SystemEnvironmentPropertySource(
            "variables-simulees", new LinkedHashMap<>(variables)));
        ajouteYaml(sources);
        return lie(sources);
    }

    /** Bloc du provider demande, vu de facon uniforme. */
    public static BlocProvider bloc(ProductionEvaluationProperties props, String provider) {
        return switch (normalise(provider)) {
            case "openai" -> {
                ProductionEvaluationProperties.OpenAi o = props.getOpenai();
                yield new BlocProvider("openai", o.getModel(), o.getCostPerMillionInputTokens(),
                    o.getCostPerMillionOutputTokens(), o.isConfigured());
            }
            case "deepseek" -> {
                ProductionEvaluationProperties.DeepSeek d = props.getDeepseek();
                yield new BlocProvider("deepseek", d.getModel(), d.getCostPerMillionInputTokens(),
                    d.getCostPerMillionOutputTokens(), d.isConfigured());
            }
            case "anthropic" -> {
                ProductionEvaluationProperties.Anthropic a = props.getAnthropic();
                yield new BlocProvider("anthropic", a.getModel(), a.getCostPerMillionInputTokens(),
                    a.getCostPerMillionOutputTokens(), a.isConfigured());
            }
            default -> throw new IllegalArgumentException("provider inconnu : " + provider);
        };
    }

    /** Bloc du provider ACTIF. */
    public static BlocProvider blocActif(ProductionEvaluationProperties props) {
        return bloc(props, props.getProvider());
    }

    /** Version de tool-schema declaree par le bloc du provider actif. */
    public static String versionPromptActive(ProductionEvaluationProperties props) {
        return switch (normalise(props.getProvider())) {
            case "openai" -> props.getOpenai().getPromptVersion();
            case "deepseek" -> props.getDeepseek().getPromptVersion();
            case "anthropic" -> props.getAnthropic().getPromptVersion();
            default -> null;
        };
    }

    /** Nom de la variable de modele d'un provider ({@code EVAL_OPENAI_MODEL}…). */
    public static String varModele(String provider) {
        return "EVAL_" + normalise(provider).toUpperCase(Locale.ROOT) + "_MODEL";
    }

    /** Nom de la variable de tarif d'entree d'un provider. */
    public static String varCoutEntree(String provider) {
        return "EVAL_" + normalise(provider).toUpperCase(Locale.ROOT) + "_COST_INPUT";
    }

    /** Nom de la variable de tarif de sortie d'un provider. */
    public static String varCoutSortie(String provider) {
        return "EVAL_" + normalise(provider).toUpperCase(Locale.ROOT) + "_COST_OUTPUT";
    }

    /**
     * NOMS des variables lisibles par le runtime HORS {@code application.yaml} :
     * celles du processus, completees par le {@code .env} local. C'est la
     * « source autre que le yaml » dont parle la regle « le tarif voyage avec le
     * modele ».
     *
     * <p><b>Les valeurs ne sortent jamais d'ici</b> : cet environnement contient
     * toutes les cles d'API du projet, et un message d'echec de test finit dans
     * les journaux de build. Seule la PRESENCE d'une variable est observable.
     */
    public static java.util.Set<String> nomsVariablesHorsYaml() {
        java.util.Set<String> out = new java.util.LinkedHashSet<>(dotenv().keySet());
        out.addAll(System.getenv().keySet());
        return out;
    }

    /** true si un fichier {@code .env} local est lisible (environnement provisionne). */
    public static boolean dotEnvPresent() {
        return resolveDotEnv() != null;
    }

    /**
     * Contenu brut d'{@code application.yaml} a plat, placeholders NON resolus :
     * la seule facon de verifier qu'une cle est bien declaree {@code ${VAR:defaut}}.
     */
    public static java.util.Properties yamlBrut() {
        org.springframework.beans.factory.config.YamlPropertiesFactoryBean yaml =
            new org.springframework.beans.factory.config.YamlPropertiesFactoryBean();
        yaml.setResources(new ClassPathResource("application.yaml"));
        java.util.Properties props = yaml.getObject();
        if (props == null) throw new IllegalStateException("application.yaml illisible");
        return props;
    }

    private static ProductionEvaluationProperties lie(MutablePropertySources sources) {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        new Binder(ConfigurationPropertySources.from(sources),
            new PropertySourcesPlaceholdersResolver(sources))
            .bind(PREFIXE, Bindable.ofInstance(props));
        return props;
    }

    private static void ajouteYaml(MutablePropertySources sources) {
        try {
            for (PropertySource<?> ps : new YamlPropertySourceLoader()
                .load("application.yaml", new ClassPathResource("application.yaml"))) {
                sources.addLast(ps);
            }
        } catch (Exception e) {
            throw new IllegalStateException("application.yaml illisible", e);
        }
    }

    /**
     * Parse naif d'un {@code .env} : lignes {@code CLE=valeur}, commentaires et
     * lignes de continuation ignores. Suffisant pour les cles d'evaluation.
     */
    private static Map<String, Object> dotenv() {
        Path file = resolveDotEnv();
        Map<String, Object> out = new LinkedHashMap<>();
        if (file == null) return out;
        try {
            for (String line : Files.readAllLines(file, StandardCharsets.UTF_8)) {
                String trimmed = line.strip();
                if (trimmed.isEmpty() || trimmed.startsWith("#")) continue;
                Matcher m = DOTENV_LINE.matcher(trimmed);
                if (!m.matches()) continue;
                out.put(m.group(1), unquote(m.group(2)));
            }
        } catch (Exception e) {
            throw new IllegalStateException("Lecture de " + file + " impossible", e);
        }
        return out;
    }

    private static Path resolveDotEnv() {
        String explicite = System.getProperty("calibration.env.file");
        if (explicite != null && !explicite.isBlank()) return Path.of(explicite);
        for (Path candidate : List.of(Path.of(".env"), Path.of("backend_sejourfr/.env"),
            Path.of("../backend_sejourfr/.env"))) {
            if (Files.isReadable(candidate)) return candidate;
        }
        return null;
    }

    private static String unquote(String v) {
        String s = v.strip();
        if (s.length() >= 2 && ((s.startsWith("\"") && s.endsWith("\""))
            || (s.startsWith("'") && s.endsWith("'")))) {
            return s.substring(1, s.length() - 1);
        }
        return s;
    }

    private static String normalise(String s) {
        return s == null ? "" : s.strip().toLowerCase(Locale.ROOT);
    }
}
