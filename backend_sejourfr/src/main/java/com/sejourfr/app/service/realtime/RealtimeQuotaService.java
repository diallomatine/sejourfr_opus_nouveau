package com.sejourfr.app.service.realtime;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.service.SubscriptionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

/**
 * Lit le quota de sessions temps reel d'un utilisateur. Le solde est STOCKE sur
 * la souscription couvrante ({@code user_subscriptions.realtime_eo_sessions_remaining}) :
 * posé à la souscription (= {@code plans.realtime_eo_sessions}), cumulé à la
 * prolongation / au ré-achat, décrémenté de 1 à la connexion réelle d'une
 * session ({@code PENDING -> ACTIVE}), et ajustable par l'admin. On ne dérive
 * plus la consommation par comptage des lignes {@code realtime_sessions}.
 *
 * <p>Un plan sans acces TCF (Civique, Free) porte 0 → aucun solde crédité → le
 * candidat fait l'epreuve en async (jamais bloque).
 */
@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class RealtimeQuotaService {

    private final SubscriptionService subscriptionService;

    /**
     * @param subscription le pass couvrant (porte le solde), ou {@code null} si
     *                     l'utilisateur n'a pas de pass eligible.
     * @param cap          allocation par pass ({@code plans.realtime_eo_sessions}),
     *                     purement informatif (affichage « X sessions incluses »).
     * @param remaining    solde restant sur le pass ({@code >= 0}).
     */
    public record Quota(UserSubscription subscription, int cap, int remaining) {
        public boolean canStartRealtime() {
            return subscription != null && remaining > 0;
        }
    }

    public Quota evaluate(UUID userId) {
        Optional<UserSubscription> sub = subscriptionService.currentSubscription(userId);
        if (sub.isEmpty()) {
            return new Quota(null, 0, 0);
        }
        UserSubscription subscription = sub.get();
        Plan plan = subscription.getPlan();
        int cap = plan != null ? Math.max(0, plan.getRealtimeEoSessions()) : 0;
        int remaining = Math.max(0, subscription.getRealtimeEoSessionsRemaining());
        return new Quota(subscription, cap, remaining);
    }

    /** Sessions restantes pour affichage (compteur). 0 si pas de pass eligible. */
    public int remaining(UUID userId) {
        return evaluate(userId).remaining();
    }
}
