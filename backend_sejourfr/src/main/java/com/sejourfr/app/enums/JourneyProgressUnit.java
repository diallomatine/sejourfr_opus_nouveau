package com.sejourfr.app.enums;

/**
 * En quoi se compte l'avancement d'une etape {@link JourneyStepType#TRAIN_SKILL}.
 *
 * <p>🛑 <b>Servi, jamais deduit par un front.</b> L'unite depend de la famille
 * de la competence — et la deduire de la nullite de {@code taskCode} reviendrait
 * a recopier dans deux fronts une regle du referentiel. Un front affiche
 * « 2 / 5 petits sujets » ou « 1 série sur 2 » parce que le serveur le lui a dit.
 *
 * <p>Motif de l'asymetrie : les competences de <b>comprehension</b> n'ont ni
 * tache ni petit sujet ({@code skills.task_code} nullable depuis V039), leur
 * entrainement est une <b>serie ciblee de 20 QCM</b>. La carte « 5 petits sujets
 * · ~2 min chacun » etait litteralement fausse pour la moitie du referentiel
 * (arbitrage D-5).
 */
public enum JourneyProgressUnit {

    /**
     * Les <b>petits sujets de l'etape</b> — expression. Le denominateur est
     * {@code LearningPlanStep.PROMPTS_PAR_ETAPE}, son unique autorite : une
     * competence qui publie moins de sujets a une etape plus courte, et on
     * n'invente jamais un denominateur.
     */
    PROMPT,

    /**
     * Les <b>series ciblees terminees</b> — comprehension. Le denominateur est
     * {@code trainSeriesQuota} de la configuration versionnee.
     */
    SERIES
}
