package com.sejourfr.app.service;

import com.sejourfr.app.enums.PlanSkillStepState;

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
 * tout vient de {@link SkillMasteryEngine.SkillMastery} — « le transfert est-il
 * prouve ? » ({@code transferProven}) et « la verification a-t-elle ete
 * rendue ? » ({@code verificationSubmitted}) — et la progression d'etape de
 * {@link SkillProgressCounter}.
 *
 * <h2>🛑 « Acquis » se lit sur transferProven, PAS sur SOLID</h2>
 * C'est la <b>meme</b> autorite que celle qui range une etape dans
 * {@code completedSteps} ({@code LearningPlanPriorityResolver.franchies} lit
 * {@code transferProven}). Elle a vecu en deux exemplaires : une compétence dont
 * le transfert etait prouve sans atteindre {@code SOLID} — le parcours
 * <b>normal</b>, 5 petits sujets puis une verification reussie, qui plafonne
 * autour de 0,68 et n'atteint donc jamais le score {@code SOLID} — s'affichait
 * <b>cochee</b> dans « Deja travaille et valide » et <b>cercle vide</b> dans
 * « Votre parcours », pour la meme competence, sur le meme ecran.
 * {@code SOLID} implique {@code transferProven} : l'un des deux etats disait
 * donc simplement moins que l'autre.
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
     * @param mastery  ce que le moteur conclut sur la competence, ou
     *                 {@code null} / {@link SkillMasteryEngine.SkillMastery#NONE}
     *                 sans observation exploitable
     * @param step     la progression sur les sujets de l'etape
     * @param courante cette competence est celle que le Plan met en tete
     */
    public static PlanSkillStepState resolve(
            SkillMasteryEngine.SkillMastery mastery,
            LearningPlanStep.Progress step,
            boolean courante) {
        SkillMasteryEngine.SkillMastery etat =
                mastery == null ? SkillMasteryEngine.SkillMastery.NONE : mastery;
        // ACQUIS se lit sur la MEME autorite que `completedSteps` : le transfert
        // prouve. Une serie finie n'est pas un acquis — cinq petits sujets ne
        // prouvent rien en situation —, mais une verification REUSSIE, si, meme
        // quand le score agrege n'atteint pas SOLID.
        if (etat.transferProven()) return PlanSkillStepState.ACQUIS;
        LearningPlanStep.Progress progress =
                step == null ? LearningPlanStep.Progress.EMPTY : step;
        if (progress.completed()) {
            return etat.verificationSubmitted()
                    ? PlanSkillStepState.SERIE_TERMINEE : PlanSkillStepState.A_VERIFIER;
        }
        // « Maintenant » passe devant « En cours » : c'est le reperage de la
        // carte en tete, et il doit rester visible meme a 2/5.
        if (courante) return PlanSkillStepState.MAINTENANT;
        return progress.attemptedCount() > 0
                ? PlanSkillStepState.EN_COURS : PlanSkillStepState.A_VENIR;
    }
}
