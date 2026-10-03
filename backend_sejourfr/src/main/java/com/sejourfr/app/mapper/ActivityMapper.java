package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ActivityPlatformCount;
import com.sejourfr.app.dto.AdminActivityLiveResponse;
import com.sejourfr.app.dto.AdminActivityResponse;
import com.sejourfr.app.dto.AdminActivityResponse.ActiveUsers;
import com.sejourfr.app.dto.AdminActivityResponse.DailyPoint;
import com.sejourfr.app.dto.AdminActivityResponse.Kpi;
import com.sejourfr.app.dto.AdminActivityResponse.Logins;
import com.sejourfr.app.dto.AdminActivityResponse.MethodCount;
import com.sejourfr.app.dto.AdminActivityResponse.PlatformRow;
import com.sejourfr.app.dto.AdminActivityResponse.ScreenRow;
import com.sejourfr.app.dto.AdminActivityResponse.ScreenRowKind;
import com.sejourfr.app.dto.AdminActivityResponse.ScreenTable;
import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.SuiviIndicator;
import com.sejourfr.app.enums.SuiviPeriodPreset;
import com.sejourfr.app.enums.TrackedScreen;
import com.sejourfr.app.manager.ActivityReadManager;
import com.sejourfr.app.repository.ActivityReadRepository.ActiveCell;
import com.sejourfr.app.repository.ActivityReadRepository.LiveCell;
import com.sejourfr.app.repository.ActivityReadRepository.LoginCell;
import com.sejourfr.app.repository.ActivityReadRepository.ScreenCell;
import com.sejourfr.app.util.FenetreMesure;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

/**
 * Construit les reponses de l'ecran « Activite » depuis les agregats SQL — pur :
 * aucune lecture, aucune horloge. 🛑 Un indicateur non mesure vaut {@code null},
 * jamais 0 ; une somme mesuree mais vide vaut 0. Tendances et libelles par les
 * memes autorites que Suivi ({@link SuiviMapper#delta}, {@link ClientPlatform#getLabel}).
 */
@Component
public class ActivityMapper {

    static final String OTHER = "~OTHER";
    static final String UNDECLARED = "~UNDECLARED";
    static final String TOTAL = "~TOTAL";

    static final String LABEL_OTHER = "Autres écrans suivis";
    static final String LABEL_UNDECLARED = "Écrans non déclarés";
    static final String LABEL_TOTAL = "Total";

    // ------------------------------------------------------------------------
    // Direct
    // ------------------------------------------------------------------------

    public AdminActivityLiveResponse toLive(Instant at, int windowSeconds, boolean includeInternal,
                                            LocalDate measurementStart, boolean measured, List<LiveCell> cells) {
        Map<ClientPlatform, Long> byPlatform = new EnumMap<>(ClientPlatform.class);
        long total = 0;
        long multi = 0;
        for (LiveCell c : cells) {
            switch (c.getKind()) {
                case "PLATFORM" -> byPlatform.put(ClientPlatform.valueOf(c.getPlatform()), c.getN());
                case "TOTAL" -> total = c.getN();
                case "MULTI" -> multi = c.getN();
                default -> { }
            }
        }
        return new AdminActivityLiveResponse(at, windowSeconds, includeInternal, measurementStart,
                measured ? total : null, measured ? multi : null,
                platformCounts(includeInternal, p -> measured ? byPlatform.getOrDefault(p, 0L) : null));
    }

    // ------------------------------------------------------------------------
    // Periode
    // ------------------------------------------------------------------------

