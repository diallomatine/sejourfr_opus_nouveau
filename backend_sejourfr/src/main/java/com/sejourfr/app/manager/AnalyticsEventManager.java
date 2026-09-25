package com.sejourfr.app.manager;

import com.sejourfr.app.entity.AnalyticsEventRecord;
import com.sejourfr.app.enums.AnalyticsEvent;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.DiagnosticRunType;
import com.sejourfr.app.repository.AnalyticsEventRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Seule couche autorisee a toucher {@link AnalyticsEventRepository}. */
@Component
@RequiredArgsConstructor
public class AnalyticsEventManager {

    private final AnalyticsEventRepository repository;

    /**
     * Une ligne a ecrire, deja validee et normalisee par le service — le
     * manager ne juge pas du contenu, il ecrit.
     *
     * @param occurredAt     date RETENUE (celle des KPI)
     * @param propertiesJson objet JSON deja serialise
     * @param eventId        identifiant client tire a la creation de l'evenement
     * @param receivedAt     horloge serveur
     * @param internal       resolu a l'ingestion
     */
    public record Ligne(AnalyticsEvent event, Instant occurredAt, UUID anonymousId, UUID sessionId,
                        UUID userId, String path, String propertiesJson, String dedupKey,
                        UUID eventId, Instant receivedAt, ClientPlatform platform, String appVersion,
                        DiagnosticRunType diagnosticType, UUID diagnosticRunId, UUID journeyId,
                        boolean internal) {
    }

    /**
     * Ecrit l'evenement, ou ne fait rien si son {@code event_id} ou sa cle de
     * dedoublonnage existe deja.
     *
     * @return {@code true} si la ligne vient d'etre creee, {@code false} sur un
     *         rejeu. Les deux cas sont normaux.
     */
    @Transactional
    public boolean record(Ligne l) {
        return repository.insertIgnoringDuplicate(
                UUID.randomUUID(), l.event().name(), l.occurredAt(), l.anonymousId(), l.sessionId(),
                l.userId(), l.path(), l.propertiesJson(), l.dedupKey(),
                l.eventId(), l.receivedAt(), l.platform() == null ? null : l.platform().name(),
                l.appVersion(), l.diagnosticType() == null ? null : l.diagnosticType().name(),
                l.diagnosticRunId(), l.journeyId(), l.internal()) > 0;
    }

    /** Detache les evenements d'un compte anonymise. Les gestes restent, anonymes. */
    @Transactional
    public int detachUser(UUID userId) {
        return repository.detachUser(userId);
    }

    /** Un lot de purge de retention : au plus {@code limit} lignes. */
    @Transactional
    public int deleteOlderThan(Instant cutoff, int limit) {
        return repository.deleteOlderThan(cutoff, limit);
    }

    @Transactional(readOnly = true)
    public long countForVisitor(UUID anonymousId) {
        return repository.countByAnonymousId(anonymousId);
    }

    @Transactional(readOnly = true)
    public Optional<AnalyticsEventRecord> findByEventId(UUID eventId) {
        return repository.findByEventId(eventId);
    }

    @Transactional(readOnly = true)
    public List<AnalyticsEventRecord> all() {
        return repository.findAll();
    }
}
