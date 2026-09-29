package com.sejourfr.app.service.email;

import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Le moteur de gabarits des emails et des pages HTML servies par le backend.
 *
 * <p>Syntaxe de substitution (facon Mustache), et RIEN d'autre :
 * <ul>
 *   <li>{@code {{cle}}}   → valeur <b>echappee</b> HTML (donnees dynamiques) ;</li>
 *   <li>{@code {{{cle}}}} → valeur <b>brute</b> (fragment HTML deja sur, ex. le
 *       corps injecte dans le layout).</li>
 * </ul>
 *
 * <p>🛑 Aucune condition, aucune boucle : c'est ce qui garantit qu'aucune regle
 * metier ne vit dans un gabarit. Un passage optionnel arrive en variable plate
 * deja calculee en Java (complement F des arbitrages), eventuellement vide.
 *
 * <p>Une cle absente de la map reste telle quelle (repérable en relecture). Les
 * gabarits sont lus une fois puis mis en cache.
 */
@Component
public class MailTemplateRenderer {

    private static final Pattern PLACEHOLDER =
            Pattern.compile("\\{\\{\\{([A-Za-z0-9_]+)\\}\\}\\}|\\{\\{([A-Za-z0-9_]+)\\}\\}");

    private final Map<String, String> cache = new ConcurrentHashMap<>();

    /** Rend un gabarit HTML du classpath ; les {@code {{cle}}} sont echappes. */
    public String render(String classpathPath, Map<String, String> vars) {
        return substitute(load(classpathPath), vars, true);
    }

    /** Rend un gabarit TEXTE du classpath : rien n'est echappe. */
    public String renderText(String classpathPath, Map<String, String> vars) {
        return substitute(load(classpathPath), vars, false);
    }

    /** Substitue dans une chaine en memoire (sujet d'un mail) — texte, sans echappement. */
    public String renderInline(String template, Map<String, String> vars) {
        return substitute(template == null ? "" : template, vars, false);
    }

    public boolean exists(String classpathPath) {
        return cache.containsKey(classpathPath) || new ClassPathResource(classpathPath).exists();
    }

    /**
     * Une seule passe sur le gabarit : une valeur injectee n'est jamais relue
     * comme un placeholder (un message de contact contenant {@code {{body}}}
     * reste du texte).
     *
     * <p><b>Ligne sans objet = ligne retiree.</b> Une ligne du gabarit dont
     * TOUS les placeholders valent la chaine vide disparait entiere, avec son
     * balisage : un passage optionnel (les priorites d'un Plan provisoire, le
     * bloc de desabonnement d'un mail REQUIRED) ne laisse ni paragraphe vide ni
     * ligne blanche. Ce n'est pas une condition ecrite dans le gabarit : la
     * decision reste en Java (la variable vide), le moteur ne fait que ne pas
     * imprimer une ligne qui ne dit plus rien (decision D-32).
     */
    private static String substitute(String template, Map<String, String> vars, boolean escapeHtml) {
        StringBuilder out = new StringBuilder(template.length());
        for (String line : template.split("(?<=\n)", -1)) {
            Matcher m = PLACEHOLDER.matcher(line);
            StringBuilder rendered = new StringBuilder(line.length());
            boolean hasKnown = false;
            boolean allEmpty = true;
            while (m.find()) {
                boolean raw = m.group(1) != null;
                String key = raw ? m.group(1) : m.group(2);
                String replacement;
                if (!vars.containsKey(key)) {
                    replacement = m.group();
                    allEmpty = false;
                } else {
                    String value = vars.get(key) == null ? "" : vars.get(key);
                    hasKnown = true;
                    if (!value.isBlank()) allEmpty = false;
                    replacement = raw || !escapeHtml ? value : escape(value);
                }
                m.appendReplacement(rendered, Matcher.quoteReplacement(replacement));
            }
            m.appendTail(rendered);
            if (!(hasKnown && allEmpty)) {
                out.append(rendered);
            }
        }
        return out.toString();
    }

    private String load(String classpathPath) {
        return cache.computeIfAbsent(classpathPath, name -> {
            ClassPathResource resource = new ClassPathResource(name);
            try (var in = resource.getInputStream()) {
                return new String(in.readAllBytes(), StandardCharsets.UTF_8);
            } catch (IOException ex) {
                throw new UncheckedIOException("Gabarit introuvable : " + name, ex);
            }
        });
    }

    /** Echappement HTML des donnees dynamiques injectees dans les gabarits. */
    public static String escape(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
}
