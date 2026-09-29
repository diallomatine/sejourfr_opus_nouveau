package com.sejourfr.app.service;

import com.sejourfr.app.enums.EpreuveType;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;

/**
 * DECOUPE NUMEROTEE de la production. C'est l'unite de PREUVE du contrat de
 * sortie v6, celui qui supprime la categorie entiere des « citations
 * introuvables ».
 *
 * <p><b>Le probleme qu'elle resout.</b> Jusqu'au contrat v5, le correcteur
 * RECOPIAIT un extrait de la production dans un champ texte, et le serveur
 * verifiait apres coup que cet extrait existait vraiment. Un modele peut se
 * tromper en recopiant — il dedouble un begaiement, il normalise une graphie,
 * il recompose deux morceaux — et nous ne pouvions que refuser sa sortie, la
 * rejouer une fois, puis la degrader. Une preuve juste etait perdue parce que
 * la COPIE etait imparfaite.
 *
 * <p><b>Ce qui change.</b> Le correcteur ne recopie plus rien : il DESIGNE un
 * numero. Inventer une preuve devient impossible PAR CONSTRUCTION, pas
 * « interdit » : le seul defaut possible est un numero hors bornes, et c'est un
 * entier a comparer a une taille de liste. Le serveur resout ensuite le numero
 * en texte AVANT persistance, donc {@code feedback_json} continue de porter un
 * champ {@code preuve} textuel et les trois fronts ne voient aucune difference.
 *
 * <p><b>Granularite retenue</b>, et pourquoi :
 * <ul>
 *   <li><b>oral en interaction : un segment = UN TOUR {@code Candidat :}</b>.
 *       C'est ce que le candidat a dit d'un seul trait, donc une unite qu'il
 *       reconnait a l'ecran. C'est aussi ce qui rend structurellement
 *       impossible de citer l'examinateur — les tours {@code Examinateur :}
 *       sont montres au correcteur (le deroule de l'echange compte dans
 *       {@code communiquer} et {@code interagir}) mais ne portent AUCUN numero.
 *       Apres recollage des tours, un tour candidat fait 14 tokens en mediane :
 *       assez court pour designer quelque chose, assez long pour montrer une
 *       construction ;</li>
 *   <li><b>ecrit, et oral monologue : un segment = UNE PHRASE</b>. A l'ecrit,
 *       la phrase est l'unite de syntaxe : c'est sur elle que se lisent la
 *       subordination, les connecteurs, les temps — exactement ce que les
 *       criteres observent.</li>
 * </ul>
 *
 * <p><b>Pourquoi pas plus fin.</b> Decouper sous la phrase (groupes de mots,
 * fenetres de N tokens) demanderait une coupure arbitraire, que le correcteur ne
 * saurait pas designer de facon fiable et qui rendrait la preuve illisible pour
 * le candidat. La preuve doit rester un morceau de langue, pas un fragment.
 *
 * <p><b>Invariant</b> : le texte d'un segment est la sous-chaine ORIGINALE de la
 * production (blancs de bordure retires), begaiements, artefacts et graphie
 * compris — le meme invariant que celui du rapprochement litteral : le texte
 * cite au candidat EST celui qu'il a produit.
 */
public final class EvaluationProductionSegments {

    /** Un segment citable : son numero (1-based) et son texte original exact. */
    public record Segment(int numero, String texte) {
    }

    /**
     * Un bloc du materiau rendu au correcteur. {@code numero == 0} = bloc montre
     * mais NON citable (un tour de l'examinateur).
     */
    private record Bloc(int numero, String texte) {
    }

    private final List<Bloc> blocs;
    private final List<Segment> segments;

    private EvaluationProductionSegments(List<Bloc> blocs, List<Segment> segments) {
        this.blocs = blocs;
        this.segments = segments;
    }

    public static EvaluationProductionSegments of(String production, EpreuveType epreuve) {
        String texte = production == null ? "" : production;
        if (texte.isBlank()) return new EvaluationProductionSegments(List.of(), List.of());
        return epreuve == EpreuveType.TCF_EO ? depuisTranscription(texte) : depuisPhrases(texte);
    }

    /** Nombre de segments CITABLES. Un numero valide vaut 1..taille(). */
    public int taille() {
        return segments.size();
    }

    public List<Segment> segments() {
        return segments;
    }

    /** Texte original exact du segment {@code numero}, vide si le numero n'existe pas. */
    public Optional<String> texte(int numero) {
        if (numero < 1 || numero > segments.size()) return Optional.empty();
        return Optional.of(segments.get(numero - 1).texte());
    }

