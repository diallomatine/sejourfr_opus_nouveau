package com.sejourfr.app.service.activity;

import com.sejourfr.app.dto.ActivityPlatformCount;
import com.sejourfr.app.dto.AdminActivityLiveResponse;
import com.sejourfr.app.dto.AdminActivityResponse;
import com.sejourfr.app.dto.AdminActivityResponse.PlatformRow;
import com.sejourfr.app.dto.AdminActivityResponse.ScreenRow;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.SuiviIndicator;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.MutableClock;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.util.FenetreMesure;
import com.sejourfr.app.util.PeriodeAdmin;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.sql.Date;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZonedDateTime;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Chiffres de l'ecran « Activite »</b>, lus a travers le vrai service : en
 * ligne (fenetre exacte, multi-plateforme compte une fois), actifs de la
 * periode, connexions, ecrans (vues, uniques, top et « autres » calcules en
 * SQL, non declares), comptes internes, et {@code null} avant la date de debut
 * de mesure (periode a cheval, D117). Septembre 2025, heure d'ete (UTC+2).
 */
class ActivityScenariosIT extends AbstractIntegrationTest {

    private static final LocalDate D10 = LocalDate.of(2025, 9, 10);
    private static final LocalDate D11 = LocalDate.of(2025, 9, 11);
    private static final LocalDate D12 = LocalDate.of(2025, 9, 12);
    private static final PeriodeAdmin PERIODE = new PeriodeAdmin(null, new FenetreMesure(D10, D12));
    private static final Instant MAINTENANT = Instant.parse("2026-10-03T08:00:00Z");

    @Autowired private ActivityService service;
    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager em;
    @Autowired private MutableClock clock;

    @AfterEach
    void reset() {
        clock.reset();
    }

    // ------------------------------------------------------------------------
    // En ligne maintenant
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("En ligne : fenêtre de 180 s exacte, multi-plateforme compté une fois, internes exclus")
    void enLigne() {
        clock.set(MAINTENANT);
        LocalDate today = LocalDate.of(2026, 10, 3);
        User a = data.user();
        User b = data.user();
        User c = data.user();
        User e = data.user();
        User interne = interne(data.user());
        presence(a, today, "WEB", MAINTENANT.minusSeconds(30));
        presence(a, today, "IOS", MAINTENANT.minusSeconds(100));
        presence(b, today, "ANDROID", MAINTENANT.minusSeconds(180));
        presence(c, today, "WEB", MAINTENANT.minusSeconds(181));
        presence(e, today, "MOBILE", MAINTENANT.minusSeconds(60));
        presence(interne, today, "WEB", MAINTENANT.minusSeconds(10));

        AdminActivityLiveResponse r = service.live(false, LocalDate.of(2026, 1, 1));

        assertThat(r.windowSeconds()).isEqualTo(180);
        assertThat(r.total()).isEqualTo(3L);
        assertThat(r.multiPlatformUsers()).isEqualTo(1L);
        assertThat(valeurs(r.byPlatform())).containsExactly(1L, 1L, 1L, 1L, 0L);
        assertThat(r.byPlatform()).extracting(ActivityPlatformCount::label)
                .containsExactly("Web", "iOS", "Android", "App — système inconnu", "Non déclarée");
        assertThat(r.byPlatform()).extracting(ActivityPlatformCount::displayed)
                .containsExactly(true, true, true, true, false);

        AdminActivityLiveResponse avecInternes = service.live(true, LocalDate.of(2026, 1, 1));
        assertThat(avecInternes.total()).isEqualTo(4L);
        assertThat(avecInternes.byPlatform().getFirst().value()).isEqualTo(2L);
        assertThat(avecInternes.byPlatform().getLast().displayed()).isTrue();
    }

    @Test
    @DisplayName("En ligne avant la date de début de mesure : null, jamais 0")
    void enLigneNonMesure() {
        clock.set(MAINTENANT);
        for (LocalDate debut : new LocalDate[]{null, LocalDate.of(2026, 10, 4)}) {
            AdminActivityLiveResponse r = service.live(false, debut);
            assertThat(r.total()).isNull();
            assertThat(r.multiPlatformUsers()).isNull();
            assertThat(valeurs(r.byPlatform())).containsOnlyNulls();
        }
    }

