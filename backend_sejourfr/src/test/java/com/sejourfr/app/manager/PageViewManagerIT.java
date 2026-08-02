package com.sejourfr.app.manager;

import com.sejourfr.app.entity.PageView;
import com.sejourfr.app.enums.PageViewEvent;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Intégration réelle pour {@link PageViewManager} : c'est l'upsert Postgres
 * ({@code ON CONFLICT DO UPDATE}) qui est testé ici, pas du mapping — un
 * incrément doit créer la ligne puis l'incrémenter en place, sans jamais
 * violer la contrainte d'unicité du bucket.
 */
class PageViewManagerIT extends AbstractIntegrationTest {

    @Autowired
    private PageViewManager manager;

    private static final String PATH = "/reussir";

    private long hitsFor(String source, PageViewEvent event, LocalDate day) {
        return manager.since(PATH, day).stream()
                .filter(v -> v.getSource().equals(source) && v.getEvent() == event
                        && v.getDay().equals(day))
                .mapToLong(PageView::getHits)
                .sum();
    }

    @Test
    void increment_createsBucketThenAccumulatesInPlace() {
        LocalDate day = LocalDate.now();

        manager.increment(PATH, "tiktok", PageViewEvent.VIEW, day);
        assertThat(hitsFor("tiktok", PageViewEvent.VIEW, day)).isEqualTo(1);

        manager.increment(PATH, "tiktok", PageViewEvent.VIEW, day);
        manager.increment(PATH, "tiktok", PageViewEvent.VIEW, day);

        assertThat(hitsFor("tiktok", PageViewEvent.VIEW, day)).isEqualTo(3);

        // Une seule ligne pour ce bucket : on agrège, on ne journalise pas.
        List<PageView> rows = manager.since(PATH, day).stream()
                .filter(v -> v.getSource().equals("tiktok")
                        && v.getEvent() == PageViewEvent.VIEW && v.getDay().equals(day))
                .toList();
        assertThat(rows).hasSize(1);
    }

    @Test
    void increment_keepsEventsAndSourcesInSeparateBuckets() {
        LocalDate day = LocalDate.now();

        manager.increment(PATH, "instagram", PageViewEvent.VIEW, day);
        manager.increment(PATH, "instagram", PageViewEvent.VIEW, day);
        manager.increment(PATH, "instagram", PageViewEvent.CTA, day);
        manager.increment(PATH, "whatsapp", PageViewEvent.VIEW, day);

        assertThat(hitsFor("instagram", PageViewEvent.VIEW, day)).isEqualTo(2);
        assertThat(hitsFor("instagram", PageViewEvent.CTA, day)).isEqualTo(1);
        assertThat(hitsFor("whatsapp", PageViewEvent.VIEW, day)).isEqualTo(1);
    }

    @Test
    void since_excludesDaysBeforeTheWindow() {
        LocalDate old = LocalDate.now().minusDays(40);
        manager.increment(PATH, "youtube", PageViewEvent.VIEW, old);

        LocalDate from = LocalDate.now().minusDays(29);

        assertThat(manager.since(PATH, from))
                .noneMatch(v -> v.getDay().equals(old));
        assertThat(manager.since(PATH, old))
                .anyMatch(v -> v.getDay().equals(old) && v.getSource().equals("youtube"));
    }
}
