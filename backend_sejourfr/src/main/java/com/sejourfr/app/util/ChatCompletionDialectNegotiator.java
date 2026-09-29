package com.sejourfr.app.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.LinkedHashSet;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * NEGOCIE la forme de la requete avec le fournisseur, au lieu de la deviner
 * depuis une liste de modeles ecrite dans le code.
 *
 * <p><b>Exigence</b> : brancher un modele qui n'existe pas encore aujourd'hui ne
 * doit demander aucune modification de code ni recompilation — une ligne de
 * {@code .env}, un redemarrage. Une table de noms de modeles ne peut pas tenir
 * cette promesse : elle deplace le probleme au prochain modele.
 *
 * <p><b>Ce qu'on exploite</b> : l'API dit elle-meme ce qui ne va pas, et donne
 * souvent le remplacant.
 * <pre>
 * 400 {"error":{"message":"Unsupported parameter: 'max_tokens' is not supported
 *      with this model. Use 'max_completion_tokens' instead.",
 *      "type":"invalid_request_error","param":"max_tokens",
 *      "code":"unsupported_parameter"}}
 * 400 {"error":{"message":"Unsupported value: 'temperature' does not support 0
 *      with this model. Only the default (1) value is supported.",
 *      "param":"temperature","code":"unsupported_value"}}
 * </pre>
 * Sur ce type de 400 on corrige la forme et on rejoue UNE fois. Le nom de
 * remplacement est LU dans le message (« Use 'X' instead ») : un futur modele
 * qui renommerait encore le parametre est absorbe ici, pas par un commit. A
 * defaut de suggestion, on bascule sur l'autre nom connu.
 *
 * <p><b>La forme retenue est memorisee</b> pour la duree du processus (un
 * negociateur par couple provider + modele, puisqu'un client = un provider et un
 * modele). Le surcout d'un aller-retour rate est donc paye une fois par
 * demarrage, pas a chaque correction. Rien n'est persiste : changer de modele
 * dans le {@code .env} repart d'une negociation neuve.
 *
 * <p><b>Ce qu'on ne touche surtout pas</b> : un 400 METIER (tool-schema refuse,
 * message invalide, contenu rejete) ne doit jamais declencher de renegociation —
 * ce serait masquer une vraie erreur derriere une boucle de reessais. La
 * distinction est explicite ({@link #concerneNotreForme}) et testee : il faut a
 * la fois un marqueur « parametre/valeur non supporte » ET l'un de NOS champs,
 * et un {@code error.param} qui designe autre chose suffit a refuser.
 */
public final class ChatCompletionDialectNegotiator {

    private static final Logger log = LoggerFactory.getLogger(ChatCompletionDialectNegotiator.class);

    /** Nombre maximal de formes essayees pour un meme appel. */
    public static final int MAX_RENEGOCIATIONS = 3;

    private static final String TEMPERATURE = "temperature";

    /** « Use 'max_completion_tokens' instead » — le fournisseur nomme le remplacant. */
    private static final Pattern SUGGESTION = Pattern.compile(
        "use\\s+['\"`]?([a-z0-9_]+)['\"`]?\\s+instead", Pattern.CASE_INSENSITIVE);
    /** {@code "param": "max_tokens"} dans le corps d'erreur. */
    private static final Pattern PARAM = Pattern.compile(
        "\"param\"\\s*:\\s*\"([^\"]+)\"", Pattern.CASE_INSENSITIVE);

    /**
     * Marqueurs d'un refus de FORME. Volontairement generiques : ils decrivent
     * une famille de messages d'erreur, pas un modele.
     */
    private static final Set<String> MARQUEURS_DE_FORME = Set.of(
        "unsupported parameter",
        "unsupported value",
        "unknown parameter",
        "unrecognized request argument",
        "is not supported with this model",
        "does not support",
        "only the default");

    private final String label;
    private final String modele;
    /** true = la config a impose le nom du plafond ; on ne le renegocie pas. */
    private final boolean plafondFige;
    /** true = la config a impose d'envoyer ou non la temperature. */
    private final boolean temperatureFigee;
    /** Noms de plafond deja essayes, pour ne jamais boucler. */
    private final Set<String> plafondsEssayes = new LinkedHashSet<>();

    private volatile ChatCompletionDialect forme;

    /**
     * @param maxTokensParamConfig {@code auto} (defaut) ou un nom de champ impose.
     * @param sendTemperatureConfig {@code auto} (defaut), {@code true}, ou
     *                              {@code false} = « ne pas envoyer du tout »,
     *                              valeur distincte de 0 et de 1.
     */
    public ChatCompletionDialectNegotiator(String label, String modele,
                                           String maxTokensParamConfig,
                                           String sendTemperatureConfig) {
        this.label = label;
        this.modele = modele;
        ChatCompletionDialect depart = ChatCompletionDialect.premiereForme(modele);

        String plafond = valeurExplicite(maxTokensParamConfig);
        this.plafondFige = plafond != null;
        if (plafond != null) {
            depart = depart.avecMaxTokensParam(plafond);
            if (!ChatCompletionDialect.NOMS_PROPOSABLES.contains(plafond)) {
                // Volontairement accepte : c'est l'echappatoire qui permet de
                // brancher un parametre encore inconnu sans recompiler. Mais une
                // COQUILLE ici enverrait un champ ignore, donc une sortie sans
                // plafond — et le mecanisme de negociation est desactive des lors
                // que la config impose une valeur.
                log.warn("{} : plafond de sortie force a '{}' (hors noms connus) — negociation "
                        + "automatique desactivee pour ce champ.", label, plafond);
            }
        }

        String temperature = valeurExplicite(sendTemperatureConfig);
        this.temperatureFigee = temperature != null;
        if (temperature != null) {
            if (!"true".equals(temperature) && !"false".equals(temperature)) {
                throw new IllegalArgumentException(
                    "send-temperature invalide : '" + sendTemperatureConfig
                        + "'. Valeurs supportees : true, false, " + ChatCompletionDialect.AUTO + ".");
            }
            if ("false".equals(temperature)) depart = depart.sansTemperature();
        }

        this.forme = depart;
        this.plafondsEssayes.add(depart.maxTokensParam());
    }

    /** Forme a utiliser pour le prochain appel. */
    public ChatCompletionDialect forme() {
        return forme;
    }

    /**
     * Tente de corriger la forme a partir d'un 400.
     *
     * @param formeUtilisee forme avec laquelle l'appel rate a ete emis (permet a
     *                      deux appels concurrents de ne pas se marcher dessus).
     * @param corpsErreur   corps de la reponse 400, tel que renvoye par l'API.
     * @return true s'il faut rejouer l'appel (forme corrigee, ou deja corrigee
     *         par un appel concurrent) ; false si le 400 n'est pas un probleme de
     *         forme — il doit alors remonter tel quel.
     */
    public synchronized boolean adapte(ChatCompletionDialect formeUtilisee, String corpsErreur) {
        // Un appel concurrent a deja corrige : rejouer avec la forme a jour.
        if (!forme.equals(formeUtilisee)) return true;

        String corps = ChatCompletionDialect.normalise(corpsErreur);
        if (corps.isEmpty()) return false;
        if (!contientMarqueurDeForme(corps)) return false;

        String param = paramCite(corps);
        if (param != null && !concerneNotreForme(param)) {
            // 400 metier (« param »: « messages », « tools »…) : ne rien toucher,
            // sinon on masque une vraie erreur derriere une boucle de reessais.
            return false;
        }

        if (viseLaTemperature(corps, param) && forme.sendTemperature() && !temperatureFigee) {
            forme = forme.sansTemperature();
            log.warn("{} : le modele {} refuse une temperature explicite — champ OMIS pour la suite "
                    + "du processus. La notation n'est plus deterministe sur ce modele.",
                label, modele);
            return true;
        }

        if (visePlafond(corps, param) && !plafondFige) {
            String remplacant = remplacantPlafond(corps);
            if (remplacant != null && plafondsEssayes.add(remplacant)) {
                forme = forme.avecMaxTokensParam(remplacant);
                log.info("{} : le modele {} refuse '{}' — bascule sur '{}' pour la suite du processus.",
                    label, modele, formeUtilisee.maxTokensParam(), remplacant);
                return true;
            }
        }
        return false;
    }

    /**
     * Nom de remplacement du champ de plafond : d'abord celui que l'API SUGGERE
     * (« Use 'X' instead ») — c'est ce qui absorbe un futur renommage sans
     * toucher au code — sinon le seul autre nom que le projet sache proposer.
     */
    private String remplacantPlafond(String corps) {
        Matcher m = SUGGESTION.matcher(corps);
        while (m.find()) {
            String suggere = m.group(1);
            if (!suggere.equals(forme.maxTokensParam())) return suggere;
        }
        for (String connu : ChatCompletionDialect.NOMS_PROPOSABLES) {
            if (!plafondsEssayes.contains(connu)) return connu;
        }
        return null;
    }

    private boolean viseLaTemperature(String corps, String param) {
        return TEMPERATURE.equals(param) || (param == null && corps.contains(TEMPERATURE));
    }

    private boolean visePlafond(String corps, String param) {
        if (param != null) return !TEMPERATURE.equals(param);
        return corps.contains(forme.maxTokensParam()) || corps.contains("max_");
    }

    /** Le parametre refuse est-il un de ceux que NOUS posons dans le corps ? */
    private boolean concerneNotreForme(String param) {
        return TEMPERATURE.equals(param)
            || param.equals(forme.maxTokensParam())
            || ChatCompletionDialect.NOMS_PROPOSABLES.contains(param)
            || param.startsWith("max_");
    }

    private static boolean contientMarqueurDeForme(String corps) {
        return MARQUEURS_DE_FORME.stream().anyMatch(corps::contains);
    }

    private static String paramCite(String corps) {
        Matcher m = PARAM.matcher(corps);
        return m.find() ? m.group(1).strip().toLowerCase(Locale.ROOT) : null;
    }

    private static String valeurExplicite(String config) {
        if (config == null || config.isBlank()) return null;
        String v = config.strip().toLowerCase(Locale.ROOT);
        return ChatCompletionDialect.AUTO.equals(v) ? null : v;
    }
}
