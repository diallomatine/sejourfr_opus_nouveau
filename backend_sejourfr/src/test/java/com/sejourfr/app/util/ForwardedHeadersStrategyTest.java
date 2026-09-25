package com.sejourfr.app.util;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import org.apache.catalina.filters.RemoteIpFilter;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import org.springframework.mock.web.MockFilterConfig;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.web.filter.ForwardedHeaderFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Contrôle N8 — d'où vient l'IP que lisent les rate-limits en production.
 *
 * <p>{@code forward-headers-strategy: framework} (le réglage d'avant) pose le
 * {@link ForwardedHeaderFilter} de Spring, qui réécrit {@code getRemoteAddr()}
 * avec la PREMIÈRE valeur de {@code X-Forwarded-For} sans regarder qui parle :
 * un client la choisit, et {@link ClientIpResolver} ne voit plus jamais la
 * socket. {@code native} délègue à la valve RemoteIp de Tomcat, qui ne lit
 * l'en-tête que si la connexion vient d'un proxy interne, et retient la
 * dernière adresse non interne de la chaîne. Même algorithme ici via
 * {@link RemoteIpFilter} (la variante filtre de la valve).
 */
class ForwardedHeadersStrategyTest {

    private static String remoteAddrApres(jakarta.servlet.Filter filter, String socket, String xff)
            throws ServletException, IOException {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/auth/login");
        request.setRemoteAddr(socket);
        if (xff != null) request.addHeader("X-Forwarded-For", xff);
        AtomicReference<String> vu = new AtomicReference<>();
        FilterChain chain = (req, res) -> vu.set(((HttpServletRequest) req).getRemoteAddr());
        filter.doFilter(request, new MockHttpServletResponse(), chain);
        return vu.get();
    }

    @Test
    @DisplayName("« framework » : l'IP d'un client connecté en direct est celle qu'il écrit dans X-Forwarded-For")
    void frameworkEstFalsifiable() throws Exception {
        ForwardedHeaderFilter filter = new ForwardedHeaderFilter();
        assertThat(remoteAddrApres(filter, "203.0.113.7", "1.2.3.4")).isEqualTo("1.2.3.4");
        // Derriere un proxy qui AJOUTE l'adresse reelle ($proxy_add_x_forwarded_for),
        // la valeur forgee reste a gauche et c'est elle qui est retenue.
        assertThat(remoteAddrApres(filter, "127.0.0.1", "1.2.3.4, 203.0.113.7")).isEqualTo("1.2.3.4");
    }

    @Test
    @DisplayName("« native » : en-tête ignoré en direct ; derrière un proxy interne, dernière adresse non interne")
    void nativeNeCroitQueLeProxy() throws Exception {
        RemoteIpFilter filter = new RemoteIpFilter();
        filter.init(new MockFilterConfig());
        assertThat(remoteAddrApres(filter, "203.0.113.7", "1.2.3.4")).isEqualTo("203.0.113.7");
        assertThat(remoteAddrApres(filter, "127.0.0.1", "1.2.3.4, 203.0.113.7")).isEqualTo("203.0.113.7");
        assertThat(remoteAddrApres(filter, "127.0.0.1", "203.0.113.7")).isEqualTo("203.0.113.7");
    }

    @Test
    @DisplayName("La configuration de production utilise « native », jamais « framework »")
    void productionEnNative() throws Exception {
        String prod = new ClassPathResource("application-prod.yaml").getContentAsString(StandardCharsets.UTF_8);
        assertThat(prod).contains("forward-headers-strategy: native")
                .doesNotContain("forward-headers-strategy: framework");
    }
}
