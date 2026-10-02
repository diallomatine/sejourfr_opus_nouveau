package com.sejourfr.app.service.billing;

import com.sejourfr.app.dto.SubscriptionStatusResponse;
import com.sejourfr.app.service.SubscriptionService;
import com.sejourfr.app.service.realtime.RealtimeQuotaService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Le statut Premium servi par {@code GET /api/billing/subscription-status} ET
 * par la réponse de {@code POST /api/billing/verify-receipt} — une seule
 * construction pour les deux : le mobile écrase {@code /me} avec ce statut au
 * démarrage, il doit donc lire le même accès effectif (GO §16).
 */
@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class SubscriptionStatusService {

    private final SubscriptionService subscriptionService;
    private final RealtimeQuotaService realtimeQuotaService;

    public SubscriptionStatusResponse statusFor(UUID userId) {
        RealtimeQuotaService.Quota quota = realtimeQuotaService.evaluate(userId);
        // Solde de sessions EO temps réel : exposé UNIQUEMENT quand le pass ouvre
        // un quota (cap > 0 = accès TCF/Intégral) ; null pour Civique/Free (non
        // concerné) → le front n'affiche le décompte que si présent.
        Integer realtimeRemaining = quota.cap() > 0 ? quota.remaining() : null;
        SubscriptionService.AccesEffectif acces = subscriptionService.effectiveAccess(userId);
        SubscriptionStatusResponse status = SubscriptionStatusResponse.from(
                acces.module(), acces.expiresAt(), acces.achat().orElse(null));
        return status.isPremium() ? status.withRealtimeSessionsRemaining(realtimeRemaining) : status;
    }
}
