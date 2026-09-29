package com.sejourfr.app.util;

/**
 * PLAFONDS DE LONGUEUR EN MOTS, et la tolerance qu'on leur accorde.
 *
 * <p>Ces plafonds sont des consignes PEDAGOGIQUES (« trois mots », « une phrase
 * courte »), declarees par les grilles, pas des contrats machine. Perdre un bloc
 * deja paye parce qu'une etiquette fait quatre mots au lieu de trois serait
 * absurde ; a huit mots, en revanche, ce n'est plus une etiquette.
 *
 * <p><b>Pourquoi cette classe existe.</b> La tolerance vivait recopiee dans trois
 * validateurs sous la forme {@code (int) Math.floor(plafond * 1,2)}, et cette
 * formule est FICTIVE sur les petits plafonds : sur 3 elle rend 3, c'est-a-dire
 * <b>aucune marge</b>. Or les plafonds les plus serres du depot valent justement 3
 * mots ({@code apport}, {@code strength_tag}, {@code focus_tag}) : la tolerance
 * ecrite pour absorber un mot de trop ne s'appliquait nulle part la ou elle etait
 * necessaire. Mesure d'appui : sur les 12 {@code leviers[].action} en base, 4
 * depassent leur plafond de 6 mots — le modele frole ces limites en permanence.
 *
 * <p>La regle est donc « au moins UN mot de marge, et 20 % au-dela » :
 * {@code max(plafond + 1, floor(plafond * 1,2))}. Elle ne change rien aux grands
 * plafonds (a partir de 5, les 20 % dominent deja) et rend la tolerance reelle sur
 * les petits.
 *
 * <p><b>Ce n'est pas un relachement de contrainte dure</b> : les bornes de
 * longueur d'un TEXTE MODELE ({@link ProductionTextBounds}) restent appliquees au
 * mot pres, parce qu'un texte hors bornes serait irrecevable a la soumission. Ici
 * on parle d'etiquettes de restitution, que rien ne resoumet.
 */
public final class PlafondMots {

    /** Marge relative historique, conservee telle quelle sur les grands plafonds. */
    public static final double TOLERANCE = 1.2;

    private PlafondMots() {
    }

    /**
     * Nombre de mots reellement TOLERE pour un plafond declare.
     *
     * @param plafond plafond pedagogique declare par la grille, en mots
     * @return le plafond effectif applique avant rejet, toujours {@code > plafond}
     */
    public static int tolere(int plafond) {
        return Math.max(plafond + 1, (int) Math.floor(plafond * TOLERANCE));
    }

    /** Vrai quand le texte depasse le plafond, tolerance comprise. */
    public static boolean depasse(String texte, int plafond) {
        return compter(texte) > tolere(plafond);
    }

    /**
     * Comptage des mots des ETIQUETTES : separation par blancs, comme partout
     * ailleurs dans les validateurs. Le comptage d'une PRODUCTION, lui, vit dans
     * {@code ProductionPayloadSupport.countWords} — c'est celui de la soumission,
     * et les deux ne doivent pas etre confondus.
     */
    public static int compter(String texte) {
        if (texte == null) return 0;
        String normalise = texte.trim();
        if (normalise.isEmpty()) return 0;
        return normalise.split("\\s+").length;
    }
}
