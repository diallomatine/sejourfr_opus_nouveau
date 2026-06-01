package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.MailService;
import com.sejourfr.app.service.SubscriptionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

/**
 * Accorde l'accès Premium pour un PASS one-time (lot 5), commun aux 3 canaux
 * (Stripe / Apple / Google). Écrit une ligne {@code user_subscriptions}
 * {@code ACTIVE}, {@code auto_renew=false}, dont la durée est posée par le
 * backend ({@code plan.durationDays}) — contrairement à l'abonnement où la
 * période vient du store.
 *
 * <p><b>Prolongation (décision produit)</b> : un nouvel achat repart de la fin
 * d'accès courante, pas de « maintenant ». Donc acheter un pass alors qu'un
 * accès est encore valide CUMULE les durées. La proration éventuelle (upgrade
 * Civique→Intégral) est gérée en amont côté Stripe (web) — ici on ne fait que
 * créditer la durée du pass acheté.
 *
 * <p><b>Idempotence</b> : la clé {@code (source, original_transaction_id)} est
 * unique. Re-vérifier le même reçu (replay) ne crée pas de seconde période —
 * on renvoie la ligne existante telle quelle.
 */
@Service
@Transactional
@RequiredArgsConstructor
@Slf4j
public class OneTimeAccessService {

    private final UserManager userManager;
    private final UserSubscriptionManager userSubscriptionManager;
    private final SubscriptionService subscriptionService;
    private final MailService mailService;

    /**
     * Crédite l'accès du pass {@code plan} à {@code userId} via {@code source}.
     *
     * @param originalTransactionId clé de réconciliation stable (Stripe:
     *        session/payment_intent ; Apple: transactionId ; Google:
     *        purchaseToken/orderId).
     * @param externalTransactionId id de transaction courant (traçabilité).
     * @return la souscription accordée (existante en cas de replay).
     */
    public UserSubscription grantOneTimeAccess(
            UUID userId, Plan plan, SubscriptionSource source,
            String originalTransactionId, String externalTransactionId) {

        UserSubscription existing = userSubscriptionManager
                .findBySourceAndOriginalTransactionId(source, originalTransactionId)
                .orElse(null);

        if (existing != null) {
            // Anti account-stealing : un reçu rattaché à un autre compte ne peut
            // pas être réutilisé.
            if (existing.getUser() == null || !existing.getUser().getId().equals(userId)) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "Ce paiement est déjà rattaché à un autre compte.");
            }
            // Replay du même achat : idempotent, pas de nouvelle période.
            log.info("Pass one-time déjà accordé (replay) user={} source={} tx={}",
                    userId, source, originalTransactionId);
            return existing;
        }

        User user = userManager.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "User introuvable : " + userId));

        Instant now = Instant.now();
        // Prolongation par module : on repart de la fin d'un accès existant de
        // module >= celui acheté (cf. currentEndForAtLeast). Ainsi un upgrade
        // Civique→Intégral repart de maintenant (le reste Civique est crédité
        // via la proration Stripe), tandis qu'un re-achat même module cumule.
        Instant currentEnd =
                subscriptionService.currentEndForAtLeast(userId, plan.getModuleAccess());
        Instant base = (currentEnd != null && currentEnd.isAfter(now)) ? currentEnd : now;
        Instant endsAt = base.plus(plan.getDurationDays(), ChronoUnit.DAYS);

        UserSubscription sub = new UserSubscription();
        sub.setUser(user);
        sub.setPlan(plan);
        sub.setProductId(plan.getCode());
        sub.setSource(source);
        sub.setOriginalTransactionId(originalTransactionId);
        sub.setExternalTransactionId(externalTransactionId);
        sub.setStatus(SubscriptionStatus.ACTIVE);
        sub.setAutoRenew(false);
        sub.setStartsAt(now);
        sub.setEndsAt(endsAt);
        userSubscriptionManager.save(sub);

        log.info("Pass one-time accordé user={} plan={} source={} endsAt={} (base={})",
                userId, plan.getCode(), source, endsAt, base);

        mailService.sendSubscriptionActivatedEmail(
                user.getEmail(), user.getFirstName(), plan.getName(),
                endsAt, source.name());

        return sub;
    }
}