    // ------------------------------------------------------------------------
    // Periode
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Actifs, connexions et répartition par plateforme sur une période, tendance servie")
    void periode() {
        User a = data.user();
        User b = data.user();
        User interne = interne(data.user());
        jourActif(a, D10, "WEB");
        jourActif(a, D11, "IOS");
        jourActif(b, D11, "ANDROID");
        jourActif(interne, D10, "WEB");
        jourActif(a, LocalDate.of(2025, 9, 8), "WEB"); // periode precedente
        connexion(a, paris(D10, 10), "LOGIN", "LOCAL", "WEB");
        connexion(a, paris(D11, 10), "LOGIN", "GOOGLE", "IOS");
        connexion(b, paris(D11, 11), "SIGNUP", "APPLE", "ANDROID");
        connexion(interne, paris(D11, 12), "LOGIN", "LOCAL", "WEB");

        AdminActivityResponse r = service.compute(PERIODE, false, tousMesures());

        assertThat(r.window().previousFrom()).isEqualTo(LocalDate.of(2025, 9, 7));
        assertThat(r.activeUsers().measuredSince()).isEqualTo(D10);
        assertThat(r.activeUsers().total().value()).isEqualTo(2L);
        assertThat(r.activeUsers().total().previous()).isEqualTo(1L);
        assertThat(r.activeUsers().total().deltaPct()).isEqualTo(100.0);
        assertThat(r.activeUsers().multiPlatformUsers()).isEqualTo(1L);
        assertThat(r.activeUsers().daily()).extracting(AdminActivityResponse.DailyPoint::day)
                .containsExactly(D10, D11, D12);
        assertThat(r.activeUsers().daily()).extracting(AdminActivityResponse.DailyPoint::total)
                .containsExactly(1L, 2L, 0L);
        assertThat(valeurs(r.activeUsers().daily().get(1).byPlatform())).containsExactly(0L, 1L, 1L, 0L, 0L);

        assertThat(r.logins().uniqueUsers().value()).isEqualTo(2L);
        assertThat(r.logins().uniqueUsers().previous()).isZero();
        assertThat(r.logins().uniqueUsers().deltaPct()).isNull();
        assertThat(r.logins().total()).isEqualTo(3L);
        assertThat(r.logins().signups()).isEqualTo(1L);
        assertThat(r.logins().byMethod()).extracting(AdminActivityResponse.MethodCount::label)
                .containsExactly("E-mail", "Google", "Apple");
        assertThat(r.logins().byMethod()).extracting(AdminActivityResponse.MethodCount::value)
                .containsExactly(1L, 1L, 1L);

        assertThat(r.platforms()).extracting(PlatformRow::platform).containsExactly(ClientPlatform.values());
        PlatformRow web = r.platforms().getFirst();
        assertThat(web.activeUsers()).isEqualTo(1L);
        assertThat(web.loggedInUsers()).isEqualTo(1L);
        assertThat(web.logins()).isEqualTo(1L);
        assertThat(r.platforms().get(3).activeUsers()).isZero();

        AdminActivityResponse avecInternes = service.compute(PERIODE, true, tousMesures());
        assertThat(avecInternes.activeUsers().total().value()).isEqualTo(3L);
        assertThat(avecInternes.logins().total()).isEqualTo(4L);
    }

