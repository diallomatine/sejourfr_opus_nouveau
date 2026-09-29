package com.sejourfr.app.service.email.automation;

import com.sejourfr.app.config.EmailProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Clock;

/**
 * Les trois passes planifiees du systeme d'emails, fuseau Europe/Paris. Une
 * seule instance backend en production (audit §3) : pas de ShedLock, et l'index
 * unique partiel protegerait de toute facon des doublons.
 *
 * <ul>
 *   <li>scenarios ENGAGEMENT, quotidien ({@code sejourfr.email.automation.cron}),
 *       <b>eteint en dev par defaut</b> (arbitrage n°11) ;</li>
 *   <li>PENDING bloques + relance differee des mails evenementiels, horaire
 *       ({@code maintenance.retry-cron}, decision D-2) ;</li>
 *   <li>purge de retention, quotidienne ({@code maintenance.retention-cron}).</li>
 * </ul>
 * Aucune passe ne propage d'exception.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class EmailAutomationJob {

    private final EmailAutomationService automation;
    private final EmailDeferredRetryService deferredRetry;
    private final EmailRetentionService retention;
    private final EmailProperties properties;
    private final Clock clock;

    @Scheduled(cron = "${sejourfr.email.automation.cron:0 0 9 * * *}", zone = "Europe/Paris")
    public void scenarios() {
        if (!properties.getAutomation().isEnabled()) {
            return;
        }
        try {
            automation.runDaily(clock.instant());
        } catch (RuntimeException e) {
            log.error("Passage des scenarios d'emails en echec : {}", e.getMessage(), e);
        }
    }

    @Scheduled(cron = "${sejourfr.email.maintenance.retry-cron:0 20 * * * *}", zone = "Europe/Paris")
    public void maintenance() {
        try {
            automation.markStalePending(clock.instant());
            deferredRetry.retry(clock.instant());
        } catch (RuntimeException e) {
            log.error("Maintenance des emails en echec : {}", e.getMessage(), e);
        }
    }

    @Scheduled(cron = "${sejourfr.email.maintenance.retention-cron:0 40 3 * * *}", zone = "Europe/Paris")
    public void retention() {
        try {
            retention.purge(clock.instant());
        } catch (RuntimeException e) {
            log.error("Purge du journal des emails en echec : {}", e.getMessage(), e);
        }
    }
}
