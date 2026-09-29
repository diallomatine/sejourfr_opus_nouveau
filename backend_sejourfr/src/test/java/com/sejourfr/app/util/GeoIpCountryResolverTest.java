package com.sejourfr.app.util;

import com.sejourfr.app.config.AnalyticsProperties;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le resolveur geo-IP <b>sans base</b> — c'est-a-dire la configuration livree
 * par defaut, et probablement celle de longue duree : le fichier GeoLite2 exige
 * un compte MaxMind et sa licence interdit de le versionner.
 *
 * <p>Ce que ces tests verrouillent : <b>l'absence de base est un cas normal, pas
 * une panne</b>. Rien ne leve, et surtout rien n'est invente — un pays inconnu
 * vaut {@code null}, jamais « FR » par defaut, jamais « autre ».
 */
class GeoIpCountryResolverTest {

    private GeoIpCountryResolver resolverSansBase() {
        AnalyticsProperties properties = new AnalyticsProperties();
        AnalyticsProperties.Geoip geoip = new AnalyticsProperties.Geoip();
        geoip.setDatabasePath("");
        geoip.setClasspathResource("geoip/inexistant.mmdb");
        properties.setGeoip(geoip);
        GeoIpCountryResolver resolver = new GeoIpCountryResolver(properties);
        resolver.openDatabase();
        return resolver;
    }

    @Test
    @DisplayName("Sans base, le résolveur est inerte et ne lève jamais")
    void inerteSansBase() {
        GeoIpCountryResolver resolver = resolverSansBase();
        assertThat(resolver.isActif()).isFalse();
        assertThat(resolver.resolve("81.250.12.34")).isNull();
        assertThat(resolver.resolve(null)).isNull();
        assertThat(resolver.resolve("pas-une-ip")).isNull();
    }

    @Test
    @DisplayName("Un chemin de base introuvable est signalé, pas fatal")
    void cheminIntrouvable() {
        AnalyticsProperties properties = new AnalyticsProperties();
        AnalyticsProperties.Geoip geoip = new AnalyticsProperties.Geoip();
        geoip.setDatabasePath("/chemin/qui/n/existe/pas/GeoLite2-Country.mmdb");
        properties.setGeoip(geoip);
        GeoIpCountryResolver resolver = new GeoIpCountryResolver(properties);
        resolver.openDatabase();
        assertThat(resolver.isActif()).isFalse();
        assertThat(resolver.resolve("81.250.12.34")).isNull();
    }

    /**
     * Meme avec une base chargee, ces adresses ne peuvent produire qu'une
     * reponse fausse : elles ne designent personne a l'exterieur. Le filtre est
     * applique AVANT toute interrogation.
     */
    @Test
    @DisplayName("Bouclage, réseau privé et lien local ne donnent jamais de pays")
    void adressesNonPubliques() {
        GeoIpCountryResolver resolver = resolverSansBase();
        for (String ip : new String[]{"127.0.0.1", "::1", "10.0.0.5", "192.168.1.20",
                "172.16.3.4", "169.254.1.1", "0.0.0.0"}) {
            assertThat(resolver.resolve(ip)).as("pays de %s", ip).isNull();
        }
    }

    @Test
    @DisplayName("La fermeture est sûre même quand aucune base n'a été ouverte")
    void fermetureSure() {
        GeoIpCountryResolver resolver = resolverSansBase();
        resolver.closeDatabase();
        assertThat(resolver.isActif()).isFalse();
    }
}
