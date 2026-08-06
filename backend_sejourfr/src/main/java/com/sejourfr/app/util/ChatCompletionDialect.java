package com.sejourfr.app.util;

import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Ce qu'un fournisseur « compatible OpenAI » accepte VRAIMENT dans le corps
 * d'une requete Chat Completions. Deux dialectes coexistent sous le meme nom
 * d'API, et se tromper coute 100 % des appels :
 *
 * <ul>
 *   <li><b>Plafond de sortie</b> — les modeles d'avant la generation de
 *       raisonnement lisent {@code max_tokens} ; les gpt-5.x et les o-series le
 *       REFUSENT en 400 (« Unsupported parameter: 'max_tokens' is not supported
 *       with this model. Use 'max_completion_tokens' instead. »). DeepSeek, qui
 *       passe par le meme client, est reste sur {@code max_tokens}.</li>
 *   <li><b>Temperature</b> — certains modeles n'acceptent que leur valeur par
 *       defaut (mesure : gpt-5.5 repond « Only the default (1) value is
 *       supported »). Sur ceux-la il faut OMETTRE le champ, pas l'envoyer a 1 :
 *       c'est un reglage qu'on n'a pas, pas un reglage qu'on choisit.</li>
 * </ul>
 *
 * <p><b>Pourquoi une detection par modele, et pas deux cles de config ?</b>
 * Parce que la seule chose qu'on change en pratique, c'est
 * {@code EVAL_OPENAI_MODEL} dans le {@code .env}. Le but explicite est que
 * changer de modele soit UNE ligne : si le dialecte etait fige a cote, il se
 * desynchroniserait au premier changement et toutes les corrections partiraient
 * en 400. La detection est donc le DEFAUT ({@code auto}) ; la config garde le
 * dernier mot pour un endpoint OpenAI-compatible exotique.
 *
 * <p><b>Modele inconnu</b> : on retombe sur le dialecte historique
 * ({@code max_tokens} + temperature envoyee), et {@link #resume(String, String,
 * String)} permet au client de le JOURNALISER au demarrage. Le choix est
 * assume : ce dialecte-la echoue en 400 explicite (« use
 * 'max_completion_tokens' instead »), la ou omettre la temperature en silence
 * donnerait une notation non deterministe que personne ne verrait passer.
 *
 * <p>Le PLAFOND lui-meme (4000) ne change jamais : seul le NOM du champ change.
 */
public final class ChatCompletionDialect {

    /** Plafond de sortie historique, encore lu par gpt-4.x et DeepSeek. */
    public static final String MAX_TOKENS = "max_tokens";
    /** Plafond de sortie des gpt-5.x / o-series, qui rejettent l'autre. */
    public static final String MAX_COMPLETION_TOKENS = "max_completion_tokens";
    /** Valeur de config demandant la detection par modele (defaut). */
    public static final String AUTO = "auto";

    private static final Set<String> NOMS_CONNUS = Set.of(MAX_TOKENS, MAX_COMPLETION_TOKENS);
    /** {@code gpt-5.4}, {@code gpt-4o-mini}, {@code gpt-4.1}… — on lit la generation. */
    private static final Pattern GPT_GENERATION = Pattern.compile("^gpt-(\\d+)");
    /** {@code o1}, {@code o3-mini}, {@code o4-mini}… : famille raisonnement. */
    private static final Pattern O_SERIES = Pattern.compile("^o\\d");
    /** DeepSeek : famille CONNUE de ce projet, restee sur le dialecte historique. */
    private static final Pattern DEEPSEEK = Pattern.compile("^deepseek");
    /** Premiere generation OpenAI a n'accepter que {@code max_completion_tokens}. */
    private static final int PREMIERE_GENERATION_MAX_COMPLETION_TOKENS = 5;

