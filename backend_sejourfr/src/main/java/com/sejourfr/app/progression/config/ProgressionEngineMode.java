package com.sejourfr.app.progression.config;

/**
 * Le regime d'exploitation du moteur de progression (V4.2 §47).
 *
 * <p>🛑 <b>{@link #ACTIVE} ne s'active qu'apres validation produit des metriques
 * shadow</b> — precision des predictions {@code SOLID} >= 70 % (§47.4). Ce n'est
 * pas un detail de deploiement : c'est la seule chose qui separe un moteur
 * calibre d'un moteur qui pilote le parcours de vrais candidats sur des seuils
 * encore hypothetiques.
 */
public enum ProgressionEngineMode {

    /**
     * Les preuves sont enregistrees, les etats calcules, les predictions
     * persistees — <b>et le Plan servi n'est pas modifie</b>.
     */
    SHADOW,

    /** Le Plan lit {@code prescriptionLevel} et les etats du moteur. */
    ACTIVE
}
