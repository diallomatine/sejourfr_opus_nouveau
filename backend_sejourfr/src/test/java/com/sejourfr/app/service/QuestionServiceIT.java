package com.sejourfr.app.service;

import com.sejourfr.app.dto.ChoiceWriteRequest;
import com.sejourfr.app.dto.QuestionDto;
import com.sejourfr.app.dto.QuestionWriteRequest;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class QuestionServiceIT extends AbstractIntegrationTest {

    @Autowired
    private QuestionService questionService;

    @Autowired
    private TestData testData;

    private QuestionWriteRequest req(UUID themeId, List<ChoiceWriteRequest> choices) {
        return new QuestionWriteRequest(
                Module.CIVIQUE, themeId, null, null,
                Difficulty.CSP, QuestionType.CONNAISSANCE,
                "Quel est le drapeau ?", "Explication.", true, choices);
    }

    private List<ChoiceWriteRequest> validChoices() {
        return List.of(
                new ChoiceWriteRequest("Bleu blanc rouge", true, 0),
                new ChoiceWriteRequest("Vert", false, 1));
    }

    @Test
    void createThenGetById() {
        Theme theme = testData.theme();
        QuestionDto created = questionService.create(req(theme.getId(), validChoices()));

        assertThat(created.id()).isNotNull();
        assertThat(created.themeId()).isEqualTo(theme.getId());
        assertThat(created.choices()).hasSize(2);
        assertThat(created.active()).isTrue();

        QuestionDto fetched = questionService.getById(created.id());
        assertThat(fetched.statement()).isEqualTo("Quel est le drapeau ?");
        assertThat(fetched.difficulty()).isEqualTo(Difficulty.CSP);
    }

    @Test
    void createWithoutCorrectChoiceIsRejected() {
        Theme theme = testData.theme();
        List<ChoiceWriteRequest> noCorrect = List.of(
                new ChoiceWriteRequest("A", false, 0),
                new ChoiceWriteRequest("B", false, 1));
        assertThatThrownBy(() -> questionService.create(req(theme.getId(), noCorrect)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("au moins un choix correct");
    }

    @Test
    void createWithAbsentThemeThrowsNotFound() {
        assertThatThrownBy(() -> questionService.create(req(UUID.randomUUID(), validChoices())))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void updateChangesFieldsAndReplacesChoices() {
        Theme theme = testData.theme();
        QuestionDto created = questionService.create(req(theme.getId(), validChoices()));

        QuestionWriteRequest update = new QuestionWriteRequest(
                Module.CIVIQUE, theme.getId(), null, null,
                Difficulty.NAT, QuestionType.MISE_SITUATION,
                "Énoncé modifié", "Maj.", true,
                List.of(
                        new ChoiceWriteRequest("X", true, 0),
                        new ChoiceWriteRequest("Y", false, 1),
                        new ChoiceWriteRequest("Z", false, 2)));

        QuestionDto updated = questionService.update(created.id(), update);
        assertThat(updated.statement()).isEqualTo("Énoncé modifié");
        assertThat(updated.difficulty()).isEqualTo(Difficulty.NAT);
        assertThat(updated.questionType()).isEqualTo(QuestionType.MISE_SITUATION);
        assertThat(updated.choices()).hasSize(3);
    }

    @Test
    void setActiveTogglesFlag() {
        Theme theme = testData.theme();
        QuestionDto created = questionService.create(req(theme.getId(), validChoices()));

        QuestionDto deactivated = questionService.setActive(created.id(), false);
        assertThat(deactivated.active()).isFalse();
        assertThat(questionService.getById(created.id()).active()).isFalse();
    }

    @Test
    void deleteRemovesQuestion() {
        Theme theme = testData.theme();
        QuestionDto created = questionService.create(req(theme.getId(), validChoices()));
        questionService.delete(created.id());

        assertThatThrownBy(() -> questionService.getById(created.id()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void deleteAbsentThrowsNotFound() {
        assertThatThrownBy(() -> questionService.delete(UUID.randomUUID()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void searchFiltersByTheme() {
        Theme themeA = testData.theme(Module.CIVIQUE, "ta", "Theme A");
        Theme themeB = testData.theme(Module.CIVIQUE, "tb", "Theme B");
        questionService.create(req(themeA.getId(), validChoices()));
        questionService.create(req(themeA.getId(), validChoices()));
        questionService.create(req(themeB.getId(), validChoices()));

        Page<QuestionDto> page = questionService.search(
                null, themeA.getId(), null, null, null, null, PageRequest.of(0, 50));

        assertThat(page.getContent()).isNotEmpty();
        assertThat(page.getContent()).allMatch(q -> q.themeId().equals(themeA.getId()));
        assertThat(page.getTotalElements()).isEqualTo(2);
    }
}
