package com.sejourfr.app.service;

import java.util.List;

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

    private EvaluationOralForme() {
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
