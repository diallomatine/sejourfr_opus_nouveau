package com.sejourfr.app.service.activity;

import com.sejourfr.app.enums.AnalyticsEvent;
import com.sejourfr.app.manager.AnalyticsEventManager;
import com.sejourfr.app.manager.UserActivityManager;
import com.sejourfr.app.manager.UserLoginEventManager;
import com.sejourfr.app.service.analytics.AnalyticsConfig;
import com.sejourfr.app.util.FenetreMesure;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDate;

/**
 * Retention de l'activite des comptes : {@code activity.retentionDays} de la
 * config (365 j, D6). Appelee par la passe quotidienne {@code AnalyticsRetentionJob}
 * (une seule heure de purge pour la mesure), par lots bornes, une transaction
 * par lot (portee par les managers).
 *
 * <ul>
 *   <li>{@code user_login_event} : connexions anterieures a {@code now - 365 j} ;</li>
 *   <li>{@code user_activity_day} : jours anterieurs a {@code aujourd'hui (Paris) - 365 j} ;</li>
 *   <li>{@code analytics_event} de type {@code SCREEN_VIEWED} :
 *       {@code activity.screenViewRetentionDays} (365 j). Les autres evenements
 *       restent a la retention generale (395 j, {@code AnalyticsRetentionService}).</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AccountActivityRetentionService {

    private final UserLoginEventManager loginEventManager;
    private final UserActivityManager activityManager;
    private final AnalyticsEventManager eventManager;
    private final AnalyticsConfig config;

    /** @return lignes supprimees (connexions + jours d'activite). */
    public int purge(Instant now) {
        int batch = config.purgeBatchSize();
        Instant cutoff = now.minus(config.activity().retention());
        LocalDate dayCutoff = LocalDate.ofInstant(now, FenetreMesure.PARIS)
                .minusDays(config.activity().retentionDays());

        int logins = 0;
        int deleted;
        do {
            deleted = loginEventManager.deleteOlderThan(cutoff, batch);
            logins += deleted;
        } while (deleted == batch);

        int days = 0;
        do {
            deleted = activityManager.deleteBefore(dayCutoff, batch);
            days += deleted;
        } while (deleted == batch);

        Instant screenCutoff = now.minus(config.activity().screenViewRetention());
        int screens = 0;
        do {
            deleted = eventManager.deleteEventOlderThan(AnalyticsEvent.SCREEN_VIEWED, screenCutoff, batch);
            screens += deleted;
        } while (deleted == batch);

        if (logins + days + screens > 0) {
            log.info("Retention activite : {} connexion(s), {} jour(s) d'activite ({} j) et {} vue(s) d'ecran ({} j)"
                            + " purges", logins, days, config.activity().retentionDays(), screens,
                    config.activity().screenViewRetentionDays());
        }
        return logins + days + screens;
    }
}
