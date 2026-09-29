package com.sejourfr.app.service.email.automation;

import com.sejourfr.app.manager.EmailDeliveryManager;
import com.sejourfr.app.service.email.EmailAutomationConfig;
import com.sejourfr.app.service.email.EmailFormats;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;

/**
 * Retention d'{@code email_deliveries} : 12 mois (arbitrage n°16), purge par lots
 * bornes, une transaction par lot. (La suppression a l'anonymisation du compte
 * vit dans {@code AccountDeletionService}.)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EmailRetentionService {

    private final EmailDeliveryManager deliveries;
    private final EmailAutomationConfig config;

    public int purge(Instant now) {
        Instant cutoff = now.atZone(EmailFormats.PARIS).minusMonths(config.retentionMonths()).toInstant();
        int total = 0;
        int deleted;
        do {
            deleted = deliveries.deleteOlderThan(cutoff, config.batchSize());
            total += deleted;
        } while (deleted == config.batchSize());
        if (total > 0) {
            log.info("Journal des emails : {} ligne(s) de plus de {} mois purgee(s)", total, config.retentionMonths());
        }
        return total;
    }
}
