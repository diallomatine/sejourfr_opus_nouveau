package com.sejourfr.app.service.analytics;

import com.sejourfr.app.config.AnalyticsProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

/**
 * Expose la configuration versionnee d'analytics, chargee une fois au demarrage.
 * Seul le profil {@code dev} peut en surcharger les dates de debut de mesure
 * ({@link AnalyticsProperties#getMeasurementStartOverrides()}).
 */
@Configuration
@RequiredArgsConstructor
public class AnalyticsConfigProvider {

    private final AnalyticsProperties properties;
    private final Environment environment;

    @Bean
    public AnalyticsConfig analyticsConfig() {
        return AnalyticsConfigLoader.withMeasurementStartOverrides(
                AnalyticsConfigLoader.load(properties.getConfigVersion()),
                properties.getMeasurementStartOverrides(),
                environment.matchesProfiles("dev"));
    }
}
