package com.sejourfr.app.service.analytics;

import com.sejourfr.app.enums.SuiviPeriodPreset;
import com.sejourfr.app.enums.SuiviPlatformFilter;
import com.sejourfr.app.enums.SuiviTypeFilter;
import com.sejourfr.app.util.FenetreMesure;

/**
 * Une lecture du dashboard « Suivi », filtres valides.
 *
 * @param preset {@code null} pour une periode personnalisee
 * @param source groupe de source de la config, {@code null} = toutes
 */
public record SuiviQuery(SuiviPeriodPreset preset, FenetreMesure window, SuiviTypeFilter type,
                         SuiviPlatformFilter platform, String source, boolean includeInternal) {

    /** La periode de comparaison : meme duree, juste avant (aujourd'hui → hier). */
    public FenetreMesure previousWindow() {
        return new FenetreMesure(window.from().minusDays(window.days()), window.from().minusDays(1));
    }
}
