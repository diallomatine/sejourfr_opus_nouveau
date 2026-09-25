package com.sejourfr.app.util;

import com.sejourfr.app.enums.ClientPlatform;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le résolveur ne fait qu'une chose : lire deux en-têtes et les ramener dans
 * des ensembles fermés. C'est cette fermeture qui empêche un tiers de créer des
 * dimensions à volonté — la même que celle opposée aux événements anonymes.
 */
class ClientContextResolverTest {

    private final ClientContextResolver resolver = new ClientContextResolver();

    private static MockHttpServletRequest request(String client, String source) {
        MockHttpServletRequest req = new MockHttpServletRequest();
        if (client != null) req.addHeader(ClientContextResolver.HEADER_CLIENT, client);
        if (source != null) req.addHeader(ClientContextResolver.HEADER_SOURCE, source);
        return req;
    }

    @Test
    void lesDeuxEnTetesSontLusEtNormalises() {
        ClientContext ctx = resolver.resolve(request("Mobile", "TikTok"));

        assertThat(ctx.platform()).isEqualTo(ClientPlatform.MOBILE);
        assertThat(ctx.source()).isEqualTo("tiktok");
    }

    @Test
    void unePlateformeInconnueOuAbsenteVautUNKNOWN() {
        assertThat(resolver.resolve(request("desktop-app", null)).platform())
                .isEqualTo(ClientPlatform.UNKNOWN);
        assertThat(resolver.resolve(request(null, null)).platform())
                .isEqualTo(ClientPlatform.UNKNOWN);
    }

    /**
     * Même allowlist que la mesure anonyme : deux copies auraient fini par
     * ranger « tiktok » dans deux dimensions différentes selon la surface.
     */
    @Test
    void uneProvenanceHorsAllowlistTombeDansAutre_etUneAbsenceVautDirect() {
        assertThat(resolver.resolve(request("web", "reseau-invente-123")).source())
                .isEqualTo(TrafficSource.OTHER);
        assertThat(resolver.resolve(request("web", null)).source())
                .isEqualTo(TrafficSource.DIRECT);
        assertThat(resolver.resolve(request("web", "   ")).source())
                .isEqualTo(TrafficSource.DIRECT);
    }

    @Test
    void sansRequeteLeContexteEstInconnu_jamaisNull() {
        ClientContext ctx = resolver.resolve(null);

        assertThat(ctx).isNotNull();
        assertThat(ctx.platform()).isEqualTo(ClientPlatform.UNKNOWN);
        assertThat(ctx.source()).isEqualTo(TrafficSource.DIRECT);
    }

    /**
     * « direct » est une provenance observée, « inconnu » est une absence
     * d'observation : les confondre gonflerait le direct de tout l'historique.
     */
    @Test
    void leRepliDeLectureDistingueLAbsenceDObservationDuDirect() {
        assertThat(TrafficSource.readOrUnknown(null)).isEqualTo("inconnu");
        assertThat(TrafficSource.readOrUnknown("")).isEqualTo("inconnu");
        assertThat(TrafficSource.readOrUnknown("direct")).isEqualTo("direct");
        assertThat(ClientPlatform.readOrUnknown(null)).isEqualTo("UNKNOWN");
        assertThat(ClientPlatform.readOrUnknown("WEB")).isEqualTo("WEB");
    }

    // ------------------------------------------------------------------------
    // Chantier Suivi (Q4) : ios / android, identifiant de mesure, version
    // ------------------------------------------------------------------------

    @Test
    void iosEtAndroidSontDistingues_etMobileResteLaValeurHistorique() {
        assertThat(resolver.resolve(request("iOS", null)).platform()).isEqualTo(ClientPlatform.IOS);
        assertThat(resolver.resolve(request("android", null)).platform()).isEqualTo(ClientPlatform.ANDROID);
        // Un client d'avant la distinction garde sa valeur : on ne devine pas le systeme.
        assertThat(resolver.resolve(request("mobile", null)).platform()).isEqualTo(ClientPlatform.MOBILE);
        assertThat(ClientPlatform.MOBILE.isNativeApp()).isTrue();
        assertThat(ClientPlatform.WEB.isNativeApp()).isFalse();
    }

    @Test
    void lIdentifiantDeMesureEtLaVersionSontLus_etUnIllisibleVautNull() {
        java.util.UUID anon = java.util.UUID.randomUUID();
        MockHttpServletRequest req = request("ios", null);
        req.addHeader(ClientContextResolver.HEADER_ANONYMOUS_ID, anon.toString());
        req.addHeader(ClientContextResolver.HEADER_APP_VERSION, "2.4.1+57");

        ClientContext ctx = resolver.resolve(req);
        assertThat(ctx.anonymousId()).isEqualTo(anon);
        assertThat(ctx.appVersion()).isEqualTo("2.4.1+57");

        MockHttpServletRequest faux = request("ios", null);
        faux.addHeader(ClientContextResolver.HEADER_ANONYMOUS_ID, "pas-un-uuid");
        faux.addHeader(ClientContextResolver.HEADER_APP_VERSION, "2.4 <script>");
        ClientContext illisible = resolver.resolve(faux);
        assertThat(illisible.anonymousId()).isNull();
        assertThat(illisible.appVersion()).isNull();
        assertThat(ClientContextResolver.parseAppVersion("v".repeat(33))).isNull();
    }

    /** Un sendBeacon ne pose aucun en-tete : le corps comble l'absence, jamais plus. */
    @Test
    void leCorpsNeCombleQuUneAbsenceDEnTete() {
        ClientContext sansEnTete = resolver.resolve(request(null, null), "android", "3.0.0");
        assertThat(sansEnTete.platform()).isEqualTo(ClientPlatform.ANDROID);
        assertThat(sansEnTete.appVersion()).isEqualTo("3.0.0");

        MockHttpServletRequest avecEnTete = request("web", null);
        avecEnTete.addHeader(ClientContextResolver.HEADER_APP_VERSION, "1.0.0");
        ClientContext enTetePrime = resolver.resolve(avecEnTete, "android", "3.0.0");
        assertThat(enTetePrime.platform()).isEqualTo(ClientPlatform.WEB);
        assertThat(enTetePrime.appVersion()).isEqualTo("1.0.0");
    }

    /** Requetes d'auth : le champ historique du corps prime, l'en-tete le complete. */
    @Test
    void lIdentifiantDuCorpsPrimeSurCeluiDeLEnTete() {
        java.util.UUID enTete = java.util.UUID.randomUUID();
        java.util.UUID corps = java.util.UUID.randomUUID();
        ClientContext ctx = new ClientContext(ClientPlatform.WEB, TrafficSource.DIRECT, enTete, null);

        assertThat(ctx.anonymousIdPreferring(corps.toString())).isEqualTo(corps);
        assertThat(ctx.anonymousIdPreferring(null)).isEqualTo(enTete);
        assertThat(ctx.anonymousIdPreferring("illisible")).isEqualTo(enTete);
        assertThat(ClientContext.unknown().anonymousIdPreferring(null)).isNull();
    }
}
