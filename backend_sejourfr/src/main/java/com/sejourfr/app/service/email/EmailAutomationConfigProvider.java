package com.sejourfr.app.service.email;

import com.sejourfr.app.config.EmailProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Expose la configuration versionnee des emails, chargee une fois au demarrage. */
@Configuration
@RequiredArgsConstructor
public class EmailAutomationConfigProvider {

    private final EmailProperties properties;

    @Bean
    public EmailAutomationConfig emailAutomationConfig() {
        return EmailAutomationConfigLoader.load(properties.getAutomation().getConfigVersion());
    }
}
