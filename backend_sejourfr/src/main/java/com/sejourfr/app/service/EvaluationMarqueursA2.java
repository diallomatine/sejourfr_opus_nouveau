package com.sejourfr.app.service;

import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TargetLevel;

import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * LES MOYENS QUE NOTRE GRILLE CLASSE A2, et la seule façon reconnue de dire
 * qu'un texte les DESIGNE comme un moyen d'action.
 *
 * <p>Extrait a la DEUXIEME occurrence, comme le veut le depot. Deux surfaces
 * differentes ont le meme defaut, et doivent donc le reconnaitre exactement de la
 * meme façon :
 * <ul>
 *   <li>{@link EvaluationPalierMarqueurFilter} — les champs de restitution du
 *       CORRECTEUR ({@code suggestions}, {@code points_a_ameliorer},
 *       {@code exemples_corriges[].gain}) ;</li>
 *   <li>{@code VersionCibleeLevierFilter} — les leviers
 *       {@code version_ciblee.ce_qui_manque}, produits par un SECOND appel, sous
 *       un autre contrat.</li>
 * </ul>
 * Deux detections ecrites separement, ce sont deux frontieres qui divergent au
 * premier ajustement.
 *
 * <p><b>Ce que cette classe ne fait PAS</b> : elle ne dit pas si la phrase promet
 * un palier. Cette moitie-la du jugement appartient a l'appelant, parce qu'elle
 * ne se lit pas au meme endroit selon la surface — dans la PHRASE cote
 * correcteur (« pour viser le B1... »), dans le CHAMP STRUCTURE
 * {@code niveau_vise} cote version ciblee.
 */
public final class EvaluationMarqueursA2 {

    /**
     * MARQUEURS CLASSES A2 par la grille active, forme normalisee. Liste
     * <b>FERMEE</b>, miroir de la rubrique — {@code EvaluationPalierMarqueurRubriqueTest}
     * la confronte au fichier de rubriques charge et echoue si l'un des deux
     * bouge. Meme technique que {@code ProductionValidityService.MOTS_OUTILS_ETRANGERS}.
     *
     * <p>Elle n'est pas derivee a l'execution : extraire une liste de mots d'une
     * prose de consignes par expression reguliere ferait taire le filet en silence
     * le jour ou une v14 reformulerait la phrase. Une liste figee plus un test qui
     * la confronte echoue bruyamment, ce qui est le comportement voulu.
     */
    public static final Set<String> MARQUEURS_A2 =
        Set.of("et", "mais", "alors", "aussi", "apres", "parce que");

    /**
     * Le seul marqueur de la liste qui ne puisse pas etre un mot de liaison
     * ordinaire de la phrase : lui seul est reconnu hors citation, quand un mot de
     * designation le precede de peu.
     */
    private static final Pattern MARQUEUR_DESIGNE = Pattern.compile(
        "(comme|par exemple|avec|utilis\\w*|emploi\\w*|employ\\w*|ajout\\w*|reli\\w*"
            + "|remplac\\w*|connecteur\\w*|conjonction\\w*|mot[- ]outil\\w*|introdui\\w*"
            + "|articulateur\\w*|marqueur\\w*|subordonn\\w*)"
            // La normalisation ramene l'apostrophe a un blanc : « parce qu'elle »
            // devient « parce qu elle ». Les deux formes doivent etre reconnues.
            + "[^.!?]{0,25}?\\bparce qu(?:e)?\\b");

    /**
     * Citations. Contrairement au garde-fou oral, l'apostrophe simple est ICI
     * acceptee comme delimiteur : le correcteur ecrit souvent 'parce que'. Le
     * risque de decoupe fautif par elision est neutralise par le fait qu'on exige
     * une egalite EXACTE avec un marqueur — une tranche mal decoupee
     * (« ajouter un connecteur logique qui organise ton propos, par exemple »)
     * ne vaut aucun marqueur.
     */
    private static final Pattern CITATION = Pattern.compile(
        "«\\s*([^«»]{1,300}?)\\s*»|\"\\s*([^\"]{1,300}?)\\s*\"|“\\s*([^”]{1,300}?)\\s*”"
            + "|'\\s*([^']{1,300}?)\\s*'");

