package com.sejourfr.app.service;

import com.sejourfr.app.dto.AccountDeletionResponse;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * IT « service + DB » : la suppression de compte (RGPD) anonymise réellement la
 * ligne {@code users} en base et purge les données de pratique. Mocker n'aurait
 * pas de valeur ici — on veut vérifier l'effet persistant ({@link User#anonymize()})
 * et l'idempotence.
 */
class AccountDeletionServiceIT extends AbstractIntegrationTest {

    @Autowired
    private AccountDeletionService service;
    @Autowired
    private TestData data;
    @Autowired
    private UserManager userManager;
    @Autowired
    private AttemptManager attemptManager;
    @Autowired
    private UserSubscriptionManager userSubscriptionManager;

    @Test
    void deleteAccount_anonymizesUser_andPurgesPractice() {
        User user = data.user();
        UUID id = user.getId();
        data.attempt(user);
        assertThat(attemptManager.countByUserId(id)).isPositive();

        AccountDeletionResponse resp = service.deleteAccount(id);

        assertThat(resp.deleted()).isTrue();
        assertThat(resp.hasActiveSubscription()).isFalse();
        assertThat(resp.subscriptionProvider()).isNull();
        assertThat(resp.manualActionMessage()).isNull();

        User reloaded = userManager.findById(id).orElseThrow();
        assertThat(reloaded.getEmail())
                .isEqualTo("deleted-" + id + "@anon.sejourfr");
        assertThat(reloaded.getPasswordHash()).isEqualTo("DELETED");
        assertThat(reloaded.getFirstName()).isNull();
        assertThat(reloaded.getLastName()).isNull();
        assertThat(reloaded.isActive()).isFalse();
        assertThat(reloaded.getDeletedAt()).isNotNull();
        assertThat(attemptManager.countByUserId(id)).isZero();
    }

    @Test
    void deleteAccount_isIdempotent() {
        User user = data.user();
        UUID id = user.getId();

        service.deleteAccount(id);
        String anonEmail = userManager.findById(id).orElseThrow().getEmail();

        AccountDeletionResponse second = service.deleteAccount(id);

        assertThat(second.deleted()).isTrue();
        assertThat(second.hasActiveSubscription()).isFalse();
        assertThat(second.subscriptionProvider()).isNull();
        // L'email anonymisé n'est pas ré-écrasé au second passage.
        assertThat(userManager.findById(id).orElseThrow().getEmail()).isEqualTo(anonEmail);
    }

    @Test
    void deleteAccount_appleSubscription_returnsManualMessage_andAnonymizes() {
        User user = data.user();
        UUID id = user.getId();
        Plan plan = data.plan();

        UserSubscription sub = new UserSubscription();
        sub.setUser(user);
        sub.setPlan(plan);
        sub.setStatus(SubscriptionStatus.ACTIVE);
        sub.setStartsAt(Instant.now());
        sub.setEndsAt(Instant.now().plus(30, ChronoUnit.DAYS));
        sub.setSource(SubscriptionSource.APPLE);
        sub.setOriginalTransactionId("apple-" + UUID.randomUUID());
        sub.setProductId(plan.getCode());
        sub.setAutoRenew(true);
        userSubscriptionManager.save(sub);

        AccountDeletionResponse resp = service.deleteAccount(id);

        assertThat(resp.deleted()).isTrue();
        assertThat(resp.hasActiveSubscription()).isTrue();
        assertThat(resp.subscriptionProvider()).isEqualTo("APPLE");
        assertThat(resp.manualActionMessage()).contains("App Store");
        assertThat(userManager.findById(id).orElseThrow().getDeletedAt()).isNotNull();
    }
}
