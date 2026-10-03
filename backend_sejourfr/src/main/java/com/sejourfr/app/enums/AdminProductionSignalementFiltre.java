package com.sejourfr.app.enums;

/**
 * Filtre « Signalement » de la liste admin des productions. Trois états
 * disjoints ; l'absence de filtre = toutes.
 * <ul>
 *   <li>{@code SIGNALEES} : un signalement actif, pas encore vérifié ;</li>
 *   <li>{@code VERIFIEES} : un signalement actif marqué vérifié ;</li>
 *   <li>{@code NON_SIGNALEES} : aucun signalement actif (un signalement
 *       retiré ne compte plus).</li>
 * </ul>
 */
public enum AdminProductionSignalementFiltre {
    SIGNALEES,
    VERIFIEES,
    NON_SIGNALEES
}
