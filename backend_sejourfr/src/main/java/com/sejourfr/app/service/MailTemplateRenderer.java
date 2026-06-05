package com.sejourfr.app.service;

import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Rend les emails HTML à partir de templates du classpath ({@code mail/*.html}).
 *
 * <p>Syntaxe de substitution (façon Mustache) :
 * <ul>
 *   <li>{@code {{cle}}}   → valeur <b>échappée</b> HTML (données dynamiques).</li>
 *   <li>{@code {{{cle}}}} → valeur <b>brute</b> (fragment HTML déjà sûr, ex. le
 *       corps injecté dans le layout).</li>
 * </ul>
 *
 * <p>Une clé absente de la map est laissée telle quelle (utile pour repérer un
 * placeholder oublié en relecture). Les templates sont lus une fois puis mis en
 * cache — un changement de template nécessite donc un redémarrage.
 */
@Component
public class MailTemplateRenderer {

    private final Map<String, String> cache = new ConcurrentHashMap<>();

    /**
     * Charge {@code mail/<templateName>} et remplace les placeholders par les
     * valeurs de {@code vars}.
     */
    public String render(String templateName, Map<String, String> vars) {
        String out = load(templateName);
        for (Map.Entry<String, String> e : vars.entrySet()) {
            String value = e.getValue() == null ? "" : e.getValue();
            out = out.replace("{{{" + e.getKey() + "}}}", value);
            out = out.replace("{{" + e.getKey() + "}}", escape(value));
        }
        return out;
    }

    private String load(String templateName) {
        return cache.computeIfAbsent(templateName, name -> {
            ClassPathResource resource = new ClassPathResource("mail/" + name);
            try (var in = resource.getInputStream()) {
                return new String(in.readAllBytes(), StandardCharsets.UTF_8);
            } catch (IOException ex) {
                throw new UncheckedIOException("Template mail introuvable : mail/" + name, ex);
            }
        });
    }

    /** Échappement HTML des données dynamiques injectées dans les templates. */
    static String escape(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }
}
