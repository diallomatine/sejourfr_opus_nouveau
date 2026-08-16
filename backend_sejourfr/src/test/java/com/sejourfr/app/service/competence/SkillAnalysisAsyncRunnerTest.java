package com.sejourfr.app.service.competence;

import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.service.LearningPlanObservationService;
import com.sejourfr.app.service.competence.niveauvise.CompetenceNiveauViseService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InOrder;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class SkillAnalysisAsyncRunnerTest {

    private UserSkillAttemptManager attempts;
    private CompetenceAnalysisService analysis;
    private CompetenceNiveauViseService niveauVise;
    private SkillAnalysisFailureRecorder failureRecorder;
    private LearningPlanObservationService observations;
    private SkillAnalysisAsyncRunner runner;

    @BeforeEach
    void setUp() {
        attempts = mock(UserSkillAttemptManager.class);
        analysis = mock(CompetenceAnalysisService.class);
        niveauVise = mock(CompetenceNiveauViseService.class);
        failureRecorder = mock(SkillAnalysisFailureRecorder.class);
        observations = mock(LearningPlanObservationService.class);
        runner = new SkillAnalysisAsyncRunner(
                attempts, analysis, niveauVise, failureRecorder, observations);
    }

    /** Tentative ECRITE : rien a transcrire, le runner part du texte. */
    private UserSkillAttempt attempt(UUID attemptId) {
        return attempt(attemptId, SkillSection.EE, null);
    }

    private UserSkillAttempt attempt(UUID attemptId, SkillSection section, String transcript) {
        SkillPrompt prompt = new SkillPrompt();
        prompt.setSection(section);
        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setId(attemptId);
        attempt.setStatut(SkillAttemptStatut.SUBMITTED);
        attempt.setSkillPrompt(prompt);
        attempt.setTranscript(transcript);
        return attempt;
    }

    /**
     * L'ORDRE est l'invariant du montage a deux appels : le bloc « pour viser »
     * ne part qu'APRES que l'analyse a ete persistee, hors de sa transaction.
     * L'inverser reviendrait a faire connaitre l'objectif au correcteur.
     */
    @Test
    void leBlocPourViserNestDemandeQuApresLanalyse() {
        UUID attemptId = UUID.randomUUID();
        UserSkillAttempt attempt = attempt(attemptId);
        when(attempts.findByIdWithPrompt(attemptId)).thenReturn(Optional.of(attempt));

        runner.runAsync(attemptId).join();

        InOrder ordre = inOrder(analysis, niveauVise);
        ordre.verify(analysis).analyse(attemptId);
        ordre.verify(niveauVise).enrichir(attemptId);
    }

    /** Une analyse en echec ne paie jamais le second appel. */
    @Test
    void uneAnalyseEnEchecNeDeclenchePasLeSecondAppel() {
        UUID attemptId = UUID.randomUUID();
        UserSkillAttempt attempt = attempt(attemptId);
        when(attempts.findByIdWithPrompt(attemptId)).thenReturn(Optional.of(attempt));
        doThrow(new IllegalStateException("analyse indisponible"))
                .when(analysis).analyse(attemptId);

        runner.runAsync(attemptId).join();

        verify(niveauVise, never()).enrichir(attemptId);
    }

    @Test
    void panneDuPlanNeTransformePasUneAnalyseReussieEnEchec() {
        UUID attemptId = UUID.randomUUID();
        UserSkillAttempt attempt = attempt(attemptId);
        when(attempts.findByIdWithPrompt(attemptId)).thenReturn(Optional.of(attempt));
        doThrow(new IllegalStateException("plan indisponible"))
                .when(observations).recordSkillAttempt(attemptId);

        runner.runAsync(attemptId).join();

        assertThat(attempt.getStatut()).isEqualTo(SkillAttemptStatut.EVALUATING);
        verify(analysis).analyse(attemptId);
        verify(observations).recordSkillAttempt(attemptId);
        verify(failureRecorder, never()).markFailed(attemptId, "plan indisponible");
    }

    @Test
    void panneDeLanalyseResteUnEchecDeTentative() {
        UUID attemptId = UUID.randomUUID();
        UserSkillAttempt attempt = attempt(attemptId);
        when(attempts.findByIdWithPrompt(attemptId)).thenReturn(Optional.of(attempt));
        doThrow(new IllegalStateException("analyse indisponible"))
                .when(analysis).analyse(attemptId);

        runner.runAsync(attemptId).join();

        verify(failureRecorder).markFailed(attemptId, "analyse indisponible");
        verify(observations, never()).recordSkillAttempt(attemptId);
    }

    /**
     * Une tentative orale SANS transcription est un etat impossible depuis la
     * soumission (elle est ecrite dans la requete), sauf sur une ligne
     * anterieure au changement. On echoue clairement — il n'y a plus d'audio a
     * relire — au lieu d'analyser du vide.
     */
    @Test
    void uneTentativeOraleSansTranscriptionEchoueSansAppelerLeCorrecteur() {
        UUID attemptId = UUID.randomUUID();
        UserSkillAttempt attempt = attempt(attemptId, SkillSection.EO, null);
        when(attempts.findByIdWithPrompt(attemptId)).thenReturn(Optional.of(attempt));

        runner.runAsync(attemptId).join();

        verify(analysis, never()).analyse(attemptId);
        verify(niveauVise, never()).enrichir(attemptId);
        verify(failureRecorder).markFailed(org.mockito.ArgumentMatchers.eq(attemptId),
                org.mockito.ArgumentMatchers.contains("refaites le sujet"));
    }

    /** Une tentative orale DEJA transcrite part directement a l'analyse. */
    @Test
    void uneTentativeOraleTranscriteVaDirectementALanalyse() {
        UUID attemptId = UUID.randomUUID();
        UserSkillAttempt attempt = attempt(attemptId, SkillSection.EO, "je voudrais reserver");
        when(attempts.findByIdWithPrompt(attemptId)).thenReturn(Optional.of(attempt));

        runner.runAsync(attemptId).join();

        assertThat(attempt.getStatut()).isEqualTo(SkillAttemptStatut.EVALUATING);
        verify(analysis).analyse(attemptId);
    }
}
