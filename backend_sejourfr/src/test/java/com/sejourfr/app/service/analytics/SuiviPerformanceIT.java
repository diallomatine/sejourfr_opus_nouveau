package com.sejourfr.app.service.analytics;

import com.sejourfr.app.dto.AdminSuiviResponse;
import com.sejourfr.app.enums.SuiviPlatformFilter;
import com.sejourfr.app.enums.SuiviTypeFilter;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.util.FenetreMesure;
import jakarta.persistence.EntityManager;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Cout du dashboard « Suivi »</b> : six requetes, constantes, et moins d'une
 * seconde sur un jeu realiste — le seuil du brief §9 au-dela duquel une vue
 * materialisee se discuterait.
 *
 * <p>Jeu seme en SQL ({@code generate_series}) sur un mois : 3 000 comptes,
 * 5 000 visiteurs, 40 000 evenements, 6 000 runs (70 % soumises, un tiers
 * rattachees), 900 achats, 120 remboursements. Soit plusieurs mois d'activite
 * au rythme actuel.
 *
 * <p>Le nombre de requetes se verrouille par une <b>egalite</b> (patron du
 * repo) : c'est la seule facon d'attraper un N+1.
 */
class SuiviPerformanceIT extends AbstractIntegrationTest {

    /** visiteurs, tunnel, activite des runs, achats, remboursements, inscriptions. */
    private static final int BUDGET_REQUETES = 6;
    private static final long SEUIL_MS = 1_000;

    private static final FenetreMesure MOIS = new FenetreMesure(LocalDate.of(2025, 9, 1),
            LocalDate.of(2025, 9, 30));

    @Autowired private SuiviService service;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager em;
    @Autowired private TestData data;

    @Test
    @DisplayName("Six requêtes, quels que soient le volume et les filtres ; moins d'une seconde sur un mois réaliste")
    void coutEtTempsDeReponse() {
        semer();
        em.flush();
        em.clear();

        SuiviQuery tous = new SuiviQuery(null, MOIS, SuiviTypeFilter.ALL, SuiviPlatformFilter.ALL, null, false);
        SuiviQuery filtre = new SuiviQuery(null, MOIS, SuiviTypeFilter.TCF, SuiviPlatformFilter.WEB,
                "instagram", false);

        Statistics stats = statistiques();
        AdminSuiviResponse r = service.compute(tous, SuiviScenariosIT.mesure());
        assertThat(stats.getPrepareStatementCount()).isEqualTo(BUDGET_REQUETES);
        stats.clear();
        service.compute(filtre, SuiviScenariosIT.mesure());
        assertThat(stats.getPrepareStatementCount()).isEqualTo(BUDGET_REQUETES);

        // Le jeu est bien lu : sinon le chronometre mesurerait du vide.
        assertThat(r.funnel().steps().get(0).count()).isGreaterThan(1_000L);
        assertThat(r.kpis().visitors().value()).isGreaterThan(1_000L);
        assertThat(r.kpis().purchases().value()).isGreaterThan(500L);

        long meilleur = Long.MAX_VALUE;
        for (int i = 0; i < 3; i++) {
            long debut = System.nanoTime();
            service.compute(tous, SuiviScenariosIT.mesure());
            service.compute(filtre, SuiviScenariosIT.mesure());
            meilleur = Math.min(meilleur, (System.nanoTime() - debut) / 2_000_000);
        }
        assertThat(meilleur).as("temps de réponse moyen d'une lecture (ms)").isLessThan(SEUIL_MS);
    }

