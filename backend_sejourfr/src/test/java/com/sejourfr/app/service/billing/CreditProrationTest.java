package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.AccessOverride;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AccessOverrideType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PaymentStatus;
import com.sejourfr.app.enums.SubscriptionStatus;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/** D-31 : la règle pure du crédit de proration, sur les achats (jamais sur l'accès effectif). */
class CreditProrationTest {

    private static final Instant NOW = Instant.parse("2026-10-02T10:00:00Z");
    private static final Duration JOUR = Duration.ofDays(1);

    private static UserSubscription achat(ModuleAccess m, Instant achete, Instant fin, PaymentStatus paiement) {
        Plan p = new Plan();
        p.setCode("PASS_" + m);
        p.setModuleAccess(m);
        p.setDurationDays(30);
        p.setPrice(new BigDecimal("30.00"));
        UserSubscription s = new UserSubscription();
        s.setId(UUID.randomUUID());
        s.setPlan(p);
        s.setStatus(SubscriptionStatus.ACTIVE);
        s.setStartsAt(achete);
        s.setPurchasedAt(achete);
        s.setEndsAt(fin);
        s.setPaymentStatus(paiement);
        return s;
    }

    private static UserSubscription civique() {
        return achat(ModuleAccess.CIVIQUE, NOW.minus(JOUR.multipliedBy(10)), NOW.plus(JOUR.multipliedBy(20)),
                PaymentStatus.PAID);
    }

    private static AccessOverride decision(ModuleAccess p, AccessOverrideType type, Instant debut, Instant fin,
                                           Instant decidee) {
        AccessOverride o = new AccessOverride();
        o.setId(UUID.randomUUID());
        o.setProduct(p);
        o.setType(type);
        o.setStartsAt(debut);
        o.setEndsAt(fin);
        o.setDecidedAt(decidee);
        return o;
    }

    @Test
    @DisplayName("Civique payé, 20 jours restants sur 30 : crédit 20,00 €")
    void creditNominal() {
        assertThat(CreditProration.creditCivique(List.of(civique()), List.of(), NOW))
                .contains(new BigDecimal("20.00"));
    }

    @Test
    @DisplayName("Un GRANT Intégral ne retire pas le crédit d'un Civique payé")
    void grantIntegralSansEffet() {
        AccessOverride grant = decision(ModuleAccess.INTEGRAL, AccessOverrideType.GRANT,
                NOW.minus(JOUR), NOW.plus(JOUR.multipliedBy(40)), NOW.minus(JOUR));
        assertThat(CreditProration.creditCivique(List.of(civique()), List.of(grant), NOW))
                .contains(new BigDecimal("20.00"));
    }

    @Test
    @DisplayName("REVOKE Civique applicable, achat antérieur : aucun crédit")
    void revokeApplicable() {
        AccessOverride revoke = decision(ModuleAccess.CIVIQUE, AccessOverrideType.REVOKE,
                NOW.minus(JOUR), null, NOW.minus(JOUR));
        assertThat(CreditProration.creditCivique(List.of(civique()), List.of(revoke), NOW)).isEmpty();
    }

    @Test
    @DisplayName("Rachat Civique APRÈS le REVOKE : le rachat est crédité")
    void rachatApresRevoke() {
        AccessOverride revoke = decision(ModuleAccess.CIVIQUE, AccessOverrideType.REVOKE,
                NOW.minus(JOUR.multipliedBy(5)), null, NOW.minus(JOUR.multipliedBy(5)));
        UserSubscription rachat = achat(ModuleAccess.CIVIQUE, NOW.minus(JOUR.multipliedBy(2)),
                NOW.plus(JOUR.multipliedBy(15)), PaymentStatus.PAID);
        assertThat(CreditProration.creditCivique(List.of(civique(), rachat), List.of(revoke), NOW))
                .contains(new BigDecimal("15.00"));
    }

    @Test
    @DisplayName("REVOKE programmé dans 6 jours : seuls 6 jours sont crédités")
    void revokeProgrammePlafonne() {
        AccessOverride revoke = decision(ModuleAccess.CIVIQUE, AccessOverrideType.REVOKE,
                NOW.plus(JOUR.multipliedBy(6)), null, NOW.minus(JOUR));
        assertThat(CreditProration.creditCivique(List.of(civique()), List.of(revoke), NOW))
                .contains(new BigDecimal("6.00"));
    }

    @Test
    @DisplayName("Remboursé, partiellement remboursé : aucun crédit ; statut de paiement inconnu (ancien achat) : crédité")
    void statutsDePaiement() {
        UserSubscription rembourse = achat(ModuleAccess.CIVIQUE, NOW.minus(JOUR), NOW.plus(JOUR.multipliedBy(20)),
                PaymentStatus.REFUNDED);
        UserSubscription partiel = achat(ModuleAccess.CIVIQUE, NOW.minus(JOUR), NOW.plus(JOUR.multipliedBy(20)),
                PaymentStatus.PARTIALLY_REFUNDED);
        UserSubscription ancien = achat(ModuleAccess.CIVIQUE, NOW.minus(JOUR), NOW.plus(JOUR.multipliedBy(20)), null);

        assertThat(CreditProration.creditCivique(List.of(rembourse), List.of(), NOW)).isEmpty();
        assertThat(CreditProration.creditCivique(List.of(partiel), List.of(), NOW)).isEmpty();
        assertThat(CreditProration.creditCivique(List.of(ancien), List.of(), NOW)).contains(new BigDecimal("20.00"));
    }

    @Test
    @DisplayName("Un Intégral payé couvrant : rien à créditer ; révoqué, le Civique payé redevient créditable")
    void integralPaye() {
        UserSubscription integral = achat(ModuleAccess.INTEGRAL, NOW.minus(JOUR), NOW.plus(JOUR.multipliedBy(5)),
                PaymentStatus.PAID);
        assertThat(CreditProration.creditCivique(List.of(civique(), integral), List.of(), NOW)).isEmpty();

        AccessOverride revokeIntegral = decision(ModuleAccess.INTEGRAL, AccessOverrideType.REVOKE,
                NOW.minus(JOUR), null, NOW);
        assertThat(CreditProration.creditCivique(List.of(civique(), integral), List.of(revokeIntegral), NOW))
                .contains(new BigDecimal("20.00"));
    }
}
