package com.sejourfr.app.service.activity;

import com.sejourfr.app.dto.AdminActivityLiveResponse;
import com.sejourfr.app.dto.AdminActivityResponse;
import com.sejourfr.app.enums.SuiviIndicator;
import com.sejourfr.app.manager.ActivityReadManager;
import com.sejourfr.app.mapper.ActivityMapper;
import com.sejourfr.app.mapper.SuiviMapper;
import com.sejourfr.app.service.analytics.AnalyticsConfig;
import com.sejourfr.app.service.analytics.SuiviService;
import com.sejourfr.app.util.FenetreMesure;
import com.sejourfr.app.util.PeriodeAdmin;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

/**
 * L'ecran « Activite » de la console ({@code /api/admin/analytics/activity} et
 * {@code /live}) : resout la periode (memes presets que Suivi,
 * {@link PeriodeAdmin}), applique les dates de debut de mesure (D117, memes
 * regles que Suivi via {@link SuiviMapper.Mesure}), lit les agregats. Definitions :
 * {@code docs/regles/mesure-audience.md} § « Activite des utilisateurs ».
 */
@Service
@RequiredArgsConstructor
public class ActivityService {

    /** Les indicateurs de l'ecran, dans l'ordre du contrat. */
    static final List<SuiviIndicator> INDICATEURS = List.of(SuiviIndicator.ACTIVE_USERS, SuiviIndicator.LOGINS,
            SuiviIndicator.SCREEN_VIEWS_WEB, SuiviIndicator.SCREEN_VIEWS_APP);

    private final ActivityReadManager readManager;
    private final ActivityMapper mapper;
    private final SuiviService suiviService;
    private final AnalyticsConfig config;
    private final Clock clock;

    /** Comptes en ligne maintenant (D3 : comptes connectes uniquement). */
    public AdminActivityLiveResponse live(boolean includeInternal) {
        return live(includeInternal, measurementStarts().get(SuiviIndicator.ACTIVE_USERS));
    }

    /** Le calcul du direct, date de debut de mesure fournie (tests). */
    public AdminActivityLiveResponse live(boolean includeInternal, LocalDate measurementStart) {
        Instant now = clock.instant();
        LocalDate today = LocalDate.ofInstant(now, FenetreMesure.PARIS);
        int window = config.activity().onlineWindowSeconds();
        boolean measured = measurementStart != null && !measurementStart.isAfter(today);
        return mapper.toLive(now, window, includeInternal, measurementStart, measured,
                readManager.live(now.minus(config.activity().onlineWindow()), today.minusDays(1), includeInternal));
    }

    /**
     * @throws IllegalArgumentException (→ 400) preset inconnu, periode
     *         incoherente, ou {@code preset} fourni avec {@code from}/{@code to}
     */
    public AdminActivityResponse activity(String preset, String from, String to, boolean includeInternal) {
        PeriodeAdmin periode = PeriodeAdmin.resolve(preset, from, to,
                LocalDate.ofInstant(clock.instant(), FenetreMesure.PARIS));
        return compute(periode, includeInternal, measurementStarts());
    }

    /** Le calcul, dates de debut de mesure fournies : les tests lisent le vrai calcul. */
    public AdminActivityResponse compute(PeriodeAdmin periode, boolean includeInternal,
                                         Map<SuiviIndicator, LocalDate> starts) {
        FenetreMesure window = periode.window();
        FenetreMesure previous = window.precedente();
        SuiviMapper.Mesure mesure = new SuiviMapper.Mesure(starts, window.from(), window.to(), previous.from(), false);
        LocalDate rien = window.to().plusDays(1);
        int top = config.activity().screenTopLimit();
        ActivityReadManager.Lectures lectures = readManager.lire(new ActivityReadManager.Requete(
                previous.from(), window.from(), window.to(),
                orElse(mesure.since(SuiviIndicator.ACTIVE_USERS), rien),
                orElse(mesure.since(SuiviIndicator.LOGINS), rien),
                orElse(mesure.since(SuiviIndicator.SCREEN_VIEWS_WEB), rien),
                orElse(mesure.since(SuiviIndicator.SCREEN_VIEWS_APP), rien),
                top, includeInternal));
        return mapper.toResponse(periode.preset(), window, previous, clock.instant(), includeInternal,
                only(starts), mesure, lectures, top);
    }

    /** Dates de debut de mesure des quatre indicateurs de l'ecran (autorite : la config, via Suivi). */
    public Map<SuiviIndicator, LocalDate> measurementStarts() {
        return only(suiviService.measurementStarts());
    }

    private static Map<SuiviIndicator, LocalDate> only(Map<SuiviIndicator, LocalDate> starts) {
        Map<SuiviIndicator, LocalDate> mine = new EnumMap<>(SuiviIndicator.class);
        for (SuiviIndicator indicator : INDICATEURS) mine.put(indicator, starts.get(indicator));
        return mine;
    }

    private static LocalDate orElse(LocalDate value, LocalDate fallback) {
        return value != null ? value : fallback;
    }
}
