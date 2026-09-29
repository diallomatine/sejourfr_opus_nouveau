package com.sejourfr.app.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Clock;

/**
 * L'horloge injectable du depot.
 *
 * <p>Creee pour le systeme d'emails (fenetres, plafond du jour, episodes
 * d'inactivite : tout est temporel et doit se tester a date fixe). Les
 * {@code Instant.now()} existants ailleurs ne sont PAS migres dans ce chantier.
 */
@Configuration
public class ClockConfig {

    @Bean
    public Clock clock() {
        return Clock.systemUTC();
    }
}
