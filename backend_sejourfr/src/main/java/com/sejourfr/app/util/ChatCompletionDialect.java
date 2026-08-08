package com.sejourfr.app.util;

import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * FORME d'une requete Chat Completions : le nom du champ de plafond de sortie,
 * et le fait d'envoyer ou non {@code temperature}.
 *
 * <p>Deux dialectes coexistent sous le meme nom d'API et se tromper coute
 * 100 % des appels (400, aucune correction rendue) :
 * <ul>
 *   <li>{@code max_tokens} (gpt-4.x, DeepSeek) contre
 *       {@code max_completion_tokens} (gpt-5.x, o-series) ;</li>
 *   <li>{@code temperature} reglable contre modele a temperature figee
 *       (« Only the default (1) value is supported »).</li>
 * </ul>
 *
 * <p><b>Ce qui decide, c'est l'API, pas une liste dans le code.</b> Cette classe
 * ne fait que porter la forme courante ; c'est
 * {@link ChatCompletionDialectNegotiator} qui la corrige a partir du 400 renvoye
 * par le fournisseur. Les heuristiques {@link #premiereForme(String)} ci-dessous
 * sont un simple RACCOURCI : elles evitent un aller-retour rate au demarrage sur
 * les familles deja connues, et leur absence de correspondance ne casse rien —
 * un modele qui n'existe pas encore aujourd'hui doit se brancher par une seule
 * ligne de {@code .env}, sans recompilation.
 *
 * <p>Le PLAFOND lui-meme (4000) ne change jamais : seul le NOM du champ change.
 */
public record ChatCompletionDialect(String maxTokensParam, boolean sendTemperature) {

    /** Plafond de sortie historique (gpt-4.x, DeepSeek). */
    public static final String MAX_TOKENS = "max_tokens";
    /** Plafond de sortie des gpt-5.x / o-series, qui rejettent l'autre. */
    public static final String MAX_COMPLETION_TOKENS = "max_completion_tokens";
    /** Valeur de config demandant la negociation automatique (defaut). */
    public static final String AUTO = "auto";

    /**
     * Noms de plafond que le projet sait proposer de lui-meme. Un nom hors de
     * cette liste reste accepte s'il vient de l'API (« Use 'X' instead ») ou de
     * la config : la liste n'est pas une autorisation, juste un point de depart.
     */
    static final Set<String> NOMS_PROPOSABLES = Set.of(MAX_TOKENS, MAX_COMPLETION_TOKENS);

    /** {@code gpt-5.4}, {@code gpt-4o-mini}… — on lit la generation. Raccourci. */
    private static final Pattern GPT_GENERATION = Pattern.compile("^gpt-(\\d+)");
    /** {@code o1}, {@code o3-mini}… : famille raisonnement. Raccourci. */
    private static final Pattern O_SERIES = Pattern.compile("^o\\d");
    /** Premiere generation OpenAI connue pour n'accepter que le nom long. */
    private static final int PREMIERE_GENERATION_NOM_LONG = 5;

    /**
     * Forme d'essai pour un modele donne. Simple raccourci : si elle se trompe,
     * le 400 du fournisseur la corrige au premier appel et la forme retenue est
     * memorisee pour le reste du processus.
     */
    public static ChatCompletionDialect premiereForme(String modele) {
        return new ChatCompletionDialect(nomProbable(modele), true);
    }

    private static String nomProbable(String modele) {
        String m = normalise(modele);
        if (O_SERIES.matcher(m).find()) return MAX_COMPLETION_TOKENS;
        Matcher gpt = GPT_GENERATION.matcher(m);
        if (gpt.find() && Integer.parseInt(gpt.group(1)) >= PREMIERE_GENERATION_NOM_LONG) {
            return MAX_COMPLETION_TOKENS;
        }
        // Modele inconnu : on part du dialecte historique. Il echoue en 400
        // EXPLICITE (« use 'max_completion_tokens' instead »), donc negociable ;
        // le pari inverse echouerait tout aussi bien mais sans rien apprendre.
        return MAX_TOKENS;
    }

    public ChatCompletionDialect avecMaxTokensParam(String nom) {
        return new ChatCompletionDialect(nom, sendTemperature);
    }

    public ChatCompletionDialect sansTemperature() {
        return new ChatCompletionDialect(maxTokensParam, false);
    }

    @Override
    public String toString() {
        return "plafond=" + maxTokensParam
            + " temperature=" + (sendTemperature ? "envoyee" : "omise");
    }

    static String normalise(String s) {
        return s == null ? "" : s.strip().toLowerCase(Locale.ROOT);
    }
}
