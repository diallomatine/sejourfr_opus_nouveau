package com.sejourfr.app.manager;

import com.sejourfr.app.entity.ProcessedExternalEvent;
import com.sejourfr.app.repository.ProcessedExternalEventRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Component;

import java.time.Instant;

/**
 * Manager d'idempotence pour les évènements webhook externes (Stripe pour
 * l'instant). Le pattern : avant d'agir sur un évènement, on tente d'insérer
 * (provider, event_id). Si la PK conflit, l'évènement a déjà été traité, on
 * skip — défense contre les replays / retries.
 *
 * <p>Cf. {@code BillingService.handleWebhook} et migration V101.
 */
@Component
@RequiredArgsConstructor
public class ProcessedExternalEventManager {

    private final ProcessedExternalEventRepository repository;

    /**
     * Tente de marquer un évènement comme traité.
     *
     * @return {@code true} si on est le premier (l'évènement n'avait jamais
     *         été vu) — il faut alors exécuter le side-effect.
     *         {@code false} si l'évènement a déjà été traité par un précédent
     *         appel — il faut skip pour éviter la double activation.
     */
    public boolean tryMarkProcessed(String provider, String eventId) {
        if (repository.existsById(new ProcessedExternalEvent.PK(provider, eventId))) {
            return false;
        }
        try {
            repository.save(new ProcessedExternalEvent(provider, eventId, Instant.now()));
            return true;
        } catch (DataIntegrityViolationException e) {
            // Race : un autre thread a inséré entre le exists et le save. C'est
            // exactement le cas qu'on veut bloquer — l'autre s'en occupe.
            return false;
        }
    }
}
