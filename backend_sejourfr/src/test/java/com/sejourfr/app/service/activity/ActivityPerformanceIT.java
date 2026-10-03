package com.sejourfr.app.service.activity;

import com.sejourfr.app.dto.AdminActivityResponse;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.MutableClock;
import com.sejourfr.app.util.FenetreMesure;
import com.sejourfr.app.util.PeriodeAdmin;
import jakarta.persistence.EntityManager;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.time.Instant;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Cout de l'ecran « Activite »</b> : trois requetes pour une periode, une
 * pour le direct, constantes (egalite : la seule facon d'attraper un N+1), et
 * moins d'une seconde sur un mois realiste — 2 000 comptes, 30 000 jours
 * d'activite, 6 000 connexions, 60 000 vues d'ecran.
 */
class ActivityPerformanceIT extends AbstractIntegrationTest {

    private static final long SEUIL_MS = 1_000;
    private static final PeriodeAdmin MOIS = new PeriodeAdmin(null,
            new FenetreMesure(LocalDate.of(2025, 9, 1), LocalDate.of(2025, 9, 30)));

    @Autowired private ActivityService service;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager em;
    @Autowired private MutableClock clock;

    @AfterEach
    void reset() {
        clock.reset();
    }

    @Test
    @DisplayName("Trois requêtes par période, une pour le direct ; moins d'une seconde sur un mois réaliste")
    void coutEtTempsDeReponse() {
        semer();
        em.flush();
        em.clear();
        clock.set(Instant.parse("2025-09-30T10:00:00Z"));

        Statistics stats = statistiques();
        AdminActivityResponse r = service.compute(MOIS, false, ActivityScenariosIT.tousMesures());
        assertThat(stats.getPrepareStatementCount()).isEqualTo(3);
        stats.clear();
        service.compute(MOIS, true, ActivityScenariosIT.tousMesures());
        assertThat(stats.getPrepareStatementCount()).isEqualTo(3);
        stats.clear();
        service.live(false, LocalDate.of(2020, 1, 1));
        assertThat(stats.getPrepareStatementCount()).isEqualTo(1);

        assertThat(r.activeUsers().total().value()).isGreaterThan(1_000L);
        assertThat(r.logins().total()).isGreaterThan(1_000L);
        assertThat(r.screens().web().total().views()).isGreaterThan(10_000L);

        long meilleur = Long.MAX_VALUE;
        for (int i = 0; i < 3; i++) {
            long debut = System.nanoTime();
            service.compute(MOIS, false, ActivityScenariosIT.tousMesures());
            meilleur = Math.min(meilleur, (System.nanoTime() - debut) / 1_000_000);
        }
        assertThat(meilleur).as("temps de réponse d'une lecture (ms)").isLessThan(SEUIL_MS);
    }

    private void semer() {
        jdbc.execute("""
                INSERT INTO users (id, email, role, is_active, created_at)
                SELECT md5('act' || g)::uuid, 'act' || g || '@test.sejourfr', 'USER', true, now()
                  FROM generate_series(1, 2000) g""");
        jdbc.execute("""
                INSERT INTO user_activity_day (user_id, day, platform, first_seen_at, last_seen_at)
                SELECT md5('act' || (1 + g % 2000))::uuid, date '2025-09-01' + (g / 2000),
                       (ARRAY['WEB','IOS','ANDROID','MOBILE'])[1 + g % 4],
                       timestamptz '2025-09-01 08:00+02' + (g / 2000) * interval '1 day',
                       timestamptz '2025-09-01 09:00+02' + (g / 2000) * interval '1 day'
                  FROM generate_series(0, 29999) g
                ON CONFLICT DO NOTHING""");
        jdbc.execute("""
                INSERT INTO user_login_event (id, user_id, occurred_at, kind, auth_method, platform)
                SELECT gen_random_uuid(), md5('act' || (1 + g % 2000))::uuid,
                       timestamptz '2025-09-01 08:00+02' + (g % 30) * interval '1 day',
                       (ARRAY['LOGIN','SIGNUP'])[1 + g % 2], (ARRAY['LOCAL','GOOGLE','APPLE'])[1 + g % 3],
                       (ARRAY['WEB','IOS','ANDROID','MOBILE'])[1 + g % 4]
                  FROM generate_series(1, 6000) g""");
        jdbc.execute("""
                INSERT INTO analytics_visitor (anonymous_id, first_seen_at, last_seen_at, ft_source, lt_source,
                                               lt_seen_at, device_type, platform)
                SELECT md5('anon' || g)::uuid, timestamptz '2025-09-01 08:00+02', timestamptz '2025-09-30 08:00+02',
                       'direct', 'direct', timestamptz '2025-09-01 08:00+02', 'DESKTOP_WEB', 'WEB'
                  FROM generate_series(0, 4999) g""");
        jdbc.execute("""
                INSERT INTO analytics_event (id, event, occurred_at, anonymous_id, session_id, user_id, path,
                                             properties, event_id, received_at, platform, is_internal)
                SELECT gen_random_uuid(), 'SCREEN_VIEWED',
                       timestamptz '2025-09-01 08:00+02' + (g % 30) * interval '1 day',
                       md5('anon' || (g % 5000))::uuid, gen_random_uuid(),
                       CASE WHEN g % 3 = 0 THEN md5('act' || (1 + g % 2000))::uuid END,
                       (ARRAY['/plan','/dashboard','/entrainement','/profil','/home','/reviser', NULL])[1 + g % 7],
                       '{}'::jsonb, gen_random_uuid(), now(),
                       (ARRAY['WEB','WEB','IOS','ANDROID'])[1 + g % 4], false
                  FROM generate_series(1, 60000) g""");
    }

    private Statistics statistiques() {
        Statistics statistiques = em.getEntityManagerFactory().unwrap(SessionFactory.class).getStatistics();
        statistiques.setStatisticsEnabled(true);
        statistiques.clear();
        return statistiques;
    }
}
