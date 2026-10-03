package com.sejourfr.app.service.session;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Clock;

/**
 * Passe quotidienne de purge de {@code refresh_tokens}
 * ({@code sejourfr.security.jwt.refresh-token-purge-cron}, Europe/Paris). Une
 * seule instance backend : pas de verrou distribue (une passe en double serait
 * idempotente). Ne propage aucune exception.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class RefreshTokenPurgeJob {

    private final RefreshTokenPurgeService purgeService;
    private final Clock clock;

    @Scheduled(cron = "${sejourfr.security.jwt.refresh-token-purge-cron:0 25 4 * * *}", zone = "Europe/Paris")
    public void purge() {
        try {
            purgeService.purge(clock.instant());
        } catch (RuntimeException e) {
            log.error("Purge des refresh tokens en echec : {}", e.getMessage(), e);
        }
    }
}
