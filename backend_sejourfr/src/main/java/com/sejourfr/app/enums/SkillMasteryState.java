package com.sejourfr.app.enums;

/**
 * Ou en est un candidat sur UNE micro-competence, tout son historique confondu.
 *
 * <p><b>A ne pas confondre avec {@link LearningPlanSkillStatus}</b>, qui est le
 * verdict d'<b>une production</b> (« dans cette copie-la, la competence etait
 * fragile ») et qui est persiste sur chaque ligne de
 * {@code learning_plan_observations}. Cet enum-ci est l'etat <b>agrege</b> :
 * derive a la lecture par {@code SkillMasteryEngine}, <b>jamais persiste</b>,
 * jamais recalcule par un front — meme philosophie que {@code SkillPromptStatus}
 * et {@code SituationDansNiveau}. C'est ce qui permet de recalibrer une
 * ponderation et de voir tout l'historique se relire immediatement, sans
 * migration ni job de rattrapage.
 *
 * <p><b>Pourquoi {@link #CONSOLIDATING} existe.</b> Un candidat qui reussit
 * plusieurs micro-exercices cibles sur une competence a demontre qu'il
 * <b>comprend</b> le moyen ; il n'a pas encore demontre qu'il le mobilise
 * spontanement dans une vraie tache TCF, ou il doit gerer en meme temps la
 * consigne, la longueur, le lexique et le temps. Sans cet etat, le moteur
 * n'aurait que « a renforcer » (injuste, il a progresse) ou « solide » (faux, la
 * preuve de transfert manque) — et la reevaluation en situation deviendrait
 * incomprehensible pour lui.
 *
 * <p>Une competence <b>sans aucune observation</b> n'a pas d'etat : les DTO
 * portent {@code null}. On n'invente pas un « a evaluer » qui laisserait croire
 * que le serveur a regarde.
 */
public enum SkillMasteryState {

    /** Fragilite mesuree : c'est ce qui freine le candidat maintenant. */
    PRIORITY("Priorité"),

    /** Le moyen est en place par intermittence ; il n'est pas encore fiable. */
    TO_REINFORCE("À renforcer"),

    /**
     * Reussi en entrainement cible, <b>pas encore prouve en situation</b>. C'est
     * l'etat qui rend la verification en situation comprehensible.
     */
    CONSOLIDATING("En consolidation"),

    /**
     * Maitrise confirmee dans une production contextualisee. Ne se perd jamais
     * sur une seule production moins bonne (cf. {@code SkillMasteryEngine}).
     */
    SOLID("Solide");

    private final String label;

    SkillMasteryState(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}
