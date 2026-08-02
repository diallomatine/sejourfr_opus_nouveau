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

    @Test
    void stats_dailySeriesIsChronological() {
        LocalDate day = LocalDate.now();
        when(manager.since(eq("/reussir"), any())).thenReturn(List.of(
                row("tiktok", PageViewEvent.VIEW, day, 5),
                row("tiktok", PageViewEvent.VIEW, day.minusDays(2), 1),
                row("instagram", PageViewEvent.VIEW, day.minusDays(1), 2)));

        PageViewStatsResponse stats = service.stats("/reussir", 30);

        assertThat(stats.daily()).extracting(PageViewStatsResponse.DailyStat::day)
                .containsExactly(day.minusDays(2).toString(), day.minusDays(1).toString(),
                        day.toString());
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
