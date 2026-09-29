package com.sejourfr.app.service.analytics;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Clock;

/**
 * Passe quotidienne de retention des donnees de mesure
 * ({@code sejourfr.analytics.retention-cron}, Europe/Paris). Une seule instance
 * backend en production : pas de verrou distribue. Ne propage aucune exception.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AnalyticsRetentionJob {

    private final AnalyticsRetentionService retention;
    private final Clock clock;

    @Scheduled(cron = "${sejourfr.analytics.retention-cron:0 10 4 * * *}", zone = "Europe/Paris")
    public void purge() {
        try {
            retention.purge(clock.instant());
        } catch (RuntimeException e) {
            log.error("Purge de retention analytics en echec : {}", e.getMessage(), e);
        }
    }
}
