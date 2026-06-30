package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class AttemptQuestionManagerIT extends AbstractIntegrationTest {

    @Autowired
    private AttemptQuestionManager manager;

    @Autowired
    private TestData testData;

    @Test
    void saveAndFindById() {
        User user = testData.user();
        Attempt attempt = testData.attempt(user);
        Question q = testData.question();

        AttemptQuestion aq = aq(attempt, q, 0);
        assertThat(aq.getId()).isNotNull();

        assertThat(manager.findById(aq.getId())).isPresent();
    }

    @Test
    void findByIdAbsentReturnsEmpty() {
        assertThat(manager.findById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void findByAttemptOrderedByPosition() {
        User user = testData.user();
        Attempt attempt = testData.attempt(user);
        Attempt other = testData.attempt(user);

        // Insérés dans le désordre des positions.
        AttemptQuestion p2 = aq(attempt, testData.question(), 2);
        AttemptQuestion p0 = aq(attempt, testData.question(), 0);
        AttemptQuestion p1 = aq(attempt, testData.question(), 1);
        // Ligne d'un autre attempt → ne doit pas remonter.
        aq(other, testData.question(), 0);

        List<AttemptQuestion> ordered = manager.findByAttemptOrderedByPosition(attempt.getId());

        assertThat(ordered).extracting(AttemptQuestion::getId)
                .containsExactly(p0.getId(), p1.getId(), p2.getId());
    }

    @Test
    void findByAttemptUnknownReturnsEmptyList() {
        assertThat(manager.findByAttemptOrderedByPosition(UUID.randomUUID())).isEmpty();
    }

    private AttemptQuestion aq(Attempt attempt, Question question, int position) {
        AttemptQuestion aq = new AttemptQuestion();
        aq.setAttempt(attempt);
        aq.setQuestion(question);
        aq.setPosition(position);
        return manager.save(aq);
    }
}