    private void semer() {
        String planId = data.plan().getId().toString();
        em.flush();
        jdbc.execute("""
                INSERT INTO users (id, email, role, is_active, created_at, signup_platform, signup_source,
                                   signup_context)
                SELECT md5('u' || g)::uuid, 'perf' || g || '@test.sejourfr', 'USER', true,
                       timestamptz '2025-09-01 08:00+02' + (g % 30) * interval '1 day',
                       (ARRAY['WEB','IOS','ANDROID'])[1 + g % 3], (ARRAY['instagram','tiktok','direct'])[1 + g % 3],
                       (ARRAY['AFTER_DIAGNOSTIC','OUTSIDE_DIAGNOSTIC'])[1 + g % 2]
                  FROM generate_series(1, 3000) g""");
        jdbc.execute("""
                INSERT INTO analytics_visitor (anonymous_id, first_seen_at, last_seen_at, ft_source, ft_source_raw,
                                               lt_source, lt_seen_at, device_type, platform)
                SELECT md5('v' || g)::uuid, timestamptz '2025-09-01 08:00+02', timestamptz '2025-09-30 08:00+02',
                       (ARRAY['instagram','tiktok','direct','autre'])[1 + g % 4],
                       (ARRAY['instagram','tiktok',NULL,'ig'])[1 + g % 4],
                       'direct', timestamptz '2025-09-01 08:00+02', 'MOBILE_WEB', 'WEB'
                  FROM generate_series(1, 5000) g""");
        jdbc.execute("""
                INSERT INTO analytics_identity (anonymous_id, user_id, linked_at)
                SELECT md5('v' || g)::uuid, md5('u' || g)::uuid, timestamptz '2025-09-02 08:00+02'
                  FROM generate_series(1, 3000) g""");
        jdbc.execute("""
                INSERT INTO diagnostic_run (id, diagnostic_type, platform, anonymous_id, user_id, subject_viewed_at,
                                            submitted_at, submitted_authenticated, claimed_at, claim_kind,
                                            claimed_via, updated_at)
                SELECT md5('r' || g)::uuid,
                       CASE WHEN g % 3 = 0 THEN 'CIVIQUE' ELSE 'QUICK_TCF' END,
                       (ARRAY['WEB','IOS','ANDROID'])[1 + g % 3],
                       md5('v' || (1 + g % 5000))::uuid,
                       CASE WHEN g % 3 = 1 THEN md5('u' || (1 + g % 3000))::uuid END,
                       timestamptz '2025-09-01 09:00+02' + (g % 30) * interval '1 day' + (g % 600) * interval '1 minute',
                       CASE WHEN g % 10 < 7
                            THEN timestamptz '2025-09-01 09:30+02' + (g % 30) * interval '1 day' END,
                       CASE WHEN g % 10 < 7 THEN g % 3 = 1 END,
                       NULL, NULL, NULL, now()
                  FROM generate_series(1, 6000) g""");
        jdbc.execute("""
                UPDATE diagnostic_run SET user_id = md5('u' || (1 + (abs(hashtext(id::text)) % 3000)))::uuid,
                                          claimed_at = submitted_at + interval '1 hour',
                                          claim_kind = CASE WHEN abs(hashtext(id::text)) % 2 = 0 THEN 'SIGNUP'
                                                            ELSE 'LOGIN' END,
                                          claimed_via = 'SAME_DEVICE'
                 WHERE user_id IS NULL AND submitted_at IS NOT NULL AND abs(hashtext(id::text)) % 3 = 0""");
        jdbc.execute("""
                INSERT INTO analytics_event (id, event, occurred_at, anonymous_id, session_id, properties, event_id,
                                             received_at, platform, diagnostic_run_id, is_internal)
                SELECT gen_random_uuid(),
                       (ARRAY['LANDING_VIEWED','DIAGNOSTIC_REPORT_VIEWED','PLAN_OPENED','PLAN_UNLOCK_CLICKED'])[1 + g % 4],
                       timestamptz '2025-09-01 10:00+02' + (g % 30) * interval '1 day' + (g % 300) * interval '1 minute',
                       md5('v' || (1 + g % 5000))::uuid, gen_random_uuid(), '{}'::jsonb, gen_random_uuid(),
                       now(), (ARRAY['WEB','IOS','ANDROID'])[1 + g % 3],
                       CASE WHEN g % 4 > 0 THEN md5('r' || (1 + g % 6000))::uuid END, false
                  FROM generate_series(1, 40000) g""");
        jdbc.execute("""
                INSERT INTO user_subscriptions (id, user_id, plan_id, status, starts_at, ends_at, source,
                                                original_transaction_id, product_id, auto_renew, amount_cents,
                                                currency, amount_eur_cents, fx_rate_to_eur, purchased_at, vat_cents,
                                                provider_fee_cents, net_after_fee_cents, net_ex_vat_cents,
                                                fee_source, revenue_rules_version, origin, diagnostic_run_id,
                                                payment_status)
                SELECT md5('s' || g)::uuid, md5('u' || (1 + g % 3000))::uuid, CAST('""" + planId + """
                ' AS uuid), 'ACTIVE',
                       timestamptz '2025-09-02 12:00+02' + (g % 28) * interval '1 day',
                       timestamptz '2025-10-02 12:00+02' + (g % 28) * interval '1 day',
                       'STRIPE', 'perf_' || g, 'PERF', false, 999, 'EUR', 999, 1,
                       timestamptz '2025-09-02 12:00+02' + (g % 28) * interval '1 day',
                       0, 40, 959, 959, 'ESTIMATED', 1,
                       CASE WHEN g % 2 = 0 THEN 'DIAGNOSTIC_PLAN' ELSE 'UNKNOWN' END,
                       CASE WHEN g % 2 = 0 THEN md5('r' || (1 + g % 6000))::uuid END, 'PAID'
                  FROM generate_series(1, 900) g""");
        jdbc.execute("""
                INSERT INTO payment_refunds (id, subscription_id, provider, provider_refund_id, refunded_amount_cents,
                                             currency, refunded_eur_cents, net_ex_vat_delta_cents,
                                             revenue_rules_version, refunded_at)
                SELECT gen_random_uuid(), md5('s' || (g * 7))::uuid, 'STRIPE', 'perf_re_' || g, 999, 'EUR', 999,
                       -999, 1, timestamptz '2025-09-20 12:00+02'
                  FROM generate_series(1, 120) g""");
        jdbc.execute("ANALYZE");
    }

    private Statistics statistiques() {
        Statistics statistiques = em.getEntityManagerFactory().unwrap(SessionFactory.class).getStatistics();
        statistiques.setStatisticsEnabled(true);
        statistiques.clear();
        return statistiques;
    }
}
