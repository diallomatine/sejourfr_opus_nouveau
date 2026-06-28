package com.sejourfr.app.service.realtime;

import com.sejourfr.app.config.RealtimeProperties;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.manager.RealtimeSessionManager;
import com.sejourfr.app.service.SubscriptionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * Calcule le quota de sessions temps reel d'un utilisateur. Le cap est ATTACHE
 * AU PASS (souscription couvrante) et configurable par {@code Plan.code}
 * (cf. {@link RealtimeProperties.Quota}) — jamais en dur. La consommation est
 * derivee par comptage de lignes {@code realtime_sessions} sur ce pass, comme
 * tout le freemium existant.
 *
 * <p>Le temps reel n'est ouvert qu'aux pass TCF (module INTEGRAL). Hors pass
 * eligible, le cap est 0 → le candidat fait l'epreuve en async (jamais bloque).
 */
@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class RealtimeQuotaService {

    private final SubscriptionService subscriptionService;
    private final RealtimeSessionManager sessionManager;
    private final RealtimeProperties props;

    /**
     * @param subscription le pass couvrant (porte le scope du quota), ou
     *                     {@code null} si l'utilisateur n'a pas de pass eligible.
     * @param cap          nombre total de sessions allouees par ce pass.
     * @param remaining    sessions restantes ({@code >= 0}).
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
        int cap = capFor(subscription);
        if (cap <= 0) {
            return new Quota(subscription, 0, 0);
        }
        Instant cutoff = Instant.now().minusSeconds(props.getReservationWindowSeconds());
        long used = sessionManager.countConsumed(subscription.getId())
                + sessionManager.countRecentPending(subscription.getId(), cutoff);
        int remaining = (int) Math.max(0, cap - used);
        return new Quota(subscription, cap, remaining);
    }

    /** Sessions restantes pour affichage (compteur). 0 si pas de pass eligible. */
    public int remaining(UUID userId) {
        return evaluate(userId).remaining();
    }

    private int capFor(UserSubscription subscription) {
        Plan plan = subscription.getPlan();
        if (plan == null || !plan.getModuleAccess().hasTcf()) {
            return 0;
        }
        return props.getQuota().getByPlanCode()
                .getOrDefault(plan.getCode(), props.getQuota().getDefaultSessions());
    }
}