    @Test
    @DisplayName("Écrans : vues, visiteurs et comptes uniques par onglet ; non déclarés à part ; autres événements ignorés")
    void ecrans() {
        User a = data.user();
        User interne = interne(data.user());
        UUID anon1 = UUID.randomUUID();
        UUID anon2 = UUID.randomUUID();
        UUID anonApp = UUID.randomUUID();
        vue("WEB", "/plan", anon1, a, paris(D10, 9));
        vue("WEB", "/plan", anon1, a, paris(D10, 10));
        vue("WEB", "/plan", anon2, null, paris(D11, 9));
        vue("WEB", "/dashboard", anon2, null, paris(D11, 10));
        vue("WEB", null, anon1, null, paris(D11, 11));
        vue("WEB", null, anon1, null, paris(D11, 12));
        vue("IOS", "/plan", anonApp, a, paris(D11, 9));
        vue("ANDROID", "/plan", UUID.randomUUID(), null, paris(D11, 9));
        vue("MOBILE", "/home", UUID.randomUUID(), null, paris(D12, 9));
        vue("WEB", "/plan", UUID.randomUUID(), interne, paris(D12, 9));
        evenement("LANDING_VIEWED", "WEB", "/plan", anon2, null, paris(D12, 9));

        AdminActivityResponse r = service.compute(PERIODE, false, tousMesures());

        AdminActivityResponse.ScreenTable web = r.screens().web();
        assertThat(web.topLimit()).isEqualTo(20);
        assertThat(web.rows()).extracting(ScreenRow::path).containsExactly("/plan", "/dashboard");
        ScreenRow plan = web.rows().getFirst();
        assertThat(plan.label()).isEqualTo("Plan");
        assertThat(plan.views()).isEqualTo(3);
        assertThat(plan.uniqueVisitors()).isEqualTo(2);
        assertThat(plan.uniqueUsers()).isEqualTo(1);
        assertThat(plan.ios()).isNull();
        assertThat(web.rows().get(1).label()).isEqualTo("Accueil");
        assertThat(web.undeclared().views()).isEqualTo(2);
        assertThat(web.undeclared().uniqueVisitors()).isEqualTo(1);
        assertThat(web.undeclared().label()).isEqualTo("Écrans non déclarés");
        assertThat(web.otherTracked().views()).isZero();
        assertThat(web.total().views()).isEqualTo(6);
        assertThat(web.total().uniqueVisitors()).isEqualTo(2);

        AdminActivityResponse.ScreenTable app = r.screens().app();
        assertThat(app.rows()).extracting(ScreenRow::path).containsExactly("/plan", "/home");
        assertThat(app.rows().getFirst().ios()).isEqualTo(1L);
        assertThat(app.rows().getFirst().android()).isEqualTo(1L);
        assertThat(app.rows().get(1).label()).isEqualTo("Accueil");
        assertThat(app.rows().get(1).appUnknownSystem()).isEqualTo(1L);
        assertThat(app.total().views()).isEqualTo(3);
        assertThat(app.undeclared().views()).isZero();
    }

    @Test
    @DisplayName("Au-delà du top, les écrans suivis sont regroupés EN SQL : leurs uniques ne s'additionnent pas")
    void autresEcransSuivis() {
        UUID anon = UUID.randomUUID();
        List<String> chemins = List.of("/", "/reussir", "/dashboard", "/connexion", "/inscription", "/diagnostic",
                "/diagnostic/resultat", "/diagnostic-civique", "/diagnostic-civique/resultat", "/plan",
                "/plan/etape/:id", "/plan/domaine/:domaine", "/plan/debloquer", "/plan/progression",
                "/progression/tcf", "/progression/tcf/:epreuve", "/progression/civique",
                "/progression/civique/:theme", "/entrainement", "/entrainement/civique/:theme",
                "/entrainement/tcf/:epreuve", "/entrainement/tcf/ee", "/tarifs");
        for (int i = 0; i < chemins.size(); i++) {
            // Le rang i a (chemins.size() - i) vues : ordre deterministe.
            for (int v = 0; v < chemins.size() - i; v++) vue("WEB", chemins.get(i), anon, null, paris(D10, 9));
        }

        AdminActivityResponse.ScreenTable web = service.compute(PERIODE, false, tousMesures()).screens().web();

        assertThat(web.rows()).hasSize(20);
        assertThat(web.rows().getFirst().path()).isEqualTo("/");
        assertThat(web.otherTracked().views()).isEqualTo(3 + 2 + 1);
        assertThat(web.otherTracked().uniqueVisitors()).isEqualTo(1);
        assertThat(web.otherTracked().label()).isEqualTo("Autres écrans suivis");
    }

    @Test
    @DisplayName("Période à cheval sur la date de début : lue depuis cette date ; non mesuré ⇒ null partout")
    void debutDeMesure() {
        User a = data.user();
        User b = data.user();
        jourActif(a, D10, "WEB");
        jourActif(b, D11, "WEB");
        connexion(a, paris(D10, 10), "LOGIN", "LOCAL", "WEB");
        vue("IOS", "/plan", UUID.randomUUID(), a, paris(D11, 9));
        Map<SuiviIndicator, LocalDate> starts = new EnumMap<>(SuiviIndicator.class);
        starts.put(SuiviIndicator.ACTIVE_USERS, D11);
        starts.put(SuiviIndicator.LOGINS, null);
        starts.put(SuiviIndicator.SCREEN_VIEWS_WEB, LocalDate.of(2020, 1, 1));
        starts.put(SuiviIndicator.SCREEN_VIEWS_APP, null);

        AdminActivityResponse r = service.compute(PERIODE, false, starts);

        assertThat(r.activeUsers().measuredSince()).isEqualTo(D11);
        assertThat(r.activeUsers().total().value()).isEqualTo(1L);
        assertThat(r.activeUsers().total().previous()).isNull();
        assertThat(r.activeUsers().daily()).extracting(AdminActivityResponse.DailyPoint::total)
                .containsExactly(null, 1L, 0L);
        assertThat(valeurs(r.activeUsers().daily().getFirst().byPlatform())).containsOnlyNulls();

        assertThat(r.logins().measuredSince()).isNull();
        assertThat(r.logins().uniqueUsers().value()).isNull();
        assertThat(r.logins().total()).isNull();
        assertThat(r.logins().byMethod()).extracting(AdminActivityResponse.MethodCount::value).containsOnlyNulls();
        assertThat(r.platforms()).extracting(PlatformRow::logins).containsOnlyNulls();
        assertThat(r.platforms().getFirst().activeUsers()).isEqualTo(1L);

        assertThat(r.screens().web().measuredSince()).isEqualTo(D10);
        assertThat(r.screens().web().total().views()).isZero();
        assertThat(r.screens().app().measuredSince()).isNull();
        assertThat(r.screens().app().rows()).isEmpty();
        assertThat(r.screens().app().total()).isNull();
        assertThat(r.measurementStart()).containsOnlyKeys(SuiviIndicator.ACTIVE_USERS, SuiviIndicator.LOGINS,
                SuiviIndicator.SCREEN_VIEWS_WEB, SuiviIndicator.SCREEN_VIEWS_APP);
    }

