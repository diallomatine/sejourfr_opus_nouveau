package com.sejourfr.app.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.sejourfr.app.enums.PlanSkillStepState;
import com.sejourfr.app.enums.SkillMasteryState;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * <b>Ou en est l'etape</b> — l'etat que les deux fronts derivaient chacun de
 * leur cote, et qu'ils lisent desormais servi.
 *
 * <p>Le defaut corrige : le web cochait une ligne sur
 * {@code masteryState == SOLID} sans jamais lire {@code completedSteps}, le
 * mobile sur l'un <b>ou</b> l'autre. Deux regles, deux parcours differents pour
 * le meme candidat.
 */
class PlanStepStateResolverTest {

    @Test
    @DisplayName("SOLID vaut ACQUIS")
    void solidVautAcquis() {
        assertThat(PlanStepStateResolver.resolve(
                moteur(SkillMasteryState.SOLID, true, false), etape(5, 5), false))
                .isEqualTo(PlanSkillStepState.ACQUIS);
    }

    /**
     * 🛑 <b>Le defaut du 2026-09-16.</b> Le parcours normal — cinq petits sujets
     * puis une verification reussie — prouve le transfert <b>sans</b> atteindre
     * le score {@code SOLID} : la competence entrait dans {@code completedSteps}
     * (« Deja travaille et valide », cochee) et ressortait « Serie terminee »
     * dans « Votre parcours », cercle vide, sur le meme ecran.
     */
    @Test
    @DisplayName("Transfert prouve sans SOLID : ACQUIS, comme dans completedSteps")
    void leTransfertProuveVautAcquisMemeSansSolid() {
        assertThat(PlanStepStateResolver.resolve(
                moteur(SkillMasteryState.CONSOLIDATING, true, true), etape(5, 5), false))
                .isEqualTo(PlanSkillStepState.ACQUIS);
        // Et meme quand l'etape n'a pas ete jouee : la preuve vient de la
        // production complete, pas des petits sujets.
        assertThat(PlanStepStateResolver.resolve(
                moteur(SkillMasteryState.CONSOLIDATING, true, false), etape(5, 0), false))
                .isEqualTo(PlanSkillStepState.ACQUIS);
    }

    /**
     * 🛑 Le coeur de la decision produit : 5/5 <b>n'est pas</b> une maitrise,
     * c'est une verification a faire.
     */
    @Test
    @DisplayName("5/5 sans verification rendue : la serie est terminee, la preuve manque")
    void cinqSurCinqDemandeLaVerification() {
        assertThat(PlanStepStateResolver.resolve(
                moteur(SkillMasteryState.TO_REINFORCE, false, false), etape(5, 5), true))
                .isEqualTo(PlanSkillStepState.A_VERIFIER);
    }

    @Test
    @DisplayName("Verification rendue mais transfert NON prouve : serie terminee, le Plan avance")
    void laVerificationRendueSansTransfertTermineLaSerie() {
        assertThat(PlanStepStateResolver.resolve(
                moteur(SkillMasteryState.CONSOLIDATING, false, true), etape(5, 5), false))
                .isEqualTo(PlanSkillStepState.SERIE_TERMINEE);
    }

    /**
     * « Maintenant » est un <b>reperage</b>, pas une mesure : il reste visible a
     * 2/5, sinon la ligne que le candidat est en train de travailler se
     * confondrait avec celles qu'il a seulement commencees.
     */
    @Test
    @DisplayName("La competence en tete dit « Maintenant », meme a mi-parcours")
    void laCompetenceEnTeteDitMaintenant() {
        assertThat(PlanStepStateResolver.resolve(vierge(), etape(5, 2), true))
                .isEqualTo(PlanSkillStepState.MAINTENANT);
        assertThat(PlanStepStateResolver.resolve(vierge(), etape(5, 0), true))
                .isEqualTo(PlanSkillStepState.MAINTENANT);
    }

    @Test
    @DisplayName("Commencee sans etre en tete : en cours ; jamais touchee : a venir")
    void lesDeuxEtatsRestants() {
        assertThat(PlanStepStateResolver.resolve(vierge(), etape(5, 2), false))
                .isEqualTo(PlanSkillStepState.EN_COURS);
        assertThat(PlanStepStateResolver.resolve(vierge(), etape(5, 0), false))
                .isEqualTo(PlanSkillStepState.A_VENIR);
    }

    /**
     * Une competence de COMPREHENSION n'a aucun petit sujet : son etape est vide
     * et ne se termine jamais. Elle ne doit donc jamais s'afficher « serie
     * terminee » — il n'y avait aucune serie.
     */
    @Test
    @DisplayName("Sans aucun sujet, l'etape ne se termine jamais")
    void sansSujetAucuneSerieNeSeTermine() {
        assertThat(PlanStepStateResolver.resolve(
                moteur(SkillMasteryState.TO_REINFORCE, false, false),
                LearningPlanStep.Progress.EMPTY, false))
                .isEqualTo(PlanSkillStepState.A_VENIR);
        assertThat(PlanStepStateResolver.resolve(null, null, true))
                .isEqualTo(PlanSkillStepState.MAINTENANT);
    }

    /** Aucune observation exploitable : on ne conclut rien, on n'invente rien. */
    private static SkillMasteryEngine.SkillMastery vierge() {
        return SkillMasteryEngine.SkillMastery.NONE;
    }

    private static SkillMasteryEngine.SkillMastery moteur(
            SkillMasteryState state, boolean transferProven, boolean verificationSubmitted) {
        return new SkillMasteryEngine.SkillMastery(
                state, 0, 0, 0, 0, 0, false, false, transferProven, verificationSubmitted, null);
    }

    private static LearningPlanStep.Progress etape(int total, int traites) {
        List<UUID> ids = new ArrayList<>();
        for (int rang = 0; rang < total; rang++) ids.add(UUID.randomUUID());
        return new LearningPlanStep.Progress(ids, traites, 0);
    }
}
