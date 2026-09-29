package com.sejourfr.app.progression.domain;

/**
 * A quel point le contenu de cette preuve etait neuf pour le candidat
 * (V4.2 §12, §12 bis).
 *
 * <p>🛑 <b>Toujours calcule serveur au moment de creer la preuve, jamais fourni
 * par le client</b> (invariant I38). C'est la fermeture de la derniere faille
 * du {@code qualificationGate} : sans elle, sur une banque de questions de
 * taille MVP, un candidat qui relance des series jusqu'a retomber sur ce qu'il
 * connait deja satisfait le Cas B de §16 sans avoir rien appris.
 */
public enum IndependenceClass {

    /** Recouvrement d'items sous le seuil : facteur 1.00. */
    NEW_CONTENT,

    /** Recouvrement >= 0.50 avec une serie recente : facteur 0.90. */
    NEW_CONTENT_SAME_BLUEPRINT,

    /** Meme {@code contentId} qu'une serie deja passee : facteur 0.50. */
    REPEATED_EXACT_CONTENT
}
