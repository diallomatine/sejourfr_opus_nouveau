package com.sejourfr.app.service.activity;

import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.manager.UserActivityManager;
import com.sejourfr.app.service.analytics.AnalyticsConfig;
import com.sejourfr.app.service.analytics.AnalyticsConfigLoader;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

/** Le service d'activite ne leve jamais, et un echec d'ecriture se retente a la requete suivante. */
class UserActivityServiceTest {

    private static final AnalyticsConfig CONFIG = AnalyticsConfigLoader.load(2);
    private static final Instant T0 = Instant.parse("2026-10-03T08:00:00Z");

    @Test
    void echecDEcritureAvale_puisRetente() {
        UserActivityManager manager = mock(UserActivityManager.class);
        doThrow(new IllegalStateException("base indisponible"))
                .when(manager).touch(any(), any(), any(), any());
        UserActivityService service = new UserActivityService(manager, CONFIG, Clock.fixed(T0, ZoneOffset.UTC));
        UUID user = UUID.randomUUID();

        assertThat(service.touch(user, ClientPlatform.WEB)).isFalse();
        assertThat(service.touch(user, ClientPlatform.WEB)).isFalse();

        verify(manager, times(2)).touch(user, LocalDate.of(2026, 10, 3), ClientPlatform.WEB, T0);
    }

    @Test
    void sansCompteRienNEstEcrit() {
        UserActivityManager manager = mock(UserActivityManager.class);
        UserActivityService service = new UserActivityService(manager, CONFIG, Clock.fixed(T0, ZoneOffset.UTC));

        assertThat(service.touch(null, ClientPlatform.WEB)).isFalse();
        verify(manager, times(0)).touch(any(), any(), any(), any());
    }

    @Test
    void plateformeNulleRangeeEnUnknown() {
        UserActivityManager manager = mock(UserActivityManager.class);
        UserActivityService service = new UserActivityService(manager, CONFIG, Clock.fixed(T0, ZoneOffset.UTC));

        assertThat(service.touch(UUID.randomUUID(), null)).isTrue();
        verify(manager).touch(any(), any(), org.mockito.ArgumentMatchers.eq(ClientPlatform.UNKNOWN), any());
    }
}
