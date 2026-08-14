package com.sejourfr.app.service;

import com.sejourfr.app.enums.EpreuveType;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * LA REGLE ORALE « une faute est une STRUCTURE, jamais la forme d'un mot »,
 * ecrite une seule fois.
 *
 * <p>Elle vivait dans {@code EvaluationOralArtifactFilter} (volet FORME), ou
 * elle repond a la question : <i>ce reproche porte-t-il sur une construction de
 * phrase, ou sur la forme d'un mot que la reconnaissance vocale a pu
 * fabriquer ?</i> Le second appel « version au niveau visee » pose exactement la
 * meme question sur ses reformulations orales — <b>deuxieme occurrence, donc
 * extraction</b>, plutot que deux seuils qui divergeront au premier ajustement.
 *
 * <p><b>TROISIEME occurrence, le 2026-08-14 : le volet ORAL du DIAGNOSTIC.</b>
 * Le diagnostic bifurque tres tot ({@code production_submissions.is_diagnostic})
 * et ne traverse aucun des filets de {@code AiEvaluationService} — il rendait
 * donc au candidat des reproches batis sur un artefact de transcription
 * (verbatim reel : « « horreurs » pour « horaires » est une erreur lexicale »,
 * alors que le candidat avait dit « horaires »). La decision « cette phrase
 * n'accuse qu'une forme de mot » est donc extraite ici en entier —
 * {@link #reprocheAncreSurUneForme(String, String, boolean)} — au lieu d'etre
 * recopiee dans le paquet diagnostic : {@code EvaluationProofMatcher} et
 * {@code EvaluationOralArtifactFilter} ne sont pas visibles hors de ce paquet,
 * et deux copies auraient diverge au premier ajustement de la liste de
 * marqueurs.
 *
 * <h2>Le fondement, mesure</h2>
 * Sur les 142 evaluations de la base, les passages cites dans un reproche,
 * presents verbatim dans la production mais absents d'un dictionnaire de 475 000
 * formes, touchent <b>9 evaluations EO sur 75 (12,0 %) et 0 EE sur 67</b>. Zero
 * a l'ecrit : la cause est la machine, pas le niveau du candidat.
 *
 * <h2>La regle</h2>
 * Un passage de <b>un ou deux</b> mots pleins ne decrit pas une structure : il
 * nomme une FORME (« abit a Lille », « zerer »). Un passage d'au moins
 * {@link #MOTS_PORTEURS_STRUCTURE_MIN} mots pleins en decrit une. Et un passage
 * fait UNIQUEMENT de mots-outils — donc zero mot plein — est une structure pure
 * (« pour ne pas que », « est-ce que ») : lui aussi est conserve.
 *
 * <p>Le comptage est celui du controle de preuve
 * ({@link EvaluationProofMatcher#significantTokens(String)}) : deux tokenisations
 * differentes liraient le meme passage de deux facons.
 */
public final class EvaluationOralForme {

    /**
     * Nombre de mots PORTEURS DE SENS a partir duquel un passage decrit une
     * STRUCTURE. En dessous — un ou deux — il ne nomme qu'une forme.
     */
    public static final int MOTS_PORTEURS_STRUCTURE_MIN = 3;

    /**
     * Guillemets francais et guillemets doubles droits/typographiques. L'apostrophe
     * simple est volontairement EXCLUE : en francais elle marque l'elision
     * ({@code l'ile}), la traiter comme un guillemet decouperait n'importe quelle
     * phrase.
     *
     * <p>Deplacee ici depuis {@code EvaluationOralArtifactFilter} : trois
     * surfaces lisent desormais les citations d'une phrase de restitution, elles
     * doivent les lire de la meme facon.
     */
    private static final Pattern CITATION = Pattern.compile(
        "«\\s*([^«»]{1,300}?)\\s*»|\"([^\"]{1,300}?)\"|“([^”]{1,300}?)”");

    /**
     * MARQUEURS DE REPROCHE. Citer un mot de la transcription ne suffit pas a
     * declencher une purge : encore faut-il que la phrase REPROCHE quelque chose
     * a ce mot. Sans cette condition, on supprimerait aussi les CONSEILS qui
     * citent un mot present dans la production (« relie tes idees avec
     * "parce que" »), c'est-a-dire exactement ce qu'on veut garder.
     *
     * <p>Liste fermee et volontairement etroite : elle ne peut que REDUIRE le
     * nombre de purges. Une formulation de reproche qui y echappe laisse passer
     * l'artefact. On prefere ce sens d'erreur a l'inverse, qui effacerait de
     * vrais conseils.
     */
    private static final Pattern REPROCHE = Pattern.compile(
        "\\b(incorrect|impropre|inappropri|inexact|fautif|fautive|faute|erreur"
            + "|agrammatical|barbarisme|calque|confusion|confond|remplac|corrig|evit"
            + "|mal (employ|chois|utilis|form|dit|plac|construit|adapt|orthographi)"
            + "|n (existe|est|a) pas|ne (se )?dit pas|ne veut rien dire"
            + "|au lieu de|a la place de"
            + "|pauvre|approximat|imprecis|passe[- ]partout|vague"
            + "|manque|absent|oubli|jamais donne|devrait|il faudrait|aurait du)");

    private EvaluationOralForme() {
    }

    /**
     * LA REGLE COMPLETE, partagee : vrai quand la phrase reunit les trois
     * conditions qui font d'un reproche un reproche de FORME.
     *
     * <ol>
     *   <li>elle REPROCHE quelque chose ({@link #estUnReproche(String)}) — un
     *       conseil qui cite un mot n'est jamais touche ;</li>
     *   <li>elle cite au moins un passage REEL de la transcription, retrouve
     *       dans un tour {@code Candidat :} — un propos general, meme maladroit,
     *       n'est jamais touche ;</li>
     *   <li>au moins un des passages cites nomme <b>une ou deux</b> formes
     *       pleines, donc ne decrit pas une structure. <b>Zero mot porteur</b>
     *       (« pour ne pas que », « est-ce que ») est une structure pure et reste
     *       conservee ; <b>trois ou plus</b> aussi.</li>
     * </ol>
     *
     * <p>Sur une transcription <b>degradee</b> ({@link TranscriptionQualityAudit}),
     * la troisieme condition tombe : le texte lu n'est pas celui qui a ete dit,
     * aucun reproche ancre n'y est opposable.
     *
     * @param production transcription servie au correcteur (tours recolles),
     *                   telle que la rend {@code TranscriptionManager}
     */
    public static boolean reprocheAncreSurUneForme(
        String phrase, String production, boolean degradee) {
        if (phrase == null || phrase.isBlank() || production == null || production.isBlank()) {
            return false;
        }
        if (!estUnReproche(phrase)) return false;
        boolean formeIsolee = false;
        boolean ancree = false;
        for (String citation : citations(phrase)) {
            if (EvaluationProofMatcher
                .canonicalPassage(production, citation, EpreuveType.TCF_EO).isEmpty()) {
                continue; // pas un passage de la transcription : on n'y touche pas
            }
            ancree = true;
            if (nommeUneFormeIsolee(citation)) formeIsolee = true;
        }
        return ancree && (degradee || formeIsolee);
    }

    /** Vrai quand la phrase REPROCHE quelque chose, au sens de {@link #REPROCHE}. */
    static boolean estUnReproche(String phrase) {
        return phrase != null && !phrase.isBlank()
            && REPROCHE.matcher(EvaluationTexte.normaliserPourMarqueur(phrase)).find();
    }

    /** Passages cites par la phrase, dans l'ordre, guillemets retires. */
    static List<String> citations(String phrase) {
        List<String> out = new ArrayList<>();
        if (phrase == null || phrase.isBlank()) return out;
        Matcher matcher = CITATION.matcher(phrase);
        while (matcher.find()) {
            for (int i = 1; i <= matcher.groupCount(); i++) {
                String groupe = matcher.group(i);
                if (groupe == null) continue;
                if (!groupe.isBlank()) out.add(groupe);
                break;
            }
        }
        return out;
    }

    /**
     * Vrai quand un nombre de mots pleins caracterise une FORME isolee : au moins
     * un (sinon c'est une structure pure), et strictement moins de
     * {@link #MOTS_PORTEURS_STRUCTURE_MIN}.
     */
    public static boolean estFormeIsolee(int motsPorteurs) {
        return motsPorteurs >= 1 && motsPorteurs < MOTS_PORTEURS_STRUCTURE_MIN;
    }

    /** Vrai quand le passage cite ne nomme qu'une ou deux formes pleines. */
    public static boolean nommeUneFormeIsolee(String passage) {
        return estFormeIsolee(EvaluationProofMatcher.significantTokenCount(passage));
    }

    /**
     * Nombre de mots PLEINS REMPLACES SUR PLACE entre deux formulations d'un meme
     * enonce — c'est-a-dire changes sans que rien d'autre bouge.
     *
     * <p><b>L'alignement POSITIONNEL est le coeur de la mesure</b>, pas un
     * detail d'implementation. Une reformulation qui change la STRUCTURE deplace
     * les mots : elle subordonne, elle reordonne, elle ajoute un connecteur, elle
     * construit une question — et alors la suite des mots pleins n'a plus ni la
     * meme longueur ni le meme ordre. Une reformulation qui ne repare qu'une
     * FORME, au contraire, laisse la phrase exactement en place et n'echange
     * qu'un mot a sa position (« abit » → « habite »).
     *
     * <p>Comparer des ENSEMBLES de mots ne separerait pas les deux : passer de
     * « ... parce que je viens d'arriver » a « Puisque je viens d'arriver, ... »
     * n'echange qu'un connecteur dans l'ensemble, alors que c'est precisement le
     * genre de montee de niveau qu'on veut conserver.
     *
     * <p>Retourne {@code 0} — donc « rien a redire » — des que les deux suites
     * n'ont pas la meme longueur : la phrase a ete refaite, ce n'est plus une
     * reparation de mot. En cas de doute, on ne purge pas.
     */
    public static int motsPorteursRemplacesEnPlace(String avant, String apres) {
        List<String> depart = EvaluationProofMatcher.significantTokens(avant);
        List<String> arrivee = EvaluationProofMatcher.significantTokens(apres);
        if (depart.isEmpty() || depart.size() != arrivee.size()) return 0;
        int remplaces = 0;
        for (int i = 0; i < depart.size(); i++) {
            if (!depart.get(i).equals(arrivee.get(i))) remplaces++;
        }
        return remplaces;
    }
}
