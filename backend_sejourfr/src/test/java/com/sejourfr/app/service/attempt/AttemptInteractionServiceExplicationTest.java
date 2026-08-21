package com.sejourfr.app.service.attempt;

import com.sejourfr.app.dto.AnswerResultResponse;
import com.sejourfr.app.dto.QuestionPublicResponse;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Media;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.manager.AnswerManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.mapper.AttemptMapper;
import com.sejourfr.app.mapper.QuestionMapper;
import com.sejourfr.app.service.ComprehensionObservationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Correction immédiate en TRAINING : l'explication rendue par
 * {@code POST /api/attempts/{id}/answers} cite les lettres de l'ordre
 * <b>affiché</b>, pas du {@code display_order} de la base.
 *
 * <p>C'est le même texte, la même graine et la même permutation que l'écran du
 * runner : deux surfaces qui répondraient différemment désigneraient deux
 * propositions différentes pour la même lettre.
 */
class AttemptInteractionServiceExplicationTest {

    private static final String EXPLICATION =
            "Seule B « en suivant la notice étape par étape » y répond. "
                    + "A indique une durée. C indique une cause. D indique un lieu. "
                    + "Piège B1 : les quatre réponses parlent du montage.";

    private final QuestionMapper questionMapper = new QuestionMapper();
    private AttemptQuestionManager attemptQuestionManager;
    private AttemptInteractionService service;

    @BeforeEach
    void setUp() {
        attemptQuestionManager = mock(AttemptQuestionManager.class);
        AnswerManager answerManager = mock(AnswerManager.class);
        service = new AttemptInteractionService(
                mock(AttemptManager.class), attemptQuestionManager, answerManager,
                mock(AttemptScoringService.class), mock(AttemptMapper.class), questionMapper,
                mock(ComprehensionObservationService.class));
        when(answerManager.save(any(Answer.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    private Choice choix(String label, boolean correct, int ordre) {
        Choice c = new Choice();
        c.setId(UUID.randomUUID());
        c.setLabel(label);
        c.setCorrect(correct);
        c.setDisplayOrder(ordre);
        return c;
    }

    private Question question() {
        Theme t = new Theme();
        t.setId(UUID.randomUUID());
        t.setName("CO");
        t.setModule(Module.TCF);
        t.setCode("CO");

        Media audio = new Media();
        audio.setId(UUID.randomUUID());
        audio.setType(MediaType.AUDIO);
        audio.setUrl("https://r2.example/a.mp3");

        Question q = new Question();
        q.setId(UUID.randomUUID());
        q.setModule(Module.TCF);
        q.setTheme(t);
        q.setDifficulty(Difficulty.B1);
        q.setQuestionType(QuestionType.CO);
        q.setStatement("Écoutez le document sonore.");
        q.setExplanation(EXPLICATION);
        q.setActive(true);
        q.setMedia(audio);
        q.setChoices(new ArrayList<>(List.of(
                choix("Pendant deux heures environ.", false, 1),
                choix("En suivant la notice étape par étape.", true, 2),
                choix("Parce que j'en avais vraiment besoin.", false, 3),
                choix("Dans le salon, contre le mur.", false, 4))));
        return q;
    }

    private Attempt session(AttemptType type) {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setType(type);
        a.setModule(Module.TCF);
        a.setStatus(AttemptStatus.EN_COURS);
        a.setStartedAt(Instant.now());
        return a;
    }

    private AttemptQuestion attemptQuestion(Attempt attempt, Question q, UUID id) {
        AttemptQuestion aq = new AttemptQuestion();
        aq.setId(id);
        aq.setAttempt(attempt);
        aq.setQuestion(q);
        aq.setPosition(1);
        when(attemptQuestionManager.findById(id)).thenReturn(Optional.of(aq));
        return aq;
    }

    @Test
    void training_lExplicationCiteLesLettresDeLOrdreAffiche() {
        Question q = question();
        Attempt attempt = session(AttemptType.TRAINING);

        // Plusieurs graines : la permutation change, l'explication doit suivre.
        for (long i = 1; i <= 30; i++) {
            UUID aqId = new UUID(i, 0L);
            AttemptQuestion aq = attemptQuestion(attempt, q, aqId);
            UUID bonne = q.getChoices().get(1).getId();

            AnswerResultResponse r = service.submitAnswerForAttempt(
                    attempt, new SubmitAnswerRequest(aq.getId(), List.of(bonne)));

            QuestionPublicResponse ecran = questionMapper.toPublic(q, true, aqId);
            assertThat(r.explanation()).isEqualTo(ecran.explanation());

            int indexBonne = ecran.choices().stream()
                    .map(c -> c.id()).toList().indexOf(bonne);
            assertThat(r.explanation()).startsWith("Seule " + (char) ('A' + indexBonne) + " «");
            assertThat(r.explanation()).contains("Piège B1 :");
        }
    }

    @Test
    void examenBlanc_neRevelePasLExplication() {
        Question q = question();
        Attempt attempt = session(AttemptType.MOCK_EXAM);
        AttemptQuestion aq = attemptQuestion(attempt, q, new UUID(99L, 0L));

        AnswerResultResponse r = service.submitAnswerForAttempt(
                attempt, new SubmitAnswerRequest(aq.getId(), List.of(q.getChoices().get(0).getId())));

        assertThat(r.recorded()).isTrue();
        assertThat(r.explanation()).isNull();
        assertThat(r.correct()).isNull();
    }
}
