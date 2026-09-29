package com.sejourfr.app.enums;

/**
 * Famille d'icone d'une etiquette de contrainte, sur l'ecran de saisie d'un
 * petit sujet.
 *
 * <p><b>Pourquoi un enum et pas une chaine libre.</b> Les deux fronts mappent
 * cette valeur sur une icone de leur bibliotheque : une valeur inconnue n'y
 * afficherait rien, ou pire une icone par defaut trompeuse. La liste est donc
 * <b>fermee</b>, et le serveur refuse a l'ecriture tout ce qui n'en fait pas
 * partie plutot que de laisser une etiquette muette atteindre l'ecran.
 *
 * <p>Elle decrit une FAMILLE de contrainte, pas un dessin : c'est chaque front
 * qui choisit son icone. Ajouter une valeur ici suppose donc de la mapper des
 * deux cotes dans la meme passe.
 */
public enum SkillConstraintIcon {

    /** Registre, politesse, ton. */
    TONE,

    /** Destinataire, vouvoiement, personne. */
    PERSON,

    /** Moment, duree, temps. */
    TIME,

    /** Lieu, situation geographique. */
    PLACE,

    /** Quantite, nombre d'elements. */
    NUMBER,

    /** Temps du recit (passe compose, imparfait). */
    TENSE,

    /** Organisation, enchainement, connecteurs. */
    STRUCTURE,

    /** Exemple, illustration, precision concrete. */
    EXAMPLE
}
