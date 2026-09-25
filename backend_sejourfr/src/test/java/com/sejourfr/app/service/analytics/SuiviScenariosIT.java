package com.sejourfr.app.service.analytics;

import com.sejourfr.app.dto.AdminSuiviResponse;
import com.sejourfr.app.dto.AdminSuiviResponse.FunnelStep;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SuiviIndicator;
import com.sejourfr.app.enums.SuiviPlatformFilter;
import com.sejourfr.app.enums.SuiviTypeFilter;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.util.FenetreMesure;
import com.sejourfr.app.util.TrafficSource;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZonedDateTime;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Scenarios d'acceptation du brief §12 (+ 18, 19, 20), lus A TRAVERS le
 * service de lecture</b> du dashboard « Suivi ». Les ecritures (claim, soumis,
 * webhooks, montants, lots d'evenements) sont deja verrouillees par les lots
 * 2a / 2b ; ici on seme l'etat qu'elles produisent et on verifie ce que
 * l'ecran en lit.
 *
 * <p>Les dates de debut de mesure sont fixees par le test (toutes au
 * 2020-01-01) : la config de production les laisse {@code null} jusqu'au
 * deploiement (D43), ce que verrouille {@code AdminSuiviControllerIT}.
 *
 * <p>Toutes les dates sont en septembre 2025 (heure d'ete, UTC+2), bien avant
 * l'horloge des tests : aucune cohorte n'est « en cours ».
 */
class SuiviScenariosIT extends AbstractIntegrationTest {

    private static final LocalDate D3 = LocalDate.of(2025, 9, 3);

    @Autowired private SuiviService service;
    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private CivicDiagnosticService civicService;
    @Autowired private EntityManager em;

    // ------------------------------------------------------------------------
    // Scenarios
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Scénario 1 — rapport ouvert 7 fois : « Rapport vu » = 1")
    void scenario1RapportVuUneFois() {
        User jean = data.userCreatedAt("direct", ClientPlatform.WEB, paris(D3, 8));
        UUID anon = visitor("direct", paris(D3, 9));
        UUID run = run("QUICK_TCF", anon, jean.getId(), "WEB", paris(D3, 9));
        submit(run, paris(D3, 10), true);
        for (int i = 0; i < 7; i++) event(anon, "DIAGNOSTIC_REPORT_VIEWED", paris(D3, 11 + i), run, null);

        AdminSuiviResponse r = lire(jour(D3), SuiviTypeFilter.ALL);

        assertThat(counts(r)).containsExactly(1L, 1L, 1L, 1L, 0L, 0L, 0L);
        assertThat(step(r, 4).pctFromPrevious()).isEqualTo(100.0);
        assertThat(step(r, 5).pctFromPrevious()).isEqualTo(0.0);
        assertThat(step(r, 5).pctOfFirst()).isEqualTo(0.0);
    }

    @Test
    @DisplayName("Scénario 2 — Ahmed fait TCF et Civique : Tous = 1, TCF = 1, Civique = 1 à chaque étape")
    void scenario2PersonneDistincte() {
        User ahmed = data.userCreatedAt("direct", ClientPlatform.WEB, paris(D3, 8));
        UUID anon = visitor("direct", paris(D3, 8));
        Plan plan = data.plan();
        for (String type : List.of("QUICK_TCF", "CIVIQUE")) {
            UUID run = run(type, anon, ahmed.getId(), "WEB", paris(D3, 9));
            submit(run, paris(D3, 10), true);
            event(anon, "DIAGNOSTIC_REPORT_VIEWED", paris(D3, 11), run, null);
            event(anon, "PLAN_OPENED", paris(D3, 12), run, null);
            event(anon, "PLAN_UNLOCK_CLICKED", paris(D3, 13), run, null);
            purchase(ahmed, plan, "STRIPE", paris(D3, 14), 999, 959, run, "DIAGNOSTIC_PLAN");
        }

        AdminSuiviResponse tous = lire(jour(D3), SuiviTypeFilter.ALL);
        AdminSuiviResponse tcf = lire(jour(D3), SuiviTypeFilter.TCF);
        AdminSuiviResponse civique = lire(jour(D3), SuiviTypeFilter.CIVIQUE);

        assertThat(counts(tous)).containsExactly(1L, 1L, 1L, 1L, 1L, 1L, 1L);
        assertThat(counts(tcf)).containsExactly(1L, 1L, 1L, 1L, 1L, 1L, 1L);
        assertThat(counts(civique)).containsExactly(1L, 1L, 1L, 1L, 1L, 1L, 1L);
        // Le CA net cohorte, lui, additionne les deux achats : ce sont deux achats.
        assertThat(tous.funnel().cohortNetExVatCents()).isEqualTo(1918L);
        assertThat(tcf.funnel().cohortNetExVatCents()).isEqualTo(959L);
        // Le bloc « par type » ignore le filtre et montre toujours les deux colonnes.
        assertThat(tcf.byType()).extracting(AdminSuiviResponse.TypeRow::subjectViewed).containsExactly(1L, 1L);
        // KPI de période : une personne, deux soumissions brutes.
        assertThat(tous.kpis().submitted().value()).isEqualTo(1L);
        assertThat(tous.activity().submittedRaw()).isEqualTo(2L);
        assertThat(tous.kpis().purchases().value()).isEqualTo(2L);
    }

    @Test
    @DisplayName("Scénario 3 — anonyme puis inscription sur le même navigateur : « inscrit après diagnostic »")
    void scenario3InscritApresDiagnostic() {
        UUID anon = visitor("direct", paris(D3, 9));
        UUID run = run("QUICK_TCF", anon, null, "WEB", paris(D3, 9));
        submit(run, paris(D3, 10), false);
        User user = data.userCreatedAt("direct", ClientPlatform.WEB, paris(D3, 11));
        claim(run, user, "SIGNUP", paris(D3, 11));
        signupContext(user, "AFTER_DIAGNOSTIC", "QUICK_TCF", run);

        AdminSuiviResponse r = lire(jour(D3), SuiviTypeFilter.ALL);

        assertThat(r.funnel().attached().signedUpAfter()).isEqualTo(1L);
        assertThat(r.funnel().attached().alreadyAuthenticated()).isZero();
        assertThat(r.signups().afterDiagnostic().total()).isEqualTo(1L);
        assertThat(r.signups().afterDiagnostic().tcf()).isEqualTo(1L);
        assertThat(r.signups().outsideDiagnostic()).isZero();
        assertThat(r.ratios().diagnosticToSignupPct()).isEqualTo(100.0);
        assertThat(r.activity().anonymousSubmittedNeverAttached()).isZero();
    }

    @Test
    @DisplayName("Scénario 5 — même cas sans jeton : non rattaché, OUTSIDE_DIAGNOSTIC, « jamais rattaché »")
    void scenario5SansJeton() {
        UUID anon = visitor("direct", paris(D3, 9));
        UUID run = run("QUICK_TCF", anon, null, "WEB", paris(D3, 9));
        submit(run, paris(D3, 10), false);
        User user = data.userCreatedAt("direct", ClientPlatform.IOS, paris(D3, 11));
        signupContext(user, "OUTSIDE_DIAGNOSTIC", null, null);

        AdminSuiviResponse r = lire(jour(D3), SuiviTypeFilter.ALL);

        assertThat(counts(r)).containsExactly(1L, 1L, 0L, 0L, 0L, 0L, 0L);
        assertThat(r.signups().outsideDiagnostic()).isEqualTo(1L);
        assertThat(r.signups().afterDiagnostic().total()).isZero();
        assertThat(r.signups().byPlatform().ios()).isEqualTo(1L);
        assertThat(r.activity().anonymousSubmittedNeverAttached()).isEqualTo(1L);
        assertThat(r.ratios().diagnosticToSignupPct()).isEqualTo(0.0);
    }

    @Test
    @DisplayName("Scénario 6 — déjà connecté : « déjà connecté », absent du ratio diagnostic → inscription")
    void scenario6DejaConnecte() {
        User user = data.userCreatedAt("direct", ClientPlatform.WEB, paris(D3.minusDays(30), 8));
        UUID run = run("QUICK_TCF", null, user.getId(), "WEB", paris(D3, 9));
        submit(run, paris(D3, 10), true);

        AdminSuiviResponse r = lire(jour(D3), SuiviTypeFilter.ALL);

        assertThat(r.funnel().attached().alreadyAuthenticated()).isEqualTo(1L);
        assertThat(r.funnel().attached().signedUpAfter()).isZero();
        // Aucun soumis anonyme : le ratio n'a pas de dénominateur, il est inconnu.
        assertThat(r.ratios().diagnosticToSignupPct()).isNull();
        assertThat(r.signups().total()).isZero();
    }

    @Test
    @DisplayName("Scénario 7 — compte existant, diagnostic déconnecté puis connexion : « connecté après », pas d'inscription")
    void scenario7ConnecteApresDiagnostic() {
        User user = data.userCreatedAt("direct", ClientPlatform.WEB, paris(D3.minusDays(30), 8));
        UUID anon = visitor("direct", paris(D3, 9));
        UUID run = run("CIVIQUE", anon, null, "WEB", paris(D3, 9));
        submit(run, paris(D3, 10), false);
        claim(run, user, "LOGIN", paris(D3, 12));

        AdminSuiviResponse r = lire(jour(D3), SuiviTypeFilter.ALL);

        assertThat(r.funnel().attached().loggedInAfter()).isEqualTo(1L);
        assertThat(r.funnel().attached().signedUpAfter()).isZero();
        assertThat(r.signups().loggedInAfterDiagnostic()).isEqualTo(1L);
        assertThat(r.signups().total()).isZero();
    }

    @Test
    @DisplayName("Scénario 8 — vu le 3/09, acheté le 7/09 : dans la cohorte du 3/09 et dans l'activité du 7/09")
    void scenario8CohorteEtActivite() {
        LocalDate d7 = D3.plusDays(4);
        User user = data.userCreatedAt("direct", ClientPlatform.WEB, paris(D3, 8));
        UUID run = tunnelComplet(user, paris(D3, 9));
        purchase(user, data.plan(), "STRIPE", paris(d7, 15), 999, 959, run, "DIAGNOSTIC_PLAN");

        AdminSuiviResponse cohorte = lire(jour(D3), SuiviTypeFilter.ALL);
        AdminSuiviResponse activite = lire(jour(d7), SuiviTypeFilter.ALL);

        assertThat(step(cohorte, 7).count()).isEqualTo(1L);
        assertThat(cohorte.funnel().cohortNetExVatCents()).isEqualTo(959L);
        assertThat(cohorte.kpis().purchases().value()).isZero();
        assertThat(activite.kpis().purchases().value()).isEqualTo(1L);
        assertThat(activite.revenue().netExVatCents()).isEqualTo(959L);
        assertThat(step(activite, 1).count()).isZero();
    }

    @Test
    @DisplayName("Scénario 9 — achat à J+15 : hors tunnel, mais dans l'activité et le CA")
    void scenario9HorsFenetre() {
        LocalDate j15 = D3.plusDays(15);
        User user = data.userCreatedAt("direct", ClientPlatform.WEB, paris(D3, 8));
        UUID run = tunnelComplet(user, paris(D3, 9));
        purchase(user, data.plan(), "STRIPE", paris(j15, 10), 999, 959, run, "DIAGNOSTIC_PLAN");

        AdminSuiviResponse cohorte = lire(jour(D3), SuiviTypeFilter.ALL);
        AdminSuiviResponse activite = lire(jour(j15), SuiviTypeFilter.ALL);

        assertThat(step(cohorte, 6).count()).isEqualTo(1L);
        assertThat(step(cohorte, 7).count()).isZero();
        assertThat(cohorte.funnel().cohortNetExVatCents()).isZero();
        assertThat(activite.kpis().purchases().value()).isEqualTo(1L);
        assertThat(activite.kpis().netExVatCents().value()).isEqualTo(959L);
        assertThat(activite.activity().purchasesByOrigin().diagnosticPlan()).isEqualTo(1L);
    }

    @Test
    @DisplayName("Scénario 12 — les sommes du bloc revenus respectent brut = TVA + frais + net, par canal")
    void scenario12Sommes() {
        User user = data.userCreatedAt("direct", ClientPlatform.WEB, paris(D3, 8));
        Plan plan = data.plan();
        UUID stripe = purchase(user, plan, "STRIPE", paris(D3, 10), 999, 959, null, "UNKNOWN");
        breakdown(stripe, 0, 40, 959, 959, "ACTUAL");
        UUID apple = purchase(user, plan, "APPLE", paris(D3, 11), 999, 708, null, "UNKNOWN");
        breakdown(apple, 166, 125, 708, 708, "ESTIMATED");

        AdminSuiviResponse.Revenue rev = lire(jour(D3), SuiviTypeFilter.ALL).revenue();

        assertThat(rev.purchases()).isEqualTo(2L);
        assertThat(rev.grossCents()).isEqualTo(1998L);
        assertThat(rev.vatCents()).isEqualTo(166L);
        assertThat(rev.providerFeeCents()).isEqualTo(165L);
        assertThat(rev.netExVatCents()).isEqualTo(1667L);
        assertThat(rev.grossCents()).isEqualTo(rev.vatCents() + rev.providerFeeCents() + rev.netExVatCents());
        assertThat(rev.netAfterFeeCents()).isEqualTo(959L + 708L);
        assertThat(rev.estimatedFeePurchases()).isEqualTo(1L);
        assertThat(rev.byProvider()).extracting(AdminSuiviResponse.ProviderRow::purchases)
                .containsExactly(1L, 1L, 0L);
        assertThat(rev.byProvider().get(1).netExVatCents()).isEqualTo(708L);
    }

    @Test
    @DisplayName("Scénario 13 — remboursements : Stripe finit à −0,40 €, store à 0 ; déduits du net de la période")
    void scenario13Remboursements() {
        User user = data.userCreatedAt("direct", ClientPlatform.WEB, paris(D3, 8));
        Plan plan = data.plan();
        UUID stripe = purchase(user, plan, "STRIPE", paris(D3, 10), 999, 959, null, "UNKNOWN");
        breakdown(stripe, 0, 40, 959, 959, "ACTUAL");
        refund(stripe, "STRIPE", paris(D3, 12), 999, -999);
        UUID google = purchase(user, plan, "GOOGLE", paris(D3, 11), 999, 708, null, "UNKNOWN");
        breakdown(google, 166, 125, 708, 708, "ESTIMATED");
        refund(google, "GOOGLE", paris(D3, 13), 999, -708);

        AdminSuiviResponse r = lire(jour(D3), SuiviTypeFilter.ALL);

        assertThat(r.revenue().refunds().count()).isEqualTo(2L);
        assertThat(r.revenue().refunds().amountCents()).isEqualTo(1998L);
        // (959 − 999) + (708 − 708) = −40
        assertThat(r.revenue().netExVatAfterRefundsCents()).isEqualTo(-40L);
        assertThat(r.kpis().netExVatCents().value()).isEqualTo(-40L);
        // Les achats remboursés restent des achats.
        assertThat(r.kpis().purchases().value()).isEqualTo(2L);
    }

    @Test
    @DisplayName("Scénario 14 — 23h30 UTC le 3/09 (heure d'été) : compté le 4/09")
    void scenario14FuseauParis() {
        Instant tard = Instant.parse("2025-09-03T23:30:00Z");
        UUID anon = visitor("direct", tard);
        event(anon, "LANDING_VIEWED", tard, null, null);
        run("CIVIQUE", anon, null, "WEB", tard);

        AdminSuiviResponse le3 = lire(jour(D3), SuiviTypeFilter.ALL);
        AdminSuiviResponse le4 = lire(jour(D3.plusDays(1)), SuiviTypeFilter.ALL);

        assertThat(le3.kpis().visitors().value()).isZero();
        assertThat(step(le3, 1).count()).isZero();
        assertThat(le4.kpis().visitors().value()).isEqualTo(1L);
        assertThat(step(le4, 1).count()).isEqualTo(1L);
    }

    @Test
    @DisplayName("Scénario 15 — compte interne : exclu par défaut, visible avec includeInternal")
    void scenario15Interne() {
        User interne = data.userCreatedAt("direct", ClientPlatform.WEB, paris(D3, 8));
        em.flush();
        jdbc.update("UPDATE users SET is_internal = true WHERE id = ?", interne.getId());
        UUID anon = visitor("direct", paris(D3, 9));
        jdbc.update("INSERT INTO analytics_identity (anonymous_id, user_id, linked_at) VALUES (?, ?, ?)",
                anon, interne.getId(), ts(paris(D3, 9)));
        event(anon, "LANDING_VIEWED", paris(D3, 9), null, null);
        UUID run = run("QUICK_TCF", anon, interne.getId(), "WEB", paris(D3, 9));
        submit(run, paris(D3, 10), true);
        purchase(interne, data.plan(), "STRIPE", paris(D3, 11), 999, 959, run, "DIAGNOSTIC_PLAN");

        AdminSuiviResponse exclu = lire(jour(D3), SuiviTypeFilter.ALL);
        AdminSuiviResponse inclus = service.compute(new SuiviQuery(null, jour(D3), SuiviTypeFilter.ALL,
                SuiviPlatformFilter.ALL, null, true), mesure());

        assertThat(exclu.kpis().visitors().value()).isZero();
        assertThat(step(exclu, 1).count()).isZero();
        assertThat(exclu.kpis().purchases().value()).isZero();
        assertThat(exclu.signups().total()).isZero();
        assertThat(inclus.kpis().visitors().value()).isEqualTo(1L);
        assertThat(step(inclus, 2).count()).isEqualTo(1L);
        assertThat(inclus.kpis().purchases().value()).isEqualTo(1L);
        assertThat(inclus.signups().total()).isEqualTo(1L);
    }

    @Test
    @DisplayName("Scénario 16 — civique refait 3 fois : 1 personne dans le tunnel, 3 soumissions brutes")
    void scenario16Refait() {
        User user = data.userCreatedAt("direct", ClientPlatform.WEB, paris(D3.minusDays(30), 8));
        for (int i = 0; i < 3; i++) {
            UUID run = run("CIVIQUE", null, user.getId(), "WEB", paris(D3, 9 + i));
            submit(run, paris(D3, 9 + i).plusSeconds(600), true);
        }

        AdminSuiviResponse r = lire(jour(D3), SuiviTypeFilter.CIVIQUE);

        assertThat(step(r, 1).count()).isEqualTo(1L);
        assertThat(r.kpis().submitted().value()).isEqualTo(1L);
        assertThat(r.activity().submittedRaw()).isEqualTo(3L);
    }

    @Test
    @DisplayName("Scénario 17 — /reussir?utm_source=IG puis achat : attribué à instagram dans le tunnel filtré")
    void scenario17SourceIg() {
        UUID anon = visitor("IG", paris(D3, 9));
        event(anon, "LANDING_VIEWED", paris(D3, 9), null, null);
        UUID run = run("QUICK_TCF", anon, null, "WEB", paris(D3, 9));
        submit(run, paris(D3, 10), false);
        User user = data.userCreatedAt("autre", ClientPlatform.WEB, paris(D3, 11));
        claim(run, user, "SIGNUP", paris(D3, 11));
        // Ce que pose l'inscription (lot 1b) : l'identifiant de mesure du compte et son lien.
        jdbc.update("UPDATE users SET signup_anonymous_id = ? WHERE id = ?", anon, user.getId());
        jdbc.update("INSERT INTO analytics_identity (anonymous_id, user_id, linked_at) VALUES (?, ?, ?)",
                anon, user.getId(), ts(paris(D3, 11)));
        event(anon, "DIAGNOSTIC_REPORT_VIEWED", paris(D3, 12), run, null);
        event(anon, "PLAN_OPENED", paris(D3, 12), run, null);
        event(anon, "PLAN_UNLOCK_CLICKED", paris(D3, 13), run, null);
        purchase(user, data.plan(), "STRIPE", paris(D3, 14), 999, 959, run, "DIAGNOSTIC_PLAN");

        AdminSuiviResponse instagram = lireSource(jour(D3), "instagram");
        AdminSuiviResponse autre = lireSource(jour(D3), "autre");

        assertThat(step(instagram, 7).count()).isEqualTo(1L);
        assertThat(instagram.kpis().purchases().value()).isEqualTo(1L);
        assertThat(instagram.kpis().visitors().value()).isEqualTo(1L);
        assertThat(step(autre, 1).count()).isZero();
        assertThat(autre.kpis().purchases().value()).isZero();
        assertThat(lire(jour(D3), SuiviTypeFilter.ALL).sources())
                .filteredOn(s -> s.group().equals("instagram"))
                .extracting(AdminSuiviResponse.SourceRow::visitors).containsExactly(1L);
    }

    @Test
    @DisplayName("Scénario 18 — achat sans intention ou via un autre CTA : hors tunnel, compté par origine")
    void scenario18HorsTunnel() {
        User user = data.userCreatedAt("direct", ClientPlatform.WEB, paris(D3, 8));
        UUID run = tunnelComplet(user, paris(D3, 9));
        purchase(user, data.plan(), "STRIPE", paris(D3, 12), 999, 959, null, "UNKNOWN");
        purchase(user, data.plan(), "APPLE", paris(D3, 13), 999, 708, null, "OTHER_CTA");

        AdminSuiviResponse r = lire(jour(D3), SuiviTypeFilter.ALL);

        assertThat(step(r, 6).count()).isEqualTo(1L);
        assertThat(step(r, 7).count()).isZero();
        assertThat(r.kpis().purchases().value()).isEqualTo(2L);
        assertThat(r.activity().purchasesByOrigin().unknown()).isEqualTo(1L);
        assertThat(r.activity().purchasesByOrigin().otherCta()).isEqualTo(1L);
        assertThat(r.activity().purchasesByOrigin().diagnosticPlan()).isZero();
        assertThat(run).isNotNull();
    }

    @Test
    @DisplayName("Étapes 5 et 6 : un événement de Plan porteur du seul parcours se rattache à la run fondatrice")
    void planParParcours() {
        User user = data.userCreatedAt("direct", ClientPlatform.WEB, paris(D3.minusDays(30), 8));
        CivicDiagnosticSession session = civicService.ouvrir(user.getId());
        em.flush();
        UUID anon = visitor("direct", paris(D3, 9));
        UUID run = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO diagnostic_run (id, diagnostic_type, platform, anonymous_id, user_id,
                                            subject_viewed_at, civic_diagnostic_session_id, updated_at)
                VALUES (?, 'CIVIQUE', 'WEB', ?, ?, ?, ?, now())""",
                run, anon, user.getId(), ts(paris(D3, 9)), session.getId());
        submit(run, paris(D3, 10), true);
        UUID journey = UUID.randomUUID();
        jdbc.update("INSERT INTO journey (id, user_id, target_procedure, module) VALUES (?, ?, 'CSP', 'CIVIQUE')",
                journey, user.getId());
        jdbc.update("INSERT INTO journey_assessment_event (id, journey_id, source_assessment_id, assessment_kind, "
                        + "completed_at) VALUES (?, ?, ?, 'CIVIC_DIAGNOSTIC', ?)",
                UUID.randomUUID(), journey, session.getId(), ts(paris(D3, 10)));
        event(anon, "DIAGNOSTIC_REPORT_VIEWED", paris(D3, 11), run, null);
        event(anon, "PLAN_OPENED", paris(D3, 12), null, journey);
        event(anon, "PLAN_UNLOCK_CLICKED", paris(D3, 13), null, journey);

        assertThat(counts(lire(jour(D3), SuiviTypeFilter.CIVIQUE)))
                .containsExactly(1L, 1L, 1L, 1L, 1L, 1L, 0L);
    }

    @Test
    @DisplayName("Q16/D43 — un indicateur dont la mesure commence après le début de la période vaut null, jamais 0")
    void debutDeMesure() {
        UUID anon = visitor("direct", paris(D3, 9));
        event(anon, "LANDING_VIEWED", paris(D3, 9), null, null);
        Map<SuiviIndicator, LocalDate> starts = mesure();
        starts.put(SuiviIndicator.VISITORS, D3.plusDays(1));
        starts.put(SuiviIndicator.REPORT_VIEWED, null);

        AdminSuiviResponse r = service.compute(new SuiviQuery(null, jour(D3), SuiviTypeFilter.ALL,
                SuiviPlatformFilter.ALL, null, false), starts);

        assertThat(r.kpis().visitors().value()).isNull();
        assertThat(r.kpis().submitted().ratioPct()).isNull();
        assertThat(r.measurementStart()).containsEntry(SuiviIndicator.VISITORS, D3.plusDays(1))
                .containsEntry(SuiviIndicator.REPORT_VIEWED, null)
                .hasSize(SuiviIndicator.values().length);
        // Etapes 1 a 3 mesurees ; a partir de l'etape 4, tout est inconnu (tunnel sequentiel).
        assertThat(r.funnel().steps()).extracting(FunnelStep::count)
                .containsExactly(0L, 0L, 0L, null, null, null, null);
        assertThat(r.byType().get(0).purchases()).isNull();
        assertThat(r.ratios().reportViewedPct()).isNull();
        assertThat(r.funnel().cohortNetExVatCents()).isNull();
        // La veille (periode precedente) n'est pas mesuree non plus : pas de tendance.
        assertThat(r.kpis().visitors().deltaPct()).isNull();
    }

    @Test
    @DisplayName("Tendance — variation par rapport à la veille ; null si la veille vaut 0")
    void tendance() {
        for (int i = 0; i < 4; i++) event(visitor("direct", paris(D3, 9)), "LANDING_VIEWED", paris(D3, 9), null, null);
        for (int i = 0; i < 5; i++) {
            event(visitor("direct", paris(D3.plusDays(1), 9)), "LANDING_VIEWED", paris(D3.plusDays(1), 9), null,
                    null);
        }

        AdminSuiviResponse.Kpi v = lire(jour(D3.plusDays(1)), SuiviTypeFilter.ALL).kpis().visitors();
        AdminSuiviResponse.Kpi vide = lire(jour(D3), SuiviTypeFilter.ALL).kpis().visitors();

        assertThat(v.value()).isEqualTo(5L);
        assertThat(v.previous()).isEqualTo(4L);
        assertThat(v.deltaPct()).isEqualTo(25.0);
        assertThat(vide.previous()).isZero();
        assertThat(vide.deltaPct()).isNull();
    }

    @Test
    @DisplayName("Filtre plateforme : la plateforme de l'étape 1 pour le tunnel, le canal pour les achats")
    void filtrePlateforme() {
        User user = data.userCreatedAt("direct", ClientPlatform.ANDROID, paris(D3, 8));
        UUID run = run("CIVIQUE", null, user.getId(), "ANDROID", paris(D3, 9));
        submit(run, paris(D3, 10), true);
        purchase(user, data.plan(ModuleAccess.CIVIQUE), "GOOGLE", paris(D3, 11), 999, 708, null, "UNKNOWN");

        AdminSuiviResponse android = service.compute(new SuiviQuery(null, jour(D3), SuiviTypeFilter.ALL,
                SuiviPlatformFilter.ANDROID, null, false), mesure());
        AdminSuiviResponse web = service.compute(new SuiviQuery(null, jour(D3), SuiviTypeFilter.ALL,
                SuiviPlatformFilter.WEB, null, false), mesure());
        AdminSuiviResponse civique = lire(jour(D3), SuiviTypeFilter.CIVIQUE);
        AdminSuiviResponse tcf = lire(jour(D3), SuiviTypeFilter.TCF);

        assertThat(step(android, 1).count()).isEqualTo(1L);
        assertThat(android.kpis().purchases().value()).isEqualTo(1L);
        assertThat(android.signups().total()).isEqualTo(1L);
        assertThat(step(web, 1).count()).isZero();
        assertThat(web.kpis().purchases().value()).isZero();
        // Un pass Civique seul, non attribue, est un achat civique ; jamais TCF.
        assertThat(civique.kpis().purchases().value()).isEqualTo(1L);
        assertThat(tcf.kpis().purchases().value()).isZero();
    }

    @Test
    @DisplayName("Contrôle C — civique : 79 % de réponses non soumis, 80 % soumis, mesure absente = inconnu")
    void seuilCivique() {
        UUID a79 = run("CIVIQUE", visitor("direct", paris(D3, 9)), null, "WEB", paris(D3, 9));
        submitCivique(a79, paris(D3, 10), false, 79, 100);
        UUID a80 = run("CIVIQUE", visitor("direct", paris(D3, 9)), null, "WEB", paris(D3, 9));
        submitCivique(a80, paris(D3, 10), false, 80, 100);
        UUID abandon = run("CIVIQUE", visitor("direct", paris(D3, 9)), null, "WEB", paris(D3, 9));
        submitCivique(abandon, paris(D3, 10), false, 0, 40);
        UUID inconnu = run("CIVIQUE", visitor("direct", paris(D3, 9)), null, "WEB", paris(D3, 9));
        submitCivique(inconnu, paris(D3, 10), false, null, null);
        // Le seuil ne vise que le civique : un TCF rapide soumis reste soumis.
        UUID tcf = run("QUICK_TCF", visitor("direct", paris(D3, 9)), null, "WEB", paris(D3, 9));
        submitCivique(tcf, paris(D3, 10), false, null, null);

        AdminSuiviResponse civique = lire(jour(D3), SuiviTypeFilter.CIVIQUE);
        AdminSuiviResponse tous = lire(jour(D3), SuiviTypeFilter.ALL);

        // 4 sujets vus, 1 seul soumis retenu (80 %) : 79 %, l'abandon et l'inconnu n'y sont pas.
        assertThat(step(civique, 1).count()).isEqualTo(4L);
        assertThat(step(civique, 2).count()).isEqualTo(1L);
        assertThat(civique.ratios().subjectToSubmissionPct()).isEqualTo(25.0);
        assertThat(civique.kpis().submitted().value()).isEqualTo(1L);
        assertThat(civique.activity().submittedRaw()).isEqualTo(1L);
        // « Jamais rattachées » ne compte que les soumis retenus, jamais l'inconnu comme 0 réponse.
        assertThat(civique.activity().anonymousSubmittedNeverAttached()).isEqualTo(1L);
        assertThat(tous.kpis().submitted().value()).isEqualTo(2L);
        assertThat(tous.byType()).extracting(AdminSuiviResponse.TypeRow::submitted).containsExactly(1L, 1L);
    }

    // ------------------------------------------------------------------------
    // Semis
    // ------------------------------------------------------------------------

    /** Une run connectee menee jusqu'au clic « Debloquer ». */
    private UUID tunnelComplet(User user, Instant vu) {
        UUID anon = visitor("direct", vu);
        UUID run = run("QUICK_TCF", anon, user.getId(), "WEB", vu);
        submit(run, vu.plusSeconds(600), true);
        event(anon, "DIAGNOSTIC_REPORT_VIEWED", vu.plusSeconds(1200), run, null);
        event(anon, "PLAN_OPENED", vu.plusSeconds(1800), run, null);
        event(anon, "PLAN_UNLOCK_CLICKED", vu.plusSeconds(2400), run, null);
        return run;
    }

    private UUID visitor(String declaredSource, Instant at) {
        em.flush();
        UUID id = UUID.randomUUID();
        String normalized = TrafficSource.normalize(declaredSource);
        jdbc.update("""
                INSERT INTO analytics_visitor (anonymous_id, first_seen_at, last_seen_at, ft_source, ft_source_raw,
                                               lt_source, lt_seen_at, device_type, platform)
                VALUES (?, ?, ?, ?, ?, ?, ?, 'DESKTOP_WEB', 'WEB')""",
                id, ts(at), ts(at), normalized, declaredSource.toLowerCase(), normalized, ts(at));
        return id;
    }

    private void event(UUID anon, String event, Instant at, UUID runId, UUID journeyId) {
        em.flush();
        jdbc.update("""
                INSERT INTO analytics_event (id, event, occurred_at, anonymous_id, session_id, properties,
                                             event_id, received_at, platform, diagnostic_run_id, journey_id,
                                             is_internal)
                VALUES (?, ?, ?, ?, ?, '{}'::jsonb, ?, ?, 'WEB', ?, ?, false)""",
                UUID.randomUUID(), event, ts(at), anon, UUID.randomUUID(), UUID.randomUUID(), ts(at), runId,
                journeyId);
    }

    private UUID run(String type, UUID anon, UUID userId, String platform, Instant viewedAt) {
        em.flush();
        UUID id = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO diagnostic_run (id, diagnostic_type, platform, anonymous_id, user_id,
                                            subject_viewed_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, now())""", id, type, platform, anon, userId, ts(viewedAt));
        return id;
    }

    /** « Soumis » ; un civique est seme complet (40/40), comme l'ecrit le serveur depuis V076. */
    private void submit(UUID run, Instant at, boolean authenticated) {
        jdbc.update("""
                UPDATE diagnostic_run SET submitted_at = ?, submitted_authenticated = ?,
                       submitted_answered_count = CASE WHEN diagnostic_type = 'CIVIQUE' THEN 40 END,
                       submitted_question_count = CASE WHEN diagnostic_type = 'CIVIQUE' THEN 40 END
                 WHERE id = ?""", ts(at), authenticated, run);
    }

    /** « Soumis » civique avec la mesure donnee ; {@code null} = run anterieure a V076. */
    private void submitCivique(UUID run, Instant at, boolean authenticated, Integer answered, Integer questions) {
        jdbc.update("""
                UPDATE diagnostic_run SET submitted_at = ?, submitted_authenticated = ?,
                       submitted_answered_count = ?, submitted_question_count = ?
                 WHERE id = ?""", ts(at), authenticated, answered, questions, run);
    }

    private void claim(UUID run, User user, String kind, Instant at) {
        em.flush();
        jdbc.update("""
                UPDATE diagnostic_run SET user_id = ?, claimed_at = ?, claim_kind = ?, claimed_via = 'SAME_DEVICE'
                 WHERE id = ?""", user.getId(), ts(at), kind, run);
    }

    private void signupContext(User user, String context, String type, UUID run) {
        em.flush();
        jdbc.update("""
                UPDATE users SET signup_context = ?, signup_diagnostic_type = ?, signup_diagnostic_run_id = ?
                 WHERE id = ?""", context, type, run, user.getId());
    }

    /** Un achat ; {@code net} ne sert qu'aux achats sans {@link #breakdown} explicite (Stripe 9,99 € par defaut). */
    private UUID purchase(User user, Plan plan, String provider, Instant at, int gross, int net, UUID runId,
                          String origin) {
        em.flush();
        UUID id = UUID.randomUUID();
        int vat = "STRIPE".equals(provider) ? 0 : gross - Math.round(gross / 1.2f);
        int fee = gross - vat - net;
        jdbc.update("""
                INSERT INTO user_subscriptions (id, user_id, plan_id, status, starts_at, ends_at, source,
                                                original_transaction_id, product_id, auto_renew, amount_cents,
                                                currency, amount_eur_cents, fx_rate_to_eur, purchased_at,
                                                vat_cents, provider_fee_cents, net_after_fee_cents,
                                                net_ex_vat_cents, fee_source, revenue_rules_version, origin,
                                                diagnostic_run_id, payment_status)
                VALUES (?, ?, ?, 'ACTIVE', ?, ?, ?, ?, ?, false, ?, 'EUR', ?, 1, ?, ?, ?, ?, ?, 'ESTIMATED', 1, ?, ?,
                        'PAID')""",
                id, user.getId(), plan.getId(), ts(at), ts(at.plus(Duration.ofDays(30))), provider,
                "tx_" + id, plan.getCode(), gross, gross, ts(at), vat, fee,
                "STRIPE".equals(provider) ? gross - fee : net, net, origin, runId);
        return id;
    }

    private void breakdown(UUID purchase, int vat, int fee, int netAfterFee, int netExVat, String feeSource) {
        jdbc.update("""
                UPDATE user_subscriptions SET vat_cents = ?, provider_fee_cents = ?, net_after_fee_cents = ?,
                                              net_ex_vat_cents = ?, fee_source = ?
                 WHERE id = ?""", vat, fee, netAfterFee, netExVat, feeSource, purchase);
    }

    private void refund(UUID purchase, String provider, Instant at, int amount, int delta) {
        jdbc.update("""
                INSERT INTO payment_refunds (id, subscription_id, provider, provider_refund_id,
                                             refunded_amount_cents, currency, refunded_eur_cents,
                                             net_ex_vat_delta_cents, revenue_rules_version, refunded_at)
                VALUES (?, ?, ?, ?, ?, 'EUR', ?, ?, 1, ?)""",
                UUID.randomUUID(), purchase, provider, "re_" + UUID.randomUUID(), amount, amount, delta, ts(at));
    }

    // ------------------------------------------------------------------------
    // Lecture
    // ------------------------------------------------------------------------

    /** Tous les indicateurs mesures depuis 2020 : le test lit le calcul, pas le calendrier de deploiement. */
    static Map<SuiviIndicator, LocalDate> mesure() {
        Map<SuiviIndicator, LocalDate> starts = new EnumMap<>(SuiviIndicator.class);
        for (SuiviIndicator indicator : SuiviIndicator.values()) starts.put(indicator, LocalDate.of(2020, 1, 1));
        return starts;
    }

    private AdminSuiviResponse lire(FenetreMesure window, SuiviTypeFilter type) {
        return service.compute(new SuiviQuery(null, window, type, SuiviPlatformFilter.ALL, null, false), mesure());
    }

    private AdminSuiviResponse lireSource(FenetreMesure window, String source) {
        return service.compute(new SuiviQuery(null, window, SuiviTypeFilter.ALL, SuiviPlatformFilter.ALL, source,
                false), mesure());
    }

    private static List<Long> counts(AdminSuiviResponse r) {
        return r.funnel().steps().stream().map(FunnelStep::count).toList();
    }

    private static FunnelStep step(AdminSuiviResponse r, int number) {
        return r.funnel().steps().get(number - 1);
    }

    static FenetreMesure jour(LocalDate day) {
        return new FenetreMesure(day, day);
    }

    static Instant paris(LocalDate day, int hour) {
        return ZonedDateTime.of(LocalDateTime.of(day, java.time.LocalTime.of(hour % 24, 0)),
                FenetreMesure.PARIS).toInstant();
    }

    private static Timestamp ts(Instant instant) {
        return Timestamp.from(instant);
    }
}
