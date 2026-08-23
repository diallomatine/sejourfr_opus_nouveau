package com.sejourfr.app.progression.domain;

/**
 * <b>D'ou le candidat a demarre l'activite</b> — trace produit, jamais un
 * facteur de calcul (V4.2 §5, invariant I1).
 *
 * <p>Une activite lancee depuis « Reviser » vaut exactement autant que la meme
 * activite lancee depuis le Plan (T24). Ce champ sert a l'observabilite (§46)
 * et a rien d'autre.
 */
public enum EvidenceEntryPoint {
    PLAN,
    REVISER,
    DIAGNOSTIC,
    EXAM_HUB,
    COMPETENCES,
    DEEP_LINK,
    UNKNOWN
}
