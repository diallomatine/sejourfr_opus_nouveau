package com.sejourfr.app.service;

import com.sejourfr.app.dto.ThemeUserResponse;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class ThemeUserServiceIT extends AbstractIntegrationTest {

    @Autowired
    private ThemeUserService themeUserService;

    @Autowired
    private QuestionManager questionManager;

    @Autowired
    private TestData testData;

    @Test
    void listCountsOnlyActiveQuestions() {
        Theme theme = testData.theme(Module.CIVIQUE, "tus-active", "Thème actif");
        testData.question(theme);
        testData.question(theme);
        Question inactive = testData.question(theme);
        inactive.setActive(false);
        questionManager.save(inactive);

        List<ThemeUserResponse> all = themeUserService.list(Module.CIVIQUE);
        ThemeUserResponse mine = all.stream()
                .filter(t -> t.id().equals(theme.getId()))
                .findFirst()
                .orElseThrow();

        assertThat(mine.questionCount()).isEqualTo(2);
        assertThat(mine.module()).isEqualTo(Module.CIVIQUE);
    }

    @Test
    void listFiltersByModule() {
        Theme civique = testData.theme(Module.CIVIQUE, "tus-civ", "Civique");
        Theme tcf = testData.theme(Module.TCF, "tus-tcf", "TCF");

        List<ThemeUserResponse> tcfThemes = themeUserService.list(Module.TCF);
        assertThat(tcfThemes).extracting(ThemeUserResponse::id).contains(tcf.getId());
        assertThat(tcfThemes).extracting(ThemeUserResponse::id).doesNotContain(civique.getId());
        assertThat(tcfThemes).allMatch(t -> t.module() == Module.TCF);
    }

    @Test
    void listWithoutModuleReturnsAll() {
        Theme civique = testData.theme(Module.CIVIQUE, "tus-all-civ", "Civique");
        Theme tcf = testData.theme(Module.TCF, "tus-all-tcf", "TCF");

        List<ThemeUserResponse> all = themeUserService.list(null);
        assertThat(all).extracting(ThemeUserResponse::id).contains(civique.getId(), tcf.getId());
    }
}
