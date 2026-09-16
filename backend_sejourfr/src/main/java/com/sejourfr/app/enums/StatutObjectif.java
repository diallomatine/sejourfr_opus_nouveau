package com.sejourfr.app.enums;

/**
 * Ou en est une epreuve TCF <b>par rapport a l'objectif du candidat</b>
 * (spec « progression par epreuve » V2 §2, arbitree le 2026-09-16).
 *
 * <p>Le fait appartient au serveur, la <b>facon de le dire</b> appartient aux
 * fronts : cet enum ne porte aucun libelle, comme {@link NiveauEvolution}.
 * « Objectif atteint » / « Proche de l'objectif » / « A renforcer » vivent une
 * fois par front, en miroir l'un de l'autre.
 *
 * <p>🛑 <b>{@link #TO_REINFORCE} recouvre DEUX situations</b> — « mesure, et
 * loin de l'objectif » et « jamais mesure ». C'est voulu au niveau du statut
 * produit, mais le DTO sert <b>aussi</b> le niveau lui-meme, et il vaut
 * {@code null} quand rien n'a ete mesure : les ecrans doivent lire les deux et
 * ne jamais rendre une absence de mesure comme un verdict. Confondre les deux a
 * l'affichage reproduirait l'incident V040/V041/V042.
 *
 * <p>🛑 <b>La regle ne se recopie nulle part</b> : elle vit dans
 * {@code StatutObjectifResolver}, seule autorite, appelee par le serveur — un
 * front qui la rejouerait finirait par afficher autre chose que le serveur.
 */
public enum StatutObjectif {

    /** Le niveau mesure est <b>au moins</b> celui exige par la demarche. */
    TARGET_REACHED,

    /** Un seul palier separe le niveau mesure de l'objectif. */
    CLOSE_TO_TARGET,

    /**
     * Plus d'un palier d'ecart, <b>ou</b> aucune mesure. 🛑 Ce n'est pas un
     * verdict sur une epreuve jamais passee : c'est le travail qui reste.
     */
    TO_REINFORCE
}
