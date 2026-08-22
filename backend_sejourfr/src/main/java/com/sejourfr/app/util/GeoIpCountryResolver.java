package com.sejourfr.app.util;

import com.maxmind.geoip2.DatabaseReader;
import com.maxmind.geoip2.exception.GeoIp2Exception;
import com.maxmind.geoip2.model.CountryResponse;
import com.sejourfr.app.config.AnalyticsProperties;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.net.InetAddress;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Locale;

/**
 * Pays d'un appelant, deduit de son IP par une base MaxMind GeoLite2-Country
 * <b>embarquee</b> — aucun appel reseau, aucun service tiers.
 *
 * <p>🛑 <b>L'IP N'EST JAMAIS PERSISTEE.</b> Elle est lue en memoire, convertie
 * en deux lettres, puis oubliee. C'est ce qui permet de continuer d'affirmer
 * qu'aucune donnee identifiante n'est conservee par la mesure d'audience — et
 * c'est aussi pourquoi la conversion se fait <i>ici</i>, en bord d'entree, et
 * non dans un traitement differe qui aurait besoin de la stocker en attendant.
 *
 * <p><b>La base n'est pas versionnee dans le depot</b> : GeoLite2 exige un
 * compte MaxMind et sa licence interdit la redistribution. Son absence est donc
 * un cas <b>normal</b> et non une panne. Sans elle, le resolveur est
 * <b>inerte</b> : il le dit une fois au demarrage, puis rend {@code null} pour
 * tout le monde. Un pays inconnu vaut {@code null}, jamais « autre », jamais un
 * pays plausible — <i>null = inconnu, jamais mauvais</i>.
 *
 * <p>Rendent aussi {@code null}, sans bruit : une IP privee ou de bouclage
 * (developpement, reseau interne), une adresse illisible, et toute adresse
 * absente de la base.
 *
 * <p>Pour l'activer : telecharger {@code GeoLite2-Country.mmdb} depuis un compte
 * MaxMind et renseigner {@code sejourfr.analytics.geoip.database-path}
 * ({@code ANALYTICS_GEOIP_DB}).
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class GeoIpCountryResolver {

    private final AnalyticsProperties properties;

    /** {@code null} tant qu'aucune base n'a pu etre ouverte : le resolveur est alors inerte. */
    private DatabaseReader reader;

    @PostConstruct
    void openDatabase() {
        AnalyticsProperties.Geoip config = properties.getGeoip();
        String path = config == null ? null : config.getDatabasePath();

        if (path != null && !path.isBlank()) {
            Path file = Path.of(path.trim());
            if (!Files.isReadable(file)) {
                log.warn("Base geo-IP introuvable ou illisible ({}) : le pays des visiteurs "
                        + "restera INCONNU. Aucune donnee n'est inventee.", file);
                return;
            }
            try {
                reader = new DatabaseReader.Builder(file.toFile()).build();
                log.info("Base geo-IP chargee depuis {}", file);
                return;
            } catch (IOException e) {
                log.warn("Base geo-IP illisible ({}) : le pays des visiteurs restera INCONNU. {}",
                        file, e.getMessage());
                return;
            }
        }

        String resource = config == null ? null : config.getClasspathResource();
        if (resource == null || resource.isBlank()) {
            logInerte();
            return;
        }
        ClassPathResource classPathResource = new ClassPathResource(resource);
        if (!classPathResource.exists()) {
            logInerte();
            return;
        }
        try (InputStream in = classPathResource.getInputStream()) {
            reader = new DatabaseReader.Builder(in).build();
            log.info("Base geo-IP chargee depuis le classpath ({})", resource);
        } catch (IOException e) {
            log.warn("Base geo-IP de classpath illisible ({}) : pays INCONNU. {}",
                    resource, e.getMessage());
        }
    }

    private void logInerte() {
        log.info("Aucune base geo-IP configuree : le pays des visiteurs vaudra INCONNU. "
                + "Renseigner sejourfr.analytics.geoip.database-path pour l'activer "
                + "(GeoLite2-Country.mmdb, compte MaxMind requis — le fichier n'est pas "
                + "versionne, sa licence l'interdit).");
    }

    @PreDestroy
    void closeDatabase() {
        if (reader == null) return;
        try {
            reader.close();
        } catch (IOException e) {
            log.debug("Fermeture de la base geo-IP : {}", e.getMessage());
        }
    }

    /** Vrai si une base est reellement chargee. Sert aux diagnostics, pas au metier. */
    public boolean isActif() {
        return reader != null;
    }

    /**
     * Code pays ISO 3166-1 alpha-2 de cette IP, ou {@code null}.
     *
     * @param ip adresse litterale telle que la rend {@code ClientIpResolver}.
     *           Elle n'est ni journalisee ni conservee.
     */
    public String resolve(String ip) {
        if (reader == null || ip == null || ip.isBlank()) return null;

        InetAddress address;
        try {
            address = InetAddress.getByName(stripZone(ip.trim()));
        } catch (Exception e) {
            // Adresse illisible, ou nom d'hote : on ne resout rien.
            return null;
        }
        // Reseau prive, bouclage, lien local : un vrai visiteur derriere un
        // proxy mal configure, ou nous-memes en developpement. Chercher un pays
        // la-dedans ne peut produire qu'une reponse fausse.
        if (address.isAnyLocalAddress() || address.isLoopbackAddress()
                || address.isSiteLocalAddress() || address.isLinkLocalAddress()
                || address.isMulticastAddress()) {
            return null;
        }

        try {
            CountryResponse response = reader.country(address);
            String iso = response == null || response.getCountry() == null
                    ? null : response.getCountry().getIsoCode();
            if (iso == null || iso.length() != 2) return null;
            return iso.toUpperCase(Locale.ROOT);
        } catch (IOException | GeoIp2Exception | RuntimeException e) {
            // Adresse absente de la base : cas normal et frequent. On ne
            // journalise pas — ce serait un log par requete pour une non-info.
            return null;
        }
    }

    /** Retire la zone d'une IPv6 ({@code fe80::1%eth0}), que l'API refuse. */
    private static String stripZone(String literal) {
        int percent = literal.indexOf('%');
        return percent > 0 ? literal.substring(0, percent) : literal;
    }
}