    // ------------------------------------------------------------------------
    // Semis
    // ------------------------------------------------------------------------

    static Map<SuiviIndicator, LocalDate> tousMesures() {
        Map<SuiviIndicator, LocalDate> starts = new EnumMap<>(SuiviIndicator.class);
        for (SuiviIndicator indicator : SuiviIndicator.values()) starts.put(indicator, LocalDate.of(2020, 1, 1));
        return starts;
    }

    private static List<Long> valeurs(List<ActivityPlatformCount> counts) {
        return counts.stream().map(ActivityPlatformCount::value).toList();
    }

    private static Instant paris(LocalDate day, int hour) {
        return ZonedDateTime.of(day.atTime(hour, 0), FenetreMesure.PARIS).toInstant();
    }

    private User interne(User user) {
        em.flush();
        jdbc.update("UPDATE users SET is_internal = true WHERE id = ?", user.getId());
        return user;
    }

    private void presence(User user, LocalDate day, String platform, Instant lastSeen) {
        em.flush();
        jdbc.update("INSERT INTO user_activity_day (user_id, day, platform, first_seen_at, last_seen_at) "
                        + "VALUES (?, ?, ?, ?, ?)", user.getId(), Date.valueOf(day), platform,
                Timestamp.from(lastSeen.minusSeconds(3600)), Timestamp.from(lastSeen));
    }

    private void jourActif(User user, LocalDate day, String platform) {
        presence(user, day, platform, paris(day, 12));
    }

    private void connexion(User user, Instant at, String kind, String method, String platform) {
        em.flush();
        jdbc.update("INSERT INTO user_login_event (id, user_id, occurred_at, kind, auth_method, platform) "
                + "VALUES (?, ?, ?, ?, ?, ?)", UUID.randomUUID(), user.getId(), Timestamp.from(at), kind, method,
                platform);
    }

    private void vue(String platform, String path, UUID anon, User user, Instant at) {
        evenement("SCREEN_VIEWED", platform, path, anon, user, at);
    }

    private void evenement(String event, String platform, String path, UUID anon, User user, Instant at) {
        em.flush();
        boolean internal = user != null && Boolean.TRUE.equals(jdbc.queryForObject(
                "SELECT is_internal FROM users WHERE id = ?", Boolean.class, user.getId()));
        jdbc.update("""
                INSERT INTO analytics_visitor (anonymous_id, first_seen_at, last_seen_at, ft_source, lt_source,
                                               lt_seen_at, device_type, platform)
                VALUES (?, ?, ?, 'direct', 'direct', ?, 'DESKTOP_WEB', 'WEB') ON CONFLICT DO NOTHING""",
                anon, Timestamp.from(at), Timestamp.from(at), Timestamp.from(at));
        jdbc.update("""
                INSERT INTO analytics_event (id, event, occurred_at, anonymous_id, session_id, user_id, path,
                                             properties, event_id, received_at, platform, is_internal)
                VALUES (?, ?, ?, ?, ?, ?, ?, '{}'::jsonb, ?, ?, ?, ?)""",
                UUID.randomUUID(), event, Timestamp.from(at), anon, UUID.randomUUID(),
                user == null ? null : user.getId(), path, UUID.randomUUID(), Timestamp.from(at), platform, internal);
    }
}
