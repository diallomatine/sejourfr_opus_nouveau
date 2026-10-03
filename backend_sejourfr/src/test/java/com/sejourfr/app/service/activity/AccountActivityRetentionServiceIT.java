package com.sejourfr.app.service.activity;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.service.analytics.AnalyticsConfig;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.sql.Date;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Retention de l'activite (D6, N5) : 365 j pour les connexions, les jours de
 * presence et les vues d'ecran ({@code SCREEN_VIEWED}) ; les autres evenements
 * d'analytics gardent leur retention generale (395 j).
 */
class AccountActivityRetentionServiceIT extends AbstractIntegrationTest {

    /** 04:10 a Paris le 3 octobre 2027. */
    private static final Instant MAINTENANT = Instant.parse("2027-10-03T02:10:00Z");

    @Autowired private AccountActivityRetentionService retention;
    @Autowired private AnalyticsConfig config;
    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager em;

    private void connexion(User user, Instant at) {
        jdbc.update("INSERT INTO user_login_event (id, user_id, occurred_at, kind, auth_method, platform) "
                + "VALUES (?, ?, ?, 'LOGIN', 'LOCAL', 'WEB')", UUID.randomUUID(), user.getId(), Timestamp.from(at));
    }

    private void jour(User user, LocalDate day) {
        Timestamp at = Timestamp.from(day.atTime(12, 0).toInstant(java.time.ZoneOffset.UTC));
        jdbc.update("INSERT INTO user_activity_day (user_id, day, platform, first_seen_at, last_seen_at) "
                + "VALUES (?, ?, 'WEB', ?, ?)", user.getId(), Date.valueOf(day), at, at);
    }

    private UUID evenement(String event, Instant at) {
        UUID id = UUID.randomUUID();
        UUID anon = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO analytics_visitor (anonymous_id, first_seen_at, last_seen_at, ft_source, lt_source,
                                               lt_seen_at, device_type, platform)
                VALUES (?, ?, ?, 'direct', 'direct', ?, 'DESKTOP_WEB', 'WEB') ON CONFLICT DO NOTHING""",
                anon, Timestamp.from(at), Timestamp.from(at), Timestamp.from(at));
        jdbc.update("""
                INSERT INTO analytics_event (id, event, occurred_at, anonymous_id, session_id, properties,
                                             event_id, received_at, platform, is_internal)
                VALUES (?, ?, ?, ?, ?, '{}'::jsonb, ?, ?, 'WEB', false)""",
                id, event, Timestamp.from(at), anon, UUID.randomUUID(), UUID.randomUUID(),
                Timestamp.from(at));
        return id;
    }

    private long count(String sql, Object... args) {
        return jdbc.queryForObject(sql, Long.class, args);
    }

    @Test
    @DisplayName("Au-delà de 365 j : connexions, jours d'activité et vues d'écran purgés ; le reste demeure")
    void purge365Jours() {
        assertThat(config.activity().retentionDays()).isEqualTo(365);
        User user = data.user();
        em.flush();
        Instant limite = MAINTENANT.minus(Duration.ofDays(365));
        connexion(user, limite.minus(Duration.ofHours(1)));
        connexion(user, limite.plus(Duration.ofHours(1)));
        LocalDate aujourdhui = LocalDate.of(2027, 10, 3);
        jour(user, aujourdhui.minusDays(366));
        jour(user, aujourdhui.minusDays(365));
        UUID vueAncienne = evenement("SCREEN_VIEWED", limite.minus(Duration.ofDays(1)));
        UUID vueRecente = evenement("SCREEN_VIEWED", limite.plus(Duration.ofDays(1)));
        // Un autre evenement de 366 j reste : sa retention est de 395 j.
        UUID landing = evenement("LANDING_VIEWED", limite.minus(Duration.ofDays(1)));

        int purges = retention.purge(MAINTENANT);

        assertThat(purges).isEqualTo(3);
        assertThat(count("SELECT count(*) FROM user_login_event WHERE user_id = ?", user.getId())).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT min(day) FROM user_activity_day WHERE user_id = ?", Date.class,
                user.getId()).toLocalDate()).isEqualTo(aujourdhui.minusDays(365));
        assertThat(count("SELECT count(*) FROM analytics_event WHERE id = ?", vueAncienne)).isZero();
        assertThat(count("SELECT count(*) FROM analytics_event WHERE id = ?", vueRecente)).isEqualTo(1);
        assertThat(count("SELECT count(*) FROM analytics_event WHERE id = ?", landing)).isEqualTo(1);
    }

    @Test
    @DisplayName("Par lots : la passe boucle tant qu'un lot est plein")
    void parLots() {
        User user = data.user();
        em.flush();
        int n = config.purgeBatchSize() + 3;
        jdbc.update("""
                INSERT INTO user_login_event (id, user_id, occurred_at, kind, auth_method, platform)
                SELECT gen_random_uuid(), ?, CAST(? AS timestamptz) - g * interval '1 minute', 'LOGIN', 'LOCAL', 'WEB'
                  FROM generate_series(1, ?) g""", user.getId(), Timestamp.from(MAINTENANT.minus(Duration.ofDays(400))),
                n);

        assertThat(retention.purge(MAINTENANT)).isEqualTo(n);
        assertThat(count("SELECT count(*) FROM user_login_event WHERE user_id = ?", user.getId())).isZero();
    }

    @Test
    @DisplayName("V087 : user_login_event refuse un type hors liste (un refresh n'est pas une connexion)")
    void contraintes() {
        User user = data.user();
        em.flush();
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> jdbc.update(
                "INSERT INTO user_login_event (id, user_id, occurred_at, kind, auth_method, platform) "
                        + "VALUES (?, ?, now(), 'REFRESH', 'LOCAL', 'WEB')", UUID.randomUUID(), user.getId()))
                .isInstanceOf(org.springframework.dao.DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("V087 : user_activity_day refuse une plateforme hors convention ClientPlatform")
    void contraintePlateforme() {
        User user = data.user();
        em.flush();
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> jdbc.update(
                "INSERT INTO user_activity_day (user_id, day, platform, first_seen_at, last_seen_at) "
                        + "VALUES (?, current_date, 'MOBILE_INCONNU', now(), now())", user.getId()))
                .isInstanceOf(org.springframework.dao.DataIntegrityViolationException.class);
    }
}
