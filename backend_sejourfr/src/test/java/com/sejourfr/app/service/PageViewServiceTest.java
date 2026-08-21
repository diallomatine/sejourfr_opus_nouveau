package com.sejourfr.app.service;

import com.sejourfr.app.dto.PageViewRequest;
import com.sejourfr.app.dto.PageViewStatsResponse;
import com.sejourfr.app.entity.PageView;
import com.sejourfr.app.enums.PageViewEvent;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.PageViewManager;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Les deux listes blanches sont ce qui borne la table face à un endpoint
 * public : elles sont testées explicitement, au même titre que l'agrégat rendu
 * à l'admin.
 */
@ExtendWith(MockitoExtension.class)
class PageViewServiceTest {

    @Mock
    private PageViewManager manager;

    @InjectMocks
    private PageViewService service;

    private static PageView row(String source, PageViewEvent event, LocalDate day, long hits) {
        PageView v = new PageView();
        v.setPath("/reussir");
        v.setSource(source);
        v.setEvent(event);
        v.setDay(day);
        v.setHits(hits);
        return v;
    }

    @Test
    void track_rejectsUnknownPath() {
        assertThatThrownBy(() -> service.track(
                new PageViewRequest("/admin-secret", "tiktok", PageViewEvent.VIEW)))
                .isInstanceOf(BusinessException.class);

        verify(manager, never()).increment(anyString(), anyString(), any(), any());
    }

    @Test
    void track_keepsKnownSourceAsIs() {
        service.track(new PageViewRequest("/reussir", "TikTok", PageViewEvent.VIEW));

        verify(manager).increment(eq("/reussir"), eq("tiktok"), eq(PageViewEvent.VIEW), any());
    }

    @Test
    void track_rejectsKnownEventOnWrongScreen() {
        assertThatThrownBy(() -> service.track(new PageViewRequest(
                "/reussir", "tiktok", PageViewEvent.DIAGNOSTIC_COMPLETED)))
                .isInstanceOf(BusinessException.class);

        verify(manager, never()).increment(anyString(), anyString(), any(), any());
    }

    @Test
    void track_acceptsTheDiagnosticAndPlanFunnelEvents() {
        service.track(new PageViewRequest(
                "/diagnostic", "instagram", PageViewEvent.DIAGNOSTIC_RESULT_VIEWED));
        service.track(new PageViewRequest(
                "/plan", "instagram", PageViewEvent.PLAN_RECOMMENDED_EXERCISE_STARTED));

        verify(manager).increment(eq("/diagnostic"), eq("instagram"),
                eq(PageViewEvent.DIAGNOSTIC_RESULT_VIEWED), any());
        verify(manager).increment(eq("/plan"), eq("instagram"),
                eq(PageViewEvent.PLAN_RECOMMENDED_EXERCISE_STARTED), any());
    }

    /**
     * Mesure de conversion du parcours invité : tout ce qui précède se joue
     * hors base, cet événement est le premier point de comptage.
     */
    @Test
    void track_acceptsTheGuestAccountRequiredStepOnDiagnosticOnly() {
        service.track(new PageViewRequest(
                "/diagnostic", "tiktok", PageViewEvent.DIAGNOSTIC_ACCOUNT_REQUIRED));

        verify(manager).increment(eq("/diagnostic"), eq("tiktok"),
                eq(PageViewEvent.DIAGNOSTIC_ACCOUNT_REQUIRED), any());

        assertThatThrownBy(() -> service.track(new PageViewRequest(
                "/plan", "tiktok", PageViewEvent.DIAGNOSTIC_ACCOUNT_REQUIRED)))
                .isInstanceOf(BusinessException.class);
    }

