package com.sejourfr.app.service;

import com.sejourfr.app.entity.AccessOverride;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.AccessOverrideManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.access.AccesEffectifResolver;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * 🛑 <b>L'autorité de l'accès EFFECTIF</b> (GO §17) : ce qu'un compte peut
 * réellement utiliser, calculé à la lecture à partir des ACHATS
 * ({@code user_subscriptions}, jamais modifiés ici) et des DÉCISIONS admin
 * courantes ({@code access_overrides}, V083). La règle elle-même vit dans
 * {@link AccesEffectifResolver} ; ce service charge les deux sources et la lui
 * applique. Tous les verrous ({@code hasCivique}/{@code hasTcf}), {@code /me},
 * {@code subscription-status}, {@code verify-receipt}, le quota EO temps réel et
 * la base de prolongation d'un pass passent par ici. Sans aucune décision admin,
 * chaque méthode rend exactement ce qu'elle rendait avant V083.
 *
 * <p>🛑 Deux mots, deux notions (D-30) : {@link #currentPurchase} = l'ACHAT
 * courant (historique commercial, décisions ignorées) ; {@link #effectiveAccess}
 * = le DROIT effectif (achats + décisions). Il n'existe plus de
 * {@code currentSubscription}, qui laissait croire que l'un valait l'autre.
 *
 * <p>Toutes les methodes publiques lisent des relations lazy (Plan via
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
    private final AccessOverrideManager accessOverrideManager;

    /** Les deux sources de l'accès d'un compte : ses achats et ses décisions admin courantes. */
    public record DonneesAcces(List<UserSubscription> achats, List<AccessOverride> decisions) {
        public static final DonneesAcces VIDE = new DonneesAcces(List.of(), List.of());
    }

    /**
     * L'accès effectif servi à {@code subscription-status} / {@code verify-receipt} :
     * le module effectif, sa fin ({@code null} = sans fin), et l'achat « qui
     * compte » de ce module s'il y en a un (vide pour un accès accordé par
     * l'admin sans achat correspondant).
     */
    public record AccesEffectif(ModuleAccess module, Instant expiresAt, Optional<UserSubscription> achat) {}

    /**
     * Renvoie true si l'utilisateur a un acces effectif, quel que soit le module.
     * Conserve pour compat : equivaut a hasCivique(userId) || hasTcf(userId).
     */
    public boolean isPremium(UUID userId) {
        return effectiveModuleAccess(userId) != ModuleAccess.NONE;
    }

    /** Acces au module Civique (pass Civique ou Integral effectif). */
    public boolean hasCivique(UUID userId) {
        return effectiveModuleAccess(userId).hasCivique();
    }

    /** Acces au module TCF (Integral effectif uniquement). */
    public boolean hasTcf(UUID userId) {
        return effectiveModuleAccess(userId).hasTcf();
    }

    /** Le module effectif : INTEGRAL gagne sur CIVIQUE. */
    public ModuleAccess effectiveModuleAccess(UUID userId) {
        return currentAccess(userId).module();
    }

    /**
     * Renvoie l'acces courant : (module effectif, fin de l'acces effectif tous
     * modules). endsAt est null si l'utilisateur n'a aucun acces. Sans decision
     * admin : la fin d'achat la plus tardive parmi les souscriptions couvrantes
     * (calcul historique inchange).
     */
    public CurrentAccess currentAccess(UUID userId) {
        return currentAccess(charger(userId), Instant.now());
    }

    public CurrentAccess currentAccess(DonneesAcces d, Instant now) {
        ModuleAccess module = AccesEffectifResolver.module(d.achats(), d.decisions(), now);
        return new CurrentAccess(module, finConventionHistorique(d, ModuleAccess.CIVIQUE, now));
    }

    public record CurrentAccess(ModuleAccess module, Instant endsAt) {}

    /**
     * Fin de l'accès EFFECTIF continu à un module AU MOINS {@code minModule}
     * (ordre NONE &lt; CIVIQUE &lt; INTEGRAL). Base de prolongation d'un pass
     * one-time (G-5) :
     * <ul>
     *   <li>acheter un pass CIVIQUE prolonge depuis la fin d'un accès CIVIQUE
     *       ou INTEGRAL effectif ;</li>
     *   <li>acheter un pass INTEGRAL ne prolonge que depuis un accès INTEGRAL
     *       effectif — un reste CIVIQUE n'est pas cumulé (il est crédité via la
     *       proration côté Stripe lors de l'upgrade) ;</li>
     *   <li>un achat révoqué par l'admin ne prolonge rien (on repart de
     *       maintenant) ; un accès accordé par l'admin prolonge depuis sa fin.</li>
     * </ul>
     * Lecture seule des décisions : le flux d'achat n'en écrit jamais.
     * Renvoie {@code null} si aucun accès effectif de ce niveau.
     */
    public Instant currentEndForAtLeast(UUID userId, ModuleAccess minModule) {
        return finConventionHistorique(charger(userId), minModule, Instant.now());
    }

    /**
     * 🛑 <b>ACHAT courant</b> — jamais un droit. La ligne d'ACHAT couvrante « qui
     * compte » (INTEGRAL &gt; CIVIQUE, puis fin la plus tardive), sans tenir
     * compte des décisions admin. Réservée aux gestes qui portent sur l'achat
     * lui-même (résilier un renouvellement, prévenir à la suppression du
     * compte) : un REVOKE admin ne doit pas empêcher de couper un prélèvement
     * récurrent. Ce que le compte peut UTILISER se lit sur
     * {@link #effectiveAccess} (D-05, révisé par D-30).
     */
    public Optional<UserSubscription> currentPurchase(UUID userId) {
        Instant now = Instant.now();
        return AccesEffectifResolver.meilleur(userSubscriptionManager.findByUserId(userId).stream()
                .filter(s -> covers(s, now))
                .toList());
    }

    /**
     * 🛑 <b>DROIT effectif</b> — ce que le compte peut utiliser maintenant :
     * module, fin, et l'achat qui porte ce droit ({@link AccesEffectif#achat()},
     * vide pour un accès accordé par l'admin sans achat de ce module). Lu par
     * {@code subscription-status}, {@code verify-receipt}, le quota EO temps réel
     * et le report du solde EO à la prolongation. Ne pas confondre avec
     * {@link #currentPurchase} (l'achat, sans les décisions admin).
     */
    public AccesEffectif effectiveAccess(UUID userId) {
        DonneesAcces d = charger(userId);
        Instant now = Instant.now();
        ModuleAccess module = AccesEffectifResolver.module(d.achats(), d.decisions(), now);
        if (module == ModuleAccess.NONE) {
            return new AccesEffectif(ModuleAccess.NONE, null, Optional.empty());
        }
        AccesEffectifResolver.Fin fin = AccesEffectifResolver.fin(d.achats(), d.decisions(), module, now);
        return new AccesEffectif(module, fin.instant(),
                AccesEffectifResolver.achatRepresentatif(d.achats(), d.decisions(), now));
    }

    /** Achats et décisions courantes d'un compte. */
    public DonneesAcces charger(UUID userId) {
        return new DonneesAcces(
                userSubscriptionManager.findByUserId(userId),
                accessOverrideManager.findCurrentByUserId(userId));
    }

    /** Achats et décisions courantes d'une page de comptes, en deux requêtes. */
    public Map<UUID, DonneesAcces> charger(Collection<UUID> userIds) {
        Map<UUID, List<UserSubscription>> achats = new HashMap<>();
        Map<UUID, List<AccessOverride>> decisions = new HashMap<>();
        if (!userIds.isEmpty()) {
            for (UserSubscription s : userSubscriptionManager.findByUserIds(userIds)) {
                achats.computeIfAbsent(s.getUser().getId(), k -> new java.util.ArrayList<>()).add(s);
            }
            for (AccessOverride o : accessOverrideManager.findCurrentByUserIds(userIds)) {
                decisions.computeIfAbsent(o.getUserId(), k -> new java.util.ArrayList<>()).add(o);
            }
        }
        Map<UUID, DonneesAcces> out = new HashMap<>();
        for (UUID id : userIds) {
            out.put(id, new DonneesAcces(achats.getOrDefault(id, List.of()),
                    decisions.getOrDefault(id, List.of())));
        }
        return out;
    }

    /**
     * Fin effective, avec la convention historique pour un accès sans fin (la
     * fin d'achat finie la plus tardive parmi les achats qui comptent).
     */
    private static Instant finConventionHistorique(DonneesAcces d, ModuleAccess min, Instant now) {
        AccesEffectifResolver.Fin fin = AccesEffectifResolver.fin(d.achats(), d.decisions(), min, now);
        if (fin.sansFin()) {
            return AccesEffectifResolver.derniereFinFinie(d.achats(), d.decisions(), min, now);
        }
        return fin.instant();
    }

    /**
     * 🛑 <b>LA regle « cette ligne d'ACHAT ouvre-t-elle un acces a cet instant ? »</b>,
     * appelee par {@link AccesEffectifResolver} et par les scenarios d'emails de
     * fin d'acces (docs/regles/emails.md) au lieu de la reecrire en SQL. Une
     * seule autorite.
     */
    public static boolean covers(UserSubscription s, Instant now) {
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
