package com.sejourfr.app.service;

import com.sejourfr.app.dto.AnswerResultResponse;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.AttemptSummaryResponse;
import com.sejourfr.app.dto.ProductionAttemptStartRequest;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Lecture, soumission de réponses et finalisation d'attempts (DB réelle).
 */
class AttemptServiceReadIT extends AbstractIntegrationTest {

    @Autowired AttemptService service;
    @Autowired TestData data;
    @Autowired AttemptManager attemptManager;
    @Autowired AttemptQuestionManager attemptQuestionManager;

    /** Utilisateur premium + thème dédié de 5 questions → l'attempt tire ces questions connues. */
    private record Fixture(User user, Theme theme) {}

    private Fixture premiumWithOwnQuestions(int count) {
        User user = data.user();
        data.userSubscription(user, data.plan());
        Theme theme = data.theme(Module.CIVIQUE, "read-theme", "Read thème");
        for (int i = 0; i < count; i++) {
            data.question(theme);
        }
        return new Fixture(user, theme);
    }

    private StartAttemptRequest training(User ignored, Theme theme, int size) {
        return new StartAttemptRequest(AttemptType.TRAINING, Module.CIVIQUE, null, theme.getId(),
                null, null, size, null, null, null);
    }

    private UUID correctChoiceId(AttemptQuestion aq) {
        return aq.getQuestion().getChoices().stream()
                .filter(Choice::isCorrect)
                .map(Choice::getId)
                .findFirst()
                .orElseThrow();
    }

    // ---- getById ----

    @Test
    void getById_proprietaire_ok() {
        User user = data.user();
        Attempt a = data.attempt(user);

        AttemptResponse r = service.getById(user.getId(), a.getId());

        assertThat(r.id()).isEqualTo(a.getId());
    }