    /**
     * Écrans de prix : ce qu'on y compte, ce sont les visiteurs qui regardent
     * les tarifs SANS jamais créer de compte — eux n'apparaissent dans aucune
     * table nominative, et le funnel par compte commence après eux.
     */
    @Test
    void track_acceptsViewAndCtaOnThePricingScreens() {
        service.track(new PageViewRequest("/tarifs", "tiktok", PageViewEvent.VIEW));
        service.track(new PageViewRequest("/tarifs", "tiktok", PageViewEvent.CTA));
        service.track(new PageViewRequest("/paiement", "tiktok", PageViewEvent.VIEW));
        service.track(new PageViewRequest("/paiement", "tiktok", PageViewEvent.CTA));

        verify(manager).increment(eq("/tarifs"), eq("tiktok"), eq(PageViewEvent.VIEW), any());
        verify(manager).increment(eq("/tarifs"), eq("tiktok"), eq(PageViewEvent.CTA), any());
        verify(manager).increment(eq("/paiement"), eq("tiktok"), eq(PageViewEvent.VIEW), any());
        verify(manager).increment(eq("/paiement"), eq("tiktok"), eq(PageViewEvent.CTA), any());
    }

    /**
     * Les écrans de prix ne portent QUE la vue et le clic : le reste du parcours
     * d'achat (écran Premium, clic abonnement, paiement) se lit par compte, pas
     * dans l'agrégat anonyme. Les mélanger produirait deux chiffres pour la même
     * étape.
     */
    @Test
    void track_rejectsFunnelEventsOnThePricingScreens() {
        assertThatThrownBy(() -> service.track(new PageViewRequest(
                "/tarifs", "tiktok", PageViewEvent.DIAGNOSTIC_TO_PREMIUM_CLICKED)))
                .isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> service.track(new PageViewRequest(
                "/paiement", "tiktok", PageViewEvent.PLAN_OPENED)))
                .isInstanceOf(BusinessException.class);

