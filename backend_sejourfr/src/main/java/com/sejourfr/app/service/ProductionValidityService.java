package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.DouteValidite;
import com.sejourfr.app.enums.ValiditeProduction;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Controles DETERMINISTES d'une production EE/EO, executes <b>avant</b> l'appel
 * au LLM (aucune IA, aucune dependance externe). Trois familles :
 *
 * <ol>
 *   <li><b>Production vide ou quasi vide</b> : texte blanc, moins de
 *       {@code min-mots-exploitables} mots, ou — en EO dialoguee — aucun tour
 *       {@code Candidat :} exploitable.</li>
 *   <li><b>Langue dominante</b> : heuristique sans dependance = (a) proportion
 *       de lettres d'un alphabet non latin, (b) proportion de mots-outils
 *       francais frequents parmi les mots de la production. Un texte francais
 *       courant depasse 30 % de mots-outils ; un texte anglais/espagnol tombe
 *       quasiment a 0 avec cette liste. Seuils volontairement bas
 *       (10 % invalide / 18 % avertissement) pour ne jamais bloquer un vrai
 *       candidat francophone maladroit. L'analyse n'est declenchee qu'a partir
 *       de {@code mots-min-analyse-langue} mots : en dessous, le ratio n'a
 *       aucune valeur statistique.</li>
 *   <li><b>Recopiage de la consigne</b> : taux de recouvrement en n-grammes de
 *       {@code ngram-consigne} mots normalises entre la production et
 *       {@code task.consigne}. Au-dela de 30 % → avertissement ; au-dela de
 *       60 % → invalide (la production n'est plus personnelle).</li>
 * </ol>
 *
 * <p>Le verdict le plus severe l'emporte, toutes les raisons sont conservees.
 * Les raisons sont redigees pour etre lues <b>par le candidat</b> (francais
 * simple, sans jargon).
 *
 * <p>Chaque avertissement porte en plus sa {@link DouteValidite nature} : un
 * doute d'<b>observation</b> (on ne lit pas bien la langue produite) n'a pas les
 * memes consequences qu'un doute d'<b>authenticite</b> (on lit tres bien, mais
 * une partie des mots vient de l'enonce). Seul le premier plafonne la confiance
 * de la correction — cf. {@code AiEvaluationService.applyConfiance}.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProductionValidityService {

    /**
     * Mots-outils francais frequents, sous leur forme NORMALISEE (minuscules,
     * sans accents) : c'est cette forme que produit {@link #motsNormalises}.
     * Les tokens ambigus avec l'anglais (« a », « i », « to », « in ») en sont
     * volontairement absents — ils feraient passer un texte anglais pour du
     * francais. Les elisions (« l », « d », « qu », « c », « j », « n ») sont
     * gardees : apres normalisation, « l'ecole » donne « l ecole », marqueur
     * tres francais.
     */
    static final Set<String> MOTS_OUTILS_FR = Set.of(
        "le", "la", "les", "un", "une", "des", "du", "de", "au", "aux",
        "et", "ou", "mais", "donc", "car", "ni", "que", "qui", "quoi", "dont",
        "est", "sont", "etait", "etaient", "sera", "seront", "ete", "etre",
        "ai", "as", "avez", "avons", "ont", "avait", "avaient", "avoir",
        "je", "tu", "il", "elle", "on", "nous", "vous", "ils", "elles",
        "me", "te", "se", "moi", "toi", "lui", "eux", "leur", "leurs",
        "mon", "ma", "mes", "ton", "ta", "tes", "son", "sa", "ses",
        "notre", "nos", "votre", "vos", "ce", "cet", "cette", "ces",
        "pour", "dans", "sur", "sous", "avec", "sans", "chez", "vers",
        "pas", "plus", "ne", "tres", "bien", "aussi", "alors", "quand",
        "parce", "comme", "tout", "tous", "toute", "toutes", "meme",
        "beaucoup", "deja", "encore", "toujours", "jamais", "ici", "aujourd",
        "faire", "fait", "dire", "dit", "peut", "peux", "veux", "veut",
        "l", "d", "qu", "c", "j", "n",
        "apres", "avant", "entre", "depuis", "pendant", "si", "y", "en"
    );

    /** Un tour de parole : « Examinateur : ... » ou « Candidat : ... ». */
    private static final Pattern MARQUEUR_TOUR =
        Pattern.compile("^\\s*(examinateur|candidat)\\s*:", Pattern.CASE_INSENSITIVE);

    private static final Pattern MARQUEUR_CANDIDAT =
        Pattern.compile("^\\s*candidat\\s*:", Pattern.CASE_INSENSITIVE);

    private final ProductionEvaluationProperties props;

    /**
     * Verdict de validite d'une production.
     *
     * @param statut  severite maximale rencontree
     * @param raisons explications lisibles PAR LE CANDIDAT (jamais de jargon)
     * @param doutes  nature des doutes rencontres. Un avertissement de langue
     *                traduit un obstacle a l'{@link DouteValidite#OBSERVATION},
     *                un recopiage de consigne un doute d'
     *                {@link DouteValidite#AUTHENTICITE} : seul le premier
     *                justifie de plafonner la confiance de la correction.
     */
    public record Verdict(ValiditeProduction statut, List<String> raisons, Set<DouteValidite> doutes) {

        public static Verdict valide() {
            return new Verdict(ValiditeProduction.VALIDE, List.of(), Set.of());
        }

        public boolean invalide() {
            return statut == ValiditeProduction.INVALIDE;
        }

        public boolean avertissement() {
            return statut == ValiditeProduction.AVERTISSEMENT;
        }

        /**
         * Vrai quand un avertissement traduit un obstacle reel a l'observation
         * de la langue produite — le seul motif qui autorise le serveur a
         * abaisser la confiance annoncee par le correcteur.
         */
        public boolean douteObservation() {
            return avertissement() && doutes.contains(DouteValidite.OBSERVATION);
        }
    }

    /**
     * Applique les trois familles de controles. Ne fait aucun appel reseau.
     *
     * @param task       la tache (fournit la consigne pour le controle de recopiage)
     * @param production texte EE rendu, ou transcription EO (dialoguee ou non)
     */
    public Verdict evaluer(ProductionTask task, String production) {
        ProductionEvaluationProperties.Validite cfg = props.getValidite();
        List<String> raisons = new ArrayList<>();
        Set<DouteValidite> doutes = EnumSet.noneOf(DouteValidite.class);
        ValiditeProduction statut = ValiditeProduction.VALIDE;

        String texte = production == null ? "" : production.strip();
        boolean dialogue = estDialogue(texte);
        String aAnalyser = dialogue ? toursDuCandidat(texte) : texte;

        // 1. Production vide / quasi vide.
        List<String> mots = motsNormalises(aAnalyser);
        if (aAnalyser.isBlank() || mots.size() < cfg.getMinMotsExploitables()) {
            raisons.add(dialogue
                ? "Nous n'avons trouvé aucune prise de parole exploitable de votre part dans cet échange."
                : "Votre production est vide ou trop courte pour être évaluée.");
            // Rien d'exploitable : inutile de pousser les autres controles.
            return new Verdict(ValiditeProduction.INVALIDE, List.copyOf(raisons), Set.of());
        }

        // 2. Langue dominante.
        double ratioNonLatin = ratioLettresNonLatines(aAnalyser);
        if (ratioNonLatin > cfg.getRatioAlphabetNonLatinInvalide()) {
            raisons.add("Votre texte n'est pas rédigé en français : il utilise un autre alphabet.");
            statut = ValiditeProduction.INVALIDE;
        } else if (mots.size() >= cfg.getMotsMinAnalyseLangue()) {
            double ratioOutils = ratioMotsOutils(mots);
            if (ratioOutils < cfg.getRatioMotsOutilsInvalide()) {
                raisons.add("Votre texte n'est pas rédigé en français. L'épreuve doit être "
                    + "composée en français pour être évaluée.");
                statut = ValiditeProduction.INVALIDE;
            } else if (ratioOutils < cfg.getRatioMotsOutilsAvertissement()) {
                raisons.add("Une partie importante de votre production ne semble pas être en français. "
                    + "L'évaluation est donc moins fiable.");
                // On ne lit qu'a moitie ce que le candidat produit en francais :
                // obstacle a l'OBSERVATION, donc plafond de confiance legitime.
                doutes.add(DouteValidite.OBSERVATION);
                statut = pire(statut, ValiditeProduction.AVERTISSEMENT);
            }
        }

        // 3. Recopiage de la consigne.
        double recopiage = ratioRecopiage(mots, task == null ? null : task.getConsigne(), cfg.getNgramConsigne());
        if (recopiage >= cfg.getRatioRecopiageInvalide()) {
            raisons.add("Votre production reprend presque mot pour mot l'énoncé de la consigne. "
                + "Ce n'est pas une production personnelle : elle ne peut pas être notée.");
            statut = ValiditeProduction.INVALIDE;
        } else if (recopiage >= cfg.getRatioRecopiageAvertissement()) {
            raisons.add("Une partie importante de votre production recopie l'énoncé de la consigne. "
                + "Seuls vos propres mots sont pris en compte.");
            // Doute sur l'ORIGINE des mots, pas sur leur lisibilite : ce qui
            // reste est parfaitement observable. On avertit le candidat, on ne
            // plafonne PAS la confiance de la correction.
            doutes.add(DouteValidite.AUTHENTICITE);
            statut = pire(statut, ValiditeProduction.AVERTISSEMENT);
        }

        if (statut != ValiditeProduction.VALIDE) {
            log.info("Controle de validite : statut={} raisons={} doutes={}",
                statut, raisons.size(), doutes);
        }
        return new Verdict(statut, List.copyOf(raisons), Set.copyOf(doutes));
    }

    /** Vrai si le texte porte au moins un marqueur de tour de parole. */
    static boolean estDialogue(String texte) {
        for (String ligne : texte.split("\\R")) {
            if (MARQUEUR_TOUR.matcher(ligne).find()) return true;
        }
        return false;
    }

    /**
     * Concatene le contenu des tours {@code Candidat :} (le contenu court
     * jusqu'au marqueur suivant). Les tours {@code Examinateur :} sont exclus :
     * les mots de l'examinateur ne sont pas la production du candidat.
     */
    static String toursDuCandidat(String texte) {
        StringBuilder sb = new StringBuilder();
        boolean dansCandidat = false;
        for (String ligne : texte.split("\\R")) {
            var m = MARQUEUR_CANDIDAT.matcher(ligne);
            if (m.find()) {
                dansCandidat = true;
                sb.append(ligne.substring(m.end())).append('\n');
                continue;
            }
            if (MARQUEUR_TOUR.matcher(ligne).find()) {
                dansCandidat = false;
                continue;
            }
            if (dansCandidat) sb.append(ligne).append('\n');
        }
        return sb.toString().strip();
    }

    /**
     * Minuscules, accents retires, tout ce qui n'est ni lettre ni chiffre
     * remplace par un espace, puis decoupage. Les elisions deviennent des
     * tokens a part entiere (« l'ecole » -> [« l », « ecole »]).
     */
    static List<String> motsNormalises(String texte) {
        if (texte == null || texte.isBlank()) return List.of();
        String sansAccents = Normalizer.normalize(texte, Normalizer.Form.NFD)
            .replaceAll("\\p{M}+", "");
        String plat = sansAccents.toLowerCase(Locale.FRENCH)
            .replaceAll("[^\\p{IsAlphabetic}\\p{IsDigit}]+", " ")
            .strip();
        if (plat.isEmpty()) return List.of();
        return List.of(plat.split("\\s+"));
    }

    /** Proportion de lettres appartenant a un alphabet non latin (0 si aucune lettre). */
    static double ratioLettresNonLatines(String texte) {
        int lettres = 0;
        int nonLatines = 0;
        for (int i = 0; i < texte.length(); ) {
            int cp = texte.codePointAt(i);
            i += Character.charCount(cp);
            if (!Character.isLetter(cp)) continue;
            lettres++;
            if (Character.UnicodeScript.of(cp) != Character.UnicodeScript.LATIN) nonLatines++;
        }
        return lettres == 0 ? 0.0 : (double) nonLatines / lettres;
    }

    /** Proportion de mots-outils francais parmi les mots (0 si aucun mot). */
    static double ratioMotsOutils(List<String> mots) {
        if (mots.isEmpty()) return 0.0;
        int hits = 0;
        for (String mot : mots) {
            if (MOTS_OUTILS_FR.contains(mot)) hits++;
        }
        return (double) hits / mots.size();
    }

    /**
     * Part des n-grammes de la production egalement presents dans la consigne.
     * 0 quand la consigne est absente ou quand l'un des deux textes est plus
     * court que {@code n} mots.
     */
    static double ratioRecopiage(List<String> motsProduction, String consigne, int n) {
        if (consigne == null || consigne.isBlank() || n < 2) return 0.0;
        List<String> motsConsigne = motsNormalises(consigne);
        if (motsConsigne.size() < n || motsProduction.size() < n) return 0.0;

        Set<String> refs = new HashSet<>(ngrammes(motsConsigne, n));
        List<String> cibles = ngrammes(motsProduction, n);
        if (cibles.isEmpty()) return 0.0;
        int hits = 0;
        for (String g : cibles) {
            if (refs.contains(g)) hits++;
        }
        return (double) hits / cibles.size();
    }

    private static List<String> ngrammes(List<String> mots, int n) {
        List<String> out = new ArrayList<>();
        for (int i = 0; i + n <= mots.size(); i++) {
            out.add(String.join(" ", mots.subList(i, i + n)));
        }
        return out;
    }

    private static ValiditeProduction pire(ValiditeProduction a, ValiditeProduction b) {
        return a.ordinal() >= b.ordinal() ? a : b;
    }
}
