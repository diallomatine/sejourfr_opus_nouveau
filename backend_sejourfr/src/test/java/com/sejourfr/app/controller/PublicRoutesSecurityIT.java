package com.sejourfr.app.controller;

import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

/**
 * Sécurité des surfaces {@code permitAll} de {@code SecurityConfig} : une requête
 * anonyme doit atteindre le controller (ni 401 ni 403 ; un 200/400/404/415 est
 * acceptable — on teste que la chaîne de sécurité laisse passer, pas le métier).
 * Ajouter une route = une ligne dans {@link #publicRoutes()}.
 */
class PublicRoutesSecurityIT extends AbstractIntegrationTest {

    private static final String RANDOM_ID = "11111111-1111-1111-1111-111111111111";

    @Autowired
    private MockMvc mockMvc;

    static Stream<Arguments> publicRoutes() {
        return Stream.of(
                // /api/public/**
                Arguments.of(HttpMethod.GET, "/api/public/themes"),
                Arguments.of(HttpMethod.GET, "/api/public/exams"),
                Arguments.of(HttpMethod.GET, "/api/public/exams/some-slug"),
                Arguments.of(HttpMethod.GET, "/api/public/lots"),
                Arguments.of(HttpMethod.POST, "/api/public/attempts/demo"),
                Arguments.of(HttpMethod.GET, "/api/public/attempts/" + RANDOM_ID),
                Arguments.of(HttpMethod.POST, "/api/public/page-views"),
                // GET /api/exams/**
                Arguments.of(HttpMethod.GET, "/api/exams"),
                Arguments.of(HttpMethod.GET, "/api/exams/some-slug"),
                // GET /api/billing/plans
                Arguments.of(HttpMethod.GET, "/api/billing/plans"),
                // POST /api/contact
                Arguments.of(HttpMethod.POST, "/api/contact"),
                // Webhooks (signature vérifiée dans le service, pas par la chaîne sécu)
                Arguments.of(HttpMethod.POST, "/api/billing/webhook"),
                Arguments.of(HttpMethod.POST, "/api/billing/webhooks/apple"),
                Arguments.of(HttpMethod.POST, "/api/billing/webhooks/google"),
                // /api/auth/** publics
                Arguments.of(HttpMethod.POST, "/api/auth/register"),
                Arguments.of(HttpMethod.POST, "/api/auth/login"),
                Arguments.of(HttpMethod.POST, "/api/auth/refresh"),
                Arguments.of(HttpMethod.POST, "/api/auth/forgot-password"),
                Arguments.of(HttpMethod.POST, "/api/auth/google"),
                Arguments.of(HttpMethod.POST, "/api/auth/apple"));
    }

    @ParameterizedTest(name = "anonyme {0} {1} -> atteint le controller")
    @MethodSource("publicRoutes")
    void anonymousReachesController(HttpMethod method, String path) throws Exception {
        MvcResult result = mockMvc.perform(build(method, path)).andReturn();
        int status = result.getResponse().getStatus();
        assertTrue(status != 401 && status != 403,
                () -> "Route publique " + method + " " + path
                        + " ne doit pas renvoyer 401/403 en anonyme (reçu " + status + ")");
    }

    private MockHttpServletRequestBuilder build(HttpMethod method, String path) {
        MockHttpServletRequestBuilder b = switch (method.name()) {
            case "GET" -> get(path);
            case "POST" -> post(path);
            default -> throw new IllegalArgumentException("Méthode non gérée : " + method);
        };
        if (method != HttpMethod.GET) {
            b.contentType(MediaType.APPLICATION_JSON).content("{}");
        }
        return b;
    }
}
