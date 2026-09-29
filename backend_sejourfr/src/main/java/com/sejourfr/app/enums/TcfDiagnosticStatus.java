package com.sejourfr.app.enums;

/**
 * Etat d'ensemble d'un diagnostic TCF 4 epreuves.
 *
 * <p>Deux valeurs seulement, et c'est volontaire. Un diagnostic dont le delai
 * de reprise est ecoule reste {@code IN_PROGRESS} : le delai borne la
 * <b>reprise</b>, pas la validite — les sections realisees comptent toujours,
 * et le candidat peut demander son resultat sur ce qui existe. Un troisieme
 * etat « EXPIRE » laisserait croire a une perte.
 *
 * <p>L'etat de chaque SECTION, lui, n'est pas persiste ici : c'est celui de son
 * sous-attempt, derive a la lecture.
 */
public enum TcfDiagnosticStatus {

    /** Commence, resultat pas encore demande. */
    IN_PROGRESS,

    /** Resultat calcule et fige. */
    COMPLETED
}
