package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class AnswerManagerIT extends AbstractIntegrationTest {

    @Autowired
    private AnswerManager answerManager;

    @Autowired
    private AttemptManager attemptManager;

    @Autowired
    private AttemptQuestionManager attemptQuestionManager;

    @Autowired
    private TestData testData;

    private int positionSeq = 0;

    @Test
    void saveIsRetrievableViaHasAnswered() {
        User user = testData.user();
        Attempt attempt = testData.attempt(user);
        Question q = testData.question();
        Answer saved = answer(user, attempt, q, true, Instant.now(), List.of());

        assertThat(saved.getId()).isNotNull();
        assertThat(answerManager.hasUserAnsweredQuestion(user.getId(), q.getId())).isTrue();
    }

    @Test
    void countAnsweredAndCorrectByUserAndModule() {
        User user = testData.user();
        User other = testData.user();
        Attempt civique = testData.attempt(user);          // module CIVIQUE
        Attempt tcf = attempt(user, Module.TCF);

        Question q1 = testData.question();
        Question q2 = testData.question();
        answer(user, civique, q1, true, Instant.now(), List.of());
        answer(user, civique, q2, false, Instant.now(), List.of());
        // Même question répondue 2× (autre attempt) → ne gonfle pas le distinct.
        Attempt civique2 = testData.attempt(user);
        answer(user, civique2, q1, true, Instant.now(), List.of());
        // Réponse TCF → exclue du compteur CIVIQUE.
        answer(user, tcf, testData.question(), true, Instant.now(), List.of());
        // Réponse d'un autre user → exclue.
        Attempt otherAttempt = testData.attempt(other);
        answer(other, otherAttempt, testData.question(), true, Instant.now(), List.of());

        assertThat(answerManager.countAnsweredByUserAndModule(user.getId(), Module.CIVIQUE)).isEqualTo(2);
        assertThat(answerManager.countCorrectByUserAndModule(user.getId(), Module.CIVIQUE)).isEqualTo(1);
        assertThat(answerManager.countAnsweredByUserAndModule(user.getId(), Module.TCF)).isEqualTo(1);
    }

    @Test
    void aggregateByThemeGroupsDistinctQuestions() {
        User user = testData.user();
        Attempt attempt = testData.attempt(user);
        Theme t1 = testData.theme(Module.CIVIQUE, "aggT1", "Thème 1");
        Theme t2 = testData.theme(Module.CIVIQUE, "aggT2", "Thème 2");

        answer(user, attempt, testData.question(t1), true, Instant.now(), List.of());
        answer(user, attempt, testData.question(t1), false, Instant.now(), List.of());
        answer(user, attempt, testData.question(t2), true, Instant.now(), List.of());

        List<Object[]> rows = answerManager.aggregateByTheme(user.getId(), Module.CIVIQUE);

        Object[] r1 = rowFor(rows, t1.getId());
        Object[] r2 = rowFor(rows, t2.getId());
        assertThat(((Number) r1[3]).longValue()).isEqualTo(2);   // total distinct
        assertThat(((Number) r1[4]).longValue()).isEqualTo(1);   // correct distinct
        assertThat(((Number) r2[3]).longValue()).isEqualTo(1);
        assertThat(((Number) r2[4]).longValue()).isEqualTo(1);
    }

    @Test
    void findRecentWrongQuestionIdsOrdersByRecencyAndCaps() {
        User user = testData.user();
        Attempt attempt = testData.attempt(user);
        Instant base = Instant.now().minus(3, ChronoUnit.HOURS);

        Question wrong1 = testData.question();
        Question wrong2 = testData.question();
        Question wrong3 = testData.question();
        answer(user, attempt, wrong1, false, base, List.of());
        answer(user, attempt, wrong2, false, base.plus(1, ChronoUnit.HOURS), List.of());
        answer(user, attempt, wrong3, false, base.plus(2, ChronoUnit.HOURS), List.of());
        // Réponse correcte → exclue.
        answer(user, attempt, testData.question(), true, base.plus(3, ChronoUnit.HOURS), List.of());

        List<UUID> capped = answerManager.findRecentWrongQuestionIds(user.getId(), Module.CIVIQUE, null, null, 2);
        assertThat(capped).containsExactly(wrong3.getId(), wrong2.getId());

        List<UUID> all = answerManager.findRecentWrongQuestionIds(user.getId(), Module.CIVIQUE, null, null, 10);
        assertThat(all).containsExactly(wrong3.getId(), wrong2.getId(), wrong1.getId());
    }

    @Test
    void hasUserAnsweredQuestion() {
        User user = testData.user();
        User other = testData.user();
        Attempt attempt = testData.attempt(user);
        Question answered = testData.question();
        Question untouched = testData.question();
        answer(user, attempt, answered, true, Instant.now(), List.of());

        assertThat(answerManager.hasUserAnsweredQuestion(user.getId(), answered.getId())).isTrue();
        assertThat(answerManager.hasUserAnsweredQuestion(user.getId(), untouched.getId())).isFalse();
        assertThat(answerManager.hasUserAnsweredQuestion(other.getId(), answered.getId())).isFalse();
    }

    @Test
    void findLatestSelectedChoiceIdsReturnsMostRecent() {
        User user = testData.user();
        Question q = testData.question();
        List<UUID> firstSelection = List.of(UUID.randomUUID());
        List<UUID> lastSelection = List.of(UUID.randomUUID(), UUID.randomUUID());

        Attempt a1 = testData.attempt(user);
        answer(user, a1, q, false, Instant.now().minus(1, ChronoUnit.HOURS), firstSelection);
        Attempt a2 = testData.attempt(user);
        answer(user, a2, q, true, Instant.now(), lastSelection);

        assertThat(answerManager.findLatestSelectedChoiceIds(user.getId(), q.getId()))
                .containsExactlyElementsOf(lastSelection);
    }

    @Test
    void findLatestSelectedChoiceIdsEmptyWhenNeverAnswered() {
        User user = testData.user();
        assertThat(answerManager.findLatestSelectedChoiceIds(user.getId(), UUID.randomUUID())).isEmpty();
    }

    // ------------------------------------------------------------------------

    private Object[] rowFor(List<Object[]> rows, UUID themeId) {
        return rows.stream()
                .filter(r -> themeId.equals(r[0]))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Aucune ligne pour le thème " + themeId));
    }

    /**
     * « Zéro réponse » est ce qui distingue, sur une sous-épreuve d'examen
     * blanc complet, une épreuve <b>jamais ouverte</b> (aucun niveau) d'une
     * épreuve ouverte puis écourtée (A1_NON_ATTEINT). Le compteur doit donc
     * répondre sur l'attempt, et sur lui seul.
     */
    @Test
    void hasAnyAnswer_distingueUneSessionVideDUneSessionRepondue() {
        User user = testData.user();
        Attempt vide = attempt(user, Module.TCF);
        Attempt repondu = attempt(user, Module.TCF);

        assertThat(answerManager.hasAnyAnswer(vide.getId())).isFalse();
        assertThat(answerManager.hasAnyAnswer(repondu.getId())).isFalse();

        answer(user, repondu, testData.question(), false, Instant.now(), List.of());

        // Une réponse FAUSSE compte : ce qui est mesuré, c'est « quelque chose
        // a été rendu », pas la réussite.
        assertThat(answerManager.hasAnyAnswer(repondu.getId())).isTrue();
        // Et rien ne déborde sur la session voisine du même utilisateur.
        assertThat(answerManager.hasAnyAnswer(vide.getId())).isFalse();
        assertThat(answerManager.hasAnyAnswer(UUID.randomUUID())).isFalse();
    }

    private Attempt attempt(User user, Module module) {
        Attempt a = new Attempt();
        a.setUser(user);
        a.setType(AttemptType.TRAINING);
        a.setModule(module);
        a.setEpreuve(module == Module.TCF ? EpreuveType.TCF_CO : EpreuveType.CIVIQUE);
        a.setMode(AttemptMode.ENTRAINEMENT);
        a.setStatus(AttemptStatus.EN_COURS);
        a.setStartedAt(Instant.now());
        return attemptManager.save(a);
    }

    private Answer answer(User user, Attempt attempt, Question question,
                          boolean correct, Instant when, List<UUID> selected) {
        AttemptQuestion aq = new AttemptQuestion();
        aq.setAttempt(attempt);
        aq.setQuestion(question);
        aq.setPosition(positionSeq++);
        aq = attemptQuestionManager.save(aq);

        Answer ans = new Answer();
        ans.setAttemptQuestion(aq);
        ans.setUser(user);
        ans.setSelectedChoiceIds(selected);
        ans.setCorrect(correct);
        ans.setAnsweredAt(when);
        return answerManager.save(ans);
    }
}
