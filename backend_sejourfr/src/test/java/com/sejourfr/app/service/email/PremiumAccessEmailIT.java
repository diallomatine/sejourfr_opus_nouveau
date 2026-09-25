package com.sejourfr.app.service.email;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.service.billing.OneTimeAccessService;
import com.sejourfr.app.support.AbstractEmailIT;
import com.sejourfr.app.support.EmailTestSupport;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * {@code PREMIUM_ACCESS_STARTED} / {@code PREMIUM_ACCESS_EXTENDED} (arbitrage n°4),
 * publies par {@code OneTimeAccessService} — le point commun aux trois canaux de
 * paiement — au moment ou l'acces est ACCORDE, envoyes apres commit.
 */
class PremiumAccessEmailIT extends AbstractEmailIT {

    @Autowired private OneTimeAccessService oneTimeAccessService;
    @Autowired private PlanManager planManager;

    private Plan passCivique() {
        Plan p = data.plan(ModuleAccess.CIVIQUE);
        p.setName("Civique — pass 1 mois");
        p.setPurchaseType(com.sejourfr.app.enums.PlanPurchaseType.ONE_TIME);
        p.setActive(false);
        return trackPlan(planManager.save(p));
    }

    @Test
    @DisplayName("Premier achat : STARTED ; achat qui prolonge : EXTENDED ; rejeu du meme recu : rien")
    void premierAchatPuisProlongation() {
        User u = user();
        Plan plan = passCivique();

        UserSubscription premier = oneTimeAccessService.grantOneTimeAccess(
                u.getId(), plan, SubscriptionSource.STRIPE, "cs_" + UUID.randomUUID(), "pi_1");
        EmailTestSupport.await("STARTED", () -> hasStatus(u, EmailType.PREMIUM_ACCESS_STARTED, EmailDeliveryStatus.SENT));

        String tx = "cs_" + UUID.randomUUID();
        UserSubscription second = oneTimeAccessService.grantOneTimeAccess(
                u.getId(), plan, SubscriptionSource.STRIPE, tx, "pi_2");
        EmailTestSupport.await("EXTENDED", () -> hasStatus(u, EmailType.PREMIUM_ACCESS_EXTENDED, EmailDeliveryStatus.SENT));

        oneTimeAccessService.grantOneTimeAccess(u.getId(), plan, SubscriptionSource.STRIPE, tx, "pi_2");
        EmailTestSupport.settle();
        awaitEmailExecutorIdle();

        assertThat(rowsOf(u, EmailType.PREMIUM_ACCESS_STARTED)).singleElement()
                .satisfies(d -> assertThat(d.getDeduplicationKey()).isEqualTo("PREMIUM_ACCESS_STARTED:" + premier.getId()));
        assertThat(rowsOf(u, EmailType.PREMIUM_ACCESS_EXTENDED)).singleElement()
                .satisfies(d -> assertThat(d.getReferenceId()).isEqualTo(second.getId()));
        EmailMessage started = mails.sentOfType(EmailType.PREMIUM_ACCESS_STARTED).stream()
                .filter(m -> m.recipient().equals(u.getEmail())).findFirst().orElseThrow();
        assertThat(started.variables()).containsEntry("offerName", "Civique — pass 1 mois")
                .containsKey("accessEndDate").containsKey("accessStartDate");
        assertThat(started.variables().get("accessTerms")).contains("Achat unique").doesNotContain("renouvelé");
        assertThat(started.unsubscribeUrl()).isNull();
    }
}
