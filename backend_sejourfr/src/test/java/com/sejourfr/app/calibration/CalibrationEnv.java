package com.sejourfr.app.calibration;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.service.EvaluationAnthropicClient;
import com.sejourfr.app.service.EvaluationLlmClient;
import com.sejourfr.app.service.OpenAiCompatibleEvalClient;
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
import org.springframework.util.ReflectionUtils;
import tools.jackson.databind.ObjectMapper;

import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Cablage du banc sur la configuration REELLE : {@code application.yaml} de
 * production + l'environnement reel du processus + le fichier {@code .env}
 * local (que les tests ne lisent pas d'eux-memes). Aucun contexte Spring n'est
 * demarre, aucune base n'est necessaire.
 *
 * <p>Les valeurs de cle d'API ne sont jamais journalisees : on n'expose que le
 * fait qu'une cle soit presente ou non.
 */
final class CalibrationEnv {

    private static final Pattern DOTENV_LINE = Pattern.compile("^([A-Za-z_][A-Za-z0-9_]*)=(.*)$");

    private CalibrationEnv() {
    }

    /**
     * Charge {@code sejourfr.production-evaluation} tel que le backend le lit,
     * en surchargeant seulement la version de rubriques, la version de prompt et
     * demandes par la campagne. Le provider et le modele ne sont jamais
     * surcharges ici : ils viennent de la meme configuration que le runtime.
     */
    static ProductionEvaluationProperties properties(String rubricsVersion, String promptVersion) {
        MutablePropertySources sources = new MutablePropertySources();

        Map<String, Object> overrides = new LinkedHashMap<>();
        if (rubricsVersion != null) overrides.put("EVAL_RUBRICS_VERSION", rubricsVersion);
        if (promptVersion != null) overrides.put("EVAL_PROMPT_VERSION", promptVersion);
        sources.addFirst(new MapPropertySource("calibration-overrides", overrides));
        Map<String, Object> processEnv = new LinkedHashMap<>();
        processEnv.putAll(System.getenv());
        sources.addLast(new SystemEnvironmentPropertySource("system-environment", processEnv));
        sources.addLast(new MapPropertySource("dotenv", dotenv()));
        for (PropertySource<?> ps : yaml()) sources.addLast(ps);

        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        new Binder(ConfigurationPropertySources.from(sources), new PropertySourcesPlaceholdersResolver(sources))
            .bind("sejourfr.production-evaluation", Bindable.ofInstance(props));
        return props;
    }

    /**
     * Client LLM du provider actif, cable exactement comme
     * {@code EvaluationLlmConfig} (meme classe, memes reglages, meme tool schema).
     */
    static EvaluationLlmClient client(ProductionEvaluationProperties props, ObjectMapper objectMapper) {
        String provider = props.getProvider() == null ? "" : props.getProvider().trim().toLowerCase();
        return switch (provider) {
            case "deepseek" -> openAiCompatible(props.getDeepseek(), "DeepSeek", objectMapper);
            case "openai" -> openAiCompatible(props.getOpenai(), "OpenAI", objectMapper);
            case "anthropic" -> {
                EvaluationAnthropicClient c = new EvaluationAnthropicClient(props, objectMapper);
                postConstruct(c, "loadToolSchema");
                yield c;
            }
            default -> throw new IllegalStateException(
                "provider d'evaluation invalide : '" + props.getProvider() + "'");
        };
    }

    private static EvaluationLlmClient openAiCompatible(
        ProductionEvaluationProperties.ChatCompletionSettings settings, String label, ObjectMapper om) {
        if (!settings.isConfigured()) {
            throw new IllegalStateException("Cle API absente pour le provider " + label
                + " — renseigner .env avant de lancer le banc.");
        }
        OpenAiCompatibleEvalClient client = new OpenAiCompatibleEvalClient(settings, label, om);
        postConstruct(client, "loadToolSchema");
        return client;
    }

    /**
     * Declenche un {@code @PostConstruct} de portee package (chargement du tool
     * schema, des rubriques) : hors contexte Spring, personne ne l'appelle.
     */
    static void postConstruct(Object bean, String methodName) {
        Method m = ReflectionUtils.findMethod(bean.getClass(), methodName);
        if (m == null) throw new IllegalStateException("Methode " + methodName + " introuvable sur " + bean.getClass());
        ReflectionUtils.makeAccessible(m);
        ReflectionUtils.invokeMethod(m, bean);
    }

    /** Liste des champs obligatoires du tool schema de la version de prompt donnee. */
    static List<String> champsRequis(String promptVersion, ObjectMapper om) {
        String path = "prompts/production-evaluation-tool-schema-" + promptVersion + ".json";
        try (var is = new ClassPathResource(path).getInputStream()) {
            Map<String, Object> schema = om.readValue(
                new String(is.readAllBytes(), StandardCharsets.UTF_8),
                new tools.jackson.core.type.TypeReference<Map<String, Object>>() {
                });
            if (schema.get("required") instanceof List<?> req) {
                return req.stream().filter(java.util.Objects::nonNull).map(Object::toString).toList();
            }
        } catch (Exception e) {
            throw new IllegalStateException("Tool schema illisible : " + path, e);
        }
        return List.of();
    }

    private static List<PropertySource<?>> yaml() {
        try {
            return new YamlPropertySourceLoader().load("application.yaml", new ClassPathResource("application.yaml"));
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
        for (Path candidate : List.of(Path.of(".env"), Path.of("backend_sejourfr/.env"), Path.of("../backend_sejourfr/.env"))) {
            if (Files.isReadable(candidate)) return candidate;
        }
        return null;
    }

    private static String unquote(String v) {
        String s = v.strip();
        if (s.length() >= 2 && ((s.startsWith("\"") && s.endsWith("\"")) || (s.startsWith("'") && s.endsWith("'")))) {
            return s.substring(1, s.length() - 1);
        }
        return s;
    }
}
