package com.sejourfr.app.service;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * INDICATEUR DE QUALITE D'UNE TRANSCRIPTION, deterministe et gratuit.
 *
 * <h2>Le probleme</h2>
 * Nos deux sources de texte oral se degradent, et nous ne le mesurions pas :
 * <ul>
 *   <li>Whisper renvoie {@code verbose_json} — donc {@code segments[].avg_logprob},
 *       {@code no_speech_prob}, {@code compression_ratio} — que nous PAYONS et
 *       que nous jetions ;</li>
 *   <li>le temps reel (Gemini natif-audio, transcription remontee par le client)
 *       n'expose <b>rien</b>. C'est pourtant la source la plus abimee.</li>
 * </ul>
 * Consequence vecue : le bug « mot coupe en deux » a hache SIX SEMAINES de
 * transcriptions temps reel (28 juin → 4 juillet 2026) sans qu'aucun chiffre ne
 * le signale. Cet indicateur, lui, marche sur les DEUX sources, parce qu'il ne
 * lit que le texte final.
 *
 * <h2>Ce qu'il mesure</h2>
 * Deux taux, pris sur les seuls tours {@code Candidat :} (les mots de
 * l'examinateur ne sont pas la production) :
 * <ol>
 *   <li><b>formes suspectes</b> — part des mots de 1 a 3 lettres <b>absents</b>
 *       de {@link #MOTS_COURTS_FR}. Un mot francais de trois lettres appartient a
 *       un inventaire petit et ferme ; un debris de mot coupe
 *       ({@code abo}, {@code ffi}, {@code cep}, {@code emplo yé}) n'y est jamais ;</li>
 *   <li><b>collages</b> — part des positions ou <b>deux</b> formes suspectes se
 *       suivent ({@code ves te}, {@code com me commer cial}). C'est la signature
 *       specifique du mot coupe, plus rare et plus sure que la premiere.</li>
 * </ol>
 *
 * <h2>Pourquoi PAS de dictionnaire francais embarque</h2>
 * Un taux de mots hors-vocabulaire exact demanderait ~475 000 formes flechies :
 * 2 a 4 Mo dans le jar, quelques dizaines de Mo en memoire, une licence tierce a
 * respecter, et un fichier de plus a maintenir. <b>Mesure faite sur les 148
 * productions reelles de la base</b> (dont 123 assez longues pour etre mesurees :
 * 63 EE, 28 EO Whisper, 32 EO temps reel) : la liste fermee ci-dessous suffit a
 * separer, et elle separe meme mieux qu'un taux de mots hors-vocabulaire brut —
 * parce que les mots <b>longs</b> hors-vocabulaire sont majoritairement des noms
 * propres, des sigles et des neologismes d'apprenant, c'est-a-dire du bruit.
 * Chiffres, part de formes suspectes :
 * <table>
 *   <caption>Repartition mesuree</caption>
 *   <tr><th></th><th>mediane</th><th>p90</th><th>max</th></tr>
 *   <tr><td>EE (tape, reference saine)</td><td>0,00 %</td><td>1,96 %</td><td>37,78 %</td></tr>
 *   <tr><td>EO Whisper</td><td>0,00 %</td><td>1,18 %</td><td>11,86 %</td></tr>
 *   <tr><td>EO temps reel</td><td>1,32 %</td><td>22,81 %</td><td>26,94 %</td></tr>
 * </table>
 * En temps reel, la separation est <b>binaire</b> et colle exactement a la
 * fenetre du bug : les 8 sessions mesurables du 28 juin au 4 juillet au matin
 * sont toutes entre <b>18,29 % et 26,94 %</b>, les 24 suivantes toutes
 * <b>sous 4,84 %</b> — aucune observation entre les deux. Le seul cas Whisper
 * au-dessus du seuil est une transcription degeneree (« bla bla bla »). Les 3
 * seuls EE au-dessus sont des productions redigees <b>en anglais</b> (hors sujet
 * reel) — et l'ecrit n'est de toute facon jamais actionne, cf. plus bas.
 *
 * <h2>Ce que l'indicateur declenche — et rien de plus</h2>
 * <ul>
 *   <li>le volet FORME de {@link EvaluationOralArtifactFilter} passe en mode
 *       large : sur une transcription abimee, tout reproche de morphosyntaxe
 *       adosse a un passage cite est suspect ;</li>
 *   <li>la <b>confiance</b> est plafonnee. C'est doctrinalement le bon champ :
 *       la confiance est la certitude du CORRECTEUR, et une transcription abimee
 *       est un obstacle a l'OBSERVATION, pas un defaut du candidat.</li>
 * </ul>
 * <b>La note, le niveau et les seuils ne bougent jamais.</b>
 */
final class TranscriptionQualityAudit {

    /**
     * Seuil de degradation sur la part de formes suspectes.
     *
     * <p><b>Origine, mesuree.</b> Pire transcription temps reel du regime actuel
     * (bug du mot coupe corrige) : <b>4,84 %</b>. Pire transcription Whisper hors
     * cas degenere : <b>2,82 %</b>. Plus faible transcription de la fenetre du
     * bug : <b>18,29 %</b>. 10 % se place a 2,1x au-dessus du pire cas sain et a
     * 1,8x en dessous du plus doux des cas abimes — au milieu d'un fosse ou il
     * n'y a <b>aucune</b> observation.
     */
    static final double SEUIL_FORMES_SUSPECTES = 0.10;

    /**
     * Seuil de degradation sur la part de collages (deux formes suspectes qui se
     * suivent). Mesure : 0 % de mediane partout, <b>1,64 % au pire</b> en temps
     * reel sain, <b>2,47 % a 9,38 %</b> dans la fenetre du bug. Ce second taux ne
     * sert qu'a rattraper une production courte ou la premiere mesure serait
     * diluee ; il ne remplace pas la premiere.
     */
    static final double SEUIL_COLLAGES = 0.02;

    /**
     * En dessous de ce nombre de mots exploitables on ne conclut rien
     * ({@code mesurable=false}) : un seul token pese alors plus de 2,5 %. Meme
     * plancher que le volet LANGUE de {@link EvaluationOralArtifactFilter}, pour
     * que les deux filets ne se contredisent pas sur la meme production.
     */
    static final int MOTS_MIN = 40;

    /** Longueur maximale d'un mot « court » : au-dela, l'inventaire n'est plus fermable. */
    private static final int LONGUEUR_COURTE_MAX = 3;

    /**
     * INVENTAIRE FERME des mots francais de 1 a 3 lettres, <b>sans accents</b>
     * (la tokenisation de {@link ProductionValidityService#motsNormalises} les
     * retire deja) : mots-outils, formes verbales breves, noms courants, lettres
     * elidees ({@code j'}, {@code l'}, {@code qu'}), interjections, unites et
     * sigles du domaine.
     *
     * <p><b>Le sens de l'erreur est assume.</b> Un mot legitime oublie ici gonfle
     * l'indicateur ; c'est pour cela que le seuil est pose a 2x au-dessus du
     * pire cas sain observe, et non au ras. A l'inverse, ajouter des entres ne
     * peut que RENDRE l'indicateur plus tolerant — c'est le sens sur : on ne
     * declare degradee qu'une transcription qui l'est franchement.
     */
    private static final Set<String> MOTS_COURTS_FR = motsCourts();

    /**
     * Inventaire = liste litterale ci-dessous <b>plus</b> les mots-outils de
     * {@link ProductionValidityService#MOTS_OUTILS_FR} de trois lettres au plus.
     * Reprendre l'autre liste plutot que de la recopier est ce qui evite qu'un
     * {@code je} ou un {@code les} manque ici : mesure faite, l'oubli des
     * mots-outils portait la mediane EE de 0,00 % a 5,26 % et rendait
     * l'indicateur inutilisable.
     */
    private static Set<String> motsCourts() {
        Set<String> mots = new HashSet<>(Set.of(
        "a", "age", "aie", "ail", "air", "ait", "ame", "ami", "an", "ane", "ans", "api", "arc",
        "art", "aws", "bac", "bah", "bal", "bar", "bas", "bec", "bel", "ben", "bio", "bis",
        "ble", "bol", "bon", "bot", "bou", "box", "bru", "bu", "bug", "bus", "but", "ca", "cap",
        "cas", "cd", "cdd", "cdi", "ci", "cle", "cm", "co", "col", "coq", "cou", "cpu", "cri",
        "cru", "css", "cul", "dis", "dix", "doc", "don", "dos", "duo", "dur", "dus", "dut",
        "eau", "eh", "elu", "ere", "es", "esn", "eu", "euh", "eus", "eut", "ex", "fac", "fee",
        "fer", "feu", "fil", "fin", "fis", "fit", "foi", "fol", "fou", "fus", "fut", "gag",
        "gai", "gaz", "gcp", "gel", "go", "gps", "gre", "ha", "he", "hem", "heu", "ho", "hui",
        "hum", "ile", "ils", "ira", "ire", "jeu", "jus", "kg", "km", "lac", "las", "lin", "lis",
        "lit", "loi", "lot", "lu", "lus", "lut", "m", "mal", "mat", "mec", "mer", "met", "mi",
        "mie", "mis", "mit", "mm", "mot", "mou", "mu", "mur", "nee", "nes", "nez", "nid", "nie",
        "nom", "non", "nu", "nue", "nul", "nus", "oh", "oie", "ok", "or", "os", "ose", "ote",
        "ouf", "oui", "par", "pc", "pdf", "peu", "pic", "pie", "pin", "plu", "pot", "pre", "pro",
        "pu", "pue", "pur", "pus", "put", "ram", "ras", "rat", "rer", "rez", "ria", "rit", "riz",
        "roi", "rtt", "ru", "rue", "rus", "s", "sac", "sec", "sel", "set", "six", "ski", "sms",
        "soi", "sol", "sou", "sql", "su", "sud", "sur", "sus", "sut", "t", "tas", "tcf", "tel",
        "tgv", "tot", "tri", "tue", "tut", "tv", "uni", "us", "usa", "usb", "use", "va", "val",
        "van", "vas", "ver", "vie", "vif", "vin", "vis", "vit", "vol", "vu", "vue", "vus", "web",
        "zoo"));
        for (String outil : ProductionValidityService.MOTS_OUTILS_FR) {
            if (outil.length() <= LONGUEUR_COURTE_MAX) mots.add(outil);
        }
        return Set.copyOf(mots);
    }

    private TranscriptionQualityAudit() {
    }

    /**
     * Mesure d'une production.
     *
     * @param production texte servi au correcteur (tours recolles), ou {@code null}
     */
    static Mesure mesurer(String production) {
        if (production == null || production.isBlank()) return Mesure.nonMesurable(0);
        String texte = production.strip();
        String duCandidat = ProductionValidityService.estDialogue(texte)
            ? ProductionValidityService.toursDuCandidat(texte)
            : texte;
        if (duCandidat.isBlank()) return Mesure.nonMesurable(0);

        List<String> mots = new ArrayList<>();
        for (String mot : ProductionValidityService.motsNormalises(duCandidat)) {
            if (!EvaluationProofMatcher.DISFLUENCES.contains(mot)) mots.add(mot);
        }
        int total = mots.size();
        if (total < MOTS_MIN) return Mesure.nonMesurable(total);

        Set<String> formes = new LinkedHashSet<>();
        boolean[] suspect = new boolean[total];
        for (int i = 0; i < total; i++) {
            suspect[i] = estSuspect(mots.get(i));
            if (suspect[i]) formes.add(mots.get(i));
        }
        int nbSuspects = 0;
        for (boolean b : suspect) if (b) nbSuspects++;
        int collages = 0;
        for (int i = 0; i + 1 < total; i++) {
            if (suspect[i] && suspect[i + 1]) collages++;
        }
        double tauxFormes = (double) nbSuspects / total;
        double tauxCollages = (double) collages / (total - 1);
        boolean degradee = tauxFormes > SEUIL_FORMES_SUSPECTES || tauxCollages > SEUIL_COLLAGES;
        return new Mesure(total, tauxFormes, tauxCollages, true, degradee, List.copyOf(formes));
    }

    /**
     * Renseigne les colonnes de qualite MAISON d'une transcription qu'on
     * s'apprete a persister. Un seul endroit pour les deux sources (Whisper
     * asynchrone et temps reel) : c'est ce qui garantit que les deux lignes de
     * la table se comparent.
     *
     * <p>Le texte mesure est le texte BRUT, avant recollage des tours. Sans
     * consequence : le recollage ne deplace que des frontieres de tour, il
     * n'ajoute ni ne retire un seul mot.
     */
    static void renseigner(com.sejourfr.app.entity.Transcription transcription, String texte) {
        Mesure mesure = mesurer(texte);
        if (!mesure.mesurable()) return;
        transcription.setTauxFormesSuspectes(mesure.tauxFormesSuspectes());
        transcription.setTauxCollages(mesure.tauxCollages());
        transcription.setQualiteDegradee(mesure.degradee());
    }

    /**
     * Une forme est suspecte quand elle est courte et absente de l'inventaire.
     * Un token portant un chiffre n'est jamais suspect : c'est une date, un age
     * ou un numero, jamais un debris de mot.
     */
    private static boolean estSuspect(String mot) {
        if (mot.length() > LONGUEUR_COURTE_MAX) return false;
        for (int i = 0; i < mot.length(); i++) {
            if (Character.isDigit(mot.charAt(i))) return false;
        }
        return !MOTS_COURTS_FR.contains(mot);
    }

    /**
     * @param mots               mots exploitables du candidat
     * @param tauxFormesSuspectes part de formes courtes inconnues
     * @param tauxCollages       part de positions ou deux formes suspectes se suivent
     * @param mesurable          production assez longue pour conclure
     * @param degradee           au moins un des deux seuils franchi
     * @param formes             formes suspectes vues (pour le log, jamais pour le candidat)
     */
    record Mesure(int mots, double tauxFormesSuspectes, double tauxCollages,
                  boolean mesurable, boolean degradee, List<String> formes) {

        static Mesure nonMesurable(int mots) {
            return new Mesure(mots, 0.0, 0.0, false, false, List.of());
        }
    }
}
