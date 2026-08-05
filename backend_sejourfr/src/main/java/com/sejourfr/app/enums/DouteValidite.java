package com.sejourfr.app.enums;

/**
 * Nature du doute porte par un avertissement des controles DETERMINISTES
 * (cf. {@code ProductionValidityService}). Deux avertissements de meme severite
 * ne disent pas la meme chose, et un seul des deux justifie de plafonner la
 * confiance de l'evaluation :
 *
 * <ul>
 *   <li>{@code OBSERVATION} : un obstacle REEL a l'observation de la langue.
 *       On ne voit pas bien ce que le candidat produit (langue partiellement
 *       non francaise, par exemple), donc la correction elle-meme est moins
 *       sure. C'est le seul cas ou le serveur <b>plafonne la confiance</b>.</li>
 *   <li>{@code AUTHENTICITE} : un doute sur l'ORIGINE des mots, pas sur leur
 *       lisibilite. Typiquement une consigne partiellement recopiee : ce qui
 *       reste est parfaitement observable, on le dit au candidat et seuls ses
 *       propres mots sont pris en compte. Un soupcon d'authenticite ne se
 *       convertit <b>jamais</b> en incertitude de correction — c'est
 *       exactement la confusion que les rubriques v8 interdisent au
 *       correcteur, le serveur ne peut pas la commettre non plus.</li>
 * </ul>
 */
public enum DouteValidite {
    OBSERVATION,
    AUTHENTICITE
}
