package com.sejourfr.app.manager;

import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.RealtimeSessionStatus;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Intégration réelle pour {@link RealtimeSessionManager} : persistance / lecture
 * et décompte de quota par pass (sessions consommées ACTIVE+COMPLETED, sessions
 * PENDING récentes réservant un slot).
 */
class RealtimeSessionManagerIT extends AbstractIntegrationTest {

    @Autowired
    private RealtimeSessionManager manager;

    @Autowired
    private TestData testData;

    private RealtimeSession session(UserSubscription subscription,
                                    RealtimeSessionStatus status,
                                    Instant startedAt) {
        RealtimeSession s = new RealtimeSession();
        s.setUser(subscription.getUser());
        s.setSubscription(subscription);
        s.setEpreuve(EpreuveType.TCF_EO);
        s.setTacheNumero((short) 1);
        s.setProvider("gemini");
        s.setModel("gemini-test");
        s.setStatus(status);
        s.setStartedAt(startedAt);
        return manager.save(s);
    }

    @Test
    void saveAndFindById() {
        RealtimeSession saved = testData.realtimeSession();
        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getCreatedAt()).isNotNull();   // @PrePersist

        assertThat(manager.findById(saved.getId()))
                .get()
                .extracting(RealtimeSession::getStatus)
                .isEqualTo(RealtimeSessionStatus.PENDING);

        assertThat(manager.findById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void countConsumedCountsActiveAndCompletedOnTargetSubscription() {
        UserSubscription subscription = testData.userSubscription();
        Instant now = Instant.now();

        session(subscription, RealtimeSessionStatus.ACTIVE, now);
        session(subscription, RealtimeSessionStatus.COMPLETED, now);
        session(subscription, RealtimeSessionStatus.PENDING, now);   // pas encore consommée
        session(subscription, RealtimeSessionStatus.FAILED, now);    // échec : exclue

        // Session ACTIVE sur un autre pass : ne doit pas être comptée.
        session(testData.userSubscription(), RealtimeSessionStatus.ACTIVE, now);

        assertThat(manager.countConsumed(subscription.getId())).isEqualTo(2);
    }

    @Test
    void countRecentPendingCountsOnlyPendingAfterCutoff() {
        UserSubscription subscription = testData.userSubscription();
        Instant now = Instant.now();
        Instant cutoff = now.minus(1, ChronoUnit.HOURS);

        session(subscription, RealtimeSessionStatus.PENDING, now);                          // récente
        session(subscription, RealtimeSessionStatus.PENDING, now.minus(2, ChronoUnit.HOURS)); // trop ancienne
        session(subscription, RealtimeSessionStatus.ACTIVE, now);                           // pas PENDING

        assertThat(manager.countRecentPending(subscription.getId(), cutoff)).isEqualTo(1);
    }
}
