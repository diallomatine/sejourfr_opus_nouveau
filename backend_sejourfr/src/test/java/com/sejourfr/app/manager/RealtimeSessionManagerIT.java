package com.sejourfr.app.manager;

import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.enums.RealtimeSessionStatus;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Intégration réelle pour {@link RealtimeSessionManager} : persistance / lecture
 * du cycle de vie d'une session. Le décompte de quota ne vit plus ici (il est
 * porté par {@code user_subscriptions.realtime_eo_sessions_remaining} —
 * cf. {@link UserSubscriptionManagerIT}).
 */
class RealtimeSessionManagerIT extends AbstractIntegrationTest {

    @Autowired
    private RealtimeSessionManager manager;

    @Autowired
    private TestData testData;

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

    /**
     * Lecture verrouillée (SELECT … FOR UPDATE) : c'est elle qui sérialise deux
     * connexions concurrentes du même candidat (celle qui tombe et celle qui
     * reprend) et garantit qu'un slot de simulation n'est débité qu'une fois.
     * Ce test l'exerce contre le vrai Postgres — la requête et son verrou
     * doivent être valides, sinon l'invariant tombe en silence.
     */
    @Test
    void findByIdForUpdateLocksTheRow() {
        RealtimeSession saved = testData.realtimeSession();

        assertThat(manager.findByIdForUpdate(saved.getId()))
                .get()
                .extracting(RealtimeSession::getId)
                .isEqualTo(saved.getId());

        assertThat(manager.findByIdForUpdate(UUID.randomUUID())).isEmpty();
    }

    /** Les colonnes de reprise (V032) sont bien persistées et relues. */
    @Test
    void persistsResumptionState() {
        RealtimeSession saved = testData.realtimeSession();
        assertThat(saved.getResumptionCount()).isZero();
        assertThat(saved.getResumptionHandle()).isNull();
        assertThat(saved.getLastTurnIndex()).isNull();

        saved.setResumptionHandle("handle-xyz");
        saved.setResumptionCount(2);
        saved.setLastTurnIndex(7);
        manager.save(saved);

        assertThat(manager.findById(saved.getId())).get().satisfies(s -> {
            assertThat(s.getResumptionHandle()).isEqualTo("handle-xyz");
            assertThat(s.getResumptionCount()).isEqualTo(2);
            assertThat(s.getLastTurnIndex()).isEqualTo(7);
        });
    }
}
