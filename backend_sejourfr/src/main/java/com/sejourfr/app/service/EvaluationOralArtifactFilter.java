package com.sejourfr.app.service;

import com.sejourfr.app.enums.EpreuveType;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * FILET DETERMINISTE de la restitution ORALE. Il retire du rapport rendu au
 * candidat deux choses que la grille interdit deja au correcteur, mais qu'il
 * produit quand meme :
 *
 * <ol>
 *   <li>les REPROCHES DE NIVEAU MOT appuyes sur un passage de la transcription
 *       (« vous employez « l'ile » », « la formulation « par travers » est
 *       incorrecte ») : a l'oral, un mot isole est exactement ce que la
 *       reconnaissance vocale se trompe a restituer, et les rubriques exigent
 *       depuis toujours des remarques au niveau de la PHRASE, jamais du MOT ;</li>
 *   <li>les entrees de {@code exemples_corriges} dont l'explication ou le gain
 *       se fondent sur une NOTION non evaluable a l'oral (hesitations, debit,
 *       prononciation...).</li>
 * </ol>
 *
 * <h2>Ce que ce filet ne touche pas</h2>
 * <b>Ni la note, ni le niveau, ni un seuil, ni un bareme.</b> Il n'agit que sur
 * du texte de restitution, apres que la note a ete calculee : le meme jeu de
 * {@code scores_criteres} donne exactement la meme note avec ou sans lui. C'est
 * ce qui permet de le livrer sans campagne de banc.
 *
 * <h2>Pourquoi un incident l'a impose</h2>
 * Sur la submission EO T3 du 2026-08-06, le candidat avait dit « Lille »,
 * « sachant qu'a Paris » et « pour traverser » ; la transcription portait
 * « l'ile », « ca sent qu'a Paris » et « par travers ». Le correcteur a impute
 * ces trois artefacts au candidat dans CINQ champs, sans employer un seul des
 * mots interdits ({@code prononciation}, {@code fluidite}...) : le garde-fou
 * lexical existant ne pouvait rien voir.
 *
 * <h2>Frontiere assumee du filet</h2>
 * <b>Il ne reconnait qu'un reproche qui ne nomme qu'UN SEUL mot porteur de
 * sens.</b> Un artefact etale sur plusieurs mots (« ca sent qu'a Paris ») est
 * indiscernable d'une vraie faute de langue sans lexique du francais, et
 * inventer une heuristique la-dessus supprimerait de VRAIES corrections. C'est
 * la consigne de la grille (rubriques v9, section orale) qui traite ce cas, et
 * elle se mesure au banc — pas ce filet.
 *
 * <h2>Regle de purge</h2>
 * <ul>
 *   <li>on ne purge que ce qui est ANCRE sur la transcription : la citation doit
 *       etre retrouvee dans un tour {@code Candidat :} par
 *       {@link EvaluationProofMatcher}. Un conseil general, meme maladroit,
 *       n'est jamais touche ;</li>
 *   <li>on purge la PHRASE, pas le champ entier : « purger le reproche, pas la
 *       production » ;</li>
 *   <li>une phrase qui cite AUSSI un passage plus long est conservee : elle
 *       parle alors de la construction de la phrase, pas d'un mot ;</li>
 *   <li>une priorite dont le {@code constat} ou le {@code comment} ne survit pas
 *       est supprimee ENTIEREMENT : elle etait batie sur l'artefact.</li>
 * </ul>
 */
final class EvaluationOralArtifactFilter {

    /**
     * Guillemets francais et guillemets doubles droits/typographiques. L'apostrophe
     * simple est volontairement EXCLUE : en francais elle marque l'elision
     * ({@code l'ile}), la traiter comme un guillemet decouperait n'importe quelle
     * phrase.
     */
    private static final Pattern CITATION = Pattern.compile(
        "«\\s*([^«»]{1,300}?)\\s*»|\"([^\"]{1,300}?)\"|“([^”]{1,300}?)”");

    /** Fin de phrase : ponctuation forte suivie d'un blanc. */
    private static final Pattern FIN_DE_PHRASE = Pattern.compile("(?<=[.!?…])\\s+");

    /**
     * MARQUEURS DE REPROCHE. Citer un mot de la transcription ne suffit pas a
     * declencher la purge : encore faut-il que la phrase REPROCHE quelque chose
     * a ce mot. Sans cette condition, le filet supprimait aussi les CONSEILS qui
     * citent un mot present dans la production (« relie tes idees avec
     * "parce que" »), c'est-a-dire exactement ce qu'on veut garder.
     *
     * <p>Liste fermee et volontairement etroite : elle ne peut que REDUIRE le
     * nombre de purges. Une formulation de reproche qui y echappe laisse passer
     * l'artefact — c'est alors la consigne de la grille (rubriques v9) qui joue,
     * et elle, se mesure au banc. On prefere ce sens d'erreur a l'inverse, qui
     * effacerait de vrais conseils.
     */
    private static final Pattern REPROCHE = Pattern.compile(
        "\\b(incorrect|impropre|inappropri|inexact|fautif|fautive|faute|erreur"
            + "|agrammatical|barbarisme|calque|confusion|confond|remplac|corrig|evit"
            + "|mal (employ|chois|utilis|form|dit|plac|construit|adapt|orthographi)"
            + "|n (existe|est|a) pas|ne (se )?dit pas|ne veut rien dire"
            + "|au lieu de|a la place de"
            + "|pauvre|approximat|imprecis|passe[- ]partout|vague"
            + "|manque|absent|oubli|jamais donne|devrait|il faudrait|aurait du)");

    /** Apostrophes typographiques ou droites, ramenees a un blanc pour la detection. */
    private static final Pattern APOSTROPHES = Pattern.compile("['’‘]");

    /** Au-dela d'un mot porteur de sens, le reproche n'est plus « de niveau mot ». */
    private static final int MAX_MOTS_PORTEURS = 1;

    /**
     * Remplace un commentaire de critere entierement purge. Le champ est
     * obligatoire cote fronts : on ne le supprime pas, on dit franchement
     * pourquoi il est vide — meme pratique que les avertissements serveur.
     */
    static final String COMMENTAIRE_CRITERE_PURGE =
        "La seule remarque proposée pour ce critère portait sur un mot isolé de la "
            + "transcription : elle a été retirée. Nous ne vous reprochons jamais un mot que "
            + "la reconnaissance vocale a pu déformer.";

    /** Avertissement candidat, pose des qu'au moins une remarque a ete retiree. */
    static final String AVERTISSEMENT_ARTEFACT =
        "Une ou plusieurs remarques portaient sur un mot isolé de la transcription "
            + "automatique : elles ont été retirées. À l'oral, un mot mal transcrit n'est "
            + "jamais compté comme une erreur de votre part.";

    /** Resultat d'une purge : le feedback est modifie en place. */
    record Resultat(int remarquesRetirees, int exemplesRetires) {
        boolean aPurge() {
            return remarquesRetirees > 0 || exemplesRetires > 0;
        }
    }

    private EvaluationOralArtifactFilter() {
    }

    /**
     * Purge en place les champs de restitution d'une sortie ORALE.
     *
     * @param feedback   sortie du correcteur, deja normalisee
     * @param production transcription servie au correcteur (tours recolles)
     */
    static Resultat purge(Map<String, Object> feedback, String production) {
        int remarques = purgeScores(feedback, production)
            + purgePriorites(feedback, production)
            + purgeSuggestions(feedback, production);
        return new Resultat(remarques, purgeExemplesCorriges(feedback));
    }

    // ------------------------------------------------------------- par champ

    @SuppressWarnings("unchecked")
    private static int purgeScores(Map<String, Object> feedback, String production) {
        if (!(feedback.get("scores_criteres") instanceof List<?> scores)) return 0;
        int retirees = 0;
        for (Object raw : scores) {
            if (!(raw instanceof Map<?, ?> rawMap)) continue;
            Map<String, Object> score = (Map<String, Object>) rawMap;
            if (!(score.get("commentaire") instanceof String commentaire)) continue;
            Purge purge = purgerPhrases(commentaire, production);
            if (purge.phrasesRetirees() == 0) continue;
            retirees += purge.phrasesRetirees();
            score.put("commentaire",
                purge.reste().isBlank() ? COMMENTAIRE_CRITERE_PURGE : purge.reste());
        }
        return retirees;
    }

    @SuppressWarnings("unchecked")
    private static int purgePriorites(Map<String, Object> feedback, String production) {
        if (!(feedback.get("points_a_ameliorer") instanceof List<?> points)) return 0;
        List<Object> gardees = new ArrayList<>();
        int retirees = 0;
        for (Object raw : points) {
            if (!(raw instanceof Map<?, ?> rawMap)) {
                gardees.add(raw);
                continue;
            }
            Map<String, Object> point = new LinkedHashMap<>((Map<String, Object>) rawMap);
            Purge constat = purgerPhrases(texte(point.get("constat")), production);
            Purge comment = purgerPhrases(texte(point.get("comment")), production);
            int purgees = constat.phrasesRetirees() + comment.phrasesRetirees();
            if (purgees == 0) {
                gardees.add(rawMap);
                continue;
            }
            retirees += purgees;
            // Une priorite dont le constat OU la technique est tombee ne tenait
            // que par l'artefact : on la retire en entier plutot que de rendre
            // au candidat un demi-conseil.
            boolean vide = constat.reste().isBlank()
                || (point.get("comment") != null && comment.reste().isBlank());
            if (vide) continue;
            point.put("constat", constat.reste());
            if (point.get("comment") != null) point.put("comment", comment.reste());
            gardees.add(point);
        }
        feedback.put("points_a_ameliorer", gardees);
        return retirees;
    }

    private static int purgeSuggestions(Map<String, Object> feedback, String production) {
        if (!(feedback.get("suggestions") instanceof List<?> suggestions)) return 0;
        List<Object> gardees = new ArrayList<>();
        int retirees = 0;
        for (Object raw : suggestions) {
            if (!(raw instanceof String suggestion)) {
                gardees.add(raw);
                continue;
            }
            Purge purge = purgerPhrases(suggestion, production);
            if (purge.phrasesRetirees() == 0) {
                gardees.add(raw);
                continue;
            }
            retirees += purge.phrasesRetirees();
            if (!purge.reste().isBlank()) gardees.add(purge.reste());
        }
        feedback.put("suggestions", gardees);
        return retirees;
    }

    /**
     * {@code exemples_corriges} : on SUPPRIME l'entree dont l'explication ou le
     * gain se fonde sur une notion non evaluable a l'oral, au lieu de faire
     * echouer l'evaluation entiere (cf. {@link EvaluationOutputValidator}).
     */
    private static int purgeExemplesCorriges(Map<String, Object> feedback) {
        if (!(feedback.get("exemples_corriges") instanceof List<?> exemples)) return 0;
        List<Object> gardes = new ArrayList<>();
        int retires = 0;
        for (Object raw : exemples) {
            if (raw instanceof Map<?, ?> exemple
                && (EvaluationOutputValidator.mentionneMotifOralInterdit(exemple.get("explication"))
                    || EvaluationOutputValidator.mentionneMotifOralInterdit(exemple.get("gain")))) {
                retires++;
                continue;
            }
            gardes.add(raw);
        }
        feedback.put("exemples_corriges", gardes);
        return retires;
    }

    // ------------------------------------------------------------- mecanique

    private record Purge(String reste, int phrasesRetirees) {
    }

    /**
     * Retire les phrases qui ne tiennent que par une citation d'UN SEUL mot de la
     * transcription. Les autres sont recopiees telles quelles.
     */
    private static Purge purgerPhrases(String texte, String production) {
        if (texte == null || texte.isBlank() || production == null || production.isBlank()) {
            return new Purge(texte == null ? "" : texte, 0);
        }
        String[] phrases = FIN_DE_PHRASE.split(texte);
        List<String> gardees = new ArrayList<>(phrases.length);
        int retirees = 0;
        for (String phrase : phrases) {
            if (reprocheDeNiveauMot(phrase, production)) {
                retirees++;
            } else {
                gardees.add(phrase.strip());
            }
        }
        if (retirees == 0) return new Purge(texte, 0);
        return new Purge(String.join(" ", gardees).strip(), retirees);
    }

    /**
     * Vrai quand la phrase reunit les TROIS conditions :
     * <ol>
     *   <li>elle REPROCHE quelque chose ({@link #REPROCHE}) — un conseil qui cite
     *       un mot n'est jamais touche ;</li>
     *   <li>elle cite au moins un passage REEL de la transcription, retrouve
     *       dans un tour {@code Candidat :} ;</li>
     *   <li>TOUS les passages qu'elle cite ne nomment qu'un seul mot porteur de
     *       sens. Citer aussi un passage plus long suffit a la conserver : la
     *       remarque porte alors sur la construction de la phrase, pas sur un mot
     *       que la reconnaissance vocale a pu deformer.</li>
     * </ol>
     */
    private static boolean reprocheDeNiveauMot(String phrase, String production) {
        if (!REPROCHE.matcher(normaliserPourMarqueur(phrase)).find()) return false;
        Matcher matcher = CITATION.matcher(phrase);
        boolean ancree = false;
        while (matcher.find()) {
            String citation = premierGroupeNonNul(matcher);
            if (citation == null || citation.isBlank()) continue;
            if (EvaluationProofMatcher
                .canonicalPassage(production, citation, EpreuveType.TCF_EO).isEmpty()) {
                continue; // pas un passage de la transcription : on n'y touche pas
            }
            ancree = true;
            if (EvaluationProofMatcher.significantTokenCount(citation) > MAX_MOTS_PORTEURS) {
                return false;
            }
        }
        return ancree;
    }

    private static String premierGroupeNonNul(Matcher matcher) {
        for (int i = 1; i <= matcher.groupCount(); i++) {
            if (matcher.group(i) != null) return matcher.group(i);
        }
        return null;
    }

    /** Minuscules, accents retires, apostrophes ramenees a un blanc. */
    private static String normaliserPourMarqueur(String text) {
        String sansAccents = java.text.Normalizer
            .normalize(APOSTROPHES.matcher(text).replaceAll(" "),
                java.text.Normalizer.Form.NFD)
            .replaceAll("\\p{M}+", "");
        return sansAccents.toLowerCase(java.util.Locale.FRENCH).replaceAll("\\s+", " ");
    }

    private static String texte(Object raw) {
        return raw == null ? "" : raw.toString();
    }
}
