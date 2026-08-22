package com.sejourfr.app.manager;

import com.sejourfr.app.repository.AnalyticsIdentityRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/** Seule couche autorisee a toucher {@link AnalyticsIdentityRepository}. */
@Component
@RequiredArgsConstructor
public class AnalyticsIdentityManager {

    private final AnalyticsIdentityRepository repository;

    /**
     * Pose le lien, ou ne fait rien (visiteur inconnu, lien deja pose).
     *
     * @return {@code true} si le lien vient d'etre pose.
     */
    @Transactional
    public boolean link(UUID anonymousId, UUID userId) {
        return repository.link(anonymousId, userId) > 0;
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
}
