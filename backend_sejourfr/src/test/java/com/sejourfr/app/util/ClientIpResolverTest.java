package com.sejourfr.app.util;

import com.sejourfr.app.config.TrustedProxyProperties;
import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Resolution de l'IP client. Le point central : {@code X-Forwarded-For} n'est
 * cru QUE si la connexion vient d'un proxy declare. Sans ces tests, les
 * rate-limits par IP restaient contournables par un simple en-tete.
 */
class ClientIpResolverTest {

    private static ClientIpResolver resolver(String... trustedRanges) {
        TrustedProxyProperties props = new TrustedProxyProperties();
        props.setRanges(List.of(trustedRanges));
        ClientIpResolver r = new ClientIpResolver(props);
        r.parseRanges();
        return r;
    }

    private static HttpServletRequest req(String xff, String realIp, String remoteAddr) {
        HttpServletRequest r = mock(HttpServletRequest.class);
        when(r.getHeader("X-Forwarded-For")).thenReturn(xff);
        when(r.getHeader("X-Real-IP")).thenReturn(realIp);
        when(r.getRemoteAddr()).thenReturn(remoteAddr);
        return r;
    }

    // ------------------------------------------------------- aucun proxy connu

    /** Le défaut : aucune configuration → l'en-tête ne vaut rien. */
    @Test
    void noTrustedProxy_ignoresForwardedFor() {
        assertThat(resolver().resolve(req("10.0.1.1", null, "203.0.113.9")))
                .isEqualTo("203.0.113.9");
    }

    @Test
    void noTrustedProxy_ignoresRealIp() {
        assertThat(resolver().resolve(req(null, "10.0.1.1", "203.0.113.9")))
                .isEqualTo("203.0.113.9");
    }

    /**
     * Le scénario de la revue : deux requêtes avec des X-Forwarded-For
     * différents doivent aboutir à la MÊME identité, sinon le compteur
     * anti-abus est remis à zéro à volonté.
     */
    @Test
    void noTrustedProxy_forgedHeadersShareTheSameIdentity() {
        ClientIpResolver r = resolver();
        String first = r.resolve(req("10.0.1.1", null, "203.0.113.9"));
        String second = r.resolve(req("10.0.2.2", null, "203.0.113.9"));
        assertThat(first).isEqualTo(second);
    }

    @Test
    void noHeaders_returnsSocketAddress() {
        assertThat(resolver().resolve(req(null, null, "203.0.113.9")))
                .isEqualTo("203.0.113.9");
    }

    @Test
    void nullRequest_returnsNull() {
        assertThat(resolver().resolve(null)).isNull();
    }

    @Test
    void unknownRemoteAddr_returnsNull() {
        assertThat(resolver().resolve(req(null, null, "unknown"))).isNull();
    }

    // ------------------------------------------------------ proxy de confiance

    @Test
    void trustedProxyExactAddress_readsForwardedFor() {
        assertThat(resolver("10.0.0.5").resolve(req("203.0.113.9", null, "10.0.0.5")))
                .isEqualTo("203.0.113.9");
    }

    @Test
    void trustedProxyCidr_readsForwardedFor() {
        assertThat(resolver("10.0.0.0/8").resolve(req("203.0.113.9", null, "10.4.2.1")))
                .isEqualTo("203.0.113.9");
    }

    @Test
    void addressOutsideCidr_isNotTrusted() {
        assertThat(resolver("10.0.0.0/8").resolve(req("203.0.113.9", null, "11.4.2.1")))
                .isEqualTo("11.4.2.1");
    }

    /**
     * Chaîne « valeur forgée par le client, IP réelle ajoutée par le proxy » :
     * on lit la dernière entrée non-proxy, donc la vraie, pas la forgée.
     */
    @Test
    void forwardedChain_takesLastUntrustedHop() {
        ClientIpResolver r = resolver("10.0.0.0/8");
        assertThat(r.resolve(req("1.2.3.4, 203.0.113.9, 10.0.0.7", null, "10.0.0.7")))
                .isEqualTo("203.0.113.9");
    }

    @Test
    void forwardedChain_allTrusted_fallsBackToRealIpThenSocket() {
        ClientIpResolver r = resolver("10.0.0.0/8");
        assertThat(r.resolve(req("10.0.0.1, 10.0.0.7", "198.51.100.7", "10.0.0.7")))
                .isEqualTo("198.51.100.7");
        assertThat(r.resolve(req("10.0.0.1, 10.0.0.7", null, "10.0.0.7")))
                .isEqualTo("10.0.0.7");
    }

    @Test
    void trustedProxy_blankForwardedFor_fallsBackToRealIp() {
        assertThat(resolver("10.0.0.5").resolve(req("   ", "198.51.100.7", "10.0.0.5")))
                .isEqualTo("198.51.100.7");
    }

    @Test
    void ipv6TrustedProxy_readsForwardedFor() {
        assertThat(resolver("::1").resolve(req("203.0.113.9", null, "0:0:0:0:0:0:0:1")))
                .isEqualTo("203.0.113.9");
    }

    // ------------------------------------------------------------- cas limites

    @Test
    void wildcard_trustsEveryCaller() {
        assertThat(resolver("*").resolve(req("203.0.113.9", null, "198.51.100.1")))
                .isEqualTo("203.0.113.9");
    }

    @Test
    void unparsableRange_isIgnoredWithoutBreakingTheOthers() {
        ClientIpResolver r = resolver("pas-une-ip", "10.0.0.0/8");
        assertThat(r.resolve(req("203.0.113.9", null, "10.0.0.7"))).isEqualTo("203.0.113.9");
        assertThat(r.resolve(req("203.0.113.9", null, "198.51.100.1"))).isEqualTo("198.51.100.1");
    }

    @Test
    void blankRangeEntries_areIgnored() {
        assertThat(resolver("", "  ").resolve(req("203.0.113.9", null, "198.51.100.1")))
                .isEqualTo("198.51.100.1");
    }
}
