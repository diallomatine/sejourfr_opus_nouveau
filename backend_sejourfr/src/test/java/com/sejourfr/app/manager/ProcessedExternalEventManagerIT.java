package com.sejourfr.app.manager;

import com.sejourfr.app.entity.ProcessedExternalEvent;
import com.sejourfr.app.repository.ProcessedExternalEventRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Intégration réelle (Postgres embarqué) du {@link ProcessedExternalEventManager} :
 * idempotence webhook via insertion conditionnelle sur la PK composite
 * {@code (provider, event_id)} (V101).
 */
class ProcessedExternalEventManagerIT extends AbstractIntegrationTest {

    @Autowired
    private ProcessedExternalEventManager manager;

    @Autowired
    private ProcessedExternalEventRepository repository;

    @Test
    void tryMarkProcessedIsTrueOnceThenFalseOnReplay() {
        String provider = "stripe";
        String eventId = "evt_" + UUID.randomUUID();

        // Premier passage : on est le premier à voir l'évènement → side-effect à faire.
        assertThat(manager.tryMarkProcessed(provider, eventId)).isTrue();
        assertThat(repository.existsById(new ProcessedExternalEvent.PK(provider, eventId))).isTrue();

        // Replay du même évènement → skip pour éviter la double activation.
        assertThat(manager.tryMarkProcessed(provider, eventId)).isFalse();

        // Même eventId mais provider différent = clé composite distincte → traité.
        assertThat(manager.tryMarkProcessed("apple", eventId)).isTrue();
        // Même provider, eventId différent → traité.
        assertThat(manager.tryMarkProcessed(provider, "evt_" + UUID.randomUUID())).isTrue();
    }
}