    @Test
    void getById_autreUtilisateur_refuse() {
        User owner = data.user();
        User other = data.user();
        Attempt a = data.attempt(owner);

        assertThatThrownBy(() -> service.getById(other.getId(), a.getId()))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void getById_introuvable_lanceNotFound() {
        User user = data.user();

        assertThatThrownBy(() -> service.getById(user.getId(), UUID.randomUUID()))
                .isInstanceOf(EntityNotFoundException.class);
    }

    // ---- listMine ----

    @Test
    void listMine_renvoieLesAttemptsDuUser() {
        User user = data.user();
        Attempt a1 = data.attempt(user);
        Attempt a2 = data.attempt(user);

        List<AttemptSummaryResponse> list = service.listMine(
                user.getId(), null, null, null, null, 10);

        assertThat(list).extracting(AttemptSummaryResponse::id).contains(a1.getId(), a2.getId());
    }

    // ---- submitAnswer ----

    @Test
    void submitAnswer_training_renvoieCorrection() {
        Fixture f = premiumWithOwnQuestions(5);
        AttemptResponse started = service.start(f.user().getId(), training(f.user(), f.theme(), 5));
        AttemptQuestion firstAq = attemptQuestionManager
                .findByAttemptOrderedByPosition(started.id()).get(0);

        AnswerResultResponse res = service.submitAnswer(f.user().getId(), started.id(),
                new SubmitAnswerRequest(firstAq.getId(), List.of(correctChoiceId(firstAq))));

        assertThat(res.recorded()).isTrue();
        assertThat(res.correct()).isTrue();
        assertThat(res.correctChoiceIds()).isNotEmpty();
        assertThat(res.explanation()).isNotNull();
    }

    @Test
    void submitAnswer_questionDuneAutreSession_refuse() {
        User user = data.user();
        Attempt attemptA = data.attempt(user);
        Fixture f = premiumWithOwnQuestions(3);
        AttemptResponse other = service.start(f.user().getId(), training(f.user(), f.theme(), 3));
        AttemptQuestion foreignAq = attemptQuestionManager
                .findByAttemptOrderedByPosition(other.id()).get(0);

        assertThatThrownBy(() -> service.submitAnswerForAttempt(attemptA,
                new SubmitAnswerRequest(foreignAq.getId(), List.of(UUID.randomUUID()))))
                .isInstanceOf(IllegalArgumentException.class);
    }

    /**
     * Un choiceId volé à une AUTRE question était accepté et persisté dans
     * {@code answers.selected_choice_ids} : sans effet sur le score, mais la
     * revue affichait ensuite une sélection introuvable dans la question.
     */
    @Test
    void submitAnswer_choixDuneAutreQuestion_refuse() {
        Fixture f = premiumWithOwnQuestions(5);
        AttemptResponse started = service.start(f.user().getId(), training(f.user(), f.theme(), 5));
        List<AttemptQuestion> aqs = attemptQuestionManager.findByAttemptOrderedByPosition(started.id());
        AttemptQuestion target = aqs.get(0);
        UUID foreignChoiceId = correctChoiceId(aqs.get(1));

        assertThatThrownBy(() -> service.submitAnswer(f.user().getId(), started.id(),
                new SubmitAnswerRequest(target.getId(), List.of(foreignChoiceId))))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void submitAnswer_choixInexistant_refuse() {
        Fixture f = premiumWithOwnQuestions(3);
        AttemptResponse started = service.start(f.user().getId(), training(f.user(), f.theme(), 3));
        AttemptQuestion firstAq = attemptQuestionManager
                .findByAttemptOrderedByPosition(started.id()).get(0);

        assertThatThrownBy(() -> service.submitAnswer(f.user().getId(), started.id(),
                new SubmitAnswerRequest(firstAq.getId(), List.of(UUID.randomUUID()))))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void submitAnswer_sessionTerminee_refuse() {
        Fixture f = premiumWithOwnQuestions(3);
        AttemptResponse started = service.start(f.user().getId(), training(f.user(), f.theme(), 3));
        AttemptQuestion firstAq = attemptQuestionManager
                .findByAttemptOrderedByPosition(started.id()).get(0);
        service.finish(f.user().getId(), started.id());

        assertThatThrownBy(() -> service.submitAnswer(f.user().getId(), started.id(),
                new SubmitAnswerRequest(firstAq.getId(), List.of(correctChoiceId(firstAq)))))
                .isInstanceOf(IllegalStateException.class);
    }

    // ---- finish ----

    @Test
    void finish_training_calculeScoreEtEstIdempotent() {
        Fixture f = premiumWithOwnQuestions(5);
        AttemptResponse started = service.start(f.user().getId(), training(f.user(), f.theme(), 5));
        for (AttemptQuestion aq : attemptQuestionManager.findByAttemptOrderedByPosition(started.id())) {
            service.submitAnswer(f.user().getId(), started.id(),
                    new SubmitAnswerRequest(aq.getId(), List.of(correctChoiceId(aq))));
        }

        AttemptResponse finished = service.finish(f.user().getId(), started.id());

        assertThat(finished.finishedAt()).isNotNull();
        assertThat(finished.score()).isEqualTo(5);

        // Idempotent : second appel renvoie le même score.
        AttemptResponse again = service.finish(f.user().getId(), started.id());
        assertThat(again.score()).isEqualTo(5);
    }

    @Test
    void finish_moduleExamTcf_poseCecrlEtScorePondere() {
        User user = data.user();
        data.userSubscription(user, data.plan());
        AttemptResponse started = service.start(user.getId(), new StartAttemptRequest(
                AttemptType.MOCK_EXAM, Module.TCF, null, null, null, null, null, null,
                QuestionType.CO, null));

        AttemptResponse finished = service.finish(user.getId(), started.id());

        assertThat(finished.finishedAt()).isNotNull();
        assertThat(finished.cecrlLevel()).isNotNull();

        Attempt persisted = attemptManager.findById(started.id()).orElseThrow();
        assertThat(persisted.getCecrlLevel()).isNotNull();
        assertThat(persisted.getWeightedScore()).isEqualTo(0); // aucune réponse correcte
        assertThat(persisted.getMaxWeightedScore()).isGreaterThan(0);
    }

    @Test
    void finish_productionEe_poseFinishedAtEtTermine() {
        User user = data.user();
        AttemptResponse started = service.startProductionAttempt(user.getId(),
                new ProductionAttemptStartRequest(Module.TCF, EpreuveType.TCF_EE, null, null, null));

        AttemptResponse finished = service.finish(user.getId(), started.id());

        assertThat(finished.finishedAt()).isNotNull();
        Attempt persisted = attemptManager.findById(started.id()).orElseThrow();
        assertThat(persisted.getStatus()).isEqualTo(AttemptStatus.TERMINE);
    }
}
