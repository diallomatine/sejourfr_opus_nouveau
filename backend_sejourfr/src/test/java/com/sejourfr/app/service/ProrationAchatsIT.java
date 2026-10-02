package com.sejourfr.app.service;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AdminAccessOperationType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PaymentStatus;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AccesAdminFixtures;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * D-31 (révise D-07) : le crédit de proration Civique → Intégral se lit sur les
 * ACHATS payés, non remboursés, non neutralisés par un REVOKE admin applicable —
 * jamais sur l'accès effectif. Actions admin RÉELLES (service), pass réels en base.
 *
 * <p>Civique 30,00 € / 30 j, fin dans 20 j (+1 h : le nombre de jours entiers
 * restants ne dépend pas de la seconde du test) ⇒ crédit 20,00 € ; Intégral
 * 60,00 € ⇒ 40,00 € facturés.
 */
class ProrationAchatsIT extends AbstractIntegrationTest {

    private static final Duration JOUR = Duration.ofDays(1);
    private static final long PLEIN = 6000L;
    private static final long PRORATE = 4000L;

    @Autowired private TestData data;
    @Autowired private AccesAdminFixtures fx;
    @Autowired private BillingService billing;
    @Autowired private PlanManager planManager;
    @Autowired private UserSubscriptionManager subscriptionManager;
    @Autowired private EntityManager em;

    private User admin;
    private User u;
    private Plan integral;
    private UserSubscription civique;

    @BeforeEach
    void civiquePaye() {
        admin = data.admin();
        u = data.user();
        integral = prix(fx.pass(ModuleAccess.INTEGRAL, 30), "60.00");
        Plan pass = prix(fx.pass(ModuleAccess.CIVIQUE, 30), "30.00");
        Instant now = Instant.now();
        civique = fx.achat(u, pass, now.minus(JOUR.multipliedBy(10)),
                now.plus(JOUR.multipliedBy(20)).plus(Duration.ofHours(1)), SubscriptionSource.STRIPE);
        em.flush();
    }

    private Plan prix(Plan p, String euros) {
        p.setPrice(new BigDecimal(euros));
        return planManager.save(p);
    }

    private long montant() {
        em.flush();
        em.clear();
        return billing.computeOneTimeAmountCents(u.getId(), integral);
    }

    @Test
    @DisplayName("Témoin : Civique payé, aucune décision ⇒ crédit des 20 jours restants")
    void temoinSansDecision() {
        assertThat(montant()).isEqualTo(PRORATE);
    }

    @Test
    @DisplayName("Civique payé + GRANT Intégral (geste) ⇒ crédit Civique conservé")
    void grantIntegralConserveLeCredit() {
        fx.agir(u, admin, AdminAccessOperationType.GRANT, ModuleAccess.INTEGRAL, null, null, AccesAdminFixtures.jour(30));

        assertThat(montant()).isEqualTo(PRORATE);
    }

    @Test
    @DisplayName("Civique payé puis CORRECT_PRODUCT → Intégral ⇒ pas de crédit (valeur déjà convertie)")
    void correctionDeProduitSupprimeLeCredit() {
        fx.agir(u, admin, AdminAccessOperationType.CORRECT_PRODUCT, ModuleAccess.INTEGRAL, ModuleAccess.CIVIQUE,
                null, AccesAdminFixtures.jour(30));

        assertThat(montant()).isEqualTo(PLEIN);
    }

    @Test
    @DisplayName("Civique payé puis Terminer ⇒ pas de crédit")
    void terminerSupprimeLeCredit() {
        fx.agir(u, admin, AdminAccessOperationType.END, ModuleAccess.CIVIQUE, null, null, null);

        assertThat(montant()).isEqualTo(PLEIN);
    }

    @Test
    @DisplayName("Civique remboursé (total) ⇒ pas de crédit")
    void achatRembourse() {
        civique.setStatus(SubscriptionStatus.REFUNDED);
        civique.setPaymentStatus(PaymentStatus.REFUNDED);
        subscriptionManager.save(civique);

        assertThat(montant()).isEqualTo(PLEIN);
    }

    @Test
    @DisplayName("Civique partiellement remboursé (accès conservé) ⇒ pas de crédit")
    void achatPartiellementRembourse() {
        civique.setPaymentStatus(PaymentStatus.PARTIALLY_REFUNDED);
        subscriptionManager.save(civique);

        assertThat(montant()).isEqualTo(PLEIN);
    }

    @Test
    @DisplayName("Raccourcir le Civique à J+10 (REVOKE programmé) ⇒ crédit limité aux jours jusqu'à la révocation")
    void raccourcirLimiteLeCredit() {
        fx.agir(u, admin, AdminAccessOperationType.SHORTEN, ModuleAccess.CIVIQUE, null, null, AccesAdminFixtures.jour(10));

        long m = montant();
        // Révocation au lendemain du 10e jour à 00:00 Paris : 10 ou 11 jours entiers selon l'heure.
        assertThat(m).isBetween(PLEIN - 1100L, PLEIN - 1000L);
    }
}
