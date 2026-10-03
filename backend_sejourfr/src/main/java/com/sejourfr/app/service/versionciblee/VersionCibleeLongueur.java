package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.util.ProductionTextBounds;

/**
 * LONGUEUR DU TEXTE MODÈLE ÉCRIT : la longueur qu'on DEMANDE, et celle qu'on
 * ACCEPTE. Deux nombres distincts, à dessein (décision du propriétaire du
 * 2026-10-04).
 *
 * <h2>Ce qu'on demande : le milieu de la fourchette, arrondi à la dizaine supérieure</h2>
 * Demander « 30 à 60 mots » faisait viser le plafond : sur EE1, 3 évaluations
 * sur 7 perdaient leur texte modèle pour 61 à 64 mots, réparation comprise
 * (0 sur 5 sur EE2/EE3, à 40–90). La consigne v3 vise donc une CIBLE :
 * {@code ceil((min + max) / 2 / 10) × 10}, ramenée dans {@code [min, max]}.
 * <ul>
 *   <li>30–60 → milieu 45 → <b>50</b> (la valeur voulue par le propriétaire) ;</li>
 *   <li>40–90 → milieu 65 → <b>70</b> (20 mots sous le plafond, 30 sous la
 *       limite tolérée).</li>
 * </ul>
 * Écartées : le milieu arrondi au multiple de 5 (rend 45 sur 30–60, pas 50) et
 * {@code max - 10} (rend 80 sur 40–90, soit 10 mots du plafond : on
 * réintroduirait sur EE2/EE3 le défaut qu'on retire d'EE1).
 *
 * <h2>Ce qu'on accepte : le plafond de la tâche, plus une tolérance</h2>
 * {@code sejourfr.production-evaluation.version-ciblee.tolerance-mots-max}
 * (défaut 10) : un texte modèle de 61 à 70 mots sur 30–60 est servi. Exception
 * ASSUMÉE à « on ne montre pas un modèle que la plateforme refuserait » : un
 * modèle légèrement long vaut mieux que pas de modèle du tout, et la consigne
 * vise le milieu pour que le cas reste rare. Le PLANCHER {@code min} reste
 * strict — un modèle trop court n'a jamais été le défaut mesuré, et le
 * relâcher n'apporterait rien.
 */
final class VersionCibleeLongueur {

    private static final int PAS_D_ARRONDI = 10;

    private VersionCibleeLongueur() {
    }

    /** Nombre de mots VISÉ par la consigne v3 (cf. la formule de la classe). */
    static int cible(ProductionTextBounds bornes) {
        int somme = bornes.min() + bornes.max();
        // ceil(somme / 2 / 10) * 10, en entiers : somme / 20 arrondi au-dessus.
        int cible = ((somme + 2 * PAS_D_ARRONDI - 1) / (2 * PAS_D_ARRONDI)) * PAS_D_ARRONDI;
        return Math.max(bornes.min(), Math.min(bornes.max(), cible));
    }

    /** Nombre de mots maximal ACCEPTÉ pour un texte modèle (plafond + tolérance). */
    static int plafondTolere(ProductionTextBounds bornes, int toleranceMotsMax) {
        return bornes.max() + toleranceMotsMax;
    }

    /** Vrai si le texte modèle est servi : plancher strict, plafond toléré. */
    static boolean accepte(int mots, ProductionTextBounds bornes, int toleranceMotsMax) {
        return mots >= bornes.min() && mots <= plafondTolere(bornes, toleranceMotsMax);
    }
}
