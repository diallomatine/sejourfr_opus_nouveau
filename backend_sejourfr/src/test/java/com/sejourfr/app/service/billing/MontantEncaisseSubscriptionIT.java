package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Le montant encaisse, contre la vraie base : la contrainte de V043 est celle de
 * la production, et le montant est bien fige a l'ecriture.
 */
class MontantEncaisseSubscriptionIT extends AbstractIntegrationTest {

    @Autowired
    private OneTimeAccessService oneTimeAccessService;
    @Autowired
    private MontantEncaisseResolver montantEncaisseResolver;
    @Autowired
    private UserSubscriptionManager userSubscriptionManager;
    @Autowired
    private TestData testData;
    @PersistenceContext
    private EntityManager entityManager;

    @Test
    @DisplayName("Un pass acheté fige le montant réellement prélevé, avec sa devise et son taux")
    void montantFigeALAchat() {
        User user = testData.user();
        Plan plan = testData.plan();

        UserSubscription sub = oneTimeAccessService.grantOneTimeAccess(
                user.getId(), plan, SubscriptionSource.APPLE,
                "tx-" + UUID.randomUUID(), "tx-ext",
                montantEncaisseResolver.duStore(34.99, "USD"));

        assertThat(sub.getAmountCents()).isEqualTo(3499);
        assertThat(sub.getCurrency()).isEqualTo("USD");
        assertThat(sub.getAmountEurCents()).isEqualTo(3219);
        assertThat(sub.getFxRateToEur()).isEqualByComparingTo(new BigDecimal("0.92"));
    }

    @Test
    @DisplayName("Sans montant déclaré par le canal, on retombe sur le prix affiché du plan")
    void repliSurLePrixDuPlan() {
        User user = testData.user();
        Plan plan = testData.plan(); // 9,99 €

        UserSubscription sub = oneTimeAccessService.grantOneTimeAccess(
                user.getId(), plan, SubscriptionSource.GOOGLE,
                "tok-" + UUID.randomUUID(), "order-1");

        assertThat(sub.getAmountCents()).isEqualTo(999);
        assertThat(sub.getCurrency()).isEqualTo("EUR");
        assertThat(sub.getAmountEurCents()).isEqualTo(999);
        assertThat(sub.getFxRateToEur()).isEqualByComparingTo(BigDecimal.ONE);
    }

    /**
     * 🛑 V043 ne migre AUCUNE donnee. Une ligne ecrite sans montant reste a
     * {@code NULL} — ce qui se lit « on ne sait pas », jamais « gratuit ». Le
     * deduire de {@code plans.price} apres coup falsifierait l'historique, ce
     * prix etant modifiable en console.
     */
    @Test
    @DisplayName("Une souscription écrite sans montant reste à NULL, elle n'est jamais dérivée du plan")
    void aucuneDerivationRetroactive() {
        UserSubscription legacy = testData.userSubscription();
        assertThat(legacy.getAmountCents()).isNull();
        assertThat(legacy.getCurrency()).isNull();
        assertThat(legacy.getAmountEurCents()).isNull();
        assertThat(legacy.getFxRateToEur()).isNull();
    }

    /**
     * La contrainte {@code chk_user_subscriptions_amount_currency} ne va que dans
     * UN sens : montant et devise vont ensemble, ou pas du tout. Elle n'exige pas
     * la reciproque (« un montant implique un montant en euros ») — ce serait
     * faux des qu'une devise n'a pas de taux configure, et c'est justement le cas
     * qu'on veut pouvoir representer.
     */
    @Test
    @DisplayName("La base refuse un montant sans devise")
    void contrainteMontantSansDevise() {
        UserSubscription sub = testData.userSubscription();
        sub.setAmountCents(1999);
        sub.setCurrency(null);

        userSubscriptionManager.save(sub);
        // `save` ne flushe pas : sans ce flush explicite, la violation ne
        // remonterait qu'au commit — piège documenté dans docs/plan-tests-backend.md.
        assertThatThrownBy(() -> entityManager.flush())
                .isInstanceOf(Exception.class);
    }
}
