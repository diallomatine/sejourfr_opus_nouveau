package com.sejourfr.app.service.email.automation;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionStatus;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class PremiumAccessEndResolverTest {

    private static final Instant NOW = Instant.parse("2027-03-10T08:00:00Z");
    private static final Duration JOUR = Duration.ofDays(1);
    private final PremiumAccessEndResolver resolver = new PremiumAccessEndResolver();

    private static UserSubscription acces(ModuleAccess module, Instant starts, Instant ends, SubscriptionStatus status) {
        Plan p = new Plan();
        p.setCode("PASS_" + module);
        p.setModuleAccess(module);
        UserSubscription s = new UserSubscription();
        s.setId(UUID.randomUUID());
        s.setPlan(p);
        s.setStatus(status);
        s.setStartsAt(starts);
        s.setEndsAt(ends);
        return s;
    }

    private static UserSubscription actif(ModuleAccess module, Instant ends) {
        return acces(module, NOW.minus(JOUR.multipliedBy(20)), ends, SubscriptionStatus.ACTIVE);
    }

    @Test
    void seulAccesQuiSeTermine() {
        UserSubscription a = actif(ModuleAccess.CIVIQUE, NOW.plus(JOUR.multipliedBy(5)));

        assertThat(resolver.seTermineSansRelais(a, List.of(a), NOW)).isTrue();
    }

    @Test
    void uneProlongationDeModuleEgalOuSuperieurSupprimeLeRappel() {
        UserSubscription a = actif(ModuleAccess.CIVIQUE, NOW.plus(JOUR.multipliedBy(5)));
        UserSubscription b = actif(ModuleAccess.INTEGRAL, NOW.plus(JOUR.multipliedBy(40)));

        assertThat(resolver.seTermineSansRelais(a, List.of(a, b), NOW)).isFalse();
    }

    @Test
    void unCiviquePlusLongNeProlongePasLIntegral() {
        UserSubscription integral = actif(ModuleAccess.INTEGRAL, NOW.plus(JOUR.multipliedBy(5)));
        UserSubscription civique = actif(ModuleAccess.CIVIQUE, NOW.plus(JOUR.multipliedBy(40)));

        assertThat(resolver.seTermineSansRelais(integral, List.of(integral, civique), NOW)).isTrue();
        PremiumAccessEndResolver.Wording w = resolver.wording(integral, List.of(integral, civique), integral.getEndsAt());
        assertThat(w.accessLabel()).isEqualTo("Votre accès TCF");
        assertThat(w.remainingAccessSentence()).isEqualTo("Votre accès Civique reste actif jusqu'au 19 avril 2027.");
    }

    @Test
    void libelles() {
        UserSubscription integral = actif(ModuleAccess.INTEGRAL, NOW.plus(JOUR));
        UserSubscription civique = actif(ModuleAccess.CIVIQUE, NOW.plus(JOUR));

        assertThat(resolver.wording(integral, List.of(integral), integral.getEndsAt()).accessLabel())
                .isEqualTo("Votre pass Intégral");
        assertThat(resolver.wording(civique, List.of(civique), civique.getEndsAt()))
                .isEqualTo(new PremiumAccessEndResolver.Wording("Votre accès Civique", ""));
    }

    @Test
    void unCiviqueQuiFinitAvantLIntegralNEstPasCite() {
        UserSubscription integral = actif(ModuleAccess.INTEGRAL, NOW.plus(JOUR.multipliedBy(5)));
        UserSubscription civique = actif(ModuleAccess.CIVIQUE, NOW.plus(JOUR.multipliedBy(2)));

        assertThat(resolver.wording(integral, List.of(integral, civique), integral.getEndsAt()).accessLabel())
                .isEqualTo("Votre pass Intégral");
    }

    @Test
    void termineSansRelais() {
        UserSubscription a = actif(ModuleAccess.CIVIQUE, NOW.minus(JOUR));

        assertThat(resolver.estTermineSansRelais(a, List.of(a), NOW)).isTrue();
        assertThat(resolver.seTermineSansRelais(a, List.of(a), NOW)).isFalse();
    }

    @Test
    void termineMaisUnAutreAccesActifOuAVenir() {
        UserSubscription a = actif(ModuleAccess.CIVIQUE, NOW.minus(JOUR));
        UserSubscription encore = actif(ModuleAccess.CIVIQUE, NOW.plus(JOUR.multipliedBy(10)));
        UserSubscription aVenir = acces(ModuleAccess.INTEGRAL, NOW.plus(JOUR), NOW.plus(JOUR.multipliedBy(30)),
                SubscriptionStatus.ACTIVE);

        assertThat(resolver.estTermineSansRelais(a, List.of(a, encore), NOW)).isFalse();
        assertThat(resolver.estTermineSansRelais(a, List.of(a, aVenir), NOW)).isFalse();
    }

    @Test
    void unPassRembourseNeSeTerminePas() {
        UserSubscription a = acces(ModuleAccess.CIVIQUE, NOW.minus(JOUR.multipliedBy(20)), NOW.minus(JOUR),
                SubscriptionStatus.REFUNDED);

        assertThat(resolver.estTermineSansRelais(a, List.of(a), NOW)).isFalse();
    }

    @Test
    void unAccesSansFinNeSeTerminePas() {
        UserSubscription a = actif(ModuleAccess.INTEGRAL, null);

        assertThat(resolver.seTermineSansRelais(a, List.of(a), NOW)).isFalse();
        assertThat(resolver.estTermineSansRelais(a, List.of(a), NOW)).isFalse();
    }
}
