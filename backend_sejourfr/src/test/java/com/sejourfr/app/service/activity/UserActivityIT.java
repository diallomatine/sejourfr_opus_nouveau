package com.sejourfr.app.service.activity;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.MutableClock;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Enregistrement de l'activite (lot 2, D1) a travers la vraie chaine HTTP :
 * filtre JWT → intercepteur → service → upsert. Au plus une ecriture par
 * minute ; plateforme par l'en-tete ; chemins exclus ; jamais d'anonyme.
 */
class UserActivityIT extends AbstractIntegrationTest {

    /** 10:00 a Paris (UTC+2). */
    private static final Instant T0 = Instant.parse("2026-10-03T08:00:00Z");

    @Autowired private MockMvc mvc;
    @Autowired private TestData data;
    @Autowired private AuthTestSupport auth;
    @Autowired private MutableClock clock;
    @Autowired private UserActivityService activityService;
    @Autowired private JdbcTemplate jdbc;

    @BeforeEach
    void horloge() {
        clock.set(T0);
        activityService.resetThrottle();
    }

    @AfterEach
    void reset() {
        clock.reset();
        activityService.resetThrottle();
    }

    private MockHttpServletRequestBuilder presence(User user, String client) {
        MockHttpServletRequestBuilder req = post("/api/me/presence").header("Authorization", auth.bearer(user));
        return client == null ? req : req.header("X-Sejourfr-Client", client);
    }

    private List<Map<String, Object>> lignes(User user) {
        return jdbc.queryForList("SELECT day, platform, first_seen_at, last_seen_at FROM user_activity_day "
                + "WHERE user_id = ? ORDER BY day, platform", user.getId());
    }

    private Instant lastSeen(User user, String platform) {
        return jdbc.queryForObject("SELECT last_seen_at FROM user_activity_day WHERE user_id = ? AND platform = ?",
                Timestamp.class, user.getId(), platform).toInstant();
    }

    @Test
    @DisplayName("Heartbeat : 204 authentifié, une ligne du jour de Paris sur la plateforme déclarée")
    void heartbeatEcritUneLigne() throws Exception {
        User user = data.user();

        mvc.perform(presence(user, "web")).andExpect(status().isNoContent());

        List<Map<String, Object>> rows = lignes(user);
        assertThat(rows).hasSize(1);
        assertThat(rows.getFirst().get("platform")).isEqualTo("WEB");
        assertThat(rows.getFirst().get("day").toString()).isEqualTo("2026-10-03");
        assertThat(lastSeen(user, "WEB")).isEqualTo(T0);
    }

    @Test
    @DisplayName("Heartbeat sans jeton : 401, rien n'est écrit")
    void heartbeatAnonyme() throws Exception {
        mvc.perform(post("/api/me/presence")).andExpect(status().isUnauthorized());
        assertThat(jdbc.queryForObject("SELECT count(*) FROM user_activity_day WHERE last_seen_at = ?", Long.class,
                Timestamp.from(T0))).isZero();
    }

    @Test
    @DisplayName("Plateformes : ios, android, ancienne app « mobile » ⇒ MOBILE, en-tête absent ⇒ UNKNOWN")
    void plateformes() throws Exception {
        User user = data.user();
        for (String client : new String[]{"ios", "android", "mobile", null}) {
            mvc.perform(presence(user, client)).andExpect(status().isNoContent());
        }
        assertThat(lignes(user)).extracting(r -> r.get("platform"))
                .containsExactly("ANDROID", "IOS", "MOBILE", "UNKNOWN");
    }

    @Test
    @DisplayName("Toute requête authentifiée compte, pas seulement le heartbeat")
    void requeteOrdinaire() throws Exception {
        User user = data.user();
        mvc.perform(get("/api/me/stats").header("Authorization", auth.bearer(user))
                .header("X-Sejourfr-Client", "mobile"));
        assertThat(lignes(user)).extracting(r -> r.get("platform")).containsExactly("MOBILE");
    }

    @Test
    @DisplayName("Au plus une écriture par minute : à 59 s rien ne bouge, à 60 s last_seen_at avance")
    void uneEcritureParMinute() throws Exception {
        User user = data.user();
        mvc.perform(presence(user, "web"));

        clock.set(T0.plusSeconds(59));
        mvc.perform(presence(user, "web")).andExpect(status().isNoContent());
        assertThat(lastSeen(user, "WEB")).isEqualTo(T0);

        clock.set(T0.plusSeconds(60));
        mvc.perform(presence(user, "web"));
        assertThat(lastSeen(user, "WEB")).isEqualTo(T0.plusSeconds(60));
        assertThat(lignes(user)).hasSize(1);
        assertThat(((Timestamp) lignes(user).getFirst().get("first_seen_at")).toInstant()).isEqualTo(T0);
    }

    @Test
    @DisplayName("Changement de jour à Paris : une nouvelle ligne, même dans la minute")
    void changementDeJour() throws Exception {
        User user = data.user();
        clock.set(Instant.parse("2026-10-03T21:59:30Z")); // 23:59:30 a Paris
        mvc.perform(presence(user, "ios"));
        clock.set(Instant.parse("2026-10-03T22:00:10Z")); // 00:00:10 le 4
        mvc.perform(presence(user, "ios"));

        assertThat(lignes(user)).extracting(r -> r.get("day").toString())
                .containsExactly("2026-10-03", "2026-10-04");
    }

    @Test
    @DisplayName("Chemins exclus : file d'analytics et refresh ne comptent pas")
    void cheminsExclus() throws Exception {
        User user = data.user();
        mvc.perform(post("/api/public/analytics/events/batch").header("Authorization", auth.bearer(user))
                .header("X-Sejourfr-Client", "web").contentType(MediaType.APPLICATION_JSON)
                .content("{\"anonymousId\":\"" + java.util.UUID.randomUUID() + "\",\"sessionId\":\""
                        + java.util.UUID.randomUUID() + "\",\"events\":[]}"));
        mvc.perform(post("/api/auth/refresh").header("Authorization", auth.bearer(user))
                .contentType(MediaType.APPLICATION_JSON).content("{\"refreshToken\":\"x\"}"));

        assertThat(lignes(user)).isEmpty();
    }
}
