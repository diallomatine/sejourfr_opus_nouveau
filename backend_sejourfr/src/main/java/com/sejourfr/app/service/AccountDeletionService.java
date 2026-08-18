package com.sejourfr.app.service;

import com.sejourfr.app.dto.AccountDeletionResponse;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ConversationManager;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.RefreshTokenManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserFunnelEventManager;
import com.sejourfr.app.manager.UserQuestionStatusManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.billing.StripeSubscriptionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Suppression de compte (RGPD + App Store Guideline 5.1.1(v)).
 *
 * <p>Stratégie : <b>anonymisation</b>. On conserve la ligne {@code users} et son
 * historique d'abonnement (obligation comptable : factures EI France ~10 ans),
 * mais on efface toutes les données personnelles directes
 * ({@link User#anonymize()}) et on purge les données de pratique (sans valeur
 * légale). L'accès Premium est coupé et les sessions sont révoquées.
 *
 * <p><b>Abonnement</b> : seul Stripe peut être résilié côté serveur. Pour
 * Apple/Google, le store interdit la résiliation serveur — on renvoie un message
 * indiquant à l'utilisateur où la faire lui-même (le binaire iOS n'affiche que
 * le message correspondant à sa propre source, jamais l'autre store).
 *
 * <p>Idempotent : un compte déjà anonymisé renvoie {@code deleted=true} sans
 * rien refaire.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AccountDeletionService {

    private final UserManager userManager;
    private final SubscriptionService subscriptionService;
    private final UserSubscriptionManager userSubscriptionManager;
    private final StripeSubscriptionService stripeSubscriptionService;
    private final AttemptManager attemptManager;
    private final DiagnosticSessionManager diagnosticSessionManager;
    private final LearningPlanObservationManager learningPlanObservationManager;
    private final UserQuestionStatusManager userQuestionStatusManager;
    private final ConversationManager conversationManager;
    private final UserFunnelEventManager userFunnelEventManager;
    private final RefreshTokenManager refreshTokenManager;

    @Transactional
    public AccountDeletionResponse deleteAccount(UUID userId) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new AccessDeniedException("Utilisateur introuvable"));

        if (user.getDeletedAt() != null) {
            return AccountDeletionResponse.alreadyDeleted();
        }

        // 1. Abonnement couvrant ? On coupe le renouvellement quand on peut, et
        //    on prépare le message d'action manuelle sinon.
        UserSubscription sub = subscriptionService.currentSubscription(userId).orElse(null);
        boolean hasActive = sub != null;
        String provider = sub != null ? sub.getSource().name() : null;
        String manualMessage = null;
        if (sub != null && sub.isAutoRenew()) {
            switch (sub.getSource()) {
                case STRIPE -> cancelStripeBestEffort(sub);
                case APPLE -> manualMessage =
                        "Votre abonnement App Store reste actif jusqu'à son terme. Pour le "
                        + "résilier : Réglages > [votre nom] > Abonnements.";
                case GOOGLE -> manualMessage =
                        "Votre abonnement Google Play reste actif jusqu'à son terme. Pour le "
                        + "résilier : Google Play > Abonnements.";
            }
        }

        // 2. Purge des données de pratique (cascade base sur les enfants).
        // Les sessions référencent deux attempts en RESTRICT : elles partent
        // avant les attempts. Les observations du Plan sont elles aussi des
        // données de pratique et ne doivent pas survivre à l'anonymisation.
        learningPlanObservationManager.deleteByUserId(userId);
        diagnosticSessionManager.deleteByUserId(userId);
        attemptManager.deleteByUserId(userId);
        userQuestionStatusManager.deleteByUserId(userId);
        conversationManager.deleteByUserId(userId);
        // Les étapes de funnel décrivent ce que CETTE personne a fait : elles
        // ne survivent pas à son anonymisation. La cascade base ne suffit pas —
        // la ligne `users` reste, seule la personne disparaît.
        userFunnelEventManager.deleteByUserId(userId);

        // 3. Révocation de toutes les sessions (refresh tokens).
        refreshTokenManager.revokeAllForUser(userId);

        // 4. Anonymisation du compte (historique d'abonnement conservé anonymisé).
        user.anonymize();
        userManager.save(user);

        log.info("Compte {} anonymisé (suppression). Abonnement actif={}, source={}.",
                userId, hasActive, provider);

        return new AccountDeletionResponse(true, hasActive, provider, manualMessage);
    }

    /**
     * Coupe le renouvellement Stripe sans bloquer la suppression : une panne
     * Stripe ne doit pas empêcher l'utilisateur de supprimer son compte. On log
     * et on continue — le webhook ou un nettoyage ultérieur restera cohérent.
     */
    private void cancelStripeBestEffort(UserSubscription sub) {
        String stripeSubId = sub.getOriginalTransactionId();
        if (stripeSubId == null || stripeSubId.isBlank()) {
            return;
        }
        try {
            stripeSubscriptionService.cancelAtPeriodEnd(stripeSubId);
            sub.setStatus(SubscriptionStatus.CANCELED);
            sub.setAutoRenew(false);
            userSubscriptionManager.save(sub);
        } catch (Exception e) {
            log.warn("Résiliation Stripe échouée lors de la suppression du compte (sub {}) : {}",
                    sub.getId(), e.getMessage());
        }
    }
}