        verify(manager, never()).increment(anyString(), anyString(), any(), any());
    }

    /**
     * La landing a DEUX portes d'entrée, et elles se comptent séparément : le
     * civique n'a ni production, ni niveau CECRL, ni diagnostic. Réutiliser
     * l'événement du diagnostic aurait gonflé sa mesure avec des clics qui n'y
     * mènent pas.
     */
    @Test
    void track_countsTheCiviqueEntryApartFromTheDiagnosticOne() {
        service.track(new PageViewRequest(
                "/reussir", "tiktok", PageViewEvent.SOCIAL_LANDING_CIVIQUE_CLICKED));
        service.track(new PageViewRequest(
                "/reussir", "tiktok", PageViewEvent.SOCIAL_LANDING_DIAGNOSTIC_CLICKED));

        verify(manager).increment(eq("/reussir"), eq("tiktok"),
                eq(PageViewEvent.SOCIAL_LANDING_CIVIQUE_CLICKED), any());
        verify(manager).increment(eq("/reussir"), eq("tiktok"),
                eq(PageViewEvent.SOCIAL_LANDING_DIAGNOSTIC_CLICKED), any());
    }

    /** L'entrée civique n'existe que sur la landing : ailleurs, elle est refusée. */
    @Test
    void track_rejectsTheCiviqueEntryOutsideTheLanding() {
        assertThatThrownBy(() -> service.track(new PageViewRequest(
                "/diagnostic", "tiktok", PageViewEvent.SOCIAL_LANDING_CIVIQUE_CLICKED)))
                .isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> service.track(new PageViewRequest(
                "/plan", "tiktok", PageViewEvent.SOCIAL_LANDING_CIVIQUE_CLICKED)))
                .isInstanceOf(BusinessException.class);

        verify(manager, never()).increment(anyString(), anyString(), any(), any());
    }

    /**
     * Les deux entrées comptent comme des clics dans l'agrégat, et restent
     * <b>distinctes</b> dans {@code events} : c'est là qu'on lit combien de
     * visiteurs sont partis vers le civique plutôt que vers le diagnostic.
     */
    @Test
    void stats_keepsBothLandingEntriesApartWhileCountingThemAsClicks() {
        LocalDate day = LocalDate.now();
        when(manager.since(eq("/reussir"), any())).thenReturn(List.of(
                row("tiktok", PageViewEvent.VIEW, day, 100),
                row("tiktok", PageViewEvent.SOCIAL_LANDING_DIAGNOSTIC_CLICKED, day, 30),
                row("tiktok", PageViewEvent.SOCIAL_LANDING_CIVIQUE_CLICKED, day, 12)));

        PageViewStatsResponse stats = service.stats("/reussir", 30);

        assertThat(stats.views()).isEqualTo(100);
        assertThat(stats.ctaClicks()).isEqualTo(42);
        assertThat(stats.events())
                .containsEntry("SOCIAL_LANDING_DIAGNOSTIC_CLICKED", 30L)
                .containsEntry("SOCIAL_LANDING_CIVIQUE_CLICKED", 12L);
    }

    @Test
    void stats_servesThePricingScreensToo() {
        when(manager.since(eq("/tarifs"), any())).thenReturn(List.of());

        assertThat(service.stats("/tarifs", 30).path()).isEqualTo("/tarifs");
    }

    @Test
    void track_foldsUnknownSourceIntoOther() {
        service.track(new PageViewRequest("/reussir", "reseau-invente-123", PageViewEvent.CTA));

        ArgumentCaptor<String> source = ArgumentCaptor.forClass(String.class);
        verify(manager).increment(eq("/reussir"), source.capture(), eq(PageViewEvent.CTA), any());
        assertThat(source.getValue()).isEqualTo("autre");
    }

    @Test
    void track_treatsMissingSourceAsDirect() {
        service.track(new PageViewRequest("/reussir", null, PageViewEvent.VIEW));

        verify(manager).increment(eq("/reussir"), eq("direct"), eq(PageViewEvent.VIEW), any());
    }

    @Test
    void stats_aggregatesBySourceAndSortsByViewsDesc() {
        LocalDate day = LocalDate.now();
        when(manager.since(eq("/reussir"), any())).thenReturn(List.of(
                row("tiktok", PageViewEvent.VIEW, day, 100),
                row("tiktok", PageViewEvent.VIEW, day.minusDays(1), 40),
                row("tiktok", PageViewEvent.CTA, day, 35),
                row("instagram", PageViewEvent.VIEW, day, 20),
                row("instagram", PageViewEvent.CTA, day, 10)));

        PageViewStatsResponse stats = service.stats("/reussir", 30);

        assertThat(stats.views()).isEqualTo(160);
        assertThat(stats.ctaClicks()).isEqualTo(45);
        assertThat(stats.sources()).extracting(PageViewStatsResponse.SourceStat::source)
                .containsExactly("tiktok", "instagram");
        assertThat(stats.sources().getFirst().views()).isEqualTo(140);
        assertThat(stats.sources().getFirst().ctaRate()).isEqualTo(25.0);
        assertThat(stats.sources().getLast().ctaRate()).isEqualTo(50.0);
        assertThat(stats.events()).containsEntry("VIEW", 160L).containsEntry("CTA", 45L);
    }

    @Test
    void stats_ctaRateIsNullWithoutViews() {
        LocalDate day = LocalDate.now();
        when(manager.since(eq("/reussir"), any()))
                .thenReturn(List.of(row("tiktok", PageViewEvent.CTA, day, 3)));

        PageViewStatsResponse stats = service.stats("/reussir", 7);

        assertThat(stats.sources()).singleElement()
                .extracting(PageViewStatsResponse.SourceStat::ctaRate)
                .isNull();
    }

    /**
     * Série CONTINUE : un point par jour de la fenêtre, même à zéro. Un trou se
     * lit comme une absence de mesure, pas comme une absence de visite — et une
     * journée choisie sans aucune vue doit rendre un point à zéro, pas une série
     * vide. Même règle que le funnel par compte.
     */
    @Test
    void stats_dailySeriesIsChronologicalAndContinuous() {
        LocalDate day = LocalDate.now();
        when(manager.since(eq("/reussir"), any())).thenReturn(List.of(
                row("tiktok", PageViewEvent.VIEW, day, 5),
                row("tiktok", PageViewEvent.VIEW, day.minusDays(2), 1),
                row("instagram", PageViewEvent.VIEW, day.minusDays(1), 2)));

        PageViewStatsResponse stats = service.stats("/reussir", 4);

        assertThat(stats.daily()).extracting(PageViewStatsResponse.DailyStat::day)
                .containsExactly(day.minusDays(3).toString(), day.minusDays(2).toString(),
                        day.minusDays(1).toString(), day.toString());
        assertThat(stats.daily().getFirst().views()).isZero();
        assertThat(stats.daily().getLast().views()).isEqualTo(5);
    }

    // ------------------------------------------------------------------------
    // Période explicite (from/to), même contrat que le funnel par compte
    // ------------------------------------------------------------------------

    @Test
    void stats_explicitWindowWinsOverDaysAndIsEchoedBack() {
        when(manager.since(eq("/reussir"), any())).thenReturn(List.of());

        PageViewStatsResponse stats = service.stats("/reussir", "2026-08-01", "2026-08-07", 30);

        assertThat(stats.from()).isEqualTo("2026-08-01");
        assertThat(stats.to()).isEqualTo("2026-08-07");
        assertThat(stats.days()).isEqualTo(7);
        assertThat(stats.daily()).hasSize(7);
    }

    /** Une seule journée : un seul point, même sans aucune vue ce jour-là. */
    @Test
    void stats_singleDayYieldsExactlyOnePoint() {
        when(manager.since(eq("/reussir"), any())).thenReturn(List.of());

        PageViewStatsResponse stats = service.stats("/reussir", "2026-08-18", "2026-08-18", 30);

        assertThat(stats.days()).isEqualTo(1);
        assertThat(stats.daily()).singleElement()
                .extracting(PageViewStatsResponse.DailyStat::day).isEqualTo("2026-08-18");
    }

    /**
     * Les buckets postérieurs à la borne de fin sont écartés : sans ça, une
     * journée choisie dans le passé renverrait tout ce qui l'a suivie.
     */
    @Test
    void stats_ignoresBucketsAfterTheEndBound() {
        LocalDate cible = LocalDate.parse("2026-08-18");
        when(manager.since(eq("/reussir"), any())).thenReturn(List.of(
                row("tiktok", PageViewEvent.VIEW, cible, 5),
                row("tiktok", PageViewEvent.VIEW, cible.plusDays(1), 99)));

        PageViewStatsResponse stats = service.stats("/reussir", "2026-08-18", "2026-08-18", 30);

        assertThat(stats.views()).isEqualTo(5);
    }

    @Test
    void stats_halfIntervalIsRejected_neverASilentFallbackOnDays() {
        assertThatThrownBy(() -> service.stats("/reussir", "2026-08-18", null, 30))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> service.stats("/reussir", null, "2026-08-18", 30))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void stats_invertedOrTooWideWindowIsRejected() {
        assertThatThrownBy(() -> service.stats("/reussir", "2026-08-19", "2026-08-18", 30))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> service.stats("/reussir",
                LocalDate.now().minusDays(400).toString(), LocalDate.now().toString(), 30))
                .isInstanceOf(IllegalArgumentException.class);
    }

    /** Non-régression : sans bornes, « days » reste la fenêtre glissante. */
    @Test
    void stats_withoutBoundsTheOldContractIsUnchanged() {
        when(manager.since(eq("/reussir"), any())).thenReturn(List.of());
        LocalDate today = LocalDate.now();

        PageViewStatsResponse stats = service.stats("/reussir", 7);

        assertThat(stats.days()).isEqualTo(7);
        assertThat(stats.to()).isEqualTo(today.toString());
        assertThat(stats.from()).isEqualTo(today.minusDays(6).toString());
    }

    @Test
    void stats_clampsWindowToASensibleRange() {
        when(manager.since(eq("/reussir"), any())).thenReturn(List.of());

        assertThat(service.stats("/reussir", 0).days()).isEqualTo(1);
        assertThat(service.stats("/reussir", 100_000).days()).isEqualTo(365);
    }

    @Test
    void stats_rejectsUnknownPath() {
        assertThatThrownBy(() -> service.stats("/autre-page", 30))
                .isInstanceOf(BusinessException.class);
    }
}
