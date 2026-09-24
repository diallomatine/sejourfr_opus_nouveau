package com.sejourfr.app.service.examencivique;

import com.sejourfr.app.dto.CivicThemeExamSlotsDto;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * La grille SERVIE des examens de thème civique (arbitrage du 2026-09-24) :
 * le créneau 1 de chaque thème est ouvert à tous, visiteurs compris ; les
 * suivants aux seuls abonnés Civique. Le front lit ce {@code locked}, il ne le
 * déduit jamais du rang.
 */
class CivicThemeExamSlotsServiceIT extends AbstractIntegrationTest {

    @Autowired CivicThemeExamSlotsService service;
    @Autowired TestData data;
    @Autowired JdbcTemplate jdbc;

    private UUID principes() {
        return jdbc.queryForObject("SELECT id FROM themes WHERE code = 'CIV_PRINCIPES'", UUID.class);
    }

    @Test
    @DisplayName("Visiteur : le créneau 1 ouvert, les 19 autres verrouillés")
    void visiteur() {
        CivicThemeExamSlotsDto dto = service.slots(null, principes());

        assertThat(dto.slots()).hasSize(20);
        assertThat(dto.slots().getFirst()).isEqualTo(new CivicThemeExamSlotsDto.Slot(1, false));
        assertThat(dto.slots().subList(1, 20)).allMatch(CivicThemeExamSlotsDto.Slot::locked);
    }

    @Test
    @DisplayName("Compte gratuit : même grille que le visiteur")
    void compteGratuit() {
        User user = data.user();

        CivicThemeExamSlotsDto dto = service.slots(user.getId(), principes());

        assertThat(dto.slots().getFirst().locked()).isFalse();
        assertThat(dto.slots().subList(1, 20)).allMatch(CivicThemeExamSlotsDto.Slot::locked);
    }

    @Test
    @DisplayName("Abonné : aucun créneau verrouillé")
    void abonne() {
        User user = data.user();
        data.userSubscription(user, data.plan());

        CivicThemeExamSlotsDto dto = service.slots(user.getId(), principes());

        assertThat(dto.slots()).noneMatch(CivicThemeExamSlotsDto.Slot::locked);
    }

    @Test
    @DisplayName("Un thème TCF n'a pas de grille d'examens de thème")
    void themeHorsCivique() {
        Theme tcf = data.theme(Module.TCF, "slots-tcf", "Thème TCF");

        assertThatThrownBy(() -> service.slots(null, tcf.getId()))
                .isInstanceOf(NotFoundException.class);
    }
}
