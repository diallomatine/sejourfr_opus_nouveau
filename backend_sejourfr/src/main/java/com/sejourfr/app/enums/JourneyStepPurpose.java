package com.sejourfr.app.enums;

/**
 * Pourquoi cette etape {@link JourneyStepType#SECTION_EXAM} est proposee.
 *
 * <p>La <b>meme action</b> — un examen blanc d'epreuve — pour deux raisons
 * differentes, et le candidat doit lire laquelle : « Evaluer mon niveau » n'est
 * pas « Verifier mes progres ». Un booleen {@code reassessment} aurait dit la
 * meme chose en moins lisible, et un troisieme cas l'aurait fait exploser.
 */
public enum JourneyStepPurpose {

    /**
     * L'epreuve n'a <b>jamais</b> ete mesuree (R12). L'action a lancer est
     * decidee par {@code PlanDomainAssessmentResolver}, jamais ici.
     */
    INITIAL_ASSESSMENT,

    /**
     * Le <b>checkpoint</b> d'un lot : l'examen qui clot les priorites qu'une
     * evaluation avait designees (R3, R7).
     */
    REASSESS
}
