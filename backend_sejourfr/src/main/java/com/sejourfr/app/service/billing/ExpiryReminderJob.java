package com.sejourfr.app.service.billing;

import com.sejourfr.app.config.BillingProperties;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.MailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

/**
 * Rappel d'expiration des passes one-time (lot 5) : un e-mail « votre accès se
 * termine bientôt » quelques jours avant la fin, pour pousser au ré-achat.
 *
 * <p>Tourne une fois par jour. N'agit qu'en mode {@code billing.mode = ONE_TIME}
 * (en mode abonnement, le renouvellement est automatique, pas de rappel). Chaque
 * pass n'est rappelé qu'une fois grâce à {@code expiry_reminded_at} (anti-doublon).
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class ExpiryReminderJob {

    /** Fenêtre de rappel : on prévient quand l'accès expire dans ≤ 5 jours. */
    private static final int REMINDER_WINDOW_DAYS = 5;

    private final UserSubscriptionManager userSubscriptionManager;
    private final MailService mailService;
    private final BillingProperties billingProperties;

    /** Tous les jours à 09:00 (heure serveur). */
    @Scheduled(cron = "0 0 9 * * *")
    @Transactional
    public void sendExpiryReminders() {
        if (!billingProperties.isOneTime()) {
            return; // mode abonnement : pas de passes à rappeler
        }
        Instant now = Instant.now();
        Instant threshold = now.plus(REMINDER_WINDOW_DAYS, ChronoUnit.DAYS);
        List<UserSubscription> expiring =
                userSubscriptionManager.findOneTimeExpiringSoon(now, threshold);

        int sent = 0;
        for (UserSubscription sub : expiring) {
            try {
                User user = sub.getUser();
                if (user == null || user.getEmail() == null || user.getEmail().isBlank()) {
                    continue;
                }
                String planName = sub.getPlan() != null ? sub.getPlan().getName() : "Premium";
                mailService.sendAccessExpiringSoonEmail(
                        user.getEmail(), user.getFirstName(), planName, sub.getEndsAt());
                sub.setExpiryRemindedAt(now);
                userSubscriptionManager.save(sub);
                sent++;
            } catch (Exception e) {
                // Un échec d'envoi ne doit pas bloquer les autres rappels ni
                // rollback la transaction (le pass non marqué sera retenté demain).
                log.warn("Rappel d'expiration échoué pour sub={} : {}", sub.getId(), e.getMessage());
            }
        }
        if (sent > 0) {
            log.info("Rappels d'expiration one-time envoyés : {}", sent);
        }
    }
}