    /**
     * Materiau rendu au correcteur : la production dans son ORDRE d'origine, les
     * segments citables prefixes de leur numero entre crochets. Un tour
     * d'examinateur est conserve tel quel, sans numero.
     */
    public String rendu() {
        StringBuilder sb = new StringBuilder();
        for (Bloc bloc : blocs) {
            if (sb.length() > 0) sb.append('\n');
            if (bloc.numero() > 0) sb.append('[').append(bloc.numero()).append("] ");
            sb.append(bloc.texte());
        }
        return sb.toString();
    }

    // ------------------------------------------------------------------ oral

    /**
     * Dialogue : un segment par tour {@code Candidat :}. Le decoupage lit le
     * meme marqueur de tour que le rapprochement litteral
     * ({@link EvaluationProofMatcher#TURN_MARKER}) — deux lectures differentes
     * d'un meme dialogue seraient exactement le defaut qu'on cherche a
     * supprimer.
     *
     * <p>Sans aucun marqueur, la transcription est un monologue : tout vient du
     * candidat, on retombe sur le decoupage en phrases.
     */
    private static EvaluationProductionSegments depuisTranscription(String production) {
        Matcher matcher = EvaluationProofMatcher.TURN_MARKER.matcher(production);
        List<int[]> marqueurs = new ArrayList<>();
        List<String> locuteurs = new ArrayList<>();
        while (matcher.find()) {
            marqueurs.add(new int[]{matcher.start(), matcher.end()});
            locuteurs.add(matcher.group(1));
        }
        if (marqueurs.isEmpty()) return depuisPhrases(production);

        List<Bloc> blocs = new ArrayList<>();
        List<Segment> segments = new ArrayList<>();
        for (int i = 0; i < marqueurs.size(); i++) {
            int fin = i + 1 < marqueurs.size() ? marqueurs.get(i + 1)[0] : production.length();
            String tour = production.substring(marqueurs.get(i)[0], fin).strip();
            if (tour.isBlank()) continue;
            boolean candidat = "candidat".equalsIgnoreCase(locuteurs.get(i));
            String contenu = production.substring(marqueurs.get(i)[1], fin).strip();
            if (!candidat || contenu.isBlank()) {
                blocs.add(new Bloc(0, tour));
                continue;
            }
            int numero = segments.size() + 1;
            segments.add(new Segment(numero, contenu));
            blocs.add(new Bloc(numero, tour));
        }
        return new EvaluationProductionSegments(List.copyOf(blocs), List.copyOf(segments));
    }

    // ----------------------------------------------------------------- ecrit

    private static EvaluationProductionSegments depuisPhrases(String production) {
        List<Bloc> blocs = new ArrayList<>();
        List<Segment> segments = new ArrayList<>();
        for (String phrase : phrases(production)) {
            int numero = segments.size() + 1;
            segments.add(new Segment(numero, phrase));
            blocs.add(new Bloc(numero, phrase));
        }
        return new EvaluationProductionSegments(List.copyOf(blocs), List.copyOf(segments));
    }

    /**
     * Decoupe en phrases : coupure apres une ponctuation forte suivie d'un blanc
     * (ou de la fin), et a chaque saut de ligne. Un morceau sans le moindre
     * caractere alphanumerique (une suite de points, un tiret isole) n'est
     * jamais un segment a lui seul : il est rattache au precedent, sinon on
     * offrirait au correcteur un numero qui ne designe aucun mot.
     */
    private static List<String> phrases(String texte) {
        List<String> brutes = new ArrayList<>();
        int debut = 0;
        for (int i = 0; i < texte.length(); i++) {
            char c = texte.charAt(i);
            int coupeApres = -1;
            if (c == '\n' || c == '\r') {
                coupeApres = i;
            } else if (".!?…".indexOf(c) >= 0) {
                int j = i + 1;
                while (j < texte.length() && ".!?…\"'»)]”".indexOf(texte.charAt(j)) >= 0) {
                    j++;
                }
                if (j >= texte.length() || Character.isWhitespace(texte.charAt(j))) {
                    coupeApres = j - 1;
                    i = j - 1;
                }
            }
            if (coupeApres >= 0) {
                brutes.add(texte.substring(debut, coupeApres + 1));
                debut = coupeApres + 1;
            }
        }
        if (debut < texte.length()) brutes.add(texte.substring(debut));

        List<String> out = new ArrayList<>();
        for (String brute : brutes) {
            String phrase = brute.strip();
            if (phrase.isEmpty()) continue;
            if (!porteDuTexte(phrase) && !out.isEmpty()) {
                out.set(out.size() - 1, out.get(out.size() - 1) + " " + phrase);
                continue;
            }
            out.add(phrase);
        }
        // Un texte entier sans aucun mot ne produit aucun segment citable.
        if (out.size() == 1 && !porteDuTexte(out.get(0))) return List.of();
        return out;
    }

    private static boolean porteDuTexte(String phrase) {
        for (int i = 0; i < phrase.length(); i++) {
            if (Character.isLetterOrDigit(phrase.charAt(i))) return true;
        }
        return false;
    }
}
