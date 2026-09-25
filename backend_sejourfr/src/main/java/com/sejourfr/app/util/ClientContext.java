package com.sejourfr.app.util;

import com.sejourfr.app.enums.ClientPlatform;

import java.util.UUID;

/**
 * Contexte declare par l'appelant : sur quelle plateforme il est, par quel
 * reseau il est arrive, quel identifiant de mesure il porte et en quelle
 * version d'application. Jamais nul en tant qu'objet — l'absence d'information
 * se dit {@link ClientPlatform#UNKNOWN} + {@link TrafficSource#DIRECT} et des
 * champs {@code null}, pas par une reference nulle qu'il faudrait tester
 * partout.
 *
 * @param platform    plateforme declaree
 * @param source      provenance normalisee par {@link TrafficSource}
 * @param anonymousId identifiant de mesure ({@code X-Sejourfr-Anonymous-Id}),
 *                    {@code null} si absent ou illisible
 * @param appVersion  version d'application ({@code X-Sejourfr-App-Version}),
 *                    {@code null} si absente ou hors format
 */
public record ClientContext(ClientPlatform platform, String source, UUID anonymousId, String appVersion) {

    /** Contexte sans identifiant de mesure ni version (appelants historiques). */
    public ClientContext(ClientPlatform platform, String source) {
        this(platform, source, null, null);
    }

    /**
     * Identifiant de mesure de l'appelant : celui du <b>corps</b> s'il est
     * lisible (champ {@code anonymousId} des requetes d'auth, historique), sinon
     * celui de l'en-tete {@code X-Sejourfr-Anonymous-Id}. {@code null} si aucun.
     */
    public UUID anonymousIdPreferring(String declaredInBody) {
        UUID body = ClientContextResolver.parseAnonymousId(declaredInBody);
        return body != null ? body : anonymousId;
    }

    /**
     * <b>Client ancien</b> (controle G) : application d'avant iOS / Android
     * ({@link ClientPlatform#MOBILE}), plateforme non declaree
     * ({@link ClientPlatform#UNKNOWN}), ou web sans {@code X-Sejourfr-App-Version}
     * (onglet charge avant le chantier Suivi). Un tel client ne sait pas
     * transmettre une run de diagnostic : l'absence de run ne dit donc rien de
     * son inscription. Autorite unique de la regle.
     */
    public boolean isLegacyClient() {
        return platform == null || platform == ClientPlatform.MOBILE || platform == ClientPlatform.UNKNOWN
                || (platform == ClientPlatform.WEB && appVersion == null);
    }

    /**
     * <b>Provenance a persister</b> (controle N2) : la source normalisee, sauf
     * pour l'application native sans provenance declaree — {@code null},
     * inconnue. {@link TrafficSource#DIRECT} n'y est qu'un repli : l'app n'a ni
     * deep link ni install referrer, « direct » n'y a jamais ete observe. Le web
     * sans provenance, lui, reste un vrai acces direct. Autorite unique, lue par
     * l'attribution du visiteur et par {@code users.signup_source}.
     */
    public String attributedSource() {
        if (platform != null && platform.isNativeApp()
                && (source == null || TrafficSource.DIRECT.equals(source))) {
            return null;
        }
        return source;
    }

    /** Contexte d'un appel qui n'a rien declare. */
    public static ClientContext unknown() {
        return new ClientContext(ClientPlatform.UNKNOWN, TrafficSource.DIRECT, null, null);
    }
}
