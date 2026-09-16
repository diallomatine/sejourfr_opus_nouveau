package com.sejourfr.app.enums;

/**
 * <b>Ce qui a clos une etape, a la date ou elle a ete close.</b>
 *
 * <p>🛑 <b>Persiste, et c'est la seule chose de l'etat qui le soit</b>
 * (arbitrage D-7). Ce n'est pas un derive : {@link #SUPERSEDED} et
 * {@link #SATISFIED_BY_ASSESSMENT} dependent d'un <b>evenement date</b> que rien
 * ne permet de reconstituer apres coup.
 *
 * <p>⚠️ <b>{@link #MASTERED} ne repond PAS a « cette competence est-elle acquise
 * aujourd'hui ? »</b> Il dit : « cette etape a ete close <b>parce que</b>
 * {@code SkillMasteryEngine} concluait au transfert, <b>a cette date</b> ».
 * L'etat courant a une seule autorite, le moteur, et elle se relit. Consequence
 * voulue : recalibrer le moteur ne reinterprete <b>aucune</b> etape deja close,
 * et une competence redevenue fragile ne reouvre pas son etape — elle reviendra
 * par un examen (R7).
 */
public enum JourneyStepResolution {

    /**
     * Transfert prouve en situation, lu chez
     * {@code SkillMasteryEngine.SkillMastery.transferProven()}.
     */
    MASTERED,

    /**
     * Le quota de travail de l'etape est atteint <b>sans</b> maitrise. On ne
     * bloque jamais un candidat sur une competence non maitrisee : l'examen
     * decidera si elle revient.
     *
     * <p>Le quota n'a pas la meme unite selon la famille (R8, D-5) :
     * 5 petits sujets en expression, {@code trainSeriesQuota} series ciblees en
     * comprehension.
     */
    QUOTA_REACHED,

    /**
     * Une evaluation a rendu cette etape inutile : le checkpoint d'un lot dont
     * tous les entrainements etaient faits, ou un « Evaluer mon niveau » dont
     * l'epreuve vient d'etre passee ailleurs (R7). <b>On ne demande jamais au
     * candidat de refaire un examen qu'il vient de passer.</b>
     */
    SATISFIED_BY_ASSESSMENT,

    /**
     * Une evaluation plus recente de la meme epreuve a pris la main alors que
     * l'etape n'etait pas faite (R7). L'etape est rendue
     * {@link JourneyStepStatus#OBSOLETE}, donc invisible.
     */
    SUPERSEDED
}
