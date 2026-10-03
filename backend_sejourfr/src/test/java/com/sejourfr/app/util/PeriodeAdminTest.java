package com.sejourfr.app.util;

import com.sejourfr.app.enums.SuiviPeriodPreset;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/** Periode des consoles de mesure (Suivi, Activite) : une table de presets, les memes refus. */
class PeriodeAdminTest {

    private static final LocalDate AUJOURDHUI = LocalDate.of(2026, 10, 3);

    @Test
    @DisplayName("LAST_30_DAYS = aujourd'hui − 29 → aujourd'hui ; précédente de même durée")
    void trenteJours() {
        PeriodeAdmin p = PeriodeAdmin.resolve("last_30_days", null, null, AUJOURDHUI);
        assertThat(p.preset()).isEqualTo(SuiviPeriodPreset.LAST_30_DAYS);
        assertThat(p.window()).isEqualTo(new FenetreMesure(LocalDate.of(2026, 9, 4), AUJOURDHUI));
        assertThat(p.window().days()).isEqualTo(30);
        assertThat(p.window().precedente())
                .isEqualTo(new FenetreMesure(LocalDate.of(2026, 8, 5), LocalDate.of(2026, 9, 3)));
    }

    @Test
    @DisplayName("Les autres presets, et TODAY par défaut")
    void presets() {
        assertThat(PeriodeAdmin.resolve(null, null, null, AUJOURDHUI).window())
                .isEqualTo(new FenetreMesure(AUJOURDHUI, AUJOURDHUI));
        assertThat(SuiviPeriodPreset.YESTERDAY.window(AUJOURDHUI).from()).isEqualTo(LocalDate.of(2026, 10, 2));
        assertThat(SuiviPeriodPreset.LAST_7_DAYS.window(AUJOURDHUI).from()).isEqualTo(LocalDate.of(2026, 9, 27));
        assertThat(SuiviPeriodPreset.MONTH.window(AUJOURDHUI).from()).isEqualTo(LocalDate.of(2026, 10, 1));
    }

    @Test
    @DisplayName("Preset et bornes ensemble, ou preset inconnu : refus nommé")
    void refus() {
        assertThatThrownBy(() -> PeriodeAdmin.resolve("TODAY", "2026-09-01", "2026-09-02", AUJOURDHUI))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("pas les deux");
        assertThatThrownBy(() -> PeriodeAdmin.resolve("HIER", null, null, AUJOURDHUI))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("LAST_30_DAYS");
    }
}