    public AdminActivityResponse toResponse(SuiviPeriodPreset preset, FenetreMesure window, FenetreMesure previous,
                                            Instant generatedAt, boolean includeInternal,
                                            Map<SuiviIndicator, LocalDate> starts, SuiviMapper.Mesure mesure,
                                            ActivityReadManager.Lectures l, int screenTop) {
        LocalDate activeSince = mesure.since(SuiviIndicator.ACTIVE_USERS);
        boolean activePrev = mesure.before(SuiviIndicator.ACTIVE_USERS);
        LocalDate loginsSince = mesure.since(SuiviIndicator.LOGINS);
        boolean loginsPrev = mesure.before(SuiviIndicator.LOGINS);

        Map<String, Long> activeCur = new HashMap<>();
        Map<String, Long> activePrevCells = new HashMap<>();
        Map<LocalDate, Map<String, Long>> daily = new HashMap<>();
        Long multiCur = 0L;
        for (ActiveCell c : l.active()) {
            String key = c.getPlatform() == null ? TOTAL : c.getPlatform();
            switch (c.getKind()) {
                case "PER" -> ("CUR".equals(c.getPer()) ? activeCur : activePrevCells).put(key, c.getN());
                case "DAY" -> daily.computeIfAbsent(LocalDate.parse(c.getDay()), d -> new HashMap<>())
                        .put(key, c.getN());
                case "MULTI" -> {
                    if ("CUR".equals(c.getPer())) multiCur = c.getN();
                }
                default -> { }
            }
        }

        Long activeTotal = activeSince != null ? activeCur.getOrDefault(TOTAL, 0L) : null;
        Long activeTotalPrev = activePrev ? activePrevCells.getOrDefault(TOTAL, 0L) : null;
        List<DailyPoint> points = new ArrayList<>(window.days());
        for (LocalDate day = window.from(); !day.isAfter(window.to()); day = day.plusDays(1)) {
            boolean measured = activeSince != null && !day.isBefore(activeSince);
            Map<String, Long> cells = daily.getOrDefault(day, Map.of());
            points.add(new DailyPoint(day, measured ? cells.getOrDefault(TOTAL, 0L) : null,
                    platformCounts(includeInternal, p -> measured ? cells.getOrDefault(p.name(), 0L) : null)));
        }
        ActiveUsers activeUsers = new ActiveUsers(activeSince,
                new Kpi(activeTotal, activeTotalPrev, SuiviMapper.delta(activeTotal, activeTotalPrev)),
                activeSince != null ? multiCur : null, points);

        Map<String, LoginCell> loginsCur = new HashMap<>();
        Map<String, LoginCell> loginsPrevCells = new HashMap<>();
        for (LoginCell c : l.logins()) {
            String key = c.getPlatform() == null ? TOTAL : c.getPlatform();
            ("CUR".equals(c.getPer()) ? loginsCur : loginsPrevCells).put(key, c);
        }
        boolean loginsMeasured = loginsSince != null;
        LoginCell all = loginsCur.get(TOTAL);
        LoginCell allPrev = loginsPrevCells.get(TOTAL);
        Long unique = loginsMeasured ? (all == null ? 0L : all.getUniqueUsers()) : null;
        Long uniquePrev = loginsPrev ? (allPrev == null ? 0L : allPrev.getUniqueUsers()) : null;
        List<MethodCount> methods = new ArrayList<>();
        for (AuthProvider method : AuthProvider.values()) {
            Long n = null;
            if (loginsMeasured) {
                n = all == null ? 0L : switch (method) {
                    case LOCAL -> all.getLocal();
                    case GOOGLE -> all.getGoogle();
                    case APPLE -> all.getApple();
                };
            }
            methods.add(new MethodCount(method, method.getLabel(), n));
        }
        Logins logins = new Logins(loginsSince, new Kpi(unique, uniquePrev, SuiviMapper.delta(unique, uniquePrev)),
                loginsMeasured ? (all == null ? 0L : all.getTotal()) : null,
                loginsMeasured ? (all == null ? 0L : all.getSignups()) : null, methods);

        List<PlatformRow> platforms = new ArrayList<>();
        for (ClientPlatform p : ClientPlatform.values()) {
            LoginCell lc = loginsCur.get(p.name());
            platforms.add(new PlatformRow(p, p.getLabel(), displayed(p, includeInternal),
                    activeSince != null ? activeCur.getOrDefault(p.name(), 0L) : null,
                    loginsMeasured ? (lc == null ? 0L : lc.getUniqueUsers()) : null,
                    loginsMeasured ? (lc == null ? 0L : lc.getTotal()) : null));
        }

        AdminActivityResponse.Screens screens = new AdminActivityResponse.Screens(
                screenTable("WEB", mesure.since(SuiviIndicator.SCREEN_VIEWS_WEB), l.screens(), screenTop, false),
                screenTable("APP", mesure.since(SuiviIndicator.SCREEN_VIEWS_APP), l.screens(), screenTop, true));

        return new AdminActivityResponse(
                new AdminActivityResponse.Window(preset, window.from(), window.to(), previous.from(), previous.to(),
                        FenetreMesure.PARIS.getId(), generatedAt),
                includeInternal, starts, activeUsers, logins, platforms, screens);
    }

