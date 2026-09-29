package com.sejourfr.app.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

import java.util.Arrays;

/**
 * Trace le(s) profil(s) Spring actif(s) au demarrage et leve un WARN visible si
 * le profil {@code dev} tourne — pour reperer immediatement un deploiement
 * production lance par erreur sans {@code SPRING_PROFILES_ACTIVE=prod} (le
 * profil dev embarque une cle JWT publique, un mot de passe DB vide et des
 * logs verbeux). Purement informatif : ne bloque pas le boot.
 */
@Slf4j
@Component
public class StartupProfileLogger {

    private final Environment environment;

    public StartupProfileLogger(Environment environment) {
        this.environment = environment;
    }

    @EventListener(ContextRefreshedEvent.class)
    public void logActiveProfiles() {
        String[] profiles = environment.getActiveProfiles();
        String active = profiles.length == 0 ? "(defaut)" : Arrays.toString(profiles);
        log.info("Profil(s) Spring actif(s) : {}", active);

        if (Arrays.asList(profiles).contains("dev")) {
            log.warn("Profil DEV actif : cle JWT non-production, CORS LAN, logs verbeux. "
                    + "Ne JAMAIS utiliser ce profil en production (poser SPRING_PROFILES_ACTIVE=prod).");
        }
    }
}
