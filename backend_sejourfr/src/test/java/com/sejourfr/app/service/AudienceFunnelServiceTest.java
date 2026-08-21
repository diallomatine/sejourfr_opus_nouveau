package com.sejourfr.app.service;

import com.sejourfr.app.dto.AudienceFunnelResponse;
import com.sejourfr.app.manager.AudienceFunnelManager;
import com.sejourfr.app.repository.AudienceFunnelRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/**
 * Ce que ce test verrouille : la cohorte, l'ordre des étapes, le repli
 * « inconnu » des comptes antérieurs à la mesure, et la continuité de la série
 * journalière — les quatre points où un funnel se met à mentir sans prévenir.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AudienceFunnelServiceTest {

    private static final ZoneId PARIS = ZoneId.of("Europe/Paris");

    @Mock
    private AudienceFunnelManager manager;

    @InjectMocks
    private AudienceFunnelService service;

    // ------------------------------------------------------------------------
    // Doublures des projections natives
    // ------------------------------------------------------------------------

    private record Cohort(String source, String platform, long total)
            implements AudienceFunnelRepository.CohortCell {
        @Override public String getSource() { return source; }
        @Override public String getPlatform() { return platform; }
        @Override public long getTotal() { return total; }
    }

    private record Diag(String source, String platform, long started, long completed)
            implements AudienceFunnelRepository.DiagnosticCell {
        @Override public String getSource() { return source; }
        @Override public String getPlatform() { return platform; }
        @Override public long getStarted() { return started; }
        @Override public long getCompleted() { return completed; }
    }

    private record Evt(String source, String platform, String event, long total)
            implements AudienceFunnelRepository.EventCell {
        @Override public String getSource() { return source; }
        @Override public String getPlatform() { return platform; }
        @Override public String getEvent() { return event; }
        @Override public long getTotal() { return total; }
    }

    private record Day(String kind, String day, long total)
            implements AudienceFunnelRepository.DailyCell {
        @Override public String getKind() { return kind; }
        @Override public String getDay() { return day; }
        @Override public long getTotal() { return total; }
    }

    private record Integrity(long accounts, long sessions, long multi)
            implements AudienceFunnelRepository.IntegrityRow {
        @Override public long getAccounts() { return accounts; }
        @Override public long getSessions() { return sessions; }
        @Override public long getMulti() { return multi; }
    }

    private void stubEmpty() {
        when(manager.signups(any(), any())).thenReturn(List.of());
        when(manager.diagnostics(any(), any())).thenReturn(List.of());
        when(manager.funnelEvents(any(), any())).thenReturn(List.of());
        when(manager.purchases(any(), any())).thenReturn(List.of());
        when(manager.daily(any(), any())).thenReturn(List.of());
        when(manager.integrity()).thenReturn(new Integrity(0, 0, 0));
    }

    // ------------------------------------------------------------------------

    @Test
    void lesSeptEtapesSontServiesDansLOrdreDuParcours() {
        stubEmpty();

        List<String> stages = service.funnel(30).stages().stream()
                .map(AudienceFunnelResponse.StageCount::stage).toList();

        assertThat(stages).containsExactly(
                "SIGNUP", "DIAGNOSTIC_STARTED", "DIAGNOSTIC_COMPLETED",
                "PAYWALL_VIEWED", "SUBSCRIBE_CLICKED", "CHECKOUT_STARTED", "PURCHASE");
    }

    @Test
    void chaqueEtapeEstUnCompteDeComptesDeLaCohorte() {
        stubEmpty();
        when(manager.signups(any(), any())).thenReturn(List.of(
                new Cohort("tiktok", "WEB", 50),
                new Cohort("tiktok", "MOBILE", 20),
                new Cohort("instagram", "WEB", 30)));
        when(manager.diagnostics(any(), any())).thenReturn(List.of(
                new Diag("tiktok", "WEB", 30, 22),
                new Diag("instagram", "WEB", 10, 4)));
        when(manager.funnelEvents(any(), any())).thenReturn(List.of(
                new Evt("tiktok", "WEB", "PAYWALL_VIEWED", 12),
                new Evt("tiktok", "WEB", "SUBSCRIBE_CLICKED", 5),
                new Evt("tiktok", "WEB", "CHECKOUT_STARTED", 4)));
        when(manager.purchases(any(), any())).thenReturn(List.of(
                new Cohort("tiktok", "WEB", 3)));

        AudienceFunnelResponse funnel = service.funnel(30);

        assertThat(funnel.stages()).extracting(AudienceFunnelResponse.StageCount::count)
                .containsExactly(100L, 40L, 26L, 12L, 5L, 4L, 3L);
        // Les deux cellules TikTok se replient sur une seule ligne de source.
        assertThat(funnel.bySource()).extracting(AudienceFunnelResponse.SourceFunnel::source)
                .containsExactly("tiktok", "instagram");
        assertThat(funnel.bySource().getFirst().signups()).isEqualTo(70);
        assertThat(funnel.bySource().getFirst().purchases()).isEqualTo(3);
        // Et les deux réseaux se replient sur une seule ligne de plateforme.
        assertThat(funnel.byPlatform()).extracting(AudienceFunnelResponse.PlatformFunnel::platform)
                .containsExactly("WEB", "MOBILE");
        assertThat(funnel.byPlatform().getFirst().signups()).isEqualTo(80);
        assertThat(funnel.byPlatform().getFirst().diagnosticsCompleted()).isEqualTo(26);
    }

    /**
     * Les comptes antérieurs à la mesure sont montrés, jamais cachés : les
     * masquer ferait un total qui ne tombe pas juste, et c'est exactement le
     * moment où l'on cesse de croire une console.
     */
    @Test
    void lesComptesSansProvenanceSortentEnInconnuEtNonMasques() {
        stubEmpty();
        when(manager.signups(any(), any())).thenReturn(List.of(
                new Cohort("inconnu", "UNKNOWN", 7),
                new Cohort("tiktok", "WEB", 3)));

        AudienceFunnelResponse funnel = service.funnel(30);

        assertThat(funnel.bySource()).extracting(AudienceFunnelResponse.SourceFunnel::source)
                .containsExactly("inconnu", "tiktok");
        assertThat(funnel.byPlatform()).extracting(AudienceFunnelResponse.PlatformFunnel::platform)
                .containsExactly("UNKNOWN", "WEB");
        assertThat(funnel.stages().getFirst().count()).isEqualTo(10);
    }

    @Test
    void laSerieJournaliereEstContinueEtPorteLesJoursAZero() {
        stubEmpty();
        LocalDate today = LocalDate.now(PARIS);
        when(manager.daily(any(), any())).thenReturn(List.of(
                new Day("SIGNUP", today.toString(), 4),
                new Day("PURCHASE", today.toString(), 1),
                new Day("DIAGNOSTIC_STARTED", today.minusDays(2).toString(), 3)));

        List<AudienceFunnelResponse.DailyPoint> daily = service.funnel(5).daily();

        assertThat(daily).hasSize(5);
        assertThat(daily).extracting(AudienceFunnelResponse.DailyPoint::day)
                .containsExactly(
                        today.minusDays(4).toString(), today.minusDays(3).toString(),
                        today.minusDays(2).toString(), today.minusDays(1).toString(),
                        today.toString());
        assertThat(daily.getFirst().signups()).isZero();
        assertThat(daily.get(2).diagnosticsStarted()).isEqualTo(3);
        assertThat(daily.get(3).signups()).isZero();
        assertThat(daily.getLast().signups()).isEqualTo(4);
        assertThat(daily.getLast().purchases()).isEqualTo(1);
    }

    @Test
    void laFenetreEstBorneeCommeLaMesureDAudience() {
        stubEmpty();

        assertThat(service.funnel(0).days()).isEqualTo(1);
        assertThat(service.funnel(-12).days()).isEqualTo(1);
        assertThat(service.funnel(100_000).days()).isEqualTo(365);
        assertThat(service.funnel(30).days()).isEqualTo(30);
    }

    @Test
    void laFenetreEstAnnoncéeEnJoursCivilsInclusifs() {
        stubEmpty();
        LocalDate today = LocalDate.now(PARIS);

        AudienceFunnelResponse funnel = service.funnel(30);

        assertThat(funnel.cohortTo()).isEqualTo(today.toString());
        assertThat(funnel.cohortFrom()).isEqualTo(today.minusDays(29).toString());
    }

    /**
     * L'intégrité se mesure sur toute la base : une anomalie d'unicité ne doit
     * pas pouvoir sortir du champ de vision en vieillissant.
     */
    @Test
    void lIntegriteDuDiagnosticEstServieTelleQuelle() {
        stubEmpty();
        when(manager.integrity()).thenReturn(new Integrity(138, 140, 0));

        AudienceFunnelResponse.Integrity integrity = service.funnel(30).integrity();

        assertThat(integrity.accountsWithDiagnostic()).isEqualTo(138);
        assertThat(integrity.diagnosticSessionsTotal()).isEqualTo(140);
        assertThat(integrity.accountsWithMultipleDiagnosticSessions()).isZero();
    }

    /**
     * Une date précise l'emporte sur la fenêtre glissante, et la réponse rend
     * les bornes RÉELLEMENT appliquées — sans elles, l'écran ne peut pas prouver
     * ce qu'il affiche.
     */
    @Test
    void unePeriodeExpliciteLEmporteSurLaFenetreGlissante() {
        stubEmpty();

        AudienceFunnelResponse funnel = service.funnel("2026-08-01", "2026-08-07", 30);

        assertThat(funnel.cohortFrom()).isEqualTo("2026-08-01");
        assertThat(funnel.cohortTo()).isEqualTo("2026-08-07");
        assertThat(funnel.days()).isEqualTo(7);
        assertThat(funnel.daily()).hasSize(7);
    }

    /** Une seule journée : un point, et « days » qui vaut 1 sans mentir. */
    @Test
    void uneSeuleJourneeRendUnPointEtUnJour() {
        stubEmpty();

        AudienceFunnelResponse funnel = service.funnel("2026-08-18", "2026-08-18", 30);

        assertThat(funnel.days()).isEqualTo(1);
        assertThat(funnel.daily()).hasSize(1);
        assertThat(funnel.daily().getFirst().day()).isEqualTo("2026-08-18");
    }

    @Test
    void unDemiIntervalleEstRefuse_jamaisUnRepliMuetSurDays() {
        stubEmpty();

        assertThatThrownBy(() -> service.funnel("2026-08-18", null, 30))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> service.funnel(null, "2026-08-18", 30))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void unePeriodeInverseeOuTropLargeEstRefusee() {
        stubEmpty();

        assertThatThrownBy(() -> service.funnel("2026-08-19", "2026-08-18", 30))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> service.funnel(
                LocalDate.now(PARIS).minusDays(400).toString(),
                LocalDate.now(PARIS).toString(), 30))
                .isInstanceOf(IllegalArgumentException.class);
    }

    /** Non-régression : sans bornes, « days » reste la fenêtre glissante. */
    @Test
    void sansBornesLAncienContratNeBougePas() {
        stubEmpty();
        LocalDate today = LocalDate.now(PARIS);

        AudienceFunnelResponse funnel = service.funnel(null, null, 7);

        assertThat(funnel.days()).isEqualTo(7);
        assertThat(funnel.cohortTo()).isEqualTo(today.toString());
        assertThat(funnel.cohortFrom()).isEqualTo(today.minusDays(6).toString());
    }

    @Test
    void uneBaseVideRendDesZeros_jamaisUneListeAbsente() {
        stubEmpty();

        AudienceFunnelResponse funnel = service.funnel(7);

        assertThat(funnel.stages()).hasSize(7)
                .allSatisfy(stage -> assertThat(stage.count()).isZero());
        assertThat(funnel.bySource()).isEmpty();
        assertThat(funnel.byPlatform()).isEmpty();
        assertThat(funnel.daily()).hasSize(7);
    }
}
