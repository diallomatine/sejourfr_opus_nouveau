package com.sejourfr.app.enums;

/**
 * Nature de l'action proposee par une etape du Plan.
 *
 * <p><b>Meme carte, meme emplacement, action differente.</b> Une etape ne se
 * dedouble jamais : quand la competence a assez ete travaillee en cible
 * ({@code LearningPlanPriorityDto.readyForReassessment}), la carte « A faire
 * maintenant » cesse de proposer un micro-sujet et propose une verification en
 * situation. Les deux ne menent pas au meme ecran, d'ou cet enum : le front lit
 * la nature, il ne la devine pas d'un {@code null}.
 */
public enum PlanExerciseKind {

    /** Un petit sujet du module Competences ({@code skillPromptId}). */
    MICRO_TRAINING,

    /**
     * Une vraie tache TCF a produire ({@code productionTaskId}), pour verifier
     * que le moyen travaille en cible se retrouve <b>en situation</b>. Ce n'est
     * jamais le diagnostic initial, qui n'est jamais rejoue.
     */
    REASSESSMENT
}
