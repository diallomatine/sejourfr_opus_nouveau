package com.sejourfr.app.service;

import com.sejourfr.app.dto.ThemeUserResponse;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class PublicThemeServiceIT extends AbstractIntegrationTest {

    @Autowired
    private PublicThemeService publicThemeService;

    @Autowired
    private TestData testData;

    @Test
    void listExposesActiveQuestionCount() {
        Theme theme = testData.theme(Module.CIVIQUE, "pub-theme", "Thème public");
        testData.question(theme);

        List<ThemeUserResponse> themes = publicThemeService.list(Module.CIVIQUE);
        ThemeUserResponse mine = themes.stream()
                .filter(t -> t.id().equals(theme.getId()))
                .findFirst()
                .orElseThrow();

        assertThat(mine.questionCount()).isEqualTo(1);
        assertThat(mine.code()).startsWith("pub-theme");
    }

    @Test
    void listFiltersByModule() {
        Theme tcf = testData.theme(Module.TCF, "pub-tcf", "TCF public");
        testData.theme(Module.CIVIQUE, "pub-civ", "Civique public");

        List<ThemeUserResponse> tcfThemes = publicThemeService.list(Module.TCF);
        assertThat(tcfThemes).extracting(ThemeUserResponse::id).contains(tcf.getId());
        assertThat(tcfThemes).allMatch(t -> t.module() == Module.TCF);
    }
}
