package com.sejourfr.app.service;

import com.sejourfr.app.dto.ThemeDto;
import com.sejourfr.app.dto.ThemeWriteRequest;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * GABARIT « service + DB » : exerce le CRUD réel d'un service transactionnel
 * (persistance + règles métier) sur Postgres embarqué. À privilégier quand le
 * cas d'usage traverse vraiment la base ; sinon préférer un test unitaire mocké.
 */
class ThemeServiceIT extends AbstractIntegrationTest {

    @Autowired
    private ThemeService themeService;

    private static ThemeWriteRequest req(String code) {
        return new ThemeWriteRequest(Module.CIVIQUE, code, "Institutions", "desc", 3);
    }

    @Test
    void createThenGetById() {
        ThemeDto created = themeService.create(req("INSTITUTIONS"));
        assertThat(created.id()).isNotNull();
        assertThat(created.questionCount()).isZero();

        ThemeDto fetched = themeService.getById(created.id());
        assertThat(fetched.code()).isEqualTo("INSTITUTIONS");
        assertThat(fetched.module()).isEqualTo(Module.CIVIQUE);
        assertThat(fetched.displayOrder()).isEqualTo(3);
    }

    @Test
    void createWithDuplicateCodeIsRejected() {
        themeService.create(req("HISTOIRE"));
        assertThatThrownBy(() -> themeService.create(req("HISTOIRE")))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("HISTOIRE");
    }

    @Test
    void updateChangesFields() {
        ThemeDto created = themeService.create(req("GEO"));
        ThemeDto updated = themeService.update(created.id(),
                new ThemeWriteRequest(Module.CIVIQUE, "GEO", "Géographie", "maj", 9));

        assertThat(updated.name()).isEqualTo("Géographie");
        assertThat(updated.displayOrder()).isEqualTo(9);
    }

    @Test
    void getByIdAbsentThrowsNotFound() {
        assertThatThrownBy(() -> themeService.getById(UUID.randomUUID()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void deleteRemovesTheme() {
        ThemeDto created = themeService.create(req("DROITS"));
        themeService.delete(created.id());

        assertThatThrownBy(() -> themeService.getById(created.id()))
                .isInstanceOf(NotFoundException.class);
    }
}
