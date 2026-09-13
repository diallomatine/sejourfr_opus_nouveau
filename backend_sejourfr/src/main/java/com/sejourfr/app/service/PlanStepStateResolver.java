package com.sejourfr.app.service;

import com.sejourfr.app.enums.PlanSkillStepState;
import com.sejourfr.app.enums.SkillMasteryState;

/**
 * <b>Ou en est l'etape d'une competence</b>, ecrit <b>une seule fois</b>.
 *
 * <p>Deux surfaces posaient la question et se repondaient differemment : la
 * carte « A faire maintenant » ({@code LearningPlanPriorityDto.stepState}) et
 * la ligne de « Votre parcours » ({@code PlanDomainSkillDto.stepState}). Avant,
 * aucune des deux ne la posait au serveur — chaque front la derivait, le web sur
 * {@code masteryState == SOLID}, le mobile sur {@code completedSteps} <b>ou</b>
 * {@code SOLID}, et le meme candidat voyait deux parcours differents selon
 * l'appareil.
 *
 * <p><b>Derive a la lecture, jamais persiste</b>, comme tout ce qui l'alimente :
 * l'etat agrege vient de {@link SkillMasteryEngine}, la progression d'etape de
 * {@link SkillProgressCounter}, et « la verification a-t-elle ete rendue ? » de
 * {@code SkillMastery.verificationSubmitted()} — la seule autorite sur ce fait.
 *
 * <p>🛑 <b>Aucune regle n'est recopiee ici</b> : cette classe ne fait
 * qu'<b>ordonner</b> des faits deja etablis ailleurs.
 */
public final class PlanStepStateResolver {

    private PlanStepStateResolver() {
    }

    /**
     * L'etat d'etape, dans l'ordre de lecture de {@link PlanSkillStepState}.
     *
     * @param masteryState          l'etat agrege, {@code null} sans observation
     * @param step                  la progression sur les sujets de l'etape
     * @param verificationSubmitted une production contextualisee est venue apres
     *                              les petits sujets ({@code SkillMasteryEngine})
     * @param courante              cette competence est celle que le Plan met en
     *                              tete
     */
    public static PlanSkillStepState resolve(
            SkillMasteryState masteryState,
            LearningPlanStep.Progress step,
            boolean verificationSubmitted,
            boolean courante) {
        // ACQUIS ne se lit QUE sur SOLID. Une serie finie n'est pas un acquis :
        // cinq petits sujets ne prouvent rien en situation.
        if (masteryState == SkillMasteryState.SOLID) return PlanSkillStepState.ACQUIS;
        LearningPlanStep.Progress progress =
                step == null ? LearningPlanStep.Progress.EMPTY : step;
        if (progress.completed()) {
            return verificationSubmitted
                    ? PlanSkillStepState.SERIE_TERMINEE : PlanSkillStepState.A_VERIFIER;
        }
        // « Maintenant » passe devant « En cours » : c'est le reperage de la
        // carte en tete, et il doit rester visible meme a 2/5.
        if (courante) return PlanSkillStepState.MAINTENANT;
        return progress.attemptedCount() > 0
                ? PlanSkillStepState.EN_COURS : PlanSkillStepState.A_VENIR;
    }
}
