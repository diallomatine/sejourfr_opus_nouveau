package com.sejourfr.app.service.plan;

import com.sejourfr.app.config.PlanProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Expose la configuration versionnee du Plan comme un bean, chargee une fois au
 * demarrage. Le chargement echoue bruyamment plutot que de servir un plafond
 * nul.
 */
@Configuration
@RequiredArgsConstructor
public class PlanConfigProvider {

    private final PlanProperties properties;

    @Bean
    public PlanConfig planConfig() {
        return PlanConfigLoader.load(properties.getConfigVersion());
    }
}
