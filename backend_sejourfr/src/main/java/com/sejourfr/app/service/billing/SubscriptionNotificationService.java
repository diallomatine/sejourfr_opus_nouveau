package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.service.email.event.PremiumAccessGrantedEvent;
import com.sejourfr.app.service.email.event.PremiumSubscriptionCanceledEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;

/**
 * Emails Premium des flux ABONNEMENT RECURRENT (dormants, conserves pour la
 * reversibilite) : activation et resiliation. Mutualise pour Stripe / Apple /
 * Google.
 *
 * <p>Ne fait que PUBLIER un evenement : le mail part apres le commit de la
 * transaction appelante (tous les appelants sont transactionnels —
 * {@code BillingService.handleWebhook}, les {@code @Transactional} des services
 * Apple / Google, {@code SubscriptionCancellationService}).
 */
@Service
@RequiredArgsConstructor
public class SubscriptionNotificationService {

    private final ApplicationEventPublisher eventPublisher;

    public void sendActivation(UserSubscription sub) {
        User user = sub.getUser();
        eventPublisher.publishEvent(new PremiumAccessGrantedEvent(
                user.getId(), user.getEmail(), sub.getId(), false));
    }

    public void sendCancellation(UserSubscription sub) {
        User user = sub.getUser();
        eventPublisher.publishEvent(new PremiumSubscriptionCanceledEvent(
                user.getId(), user.getEmail(), sub.getId()));
    }
}
