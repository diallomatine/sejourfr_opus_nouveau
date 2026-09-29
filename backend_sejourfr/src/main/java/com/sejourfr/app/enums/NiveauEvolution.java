package com.sejourfr.app.enums;

/**
 * Le sens d'une comparaison de paliers entre deux diagnostics (30_ §7, « ↑
 * depuis A2 », « = »).
 *
 * <p>🛑 <b>{@link #INCONNUE} n'est pas {@link #STABLE}.</b> Une epreuve non
 * evaluee d'un cote ou de l'autre n'a pas progresse, n'a pas regresse, et n'est
 * pas stable : elle n'est pas comparable. Les confondre reproduirait l'incident
 * V040/V041/V042 en le deguisant en bonne nouvelle — un candidat qui n'avait
 * pas passe l'EO au premier diagnostic verrait « = », comme si son niveau avait
 * ete tenu.
 *
 * <p>🛑 <b>{@link #BAISSE} existe et se sert.</b> Masquer une baisse rendrait
 * la mesure de progression invendable : c'est precisement ce qu'une
 * reevaluation payante promet de mesurer. La <b>facon de le dire</b> appartient
 * aux fronts, le fait appartient au serveur.
 */
public enum NiveauEvolution {

    /** Le palier mesure est superieur a celui du diagnostic precedent. */
    HAUSSE,

    /** Meme palier des deux cotes. Les deux sont mesures. */
    STABLE,

    /** Le palier mesure est inferieur a celui du diagnostic precedent. */
    BAISSE,

    /** Au moins un des deux cotes n'a pas ete evalue. Aucun verdict. */
    INCONNUE
}
