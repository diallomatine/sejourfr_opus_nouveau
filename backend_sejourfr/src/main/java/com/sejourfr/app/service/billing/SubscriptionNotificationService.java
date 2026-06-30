package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.service.MailService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * Envoi des emails transactionnels Premium (activation / résiliation) à partir
 * d'une {@link UserSubscription}. Mutualise la logique qui était dupliquée à
 * l'identique dans les trois canaux de paiement (Stripe / Apple / Google) —
 * un seul endroit pour le wording et les déclencheurs.
 */
@Service
@RequiredArgsConstructor
public class SubscriptionNotificationService {

    private final MailService mailService;

    public void sendActivation(UserSubscription sub) {
        User user = sub.getUser();
        String planName = sub.getPlan() != null ? sub.getPlan().getName() : "Premium";
        mailService.sendSubscriptionActivatedEmail(
                user.getEmail(), user.getFirstName(), planName,
                sub.getEndsAt(), sub.isAutoRenew());
    }

    public void sendCancellation(UserSubscription sub) {
        User user = sub.getUser();
        String planName = sub.getPlan() != null ? sub.getPlan().getName() : "Premium";
        mailService.sendSubscriptionCanceledEmail(
                user.getEmail(), user.getFirstName(), planName,
                sub.getEndsAt(), sub.getSource().name());
    }
}
