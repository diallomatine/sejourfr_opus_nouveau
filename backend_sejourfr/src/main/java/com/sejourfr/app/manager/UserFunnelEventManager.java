package com.sejourfr.app.manager;

import com.sejourfr.app.entity.UserFunnelEvent;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.FunnelEvent;
import com.sejourfr.app.repository.UserFunnelEventRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/** Seule couche autorisee a toucher {@link UserFunnelEventRepository}. */
@Component
@RequiredArgsConstructor
public class UserFunnelEventManager {

    private final UserFunnelEventRepository repository;

    /**
     * Pose la premiere occurrence de l'evenement, ou ne fait rien.
     *
     * @return {@code true} si la ligne vient d'etre creee, {@code false} si le
     *         compte l'avait deja (rejeu). Les deux cas sont normaux.
     */
    @Transactional
    public boolean recordFirstOccurrence(UUID userId, FunnelEvent event,
                                         ClientPlatform platform, String source) {
        return repository.recordFirstOccurrence(
                UUID.randomUUID(), userId, event.name(),
                platform == null ? null : platform.name(), source) > 0;
    }

    /** Purge explicite : l'anonymisation ne declenche pas la cascade base. */
    @Transactional
    public int deleteByUserId(UUID userId) {
        return repository.deleteByUserId(userId);
    }

    @Transactional(readOnly = true)
    public long countForUser(UUID userId) {
        return repository.countByUserId(userId);
    }

    @Transactional(readOnly = true)
    public long countAll() {
        return repository.count();
    }
}
