package com.sejourfr.app.enums;

/**
 * Nature d'une etape du <b>chemin vers l'objectif</b> affiche par le Plan.
 *
 * <p><b>Le serveur expose des faits, la phrase appartient aux fronts</b> — meme
 * regle que {@code PlanChangeDto} et que les jalons de
 * {@code PlanRecommendedExerciseDto} : une etape dit sa nature et, quand elle en
 * a un, le palier concerne ({@code PlanPathStepDto.level}). « Construire votre
 * B1 » est une formulation, pas une donnee.
 */
public enum PlanPathStepKind {

    /** Mesurer les quatre domaines. Toujours la premiere etape du chemin. */
    COMPLETE_PROFILE,

    /** Construire un palier CECRL ; le palier vit sur {@code level}. */
    BUILD_LEVEL,

    /** Objectif atteint : tenir le niveau en conditions d'examen. Toujours la derniere. */
    STABILIZE
}
