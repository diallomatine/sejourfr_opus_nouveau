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
import org.springframework.jdbc.core.JdbcTemplate;
import jakarta.persistence.EntityManager;

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
    @Autowired
    private JdbcTemplate jdbc;
    @Autowired
    private EntityManager entityManager;

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
    void deleteAccount_purgeSessionsAttemptsEtObservationsDiagnosticAvantAnonymisation() {
        User user = data.user();
        UUID id = user.getId();
        var writtenAttempt = data.attempt(user);
        var oralAttempt = data.attempt(user);
        entityManager.flush();
        jdbc.update("""
                INSERT INTO diagnostic_sessions
                    (id, user_id, diagnostic_code, diagnostic_version,
                     written_task_id, oral_task_id, written_attempt_id, oral_attempt_id,
                     status, retry_count, started_at, updated_at)
                VALUES (?, ?, 'INITIAL_TCF', 1, ?, ?, ?, ?, 'IN_PROGRESS', 0, now(), now())
                """, UUID.randomUUID(), id,
                UUID.fromString("d1a60000-0000-5000-8000-000000000001"),
                UUID.fromString("d1a60000-0000-5000-8000-000000000002"),
                writtenAttempt.getId(), oralAttempt.getId());
        jdbc.update("""
                INSERT INTO learning_plan_observations
                    (id, user_id, skill_id, source_type, source_id, observed, status,
                     evidence, explanation, confidence, baseline, observed_at, created_at)
                SELECT ?, ?, s.id, 'DIAGNOSTIC_EE', ?, true, 'PRIORITY',
                       'preuve', 'explication', 'HIGH', true, now(), now()
                FROM skills s WHERE s.code = 'EE1-C1'
                """, UUID.randomUUID(), id, UUID.randomUUID());

        assertThat(count("diagnostic_sessions", id)).isEqualTo(1);
        assertThat(count("attempts", id)).isEqualTo(2);
        assertThat(count("learning_plan_observations", id)).isEqualTo(1);

        service.deleteAccount(id);

        assertThat(count("diagnostic_sessions", id)).isZero();
        assertThat(count("attempts", id)).isZero();
        assertThat(count("learning_plan_observations", id)).isZero();
        assertThat(userManager.findById(id).orElseThrow().getDeletedAt()).isNotNull();
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

    private int count(String table, UUID userId) {
        Integer value = jdbc.queryForObject(
                "SELECT count(*) FROM " + table + " WHERE user_id = ?", Integer.class, userId);
        return value == null ? 0 : value;
    }
}
