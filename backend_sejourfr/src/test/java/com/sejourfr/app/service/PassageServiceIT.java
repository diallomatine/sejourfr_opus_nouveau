package com.sejourfr.app.service;

import com.sejourfr.app.dto.PassageDto;
import com.sejourfr.app.dto.PassageWriteRequest;
import com.sejourfr.app.entity.Passage;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.PassageType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PassageServiceIT extends AbstractIntegrationTest {

    @Autowired
    private PassageService passageService;

    @Autowired
    private QuestionManager questionManager;

    @Autowired
    private TestData testData;

    @Test
    void createThenGetById() {
        Theme theme = testData.theme();
        PassageDto created = passageService.create(
                new PassageWriteRequest(PassageType.TEXTE, "Un texte de loi.", theme.getId(), null));

        assertThat(created.id()).isNotNull();
        assertThat(created.themeId()).isEqualTo(theme.getId());
        assertThat(created.content()).isEqualTo("Un texte de loi.");
        assertThat(created.questionCount()).isZero();

        PassageDto fetched = passageService.getById(created.id());
        assertThat(fetched.type()).isEqualTo(PassageType.TEXTE);
    }

    @Test
    void updateChangesContent() {
        Theme theme = testData.theme();
        PassageDto created = passageService.create(
                new PassageWriteRequest(PassageType.TEXTE, "Initial", theme.getId(), null));

        PassageDto updated = passageService.update(created.id(),
                new PassageWriteRequest(PassageType.TEXTE, "Modifié", theme.getId(), null));
        assertThat(updated.content()).isEqualTo("Modifié");
    }

    @Test
    void createWithAbsentThemeThrowsNotFound() {
        assertThatThrownBy(() -> passageService.create(
                new PassageWriteRequest(PassageType.TEXTE, "x", UUID.randomUUID(), null)))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void getByIdAbsentThrowsNotFound() {
        assertThatThrownBy(() -> passageService.getById(UUID.randomUUID()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void deleteRemovesUnreferencedPassage() {
        Theme theme = testData.theme();
        PassageDto created = passageService.create(
                new PassageWriteRequest(PassageType.TEXTE, "à supprimer", theme.getId(), null));
        passageService.delete(created.id());

        assertThatThrownBy(() -> passageService.getById(created.id()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void deleteIsBlockedWhenReferencedByQuestion() {
        Theme theme = testData.theme();
        Passage passage = testData.passage(PassageType.TEXTE, theme);
        Question q = testData.question(theme);
        q.setPassage(passage);
        questionManager.save(q);

        assertThatThrownBy(() -> passageService.delete(passage.getId()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("question");
    }

    @Test
    void listFiltersByTheme() {
        Theme themeA = testData.theme(com.sejourfr.app.enums.Module.CIVIQUE, "pa", "Theme A");
        Theme themeB = testData.theme(com.sejourfr.app.enums.Module.CIVIQUE, "pb", "Theme B");
        testData.passage(PassageType.TEXTE, themeA);
        testData.passage(PassageType.TEXTE, themeA);
        testData.passage(PassageType.TEXTE, themeB);

        List<PassageDto> forA = passageService.list(themeA.getId());
        assertThat(forA).hasSize(2);
        assertThat(forA).allMatch(p -> p.themeId().equals(themeA.getId()));
    }
}
