package com.sejourfr.app.service;

import com.sejourfr.app.enums.SkillPromptStatus;

/**
 * Compteurs de progression accumules sur un ensemble de petits sujets.
 *
 * <p><b>Une seule definition de « tente / valide / a renforcer ».</b> Ces trois
 * compteurs sont servis par deux surfaces differentes — le catalogue de
 * competences ({@code SkillDto}) et le Plan ({@code LearningPlanPriorityDto} /
 * {@code LearningPlanSkillDto}) — et un candidat qui verrait « 2 sur 5 » d'un
 * cote et « 3 sur 5 » de l'autre n'aurait aucun moyen de savoir lequel ment.
 * La regle vit donc ici, pas dans chaque service.
 *
 * <p>Le statut d'entree vient toujours de {@code SkillStatusResolver} : c'est
 * lui qui decide qu'une production sans analyse est « Fait » et non « Valide ».
 */
public final class SkillProgressTally {

    private int attempted;
    private int validated;
    private int toReinforce;

    public void add(SkillPromptStatus status) {
        if (!status.isAttempted()) return;
        attempted++;
        if (status == SkillPromptStatus.VALIDATED) validated++;
        if (status == SkillPromptStatus.TO_REINFORCE) toReinforce++;
    }

    public int attempted() {
        return attempted;
    }

    public int validated() {
        return validated;
    }

    public int toReinforce() {
        return toReinforce;
    }
}
