package com.sejourfr.app.manager;

import com.sejourfr.app.entity.AccessOverride;
import com.sejourfr.app.enums.AccessOverrideType;
import com.sejourfr.app.repository.AccessOverrideRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

/**
 * Couche d'accès aux décisions admin ({@code access_overrides}, V083). Les
 * écritures passent par {@link #saveAndFlush} : la contrainte d'exclusion est
 * immédiate, donc une supersession doit être en base AVANT l'insertion de la
 * décision qui la remplace (Hibernate ordonne sinon les INSERT avant les UPDATE).
 */
@Component
@RequiredArgsConstructor
public class AccessOverrideManager {

    private final AccessOverrideRepository repository;

    public List<AccessOverride> findCurrentByUserId(UUID userId) {
        return repository.findByUserIdAndSupersededAtIsNull(userId);
    }

    public List<AccessOverride> findCurrentByUserIds(Collection<UUID> userIds) {
        if (userIds.isEmpty()) return List.of();
        return repository.findByUserIdInAndSupersededAtIsNull(userIds);
    }

    public List<UUID> findUserIdsWithGrantCovering(Instant now) {
        return repository.findUserIdsWithCurrentOverrideCovering(AccessOverrideType.GRANT, now);
    }

    /** Verrou consultatif par compte, tenu jusqu'à la fin de la transaction (G-11). */
    public void verrouiller(UUID userId) {
        repository.verrouiller("access-override:" + userId);
    }

    /**
     * Débite une session EO temps réel d'un GRANT INTEGRAL courant. Vrai si une
     * ligne a été débitée. 🛑 Appelé par {@code RealtimeQuotaService} seulement,
     * sous {@link #verrouiller} (même verrou que les actions admin).
     */
    public boolean decrementRealtimeSessions(UUID overrideId) {
        return repository.decrementRealtimeSessions(overrideId) > 0;
    }

    public AccessOverride saveAndFlush(AccessOverride override) {
        return repository.saveAndFlush(override);
    }

    public int deleteByUserId(UUID userId) {
        return repository.deleteByUserId(userId);
    }
}