    /**
     * CE QUI OUVRE UN REJET. Apres l'une de ces formules, le texte ne recommande
     * plus : il nomme ce qu'il faut ARRETER de faire. Tout ce qui suit la premiere
     * occurrence est donc ignore par la recherche de marqueurs.
     *
     * <p>Sans cette coupure, l'ancre de notre propre prompt « version ciblee » —
     * « Annoncer l'objection avant d'y repondre : "On objectera que... ; c'est
     * vrai, mais..." <b>au lieu de poser</b> "mais" seul » — serait purgee, alors
     * qu'elle dit exactement la bonne chose. C'est un faux positif produit par
     * notre propre contenu de reference.
     *
     * <p><b>Limite assumee</b>, et elle va dans le sens sûr : un levier qui
     * S'OUVRE sur un rejet (« Remplacer... ») n'est jamais purge, puisqu'il ne
     * reste rien a inspecter avant la coupure. Une promesse fausse qui passe coute
     * moins cher qu'un vrai conseil efface.
     */
    private static final Pattern REJET = Pattern.compile(
        "au lieu d|plut[oô]t qu|[àa] la place d|au[- ]del[àa] d|remplac|[ée]viter|banni[rs]"
            + "|proscri", Pattern.CASE_INSENSITIVE);

    private EvaluationMarqueursA2() {
    }

    /**
     * Vrai quand les marqueurs de {@link #MARQUEURS_A2} sont classes <b>au niveau
     * vise ou en dessous</b> — c'est-a-dire des que le candidat vise plus haut que
     * A2. Les designer comme la marche suivante n'a alors aucun sens : il les
     * emploie deja.
     *
     * <p>Extrait ici a la DEUXIEME occurrence, comme le veut le depot : le filet
     * des leviers « version au niveau vise » (productions completes) et celui des
     * leviers « pour viser X » (module Competences) posent exactement la meme
     * condition. Deux copies auraient fini par purger a deux seuils differents.
     *
     * <p>Null ou A2 : on ne purge rien — « parce que » est alors exactement le
     * moyen a conseiller, et c'est meme ce qu'ordonne une ancre de la grille.
     */
    public static boolean sousLeNiveauVise(TargetLevel vise) {
        return vise != null
            && NiveauCecrl.valueOf(vise.name()).ordinal() > NiveauCecrl.A2.ordinal();
    }

    /**
     * Vrai quand le texte DESIGNE un marqueur A2 comme un moyen d'action, sous
     * l'une des deux seules formes reconnues :
     * <ul>
     *   <li>le marqueur est <b>cite seul</b> (« parce que », 'et', "mais") ;</li>
     *   <li>un verbe ou un nom de designation (« avec », « comme »,
     *       « connecteur », « employer »...) precede de peu <b>« parce que »</b>,
     *       seul marqueur de la liste qui ne puisse pas etre un mot de liaison
     *       ordinaire de la phrase.</li>
     * </ul>
     * Ce qui suit une formule de rejet ({@link #REJET}) n'est jamais inspecte.
     */
    public static boolean designe(String texte) {
        if (texte == null || texte.isBlank()) return false;
        String recommande = avantLeRejet(texte);
        if (recommande.isBlank()) return false;
        Matcher citations = CITATION.matcher(recommande);
        while (citations.find()) {
            for (int i = 1; i <= citations.groupCount(); i++) {
                String citation = citations.group(i);
                if (citation == null) continue;
                if (MARQUEURS_A2.contains(nettoyer(citation))) return true;
            }
        }
        return MARQUEUR_DESIGNE.matcher(EvaluationTexte.normaliserPourMarqueur(recommande)).find();
    }

    /**
     * Vrai quand le texte EST un marqueur A2, sans guillemets ni verbe de
     * designation autour.
     *
     * <p>Complement de {@link #designe(String)} pour les champs qui sont
     * eux-memes des ETIQUETTES de trois mots — l'{@code apport} d'un passage
     * surligne. Dans une phrase, « et » est un mot de liaison ordinaire et ne
     * prouve rien ; dans une etiquette qui dit ce qu'un passage APPORTE, « et »
     * ou « parce que » ne peut etre qu'une chose : le moyen qu'on vend comme la
     * marche suivante. La forme citee reste couverte par {@code designe}, qui
     * lit les guillemets.
     */
    public static boolean estUnMarqueur(String etiquette) {
        if (etiquette == null || etiquette.isBlank()) return false;
        return MARQUEURS_A2.contains(nettoyer(etiquette));
    }

    /** Tranche du texte qui precede la premiere formule de rejet, sinon tout le texte. */
    private static String avantLeRejet(String texte) {
        Matcher rejet = REJET.matcher(texte);
        return rejet.find() ? texte.substring(0, rejet.start()) : texte;
    }

    /** Contenu d'une citation ramene a sa forme comparable a un marqueur. */
    private static String nettoyer(String citation) {
        String normalise = EvaluationTexte.normaliserPourMarqueur(citation).strip();
        while (!normalise.isEmpty()
            && ",.;:!?".indexOf(normalise.charAt(normalise.length() - 1)) >= 0) {
            normalise = normalise.substring(0, normalise.length() - 1).strip();
        }
        // « parce qu' » : l'apostrophe a deja ete ramenee a un blanc par la
        // normalisation, le « qu » esseule doit retrouver sa forme de reference.
        return normalise.endsWith(" qu") ? normalise + "e" : normalise;
    }
}
