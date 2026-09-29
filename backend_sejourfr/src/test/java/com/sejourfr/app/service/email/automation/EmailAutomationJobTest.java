package com.sejourfr.app.service.email.automation;

import com.sejourfr.app.config.EmailProperties;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class EmailAutomationJobTest {

    private final EmailAutomationService automation = mock(EmailAutomationService.class);
    private final EmailDeferredRetryService retry = mock(EmailDeferredRetryService.class);
    private final EmailRetentionService retention = mock(EmailRetentionService.class);
    private final EmailProperties props = new EmailProperties();
    private final Instant now = Instant.parse("2027-01-01T08:00:00Z");
    private final EmailAutomationJob job = new EmailAutomationJob(automation, retry, retention, props,
            Clock.fixed(now, ZoneOffset.UTC));

    @Test
    void scenariosEteintsNeTournentPas() {
        props.getAutomation().setEnabled(false);

        job.scenarios();

        verify(automation, never()).runDaily(any());
    }

    @Test
    void scenariosAllumesTournentALHeureDeLHorloge() {
        job.scenarios();

        verify(automation).runDaily(now);
    }

    @Test
    void aucunePasseNePropageDException() {
        when(automation.runDaily(any())).thenThrow(new IllegalStateException("boom"));
        when(retry.retry(any())).thenThrow(new IllegalStateException("boom"));
        when(retention.purge(any())).thenThrow(new IllegalStateException("boom"));

        assertThatCode(() -> {
            job.scenarios();
            job.maintenance();
            job.retention();
        }).doesNotThrowAnyException();
    }
}
