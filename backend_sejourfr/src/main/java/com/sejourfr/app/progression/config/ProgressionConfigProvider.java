package com.sejourfr.app.progression.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Expose la configuration versionnée active comme un bean, chargée une fois au
 * démarrage.
 *
 * <p>Le chargement échoue bruyamment si le fichier manque, contient une clé
 * inconnue, oublie une entrée d'un enum, ou déclare un {@code engineVersion}
 * différent de celui demandé. Une configuration incomplète qui démarrerait quand
 * même produirait des états faux qu'on ne découvrirait que des mois plus tard,
 * sur des données déjà matérialisées.
 */
@Configuration
@RequiredArgsConstructor
public class ProgressionConfigProvider {

    private final ProgressionProperties properties;

    @Bean
    public ProgressionConfig progressionConfig() {
        return ProgressionConfigLoader.load(properties.getEngineVersion());
    }
}
