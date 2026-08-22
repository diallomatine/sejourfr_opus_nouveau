package com.sejourfr.app.manager;

import com.sejourfr.app.entity.AnalyticsVisitor;
import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.repository.AnalyticsVisitorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/** Seule couche autorisee a toucher {@link AnalyticsVisitorRepository}. */
@Component
@RequiredArgsConstructor
public class AnalyticsVisitorManager {

    private final AnalyticsVisitorRepository repository;

    /**
     * Cree ou rafraichit le visiteur. Le first touch n'est jamais reecrit ; le
     * last touch ne l'est que si {@code explicitSource}.
     */
    @Transactional
    public void touch(UUID anonymousId, Instant seenAt, Attribution attribution,
                      boolean explicitSource, String countryCode,
                      AnalyticsDeviceType deviceType, ClientPlatform platform) {
        repository.upsert(anonymousId, seenAt,
                attribution.source(), attribution.medium(), attribution.campaign(),
                attribution.content(), attribution.term(),
                attribution.landingPath(), attribution.referrerHost(),
                explicitSource, countryCode,
                deviceType.name(), platform.name());
    }

    @Transactional(readOnly = true)
    public Optional<AnalyticsVisitor> findById(UUID anonymousId) {
        return repository.findById(anonymousId);
    }

    @Transactional(readOnly = true)
    public long countAll() {
        return repository.count();
    }

    /**
     * Attribution d'un visiteur : d'ou il vient, par quelle campagne, sur quelle
     * page il a atterri.
     *
     * @param source       provenance normalisee ({@code util/TrafficSource})
     * @param medium       {@code utm_medium}
     * @param campaign     {@code utm_campaign}
     * @param content      {@code utm_content} — c'est lui qui distingue deux
     *                     videos d'une meme campagne
     * @param term         {@code utm_term}
     * @param landingPath  page d'arrivee
     * @param referrerHost hote du referrer, jamais l'URL complete
     */
    public record Attribution(String source, String medium, String campaign, String content,
                              String term, String landingPath, String referrerHost) {
    }
}
