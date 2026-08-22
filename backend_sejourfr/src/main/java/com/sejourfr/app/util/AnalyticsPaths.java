package com.sejourfr.app.util;

import java.util.LinkedHashSet;
import java.util.Locale;
import java.util.Set;

/**
 * Allowlist <b>fermee</b> des chemins qu'un evenement d'analytics peut nommer,
 * et leur normalisation — <b>autorite unique</b>.
 *
 * <p><b>Pourquoi une liste fermee.</b> L'endpoint d'ingestion est public. Un
 * chemin libre, c'est une dimension a cardinalite infinie : un bot qui poste
 * {@code /a}, {@code /b}, {@code /c}... fait enfler la table et rend le
 * regroupement par page illisible. Pire, un chemin reel peut porter un
 * identifiant ({@code /diagnostic/3f2a-...}), donc de la donnee qui n'a rien a
 * faire dans une mesure d'audience. Meme parti pris que
 * {@code PageViewService.EVENTS_BY_PATH} et {@link TrafficSource#KNOWN} : on
 * borne, et ce qui n'est pas prevu est <b>refuse en 400 nomme</b> plutot que
 * range en silence dans un fourre-tout.
 *
 * <p>Un chemin hors liste n'est donc jamais « autre » : c'est un front qui
 * instrumente un ecran qu'on n'a pas declare, et il doit l'apprendre tout de
 * suite. Ajouter un ecran = ajouter une ligne ici, dans la meme passe.
 */
public final class AnalyticsPaths {

    /**
     * Les ecrans suivis, exactement.
     *
     * <p>Web d'abord (c'est la ou se joue l'acquisition), puis les quelques
     * routes mobiles qui participent au meme entonnoir. Les deux fronts
     * partagent volontairement la meme dimension : « combien ont vu le
     * paywall » doit se lire d'un seul cote du tableau.
     */
    public static final Set<String> KNOWN = Set.of(
            // Accueil et landings de campagne
            "/",
            "/reussir",
            // Diagnostic
            "/diagnostic",
            "/diagnostic/resultat",
            // Plan personnalise
            "/plan",
            // Prix et paiement
            "/tarifs",
            "/paiement",
            // Compte
            "/connexion",
            "/inscription",
            // Produit
            "/dashboard",
            "/entrainement",
            "/examens-blancs",
            "/competences",
            "/profil",
            // Mobile (go_router)
            "/home",
            "/target-path",
            "/paywall");

    private AnalyticsPaths() {
    }

    /**
     * Chemin normalise, ou {@code null} si l'appelant n'en a pas envoye.
     *
     * <p>Normalisation minimale et sans surprise : on retire la
     * query-string et le fragment (ils portent les UTM et parfois un jeton),
     * on met en minuscules, on retire le {@code /} final. On ne « repare »
     * rien d'autre — un chemin qui a besoin d'etre devine est un chemin qu'on
     * ne veut pas compter.
     *
     * @throws IllegalArgumentException si le chemin ne figure pas dans
     *         l'allowlist. Le message nomme le champ, la valeur recue et les
     *         valeurs admises (patron {@code TargetProcedure}).
     */
    public static String normalizeOrThrow(String raw) {
        if (raw == null || raw.isBlank()) return null;
        String path = strip(raw);
        if (KNOWN.contains(path)) return path;
        throw new IllegalArgumentException(
                "Valeur invalide pour « path » : « " + raw + " ». Valeurs acceptées : "
                        + sorted() + ".");
    }

    /** Vrai si le chemin, une fois normalise, est suivi. */
    public static boolean isKnown(String raw) {
        if (raw == null || raw.isBlank()) return false;
        return KNOWN.contains(strip(raw));
    }

    private static String strip(String raw) {
        String path = raw.trim();
        int cut = indexOfFirst(path, '?', '#');
        if (cut >= 0) path = path.substring(0, cut);
        path = path.toLowerCase(Locale.ROOT);
        if (path.length() > 1 && path.endsWith("/")) {
            path = path.substring(0, path.length() - 1);
        }
        return path.isEmpty() ? "/" : path;
    }

    private static int indexOfFirst(String value, char a, char b) {
        int i = value.indexOf(a);
        int j = value.indexOf(b);
        if (i < 0) return j;
        if (j < 0) return i;
        return Math.min(i, j);
    }

    /** Liste ordonnee, pour un message d'erreur reproductible. */
    private static String sorted() {
        return new LinkedHashSet<>(KNOWN.stream().sorted().toList()).toString();
    }
}
