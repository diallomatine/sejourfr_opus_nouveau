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
}
