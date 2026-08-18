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
}
