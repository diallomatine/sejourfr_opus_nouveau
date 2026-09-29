package com.sejourfr.app.service.journey;

import com.sejourfr.app.config.TcfJourneyProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Expose la configuration versionnee du parcours comme un bean, chargee une fois
 * au demarrage. Le chargement echoue bruyamment plutot que de servir un plafond
 * nul.
 */
@Configuration
@RequiredArgsConstructor
public class TcfJourneyConfigProvider {

    private final TcfJourneyProperties properties;

    @Bean
    public TcfJourneyConfig tcfJourneyConfig() {
        return TcfJourneyConfigLoader.load(properties.getConfigVersion());
    }
}
