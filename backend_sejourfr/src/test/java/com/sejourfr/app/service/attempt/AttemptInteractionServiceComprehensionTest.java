package com.sejourfr.app.service.attempt;

import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.manager.AnswerManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.mapper.AttemptMapper;
import com.sejourfr.app.mapper.QuestionMapper;
import com.sejourfr.app.service.ComprehensionObservationService;
import com.sejourfr.app.service.ComprehensionObservationService.ReponseComprehension;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Le branchement du producteur d'observations CO / CE sur la fin d'une session
 * QCM : ce qu'il recoit, et surtout le fait qu'il ne peut <b>jamais</b> faire
 * echouer la correction.
 */
class AttemptInteractionServiceComprehensionTest {

    private AttemptManager attemptManager;
    private AttemptQuestionManager attemptQuestionManager;
    private ComprehensionObservationService observationService;
    private AttemptInteractionService service;

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        attemptQuestionManager = mock(AttemptQuestionManager.class);
        observationService = mock(ComprehensionObservationService.class);

        service = new AttemptInteractionService(
                attemptManager, attemptQuestionManager, mock(AnswerManager.class),
                mock(AttemptScoringService.class), mock(AttemptMapper.class),
                new QuestionMapper(), observationService);

        when(attemptManager.save(any(Attempt.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    @DisplayName("La fin d'une session TCF transmet toutes ses reponses, telles qu'elles sont")
    void laFinDeSessionTransmetLesReponses() {
        Attempt attempt = session(Module.TCF);
        questions(attempt,
                reponse(QuestionType.CO, Difficulty.A2, true),
                reponse(QuestionType.CO_IMAGE, Difficulty.A2, false),
                reponse(QuestionType.STRUCTURE, Difficulty.B1, true));

        service.finish(attempt.getUser().getId(), attempt.getId());

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<ReponseComprehension>> captor = ArgumentCaptor.forClass(List.class);
        verify(observationService).record(
                eq(attempt.getUser().getId()), eq(attempt.getId()), any(), captor.capture());
        // Le tri du perimetre (STRUCTURE, difficultes civiques...) appartient au
        // producteur : l'appelant lui transmet la session entiere.
        assertThat(captor.getValue()).containsExactly(
                new ReponseComprehension(QuestionType.CO, Difficulty.A2, true),
                new ReponseComprehension(QuestionType.CO_IMAGE, Difficulty.A2, false),
                new ReponseComprehension(QuestionType.STRUCTURE, Difficulty.B1, true));
    }

    @Test
    @DisplayName("Un echec du producteur ne fait jamais echouer la correction du QCM")
    void lEcritureDesObservationsEstBestEffort() {
        Attempt attempt = session(Module.TCF);
        questions(attempt, reponse(QuestionType.CE, Difficulty.B1, true));
        when(observationService.record(any(), any(), any(), anyList()))
                .thenThrow(new IllegalStateException("base indisponible"));

        assertThatCode(() -> service.finish(attempt.getUser().getId(), attempt.getId()))
                .doesNotThrowAnyException();

        // La session est bel et bien corrigee et close.
        assertThat(attempt.getFinishedAt()).isNotNull();
        assertThat(attempt.getStatus()).isEqualTo(AttemptStatus.TERMINE);
        assertThat(attempt.getScore()).isEqualTo(1);
    }

    @Test
    @DisplayName("Une session civique n'appelle meme pas le producteur")
    void uneSessionCiviqueNAppellePasLeProducteur() {
        Attempt attempt = session(Module.CIVIQUE);
        questions(attempt, reponse(QuestionType.CONNAISSANCE, Difficulty.CSP, true));

        service.finish(attempt.getUser().getId(), attempt.getId());

        verify(observationService, never()).record(any(), any(), any(), anyList());
    }

    @Test
    @DisplayName("Une session deja terminee ne re-observe rien")
    void uneSessionDejaTermineeNeReObservePas() {
        Attempt attempt = session(Module.TCF);
        attempt.setFinishedAt(Instant.now());
        questions(attempt, reponse(QuestionType.CO, Difficulty.B2, true));

        service.finish(attempt.getUser().getId(), attempt.getId());

        verify(observationService, never()).record(any(), any(), any(), anyList());
    }

    // ------------------------------------------------------------------ fixtures

    private Attempt session(Module module) {
        Attempt attempt = new Attempt();
        attempt.setId(UUID.randomUUID());
        User user = new User();
        user.setId(UUID.randomUUID());
        attempt.setUser(user);
        attempt.setType(AttemptType.TRAINING);
        attempt.setModule(module);
        attempt.setStatus(AttemptStatus.EN_COURS);
        attempt.setStartedAt(Instant.now());
        when(attemptManager.findById(attempt.getId())).thenReturn(Optional.of(attempt));
        return attempt;
    }

    private void questions(Attempt attempt, AttemptQuestion... aqs) {
        List<AttemptQuestion> liste = new ArrayList<>(List.of(aqs));
        liste.forEach(aq -> aq.setAttempt(attempt));
        when(attemptQuestionManager.findByAttemptOrderedByPosition(attempt.getId()))
                .thenReturn(liste);
    }

    private static AttemptQuestion reponse(
            QuestionType type, Difficulty difficulty, boolean correcte) {
        Question question = new Question();
        question.setId(UUID.randomUUID());
        question.setQuestionType(type);
        question.setDifficulty(difficulty);
        AttemptQuestion aq = new AttemptQuestion();
        aq.setId(UUID.randomUUID());
        aq.setQuestion(question);
        Answer answer = new Answer();
        answer.setCorrect(correcte);
        aq.setAnswer(answer);
        return aq;
    }
}
