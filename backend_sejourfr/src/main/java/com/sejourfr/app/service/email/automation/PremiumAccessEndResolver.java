package com.sejourfr.app.service.email.automation;

import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.service.SubscriptionService;
import com.sejourfr.app.service.email.EmailFormats;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

/**
 * <b>Ce qui se termine vraiment</b>, pour les mails {@code PREMIUM_ENDING_*} et
 * {@code PREMIUM_ENDED} — sans condition dans les gabarits (complement F).
 *
 * <p>Un achat = une ligne ; une prolongation cree une NOUVELLE ligne qui
 * chevauche l'ancienne (audit §4.2). « Aucun autre acces prolongeant au-dela »
 * = aucune autre ligne couvrante de module &ge; qui finit plus tard. La
 * couverture elle-meme est lue chez son autorite unique,
 * {@link SubscriptionService#covers}. Pur : aucune lecture en base.
 */
@Component
public class PremiumAccessEndResolver {

    /** Le libelle et la phrase eventuelle, calcules en Java, passes en variables plates. */
    public record Wording(String accessLabel, String remainingAccessSentence) {}

    static int rang(UserSubscription s) {
        ModuleAccess m = s.getPlan() == null ? ModuleAccess.NONE : s.getPlan().getModuleAccess();
        return m == null ? 0 : m.ordinal();
    }

    /** L'acces couvre encore, et rien de module &ge; ne le prolonge au-dela de sa fin. */
    public boolean seTermineSansRelais(UserSubscription access, List<UserSubscription> all, Instant now) {
        if (access.getEndsAt() == null || !SubscriptionService.covers(access, now)) {
            return false;
        }
        return all.stream().filter(o -> !o.getId().equals(access.getId()))
                .filter(o -> rang(o) >= rang(access))
                .filter(o -> SubscriptionService.covers(o, now))
                .noneMatch(o -> o.getEndsAt() == null || o.getEndsAt().isAfter(access.getEndsAt()));
    }

    /**
     * L'acces COUVRAIT jusqu'a sa fin (deja passee), et aucun autre acces de module
     * &ge; n'est actif ni a venir. Un pass rembourse ou revoque ne « se termine » pas.
     */
    public boolean estTermineSansRelais(UserSubscription access, List<UserSubscription> all, Instant now) {
        Instant end = access.getEndsAt();
        if (end == null || end.isAfter(now) || !SubscriptionService.covers(access, end.minusMillis(1))) {
            return false;
        }
        return all.stream().filter(o -> !o.getId().equals(access.getId()))
                .filter(o -> rang(o) >= rang(access))
                .noneMatch(o -> SubscriptionService.covers(o, now)
                        || (o.getStartsAt() != null && o.getStartsAt().isAfter(now)
                        && SubscriptionService.covers(o, o.getStartsAt())));
    }

    /**
     * « Votre pass Integral » / « Votre acces TCF » (+ « Votre acces Civique reste
     * actif jusqu'au … ») / « Votre acces Civique » — arbitrage n°3 : ne jamais
     * annoncer la fin de tout quand seul le TCF s'arrete.
     *
     * @param at l'instant ou l'on regarde ce qui reste : la fin de l'acces pour
     *           un mail « se termine », maintenant pour un mail « est termine »
     */
    public Wording wording(UserSubscription access, List<UserSubscription> all, Instant at) {
        if (rang(access) < ModuleAccess.INTEGRAL.ordinal()) {
            return new Wording("Votre accès Civique", "");
        }
        Optional<Instant> civiqueJusquA = all.stream()
                .filter(o -> !o.getId().equals(access.getId()))
                .filter(o -> rang(o) == ModuleAccess.CIVIQUE.ordinal())
                .filter(o -> SubscriptionService.covers(o, at))
                .map(UserSubscription::getEndsAt)
                .max(Comparator.nullsLast(Comparator.naturalOrder()));
        if (civiqueJusquA.isEmpty()) {
            return new Wording("Votre pass Intégral", "");
        }
        Instant jusquA = civiqueJusquA.get();
        return new Wording("Votre accès TCF", jusquA == null
                ? "Votre accès Civique reste actif."
                : "Votre accès Civique reste actif jusqu'au " + EmailFormats.date(jusquA) + ".");
    }
}
