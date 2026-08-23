package com.sejourfr.app.progression.domain;

/**
 * Signaux de production de contenu remontes par le moteur (V4.2 §12 bis.5).
 *
 * <p>🛑 <b>Un signal ne modifie jamais un seuil.</b> Quand la banque d'un couple
 * {@code domain + level} est trop petite pour produire une seconde serie sous le
 * seuil de recouvrement, le moteur ne s'assouplit pas : il le dit, et la
 * priorisation de contenu se decide ailleurs.
 */
public enum ContentBankSignal {
    CONTENT_BANK_TOO_SMALL
}
