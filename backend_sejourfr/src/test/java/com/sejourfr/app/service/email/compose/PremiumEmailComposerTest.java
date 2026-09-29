package com.sejourfr.app.service.email.compose;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.email.EmailLinks;
import com.sejourfr.app.service.email.EmailRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class PremiumEmailComposerTest {

    private final UUID accessId = UUID.randomUUID();
    private UserSubscriptionManager subscriptions;
    private PremiumEmailComposer composer;
    private UserSubscription sub;

    @BeforeEach
    void setUp() {
        subscriptions = mock(UserSubscriptionManager.class);
        composer = new PremiumEmailComposer(subscriptions, new EmailLinks("https://sejourfr.fr", "https://api"));
        User u = new User();
        u.setId(UUID.randomUUID());
        u.setEmail("alice@example.com");
        u.setFirstName("Alice");
        Plan plan = new Plan();
        plan.setName("Intégral — pass 1 mois");
        sub = new UserSubscription();
        sub.setId(accessId);
        sub.setUser(u);
        sub.setPlan(plan);
        sub.setSource(SubscriptionSource.STRIPE);
        sub.setStartsAt(Instant.parse("2026-09-20T10:00:00Z"));
        sub.setEndsAt(Instant.parse("2026-10-20T10:00:00Z"));
        when(subscriptions.findById(accessId)).thenReturn(Optional.of(sub));
    }

    @Test
    void premierAccesAchatUnique() {
        EmailRequest r = composer.accessGranted(EmailType.PREMIUM_ACCESS_STARTED, accessId, EmailRequest.Origin.EVENT)
                .orElseThrow();

        assertThat(r.deduplicationKey()).isEqualTo("PREMIUM_ACCESS_STARTED:" + accessId);
        assertThat(r.referenceId()).isEqualTo(accessId);
        assertThat(r.variables()).containsEntry("offerName", "Intégral — pass 1 mois")
                .containsEntry("accessStartDate", "20 septembre 2026")
                .containsEntry("accessEndDate", "20 octobre 2026")
                .containsEntry("accessTerms", PremiumEmailComposer.TERMES_ACHAT_UNIQUE)
                .containsEntry("appUrl", "https://sejourfr.fr/dashboard");
    }

    @Test
    void leModeRecurrentDormantGardeSonWording() {
        sub.setAutoRenew(true);

        EmailRequest r = composer.accessGranted(EmailType.PREMIUM_ACCESS_STARTED, accessId, EmailRequest.Origin.EVENT)
                .orElseThrow();

        assertThat(r.variables()).containsEntry("accessTerms", PremiumEmailComposer.TERMES_RECURRENT);
    }

    @Test
    void prolongation() {
        EmailRequest r = composer.accessGranted(EmailType.PREMIUM_ACCESS_EXTENDED, accessId, EmailRequest.Origin.DEFERRED_RETRY)
                .orElseThrow();

        assertThat(r.type()).isEqualTo(EmailType.PREMIUM_ACCESS_EXTENDED);
        assertThat(r.origin()).isEqualTo(EmailRequest.Origin.DEFERRED_RETRY);
    }

    @Test
    void unAutreTypeEstRefuse() {
        assertThatThrownBy(() -> composer.accessGranted(EmailType.WELCOME, accessId, EmailRequest.Origin.EVENT))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void resiliationDormanteParSource() {
        sub.setSource(SubscriptionSource.APPLE);

        EmailRequest r = composer.subscriptionCanceled(accessId, EmailRequest.Origin.EVENT).orElseThrow();

        assertThat(r.type()).isEqualTo(EmailType.PREMIUM_SUBSCRIPTION_CANCELED);
        assertThat(r.variables().get("reactivateHint")).contains("Réglages");
    }

    @Test
    void unCompteSupprimeNeRecoitRien() {
        sub.getUser().setDeletedAt(Instant.now());

        assertThat(composer.accessGranted(EmailType.PREMIUM_ACCESS_STARTED, accessId, EmailRequest.Origin.EVENT)).isEmpty();
    }

    @Test
    void sansNomDePlanLeRepliEstPremium() {
        sub.getPlan().setName(" ");

        assertThat(composer.accessGranted(EmailType.PREMIUM_ACCESS_STARTED, accessId, EmailRequest.Origin.EVENT)
                .orElseThrow().variables()).containsEntry("offerName", "Premium");
    }
}
