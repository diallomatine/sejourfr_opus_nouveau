package com.sejourfr.app.enums;

/**
 * Par quoi un domaine du TCF encore <b>non mesure</b> se fait mesurer.
 *
 * <p>Le serveur dit <b>quoi lancer</b>, jamais quoi ecrire : « Evaluer ma
 * comprehension orale » appartient aux fronts, comme la phrase d'un jalon
 * ({@code PlanRecommendedExerciseDto}) ou celle de {@code PlanChangeDto}.
 *
 * <p>🛑 <b>Aucune de ces natures ne cree de contenu.</b> Chacune designe un
 * parcours <b>deja existant</b> — le diagnostic, un examen blanc de module, une
 * production EE/EO — conformement au brief §5 et §84 : ni banque de questions
 * dupliquee, ni composant QCM duplique, ni logique d'{@code Attempt} dupliquee.
 * Un domaine ne s'evalue jamais par un moteur qui lui serait propre.
 */
public enum PlanDomainAssessmentKind {

    /**
     * Le <b>diagnostic</b> ({@code POST /api/diagnostics}) : une production
     * ecrite puis une production orale.
     *
     * <p>Il mesure <b>les deux domaines d'expression a la fois</b> — c'est
     * pourquoi il peut etre designe sur {@code TCF_EE} <b>et</b> sur
     * {@code TCF_EO} dans la meme reponse. Ce n'est pas un doublon : ce sont
     * deux domaines qui pointent vers la meme porte.
     *
     * <p>Jamais designe quand le candidat a deja une session de diagnostic
     * terminee : elle est unique par {@code (user, code, version)} et ne se
     * rejoue pas. Le domaine retombe alors sur {@link #PRODUCTION}.
     */
    DIAGNOSTIC,

    /**
     * Un <b>examen blanc de module</b> QCM sur l'epreuve du domaine
     * ({@code POST /api/attempts}, {@code type=MOCK_EXAM},
     * {@code moduleExamQuestionType=CO|CE}).
     *
     * <p>C'est ce que le brief §6 et §7 demandent explicitement pour CO et CE :
     * « ouvre un examen blanc CO existant ». Sa correction est
     * <b>100 % deterministe</b> — aucune IA n'y touche (brief §105).
     */
    MODULE_MOCK_EXAM,

    /**
     * Une <b>production</b> EE ou EO du catalogue standard.
     *
     * <p>Repli du domaine d'expression dont le diagnostic est <b>deja
     * termine</b> alors que ce domaine n'a toujours pas de niveau : analyse en
     * echec, session ancienne d'une version qui ne portait qu'un cote, ou
     * production jamais rendue. On ne rejoue pas le diagnostic pour ca — on
     * demande une vraie production, qui vaut de toute facon davantage que la
     * baseline ({@code TcfProfileService} ne lit le diagnostic qu'en repli).
     */
    PRODUCTION
}
