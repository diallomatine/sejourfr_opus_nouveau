package com.sejourfr.app.service;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.UserSubscriptionManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * Toutes les methodes publiques lisent des relations lazy (Plan via
 * UserSubscription). Avec {@code open-in-view: false}, il faut une session
 * Hibernate ouverte pendant l'execution. On annote au niveau classe pour que
 * chaque entry point ouvre sa propre transaction read-only — l'annotation sur
 * une seule methode interne (currentAccess) etait court-circuitee par Spring
 * AOP qui n'intercepte pas les appels intra-bean.
 */
@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class SubscriptionService {

    // Code en base du plan gratuit (cf. 10_reference/V100__seed_reference.sql). Toute
    // souscription rattachée à ce plan est ignorée pour le calcul Premium,
    // même si son statut est ACTIVE.
    private static final String FREE_PLAN_CODE = "FREE";

    private final UserSubscriptionManager userSubscriptionManager;

    /**
     * Renvoie true si l'utilisateur a au moins un abonnement payant ACTIVE
     * non expire, quel que soit le module. Conserve pour compat : equivaut a
     * hasCivique(userId) || hasTcf(userId).
     */
    public boolean isPremium(UUID userId) {
        return effectiveModuleAccess(userId) != ModuleAccess.NONE;
    }

    /** Acces au module Civique (CIVIQUE_3MOIS ou INTEGRAL_3MOIS actif). */
    public boolean hasCivique(UUID userId) {
        return effectiveModuleAccess(userId).hasCivique();
    }

    /** Acces au module TCF (INTEGRAL_3MOIS actif uniquement). */
    public boolean hasTcf(UUID userId) {
        return effectiveModuleAccess(userId).hasTcf();
    }

    /**
     * Calcule le niveau d'acces effectif : on prend le plus permissif parmi
     * les souscriptions ACTIVE non expirees. INTEGRAL gagne sur CIVIQUE.
     */
    public ModuleAccess effectiveModuleAccess(UUID userId) {
        return currentAccess(userId).module();
    }

    /**
     * Renvoie l'acces courant : (module le plus permissif, date de fin la
     * plus tardive parmi les souscriptions actives le couvrant). endsAt est
     * null si l'utilisateur n'a aucun acces payant.
     */
    public CurrentAccess currentAccess(UUID userId) {
        Instant now = Instant.now();
        ModuleAccess best = ModuleAccess.NONE;
        Instant latestEnd = null;
        for (UserSubscription s : userSubscriptionManager.findByUserId(userId)) {
            if (!isCovering(s, now)) continue;

            ModuleAccess access = s.getPlan().getModuleAccess();
            // INTEGRAL gagne toujours, CIVIQUE remplace NONE.
            if (access == ModuleAccess.INTEGRAL
                    || (access == ModuleAccess.CIVIQUE && best == ModuleAccess.NONE)) {
                best = access;
            }
            Instant endsAt = s.getEndsAt();
            if (endsAt != null && (latestEnd == null || endsAt.isAfter(latestEnd))) {
                latestEnd = endsAt;
            }
        }
        return new CurrentAccess(best, latestEnd);
    }

    public record CurrentAccess(ModuleAccess module, Instant endsAt) {}

    /**
     * Retourne la souscription "qui compte" pour ce user — celle qui ouvre
     * l'accès Premium visible côté app. Critères de sélection :
     *
     * <ol>
     *   <li>Statut "couvrant" (cf. {@link #isCovering}) : ACTIVE / TRIAL /
     *       IN_GRACE, ou CANCELED tant que {@code endsAt} est dans le futur.</li>
     *   <li>Accès le plus permissif (INTEGRAL &gt; CIVIQUE).</li>
     *   <li>À niveau égal, {@code endsAt} le plus tardif.</li>
     * </ol>
     *
     * <p>Sert au endpoint {@code GET /api/billing/subscription-status} : l'app
     * mobile NE doit PAS proposer d'IAP si une souscription Stripe est encore
     * active, et inversement. C'est ici qu'on tranche.
     */
    public Optional<UserSubscription> currentSubscription(UUID userId) {
        Instant now = Instant.now();
        UserSubscription best = null;
        for (UserSubscription s : userSubscriptionManager.findByUserId(userId)) {
            if (!isCovering(s, now)) continue;
            if (best == null || isBetter(s, best)) {
                best = s;
            }
        }
        return Optional.ofNullable(best);
    }

    /**
     * Vrai si {@code candidate} doit l'emporter sur {@code incumbent} pour
     * l'affichage du statut Premium. INTEGRAL gagne sur CIVIQUE ; à module
     * égal, la date de fin la plus tardive l'emporte ; une souscription sans
     * date de fin (cas seed / lifetime) bat toute date finie.
     */
    private boolean isBetter(UserSubscription candidate, UserSubscription incumbent) {
        ModuleAccess candidateAccess = candidate.getPlan().getModuleAccess();
        ModuleAccess incumbentAccess = incumbent.getPlan().getModuleAccess();
        if (candidateAccess == ModuleAccess.INTEGRAL && incumbentAccess != ModuleAccess.INTEGRAL) {
            return true;
        }
        if (candidateAccess != ModuleAccess.INTEGRAL && incumbentAccess == ModuleAccess.INTEGRAL) {
            return false;
        }
        Instant candidateEnd = candidate.getEndsAt();
        Instant incumbentEnd = incumbent.getEndsAt();
        if (candidateEnd == null) return incumbentEnd != null;
        if (incumbentEnd == null) return false;
        return candidateEnd.isAfter(incumbentEnd);
    }

    private boolean isCovering(UserSubscription s, Instant now) {
        SubscriptionStatus status = s.getStatus();
        // ACTIVE / TRIAL / IN_GRACE = Premium ouvert sans condition.
        // CANCELED = Premium ouvert tant que ends_at est dans le futur (annulation
        //            sans expiration immédiate).
        // PENDING / EXPIRED / REFUNDED = pas de Premium.
        boolean statusCovers = status == SubscriptionStatus.ACTIVE
                || status == SubscriptionStatus.TRIAL
                || status == SubscriptionStatus.IN_GRACE
                || status == SubscriptionStatus.CANCELED;
        if (!statusCovers) {
            return false;
        }
        Plan plan = s.getPlan();
        if (plan == null || FREE_PLAN_CODE.equalsIgnoreCase(plan.getCode())) {
            return false;
        }
        return s.getEndsAt() == null || s.getEndsAt().isAfter(now);
    }
}
