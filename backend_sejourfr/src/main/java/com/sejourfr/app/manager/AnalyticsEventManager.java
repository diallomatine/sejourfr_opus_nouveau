package com.sejourfr.app.manager;

import com.sejourfr.app.entity.AnalyticsEventRecord;
import com.sejourfr.app.enums.AnalyticsEvent;
import com.sejourfr.app.repository.AnalyticsEventRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

/** Seule couche autorisee a toucher {@link AnalyticsEventRepository}. */
@Component
@RequiredArgsConstructor
public class AnalyticsEventManager {

    private final AnalyticsEventRepository repository;

    /**
     * Ecrit l'evenement, ou ne fait rien si sa cle de dedoublonnage existe deja.
     *
     * @param propertiesJson objet JSON deja valide et serialise par le service —
     *                       le manager ne juge pas du contenu, il ecrit.
     * @return {@code true} si la ligne vient d'etre creee, {@code false} sur un
     *         rejeu. Les deux cas sont normaux.
     */
    @Transactional
    public boolean record(AnalyticsEvent event, Instant occurredAt, UUID anonymousId,
                          UUID sessionId, UUID userId, String path,
                          String propertiesJson, String dedupKey) {
        return repository.insertIgnoringDuplicate(
                UUID.randomUUID(), event.name(), occurredAt, anonymousId, sessionId,
                userId, path, propertiesJson, dedupKey) > 0;
    }

    /** Detache les evenements d'un compte anonymise. Les gestes restent, anonymes. */
    @Transactional
    public int detachUser(UUID userId) {
        return repository.detachUser(userId);
    }

    @Transactional(readOnly = true)
    public long countForVisitor(UUID anonymousId) {
        return repository.countByAnonymousId(anonymousId);
    }

    @Transactional(readOnly = true)
    public java.util.List<AnalyticsEventRecord> all() {
        return repository.findAll();
    }
}
