package com.sejourfr.app.service.analytics;

import com.sejourfr.app.service.activity.AccountActivityRetentionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Clock;

/**
 * Passe quotidienne de retention des donnees de mesure
 * ({@code sejourfr.analytics.retention-cron}, Europe/Paris) : evenements et
 * visiteurs (395 j), puis activite des comptes (365 j). Une seule instance
 * backend en production : pas de verrou distribue. Ne propage aucune exception.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AnalyticsRetentionJob {

    private final AnalyticsRetentionService retention;
    private final AccountActivityRetentionService activityRetention;
    private final Clock clock;

    /** Deux passes independantes : l'echec de l'une n'empeche pas l'autre. */
    @Scheduled(cron = "${sejourfr.analytics.retention-cron:0 10 4 * * *}", zone = "Europe/Paris")
    public void purge() {
        try {
            retention.purge(clock.instant());
        } catch (RuntimeException e) {
            log.error("Purge de retention analytics en echec : {}", e.getMessage(), e);
        }
        try {
            activityRetention.purge(clock.instant());
        } catch (RuntimeException e) {
            log.error("Purge de retention de l'activite en echec : {}", e.getMessage(), e);
        }
    }
}
