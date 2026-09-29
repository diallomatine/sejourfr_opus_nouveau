package com.sejourfr.app.config;

import jakarta.annotation.PostConstruct;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.regex.Pattern;

/**
 * Configuration publique de l'application mobile, servie par
 * {@code GET /api/public/app-config} (controle G, option a).
 *
 * <p><b>Version minimale supportee, par systeme.</b> {@code null} = aucune
 * exigence : personne n'est bloque. C'est la valeur livree. La poser (ex.
 * {@code APP_MIN_VERSION_IOS=2.5.0}) fait afficher « mettre a jour » aux
 * applications plus anciennes <b>qui embarquent ce controle</b> — les versions
 * deja publiees ne le lisent pas.
 *
 * <p>Format {@code MAJOR.MINOR.PATCH} (chiffres seuls) : c'est ce que l'app
 * compare a sa {@code version} ({@code package_info_plus}, sans le
 * {@code +build}). Un format illisible fait echouer le demarrage : un seuil mal
 * ecrit ne doit ni bloquer tout le monde, ni personne en silence.
 */
@ConfigurationProperties(prefix = "sejourfr.app-config")
public class AppConfigProperties {

    private static final Pattern VERSION = Pattern.compile("^\\d{1,4}\\.\\d{1,4}\\.\\d{1,4}$");

    private final MinSupportedVersion minSupportedVersion = new MinSupportedVersion();

    public MinSupportedVersion getMinSupportedVersion() {
        return minSupportedVersion;
    }

    @PostConstruct
    void verifier() {
        verifier("ios", minSupportedVersion.getIos());
        verifier("android", minSupportedVersion.getAndroid());
    }

    private static void verifier(String systeme, String version) {
        if (version != null && !VERSION.matcher(version).matches()) {
            throw new IllegalStateException("sejourfr.app-config.min-supported-version." + systeme
                    + " doit valoir MAJOR.MINOR.PATCH (chiffres) ou rester vide : « " + version + " »");
        }
    }

    /** Par systeme ; {@code null} (ou vide) = aucune version minimale. */
    public static class MinSupportedVersion {
        private String ios;
        private String android;

        public String getIos() { return ios; }
        public void setIos(String ios) { this.ios = blankToNull(ios); }
        public String getAndroid() { return android; }
        public void setAndroid(String android) { this.android = blankToNull(android); }

        private static String blankToNull(String value) {
            return value == null || value.isBlank() ? null : value.trim();
        }
    }
}