    /**
     * Modeles VERIFIES comme refusant toute temperature autre que leur defaut.
     * Liste fermee et volontairement courte : n'y ajouter qu'un modele dont le
     * refus a ete constate contre l'API, jamais « par precaution ».
     */
    private static final Pattern TEMPERATURE_VERROUILLEE = Pattern.compile("^gpt-5\\.5(\\b|[.\\-]).*");

    private ChatCompletionDialect() {
    }

    /**
     * Nom du champ de plafond de sortie a poser dans le corps de la requete.
     *
     * @param configure valeur de config : {@code auto} (ou vide) = detection par
     *                  modele ; sinon un nom de champ explicite, qui l'emporte.
     * @param modele    modele reellement appele.
     * @throws IllegalArgumentException si la config force un nom inconnu — une
     *                                  coquille silencieuse enverrait un champ
     *                                  ignore et laisserait la sortie sans
     *                                  plafond.
     */
    public static String maxTokensParam(String configure, String modele) {
        if (estExplicite(configure)) {
            String force = configure.strip().toLowerCase(Locale.ROOT);
            if (!NOMS_CONNUS.contains(force)) {
                throw new IllegalArgumentException(
                    "max-tokens-param invalide : '" + configure + "'. Valeurs supportees : "
                        + MAX_TOKENS + ", " + MAX_COMPLETION_TOKENS + ", " + AUTO + ".");
            }
            return force;
        }
        String m = normalise(modele);
        if (O_SERIES.matcher(m).find()) return MAX_COMPLETION_TOKENS;
        Matcher gpt = GPT_GENERATION.matcher(m);
        if (gpt.find() && Integer.parseInt(gpt.group(1)) >= PREMIERE_GENERATION_MAX_COMPLETION_TOKENS) {
            return MAX_COMPLETION_TOKENS;
        }
        return MAX_TOKENS;
    }

    /**
     * Faut-il envoyer le champ {@code temperature} ?
     *
     * @param configure {@code auto} (ou vide) = detection par modele ;
     *                  {@code true} / {@code false} pour forcer.
     * @param modele    modele reellement appele.
     * @throws IllegalArgumentException si la config n'est ni {@code auto}, ni un
     *                                  booleen.
     */
    public static boolean sendTemperature(String configure, String modele) {
        if (estExplicite(configure)) {
            String force = configure.strip().toLowerCase(Locale.ROOT);
            if ("true".equals(force)) return true;
            if ("false".equals(force)) return false;
            throw new IllegalArgumentException(
                "send-temperature invalide : '" + configure + "'. Valeurs supportees : true, false, "
                    + AUTO + ".");
        }
        return !TEMPERATURE_VERROUILLEE.matcher(normalise(modele)).matches();
    }

    /** true si le modele n'est reconnu d'aucune famille connue de ce dialecte. */
    public static boolean modeleInconnu(String modele) {
        String m = normalise(modele);
        return !O_SERIES.matcher(m).find()
            && !GPT_GENERATION.matcher(m).find()
            && !DEEPSEEK.matcher(m).find();
    }

    /**
     * Ligne de log lisible resumant le dialecte resolu : c'est elle qui evite
     * qu'un modele mal reconnu passe inapercu au demarrage.
     */
    public static String resume(String maxTokensParamConfigure, String sendTemperatureConfigure, String modele) {
        String champ = maxTokensParam(maxTokensParamConfigure, modele);
        boolean temperature = sendTemperature(sendTemperatureConfigure, modele);
        return "modele=" + modele
            + " plafond=" + champ
            + " temperature=" + (temperature ? "envoyee" : "omise (modele a temperature figee)")
            + (modeleInconnu(modele) ? " [modele hors familles connues : dialecte historique applique]" : "");
    }

    private static boolean estExplicite(String configure) {
        return configure != null && !configure.isBlank() && !AUTO.equalsIgnoreCase(configure.strip());
    }

    private static String normalise(String modele) {
        return modele == null ? "" : modele.strip().toLowerCase(Locale.ROOT);
    }
}
