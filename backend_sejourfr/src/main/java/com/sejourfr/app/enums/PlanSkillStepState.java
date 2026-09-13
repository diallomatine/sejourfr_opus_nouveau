package com.sejourfr.app.enums;

/**
 * <b>Ou en est le candidat sur l'ETAPE d'une competence</b> — la ligne de
 * « Votre parcours — Tache N » et le bandeau de la carte « A faire
 * maintenant ».
 *
 * <p>Il repond a une question qu'aucun des trois autres vocabulaires ne
 * posait : <i>la serie de {@code LearningPlanStep.PROMPTS_PAR_ETAPE} petits
 * sujets est-elle finie, et la verification en situation a-t-elle ete
 * rendue ?</i> {@link LearningPlanSkillStatus} est le verdict d'<b>une</b>
 * production, {@link SkillMasteryState} l'etat <b>agrege</b> d'une competence,
 * {@link PlanActionNature} l'<b>action a faire</b> ; aucun des trois ne sait
 * dire « serie terminee, verification pas encore rendue ».
 *
 * <h2>🛑 Pourquoi il est SERVI et non derive par les fronts</h2>
 * Les deux fronts le derivaient chacun de leur cote — le web cochait sur
 * {@code masteryState == SOLID} sans jamais lire {@code completedSteps}, le
 * mobile sur l'un <b>ou</b> l'autre — et ils montraient donc deux parcours
 * differents au meme candidat. Un front ne classe pas un compteur en etat
 * pedagogique : l'etat arrive servi, le front l'affiche.
 *
 * <p>🛑 <b>{@link #SERIE_TERMINEE} n'est pas {@link #ACQUIS}.</b> Cinq petits
 * sujets traites ne prouvent rien en situation — c'est tout le principe du
 * module. Seul {@code SkillMasteryState.SOLID} vaut « acquis », et il reclame
 * une production contextualisee. Ne jamais cocher une serie finie comme un
 * acquis.
 *
 * <p>🛑 <b>Aucun palier CECRL ne s'y accroche</b> : on n'ecrit jamais
 * « Acquis · B1 ». Le palier d'une competence est notre palier <b>pedagogique
 * interne</b> ({@code SkillTaskCode.targetLevel}), il s'affiche a part et
 * seulement comme « Niveau vise B1 ».
 *
 * <p><b>L'ordre de declaration EST l'ordre de lecture</b> (patron
 * {@link PlanActionNature}) : ce qui est acquis, ce qui attend sa preuve, ce
 * qui est fini, ce qu'on travaille maintenant, ce qui est commence, ce qui
 * vient. L'autorite unique qui le resout est
 * {@code PlanStepStateResolver}.
 *
 * <p><b>Libelles geles</b> par {@code SkillLabelsTest} et recopies a la main
 * dans les fronts.
 */
public enum PlanSkillStepState {

    /** {@code SkillMasteryState.SOLID} : la maitrise est prouvee en situation. */
    ACQUIS("Acquis"),

    /**
     * Les petits sujets de l'etape sont <b>tous</b> traites et aucune production
     * contextualisee n'est venue depuis : c'est la verification qui manque, plus
     * les exercices.
     */
    A_VERIFIER("Série terminée · À vérifier"),

    /**
     * Serie finie <b>et</b> verification rendue, sans que la maitrise soit
     * encore installee. Le Plan passe a la priorite suivante ; la competence
     * pourra revenir, elle n'enferme personne.
     */
    SERIE_TERMINEE("Série terminée"),

    /** La competence que le Plan met en tete : c'est elle qu'on travaille. */
    MAINTENANT("Maintenant"),

    /** La serie est commencee, elle n'est pas finie. */
    EN_COURS("En cours"),

    /** Rien n'a encore ete fait dessus. <i>Pas un retard : un a-venir.</i> */
    A_VENIR("À venir");

    private final String label;

    PlanSkillStepState(String label) {
        this.label = label;
    }

    /** Libelle FR rendu au candidat, tel quel. */
    public String getLabel() {
        return label;
    }
}
