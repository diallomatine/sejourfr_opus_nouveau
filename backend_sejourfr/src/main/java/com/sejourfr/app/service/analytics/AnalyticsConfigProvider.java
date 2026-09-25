package com.sejourfr.app.service.analytics;

import com.sejourfr.app.config.AnalyticsProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Expose la configuration versionnee d'analytics, chargee une fois au demarrage. */
@Configuration
@RequiredArgsConstructor
public class AnalyticsConfigProvider {

    private final AnalyticsProperties properties;

    @Bean
    public AnalyticsConfig analyticsConfig() {
        return AnalyticsConfigLoader.load(properties.getConfigVersion());
    }
}
