package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Reglages de la mesure d'audience : taux de change figes a l'encaissement,
 * base geo-IP, et comptes exclus des statistiques.
 *
 * <p><b>Les valeurs par defaut sont ici ET dans {@code application.yaml}, a
 * l'identique</b> — doctrine du depot : un POJO qui diverge de son YAML est une
 * bombe a retardement, on ne decouvre l'ecart que le jour ou la cle disparait
 * de la configuration.
 */
@ConfigurationProperties(prefix = "sejourfr.analytics")
public class AnalyticsProperties {

    /**
     * Taux de conversion vers l'euro, par devise ISO 4217.
     *
     * <p><b>Ce n'est pas un taux « du jour », c'est un taux de reference
     * FIGE A L'ENCAISSEMENT</b> : la valeur lue ici est recopiee dans
     * {@code user_subscriptions.fx_rate_to_eur} au moment du paiement, et plus
     * jamais relue pour cette ligne. Changer un taux ici n'affecte donc que les
     * paiements <i>a venir</i> — le chiffre d'affaires passe ne bouge pas.
     *
     * <p>Une devise absente de cette table donne un {@code amount_eur_cents}
     * <b>nul</b>, jamais une conversion approchee : un revenu inconnu vaut
     * {@code null}, pas zero, et surtout pas un chiffre invente.
     *
     * <p>Ordre de grandeur releve a la mise en service. On ne branche pas de
     * service de taux temps reel : la quasi-totalite des encaissements est en
     * euros, et une dependance reseau sur le chemin d'un paiement serait un
     * risque sans contrepartie.
     */
    private Map<String, BigDecimal> fxRates = defaultFxRates();

    /**
     * Comptes exclus de toutes les statistiques — les comptes de demonstration
     * et de test (brief §85). L'exclusion s'applique <b>en SQL</b>, jamais apres
     * coup : soustraire a la lecture laisse les pourcentages faux.
     */
    private List<String> excludedEmails = List.of(
            "admin@sejourfr.fr", "user@sejourfr.fr", "karim.test@sejourfr.fr");

    /** Base MaxMind GeoLite2-Country. */
    private Geoip geoip = new Geoip();

    private static Map<String, BigDecimal> defaultFxRates() {
        Map<String, BigDecimal> rates = new LinkedHashMap<>();
        rates.put("EUR", BigDecimal.ONE);
        rates.put("USD", new BigDecimal("0.920000"));
        rates.put("GBP", new BigDecimal("1.170000"));
        rates.put("CHF", new BigDecimal("1.050000"));
        rates.put("CAD", new BigDecimal("0.680000"));
        return rates;
    }

    /** Taux vers l'euro pour cette devise, ou {@code null} si elle est inconnue. */
    public BigDecimal fxRate(String currency) {
        if (currency == null || currency.isBlank() || fxRates == null) return null;
        return fxRates.get(currency.trim().toUpperCase(Locale.ROOT));
    }

    public Map<String, BigDecimal> getFxRates() { return fxRates; }
    public void setFxRates(Map<String, BigDecimal> fxRates) { this.fxRates = fxRates; }

    public List<String> getExcludedEmails() { return excludedEmails; }
    public void setExcludedEmails(List<String> excludedEmails) { this.excludedEmails = excludedEmails; }

    public Geoip getGeoip() { return geoip; }
    public void setGeoip(Geoip geoip) { this.geoip = geoip; }

    /**
     * Base geo-IP embarquee.
     *
     * <p>Le fichier n'est <b>pas versionne</b> : GeoLite2 exige un compte
     * MaxMind et sa licence interdit la redistribution. Son absence est donc un
     * cas <b>normal</b>, pas une panne : le resolveur devient inerte et tous les
     * pays valent {@code null} — <i>inconnu, jamais invente</i>.
     */
    public static class Geoip {

        /**
         * Chemin du fichier {@code .mmdb} sur le disque. Vide = on tente la
         * ressource de classpath ci-dessous, puis on abandonne.
         */
        private String databasePath = "";

        /** Repli de classpath, pour un deploiement qui embarquerait la base. */
        private String classpathResource = "geoip/GeoLite2-Country.mmdb";

        public String getDatabasePath() { return databasePath; }
        public void setDatabasePath(String databasePath) { this.databasePath = databasePath; }

        public String getClasspathResource() { return classpathResource; }
        public void setClasspathResource(String classpathResource) { this.classpathResource = classpathResource; }
    }
}
