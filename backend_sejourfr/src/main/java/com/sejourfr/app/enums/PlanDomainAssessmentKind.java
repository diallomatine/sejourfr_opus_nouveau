package com.sejourfr.app.enums;

/**
 * Par quoi un domaine du TCF encore <b>non mesure</b> se fait mesurer.
 *
 * <p>Le serveur dit <b>quoi lancer</b>, jamais quoi ecrire : « Evaluer ma
 * comprehension orale » appartient aux fronts, comme la phrase d'un jalon
 * ({@code PlanRecommendedExerciseDto}) ou celle de {@code PlanChangeDto}.
 *
 * <p>🛑 <b>Aucune de ces natures ne cree de contenu.</b> Chacune designe un
 * parcours <b>deja existant</b> — un examen blanc de module, un examen blanc de
 * production — conformement au brief §5 et §84 : ni banque de questions
 * dupliquee, ni composant QCM duplique, ni logique d'{@code Attempt} dupliquee.
 * Un domaine ne s'evalue jamais par un moteur qui lui serait propre.
 *
 * <p>🛑 <b>Mesurer un domaine, c'est passer un EXAMEN BLANC — les quatre
 * epreuves, sans exception</b> (arbitrage du proprietaire, 2026-09-16). Les
 * deux natures qui vivaient ici pour l'expression — {@code DIAGNOSTIC}
 * (l'ancien diagnostic 1 EE + 1 EO) et {@code PRODUCTION} (les 3 taches en
 * entrainement libre) — sont <b>supprimees</b> : ni l'une ni l'autre ne
 * lancait un examen blanc, donc « Evaluer mon niveau » ne voulait pas dire la
 * meme chose en CO/CE et en EE/EO. Le niveau qu'un ancien diagnostic a deja
 * produit continue de s'afficher ({@code TcfProfileService} le lit en repli) :
 * c'est l'<b>affichage</b> qui garde ce repli, pas l'<b>action</b>.
 */
public enum PlanDomainAssessmentKind {

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
     * Un <b>examen blanc de production</b> sur l'epreuve du domaine : les
     * <b>3 taches</b> d'expression enchainees, telles que les sert deja
     * {@code POST /api/attempts/production} ({@code exam=true},
     * {@code slotNumber}) — exactement le parcours du jalon du Plan
     * ({@code PlanExerciseKind.EPREUVE_MOCK_EXAM}).
     *
     * <p>{@code moduleExamQuestionType} n'a aucun sens ici (une production ne
     * se compose pas d'un type de question) et reste {@code null}.
     * {@code estimatedMinutes} suit {@code DureeEpreuve} : <b>30 min</b> a
     * l'ecrit, <b>{@code null} a l'oral</b>, qui se chronometre tache par tache
     * et n'a pas de duree d'epreuve opposable.
     */
    PRODUCTION_MOCK_EXAM
}
