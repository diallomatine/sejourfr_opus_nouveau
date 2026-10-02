package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.AccessOverride;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AccessOverrideType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PaymentStatus;
import com.sejourfr.app.service.SubscriptionService;
import com.sejourfr.app.service.access.AccesEffectifResolver;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

/**
 * 🛑 <b>LA règle du crédit de proration</b> d'un upgrade Stripe Civique → Intégral
 * (D-07, révisée par D-31). Pur : aucune lecture en base.
 *
 * <p>Les décisions admin disent ce que le compte peut UTILISER ; les achats, ce
 * qu'il a réellement PAYÉ. Le crédit se calcule donc sur les ACHATS, jamais sur
 * l'accès effectif : un GRANT Intégral (geste) ne fait pas perdre le crédit d'un
 * Civique payé. Un achat entre dans le calcul s'il est :
 * <ul>
 *   <li>valide maintenant ({@link SubscriptionService#covers}, seule autorité) ;</li>
 *   <li>payé et non remboursé — ni {@code REFUNDED}, ni {@code PARTIALLY_REFUNDED}
 *       ({@code null} = achat antérieur à la mesure, tenu pour payé) ;</li>
 *   <li>non neutralisé par un REVOKE admin applicable maintenant — même lecture que
 *       l'accès effectif : achat antérieur à la décision
 *       ({@link AccesEffectifResolver#dateAchat}). Un REVOKE ne naît que de
 *       Terminer, Raccourcir ou Corriger le produit (et de leurs copies
 *       tronquées) : après une correction Civique → Intégral, la valeur Civique a
 *       déjà été convertie, il n'y a plus rien à créditer.</li>
 * </ul>
 * Parmi eux, le meilleur au sens historique (INTEGRAL &gt; CIVIQUE, puis fin la
 * plus tardive) : un Intégral payé ⇒ aucun crédit. Les jours crédités s'arrêtent
 * au début d'un REVOKE programmé qui neutralisera l'achat. Sans décision admin ni
 * remboursement : exactement le calcul d'avant V083 (seul écart : un Civique
 * partiellement remboursé n'est plus crédité).
 */
public final class CreditProration {

    private CreditProration() {}

    /** Le crédit en euros (arrondi au centime), ou vide s'il n'y a rien à créditer. */
    public static Optional<BigDecimal> creditCivique(List<UserSubscription> achats,
                                                     List<AccessOverride> decisions, Instant now) {
        Optional<UserSubscription> achat = AccesEffectifResolver.meilleur(achats.stream()
                .filter(s -> SubscriptionService.covers(s, now))
                .filter(s -> AccesEffectifResolver.produitDe(s) != null)
                .filter(CreditProration::payeNonRembourse)
                .filter(s -> neutralisePar(s, decisions, now).map(d -> d.getStartsAt().isAfter(now)).orElse(true))
                .toList());
        if (achat.isEmpty() || AccesEffectifResolver.produitDe(achat.get()) != ModuleAccess.CIVIQUE) {
            return Optional.empty();
        }
        UserSubscription civique = achat.get();
        int duree = civique.getPlan().getDurationDays();
        Instant fin = civique.getEndsAt();
        if (fin == null || duree <= 0) return Optional.empty();
        Optional<AccessOverride> revokeProgramme = neutralisePar(civique, decisions, now);
        if (revokeProgramme.isPresent() && revokeProgramme.get().getStartsAt().isBefore(fin)) {
            fin = revokeProgramme.get().getStartsAt();
        }
        if (!fin.isAfter(now)) return Optional.empty();
        long joursRestants = Math.max(0, ChronoUnit.DAYS.between(now, fin));
        return Optional.of(civique.getPlan().getPrice()
                .multiply(BigDecimal.valueOf(joursRestants))
                .divide(BigDecimal.valueOf(duree), 2, RoundingMode.HALF_UP));
    }

    private static boolean payeNonRembourse(UserSubscription s) {
        PaymentStatus p = s.getPaymentStatus();
        return p != PaymentStatus.REFUNDED && p != PaymentStatus.PARTIALLY_REFUNDED;
    }

    /**
     * Le premier REVOKE courant de ce produit, en cours ou programmé, qui
     * neutralise cet achat (achat antérieur à la décision) : début passé ⇒
     * neutralisé maintenant ; début futur ⇒ les jours crédités s'y arrêtent. Un
     * achat postérieur à la décision n'est jamais neutralisé : un REVOKE ne
     * bloque pas un rachat.
     */
    private static Optional<AccessOverride> neutralisePar(UserSubscription s, List<AccessOverride> decisions,
                                                          Instant now) {
        ModuleAccess produit = AccesEffectifResolver.produitDe(s);
        Instant dateAchat = AccesEffectifResolver.dateAchat(s);
        return decisions.stream()
                .filter(AccessOverride::estCourante)
                .filter(d -> d.getProduct() == produit && d.getType() == AccessOverrideType.REVOKE)
                .filter(d -> d.getEndsAt() == null || d.getEndsAt().isAfter(now))
                .filter(d -> !dateAchat.isAfter(d.getDecidedAt()))
                .min(Comparator.comparing(AccessOverride::getStartsAt));
    }
}
