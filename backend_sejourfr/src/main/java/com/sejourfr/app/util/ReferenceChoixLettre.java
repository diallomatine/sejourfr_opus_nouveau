package com.sejourfr.app.util;

import java.text.Normalizer;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Remappe les lettres A-D citées dans le texte d'une explication de question QCM
 * quand les propositions ont été <b>mélangées</b> à l'affichage.
 *
 * <p><b>Le problème.</b> Les explications sont rédigées sur l'ordre
 * {@code choices.display_order} de la base (« Seule B « … » y répond. A indique
 * une durée… ») alors que le runner mélange les propositions
 * ({@code QuestionMapper.toPublic}, graine dérivée de l'{@code AttemptQuestion}).
 * Les lettres citées désignaient donc des propositions qui ne sont plus à cette
 * place. Le mélange est voulu (sans lui la bonne réponse restait collée en A) :
 * c'est le texte qui doit suivre, pas l'inverse.
 *
 * <p><b>Autorité unique.</b> Tout point qui sert une explication à côté de
 * propositions mélangées appelle cette classe, avec <b>exactement</b> la
 * permutation appliquée aux propositions — jamais une copie de la règle.
 *
 * <h2>Doctrine : en cas de doute, on ne transforme pas</h2>
 * Une lettre laissée en place reste au pire aussi fausse qu'avant ; une lettre
 * transformée à tort casse un texte juste. Le corpus réel (2 339 explications de
 * questions mélangées) contient massivement des lettres A-D qui ne désignent
 * <b>aucune</b> proposition :
 * <ul>
 *   <li>paliers CECRL — « Piège <b>B1</b> : … » (exclus : lettre suivie d'un chiffre) ;</li>
 *   <li>le verbe « a » capitalisé dans une forme citée — « <b>« A</b> allé » est
 *       incorrect » (33 occurrences, toutes en STRUCTURE) ;</li>
 *   <li>des lieux — « <b>bâtiment B</b> », « salle A », « allée C », « escalier B »,
 *       « permis B » (24 occurrences, surtout en CE) ;</li>
 *   <li>la préposition « à » écrite sans accent — « <b>A</b> la fin de la 3e » ;</li>
 *   <li>« <b>C'</b>est », « <b>D-</b>Day », « J.-<b>C.</b> », « CMU-<b>C</b> »
 *       (exclus : apostrophe ou trait d'union adjacent).</li>
 * </ul>
 *
 * <p>D'où un classement en trois états — <i>référence</i>, <i>ignorée</i>,
 * <i>indécidable</i> — et une règle <b>tout ou rien</b> : dès qu'une occurrence
 * est indécidable, <b>le texte entier est rendu inchangé</b>. Un remappage
 * partiel serait pire que pas de remappage du tout : la même lettre y
 * désignerait deux propositions différentes selon la phrase.
 */
public final class ReferenceChoixLettre {

    private ReferenceChoixLettre() {}

    /** Lettre A-D isolée : ni lettre/chiffre, ni apostrophe, ni tiret de part et d'autre. */
    private static final Pattern LETTRE = Pattern.compile(
            "(?<![\\p{L}\\p{N}'’\\-])([A-D])(?![\\p{L}\\p{N}'’\\-])");

    /** Fin de phrase (ou de segment) : la lettre qui suit ouvre un énoncé. */
    private static final Pattern DEBUT_PHRASE = Pattern.compile(
            "[.!?:;»–—)\\]*]\\s*[«“\"'‘*\\s]*$");

    /** Séparateurs admis entre deux lettres d'une énumération : « A, B et C ». */
    private static final Pattern SEPARATEURS = Pattern.compile(
            "[\\s,;/]*(?:et|ou|ni|puis)?[\\s,;/]*", Pattern.CASE_INSENSITIVE);

    /** Caractères sautés à gauche pour retrouver le mot précédent (guillemets, gras markdown…). */
    private static final String SAUTS_GAUCHE = " \t\n\r(«“\"'‘*[-—–";

    /** Guillemets ouvrants : ce qui suit est du matériau cité, pas une désignation. */
    private static final String GUILLEMETS_OUVRANTS = "«“\"‘";

    /** Mots qui désignent explicitement une proposition. */
    private static final Set<String> DESIGNATEURS = Set.of(
            "reponse", "reponses", "choix", "proposition", "propositions",
            "option", "options", "item", "items", "distracteur", "distracteurs",
            "affirmation", "affirmations", "enonce", "enonces", "variante", "variantes",
            "seul", "seule", "seuls", "seules");

    /** Noms communs suivis d'une lettre qui n'est PAS une proposition. */
    private static final Set<String> NOMS_DE_LIEU = Set.of(
            "batiment", "batiments", "salle", "salles", "allee", "allees",
            "escalier", "escaliers", "permis", "porte", "portes", "etage", "etages",
            "aile", "hall", "couloir", "quai", "voie", "bloc", "secteur", "zone",
            "groupe", "wagon", "rangee", "categorie", "classe", "niveau", "annexe",
            "section", "formulaire", "plan", "vitamine", "serie", "box", "place",
            "immeuble", "entree", "tour", "pavillon", "residence", "parking",
            "local", "guichet", "comptoir", "atelier", "studio", "appartement",
            "chambre", "table", "siege", "cle", "case", "colonne", "ligne",
            "point", "article", "porte-cles");

    /** Conjonctions d'énumération : le rôle de la lettre se lit sur ses voisines. */
    private static final Set<String> LIAISONS = Set.of("et", "ou", "ni", "puis");

    /**
     * Verbes rencontrés juste après une lettre en tête de phrase (« A indique une
     * durée »). Liste fermée : un verbe inconnu rend la lettre indécidable, donc
     * l'explication intacte — jamais un remappage hasardeux.
     */
    private static final Set<String> VERBES = Set.of(
            "donne", "donnent", "indique", "indiquent", "exprime", "expriment",
            "designe", "designent", "precise", "precisent", "renvoie", "renvoient",
            "decrit", "decrivent", "propose", "proposent", "repond", "repondent",
            "contredit", "contredisent", "inverse", "inversent", "invente", "inventent",
            "confond", "confondent", "deforme", "deforment", "reformule", "reformulent",
            "reprend", "reprennent", "melange", "melangent", "transforme", "transforment",
            "detourne", "detournent", "exagere", "exagerent", "adopte", "adoptent",
            "introduit", "introduisent", "deplace", "deplacent", "attribue", "attribuent",
            "ignore", "ignorent", "generalise", "generalisent", "combine", "combinent",
            "respecte", "respectent", "ajoute", "ajoutent", "inclut", "incluent",
            "echoue", "echouent", "promeut", "promeuvent", "prend", "prennent",
            "contient", "contiennent", "identifie", "identifient", "semble", "semblent",
            "est", "sont", "serait", "seraient", "porte", "portent", "evoque", "evoquent",
            "suggere", "suggerent", "vise", "visent", "situe", "situent", "reste", "restent",
            "parle", "parlent", "annonce", "annoncent", "mentionne", "mentionnent",
            "ne", "n", "se", "s", "peut", "peuvent", "pourrait", "pourraient",
            "aurait", "auraient", "a", "ont");

    /**
     * Mots qui suivent le « A » préposition écrit sans accent (« A la fin de… ») :
     * la lettre n'est alors sûrement pas une proposition.
     */
    private static final Set<String> APRES_PREPOSITION = Set.of(
            "la", "le", "les", "l", "un", "une", "des", "du", "de", "d",
            "ce", "cet", "cette", "ces", "mon", "ton", "son", "notre", "votre",
            "leur", "leurs", "partir", "travers", "condition", "noter", "defaut",
            "moins", "peine", "cause", "savoir", "nouveau", "chaque", "tout",
            "toute", "quel", "quelle", "quels", "quelles", "cote", "compter",
            "terme", "force", "titre", "juste");

    /**
     * Mots-outils après lesquels la lettre reprend une proposition déjà en jeu
     * (« la préposition « à » se retrouve aussi dans D », « ce qui rend C plausible »).
     */
    private static final Set<String> AVANT_REPRISE = Set.of(
            "dans", "de", "d", "a", "avec", "entre", "sur", "pour", "vers",
            "comme", "mais", "que", "qu", "car", "donc", "or", "si",
            "rend", "rendent");

    private enum Role { REFERENCE, IGNOREE, LIAISON, INDECIDABLE }

    private static final class Occurrence {
        final int position;
        final char lettre;
        Role role;
        Occurrence(int position, char lettre, Role role) {
            this.position = position;
            this.lettre = lettre;
            this.role = role;
        }
    }

    /**
     * @param texte           l'explication rédigée sur l'ordre {@code display_order}.
     * @param positionAffichee {@code positionAffichee[r]} = index d'affichage de la
     *                         proposition de rang d'origine {@code r} (0 = A). Une
     *                         permutation identité, nulle ou vide rend le texte tel quel.
     * @return le texte dont les lettres de proposition suivent l'ordre affiché, ou
     *         le texte <b>inchangé</b> si une seule occurrence est indécidable.
     */
    public static String remappe(String texte, int[] positionAffichee) {
        if (texte == null || texte.isEmpty() || positionAffichee == null || positionAffichee.length == 0) {
            return texte;
        }
        if (estIdentite(positionAffichee)) return texte;

        List<Occurrence> occurrences = classe(texte);
        if (occurrences.isEmpty()) return texte;

        boolean auMoinsUneReference = false;
        for (Occurrence o : occurrences) {
            if (o.role == Role.INDECIDABLE || o.role == Role.LIAISON) return texte;
            if (o.role != Role.REFERENCE) continue;
            int rang = o.lettre - 'A';
            // Lettre hors du nombre de propositions : on ne sait pas ce qu'elle
            // désigne, on rend le texte intact (tout ou rien).
            if (rang >= positionAffichee.length) return texte;
            auMoinsUneReference = true;
        }
        if (!auMoinsUneReference) return texte;

        StringBuilder sb = new StringBuilder(texte);
        for (Occurrence o : occurrences) {
            if (o.role != Role.REFERENCE) continue;
            sb.setCharAt(o.position, (char) ('A' + positionAffichee[o.lettre - 'A']));
        }
        return sb.toString();
    }

    private static boolean estIdentite(int[] permutation) {
        for (int i = 0; i < permutation.length; i++) {
            if (permutation[i] != i) return false;
        }
        return true;
    }

    // ------------------------------------------------------------------------
    // Classement
    // ------------------------------------------------------------------------

    private static List<Occurrence> classe(String texte) {
        List<Occurrence> occurrences = new java.util.ArrayList<>();
        Matcher m = LETTRE.matcher(texte);
        while (m.find()) {
            occurrences.add(new Occurrence(m.start(1), texte.charAt(m.start(1)), roleIsole(texte, m.start(1))));
        }
        resoutEnumerationsEnTete(texte, occurrences);
        resoutLiaisons(texte, occurrences);
        return occurrences;
    }

    private static Role roleIsole(String texte, int position) {
        String prefixe = texte.substring(0, position);
        char precedent = dernierCaractereSignifiant(prefixe);
        if (GUILLEMETS_OUVRANTS.indexOf(precedent) >= 0) return Role.IGNOREE;

        String avant = motAvant(texte, position);
        if (DESIGNATEURS.contains(avant)) return Role.REFERENCE;
        if (NOMS_DE_LIEU.contains(avant)) return Role.IGNOREE;
        if (LIAISONS.contains(avant)) return Role.LIAISON;

        if (avant.isEmpty() || DEBUT_PHRASE.matcher(prefixe).find()) {
            String apres = motApres(texte, position + 1);
            if (VERBES.contains(apres)) return Role.REFERENCE;
            if (APRES_PREPOSITION.contains(apres)) return Role.IGNOREE;
            return Role.INDECIDABLE;
        }
        if (AVANT_REPRISE.contains(avant)) return Role.REFERENCE;
        return Role.INDECIDABLE;
    }

    /**
     * Énumération en tête de phrase ancrée par le verbe qui la suit :
     * « Piège B1 : B, C, D <b>restent</b> crédibles ». Aucune des lettres n'est
     * désignée individuellement, c'est la chaîne entière qui l'est.
     */
    private static void resoutEnumerationsEnTete(String texte, List<Occurrence> occurrences) {
        int i = 0;
        while (i < occurrences.size()) {
            int fin = i;
            while (fin + 1 < occurrences.size()
                    && separateursSeuls(texte, occurrences.get(fin), occurrences.get(fin + 1))) {
                fin++;
            }
            if (fin > i) {
                Occurrence tete = occurrences.get(i);
                boolean enTete = (tete.role == Role.INDECIDABLE || tete.role == Role.LIAISON)
                        && (tete.position == 0
                            || DEBUT_PHRASE.matcher(texte.substring(0, tete.position)).find());
                if (enTete && VERBES.contains(motApres(texte, occurrences.get(fin).position + 1))) {
                    for (int k = i; k <= fin; k++) occurrences.get(k).role = Role.REFERENCE;
                }
            }
            i = fin + 1;
        }
    }

    /**
     * Une lettre reliée à une référence par les seuls séparateurs d'énumération
     * (« Les réponses A et B », « B, C, D ») est une référence elle aussi.
     */
    private static void resoutLiaisons(String texte, List<Occurrence> occurrences) {
        boolean change = true;
        while (change) {
            change = false;
            for (int i = 0; i < occurrences.size(); i++) {
                Occurrence o = occurrences.get(i);
                if (o.role != Role.LIAISON && o.role != Role.INDECIDABLE) continue;
                if (o.role == Role.INDECIDABLE && !voisinParSeparateurs(texte, occurrences, i)) continue;
                if (voisinReference(texte, occurrences, i, -1) || voisinReference(texte, occurrences, i, 1)) {
                    o.role = Role.REFERENCE;
                    change = true;
                }
            }
        }
        for (Occurrence o : occurrences) {
            if (o.role == Role.LIAISON) o.role = Role.INDECIDABLE;
        }
    }

    private static boolean voisinParSeparateurs(String texte, List<Occurrence> occurrences, int i) {
        return voisin(texte, occurrences, i, -1) != null || voisin(texte, occurrences, i, 1) != null;
    }

    private static boolean voisinReference(String texte, List<Occurrence> occurrences, int i, int sens) {
        Occurrence v = voisin(texte, occurrences, i, sens);
        return v != null && v.role == Role.REFERENCE;
    }

    private static Occurrence voisin(String texte, List<Occurrence> occurrences, int i, int sens) {
        int k = i + sens;
        if (k < 0 || k >= occurrences.size()) return null;
        Occurrence gauche = sens < 0 ? occurrences.get(k) : occurrences.get(i);
        Occurrence droite = sens < 0 ? occurrences.get(i) : occurrences.get(k);
        return separateursSeuls(texte, gauche, droite) ? occurrences.get(k) : null;
    }

    private static boolean separateursSeuls(String texte, Occurrence gauche, Occurrence droite) {
        return SEPARATEURS.matcher(texte.substring(gauche.position + 1, droite.position)).matches();
    }

    // ------------------------------------------------------------------------
    // Lecture du voisinage
    // ------------------------------------------------------------------------

    private static char dernierCaractereSignifiant(String prefixe) {
        int i = prefixe.length();
        while (i > 0 && prefixe.charAt(i - 1) == ' ') i--;
        return i > 0 ? prefixe.charAt(i - 1) : '\0';
    }

    /** Mot alphanumérique qui précède, sauts de guillemets/parenthèses/gras compris, élision retirée. */
    private static String motAvant(String texte, int position) {
        int fin = position;
        while (fin > 0 && SAUTS_GAUCHE.indexOf(texte.charAt(fin - 1)) >= 0) fin--;
        int debut = fin;
        while (debut > 0 && estMot(texte.charAt(debut - 1))) debut--;
        String mot = texte.substring(debut, fin).toLowerCase();
        int apostrophe = Math.max(mot.lastIndexOf('\''), mot.lastIndexOf('’'));
        if (apostrophe >= 0) mot = mot.substring(apostrophe + 1);
        return sansAccent(mot);
    }

    /** Mot alphanumérique qui suit, blancs sautés. */
    private static String motApres(String texte, int position) {
        int debut = position;
        while (debut < texte.length() && Character.isWhitespace(texte.charAt(debut))) debut++;
        int fin = debut;
        while (fin < texte.length() && estMot(texte.charAt(fin))) fin++;
        String mot = texte.substring(debut, fin).toLowerCase();
        while (mot.endsWith("'") || mot.endsWith("’")) mot = mot.substring(0, mot.length() - 1);
        return sansAccent(mot);
    }

    private static boolean estMot(char c) {
        return Character.isLetterOrDigit(c) || c == '\'' || c == '’';
    }

    private static String sansAccent(String mot) {
        String sansLigature = mot.replace("œ", "oe").replace("æ", "ae");
        return Normalizer.normalize(sansLigature, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "");
    }

    /** Exposé pour les tests : la liste ordonnée des lettres considérées comme des références. */
    static List<Character> referencesDetectees(String texte) {
        return classe(texte).stream()
                .filter(o -> o.role == Role.REFERENCE)
                .map(o -> o.lettre)
                .toList();
    }

    /** Exposé pour les tests : vrai si une occurrence rend le texte indécidable. */
    static boolean abstention(String texte) {
        return classe(texte).stream().anyMatch(o -> o.role == Role.INDECIDABLE || o.role == Role.LIAISON);
    }

}