    private ScreenTable screenTable(String side, LocalDate since, List<ScreenCell> cells, int top, boolean app) {
        if (since == null) {
            return new ScreenTable(null, top, List.of(), null, null, null);
        }
        List<ScreenRow> rows = new ArrayList<>();
        ScreenRow other = row(ScreenRowKind.OTHER, null, LABEL_OTHER, null, app);
        ScreenRow undeclared = row(ScreenRowKind.UNDECLARED, null, LABEL_UNDECLARED, null, app);
        ScreenRow total = row(ScreenRowKind.TOTAL, null, LABEL_TOTAL, null, app);
        for (ScreenCell c : cells) {
            if (!side.equals(c.getSide())) continue;
            switch (c.getBucket()) {
                case OTHER -> other = row(ScreenRowKind.OTHER, null, LABEL_OTHER, c, app);
                case UNDECLARED -> undeclared = row(ScreenRowKind.UNDECLARED, null, LABEL_UNDECLARED, c, app);
                case TOTAL -> total = row(ScreenRowKind.TOTAL, null, LABEL_TOTAL, c, app);
                default -> rows.add(row(ScreenRowKind.SCREEN, c.getBucket(), screenLabel(c.getBucket(), app), c, app));
            }
        }
        rows.sort(Comparator.comparingLong(ScreenRow::views).reversed().thenComparing(ScreenRow::path));
        return new ScreenTable(since, top, rows, other, undeclared, total);
    }

    /** Libelle de l'ecran de reference ; un chemin historique sert de libelle a lui-meme. */
    static String screenLabel(String path, boolean app) {
        return TrackedScreen.byPath(path, app).map(TrackedScreen::getLabel).orElse(path);
    }

    private static ScreenRow row(ScreenRowKind kind, String path, String label, ScreenCell c, boolean app) {
        if (c == null) {
            return new ScreenRow(kind, path, label, 0, 0, 0, app ? 0L : null, app ? 0L : null, app ? 0L : null);
        }
        return new ScreenRow(kind, path, label, c.getViews(), c.getUniqueVisitors(), c.getUniqueUsers(),
                app ? c.getIos() : null, app ? c.getAndroid() : null, app ? c.getAppUnknown() : null);
    }

    // ------------------------------------------------------------------------
    // Plateformes
    // ------------------------------------------------------------------------

    /** « Non declaree » n'est affichee qu'avec les comptes internes (N6) : console, scripts. */
    static boolean displayed(ClientPlatform platform, boolean includeInternal) {
        return platform != ClientPlatform.UNKNOWN || includeInternal;
    }

    private static List<ActivityPlatformCount> platformCounts(boolean includeInternal,
                                                              Function<ClientPlatform, Long> value) {
        List<ActivityPlatformCount> rows = new ArrayList<>(ClientPlatform.values().length);
        for (ClientPlatform p : ClientPlatform.values()) {
            rows.add(new ActivityPlatformCount(p, p.getLabel(), displayed(p, includeInternal), value.apply(p)));
        }
        return rows;
    }
}
