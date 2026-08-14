package com.sejourfr.app.enums;

/**
 * Nature de l'action proposee par le Plan.
 *
 * <p><b>Meme carte, meme emplacement, action differente.</b> Une etape ne se
 * dedouble jamais : quand la competence a assez ete travaillee en cible
 * ({@code LearningPlanPriorityDto.readyForReassessment}), la carte « A faire
 * maintenant » cesse de proposer un micro-sujet et propose une verification en
 * situation. Les deux ne menent pas au meme ecran, d'ou cet enum : le front lit
 * la nature, il ne la devine pas d'un {@code null}.
 *
 * <h2>Une echelle a trois barreaux, on escalade au lieu de reporter</h2>
 * <ol>
 *   <li>{@link #MICRO_TRAINING} &rarr; {@link #REASSESSMENT} : ce qui fait
 *       passer <b>une competence</b> a « solide » — {@code SOLID} exige une
 *       preuve contextualisee, et c'est la verification qui l'apporte ;</li>
 *   <li>{@link #EPREUVE_MOCK_EXAM} : une <b>epreuve</b> (EE ou EO) dont les
 *       competences travaillees ont majoritairement transfere se verifie en
 *       conditions d'examen, 3 taches d'affilee ;</li>
 *   <li>{@link #FULL_TCF_MOCK_EXAM} : les deux epreuves ayant franchi leur
 *       jalon, il reste a les tenir <b>ensemble</b>, dans les 90 minutes du
 *       TCF complet.</li>
 * </ol>
 * L'echelle est deja tarifee par le moteur de maitrise (poids
 * micro-entrainement {@code 0.45} &lt; diagnostic {@code 0.80} &lt; production
 * {@code 1.00} &lt; examen blanc {@code 1.20}) : chaque barreau vaut plus que le
 * precedent parce qu'il est moins assiste.
 *
 * <p>Les deux derniers rangs ne pointent <b>aucun contenu nouveau</b> : ils
 * designent un examen blanc <b>deja existant</b> par son epreuve et son slot de
 * grille. Aucune generation, aucune banque, aucun appel LLM, aucune route de
 * plus.
 */
public enum PlanExerciseKind {

    /** Un petit sujet du module Competences ({@code skillPromptId}). */
    MICRO_TRAINING,

    /**
     * Une vraie tache TCF a produire ({@code productionTaskId}), pour verifier
     * que le moyen travaille en cible se retrouve <b>en situation</b>. Ce n'est
     * jamais le diagnostic initial, qui n'est jamais rejoue.
     */
    REASSESSMENT,

    /**
     * Un examen blanc d'<b>epreuve</b> : 3 taches d'expression ecrite ou orale
     * en conditions d'examen ({@code epreuve} + {@code slotNumber}, demarre par
     * {@code POST /api/attempts/production} avec {@code exam=true}).
     */
    EPREUVE_MOCK_EXAM,

    /**
     * L'examen blanc <b>TCF complet</b> : CO + CE + EE + EO enchainees
     * ({@code epreuve = TCF_COMPLET} + {@code slotNumber}, demarre par
     * {@code POST /api/full-tcf-exams}).
     */
    FULL_TCF_MOCK_EXAM
}
