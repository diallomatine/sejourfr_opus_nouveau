package com.sejourfr.app.controller;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;

/**
 * Sécurité de toutes les surfaces {@code /api/admin/**} (règle
 * {@code hasRole("ADMIN")} de {@code SecurityConfig}). Un endpoint représentatif
 * par controller admin. Matrice par route :
 * <ul>
 *   <li>anonyme → 401</li>
 *   <li>USER → 403</li>
 *   <li>ADMIN → ni 401 ni 403 (200/400/404/405/415… = OK, on teste l'autorisation,
 *       pas le métier).</li>
 * </ul>
 * Ajouter une route = une ligne dans {@link #adminRoutes()}.
 */
class AdminRoutesSecurityIT extends AbstractIntegrationTest {

    private static final String RANDOM_ID = "11111111-1111-1111-1111-111111111111";

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private TestData testData;
    @Autowired
    private AuthTestSupport auth;

    static Stream<Arguments> adminRoutes() {
        return Stream.of(
                Arguments.of(HttpMethod.GET, "/api/admin/themes"),
                Arguments.of(HttpMethod.GET, "/api/admin/questions"),
                Arguments.of(HttpMethod.GET, "/api/admin/passages"),
                Arguments.of(HttpMethod.GET, "/api/admin/exams"),
                Arguments.of(HttpMethod.GET, "/api/admin/plans"),
                Arguments.of(HttpMethod.GET, "/api/admin/subscriptions"),
                Arguments.of(HttpMethod.GET, "/api/admin/conversations"),
                Arguments.of(HttpMethod.GET, "/api/admin/conversations/unread-count"),
                Arguments.of(HttpMethod.GET, "/api/admin/dashboard"),
                Arguments.of(HttpMethod.GET, "/api/admin/page-views"),
                Arguments.of(HttpMethod.GET, "/api/admin/page-views/paths"),
                // Funnel d'acquisition par compte (distinct de l'agrégat anonyme).
                Arguments.of(HttpMethod.GET, "/api/admin/audience/funnel"),
                Arguments.of(HttpMethod.GET, "/api/admin/audience/funnel?days=7"),
                Arguments.of(HttpMethod.GET,
                        "/api/admin/audience/funnel?from=2026-08-18&to=2026-08-18"),
                Arguments.of(HttpMethod.GET,
                        "/api/admin/page-views?path=/reussir&from=2026-08-18&to=2026-08-18"),
                // Ecran Analytics : un seul endpoint de lecture, plus ses reperes.
                // L8 — le referentiel de notions civiques et son tagging.
                // Il porte le programme civique : jamais ouvert hors ADMIN.
                Arguments.of(HttpMethod.GET, "/api/admin/civic-notions"),
                Arguments.of(HttpMethod.GET, "/api/admin/civic-notions/questions"),
                // La relecture (V054) ECRIT le programme et nomme son auteur :
                // elle est encore moins ouverte que la lecture.
                Arguments.of(HttpMethod.PUT,
                        "/api/admin/civic-notions/questions/" + RANDOM_ID),
                // L12 — la supervision du cout IA. Elle lit des chiffres de
                // facturation : elle n'est jamais ouverte a un compte non ADMIN.
                Arguments.of(HttpMethod.GET, "/api/admin/ai-costs"),
                Arguments.of(HttpMethod.GET, "/api/admin/ai-costs?days=7"),
                Arguments.of(HttpMethod.GET, "/api/admin/analytics"),
                Arguments.of(HttpMethod.GET, "/api/admin/analytics?days=7"),
                Arguments.of(HttpMethod.GET,
                        "/api/admin/analytics?from=2026-08-18&to=2026-08-18"),
                Arguments.of(HttpMethod.GET,
                        "/api/admin/analytics?days=30&source=tiktok&country=FR"
                        + "&device=MOBILE_WEB&platform=WEB"),
                Arguments.of(HttpMethod.GET, "/api/admin/analytics/annotations"),
                Arguments.of(HttpMethod.POST, "/api/admin/analytics/annotations"),
                Arguments.of(HttpMethod.DELETE, "/api/admin/analytics/annotations/" + RANDOM_ID),
                Arguments.of(HttpMethod.GET, "/api/admin/calibration/stats"),
                Arguments.of(HttpMethod.GET, "/api/admin/calibration/submissions"),
                Arguments.of(HttpMethod.GET,
                    "/api/admin/calibration/submissions/" + RANDOM_ID + "/human-note"),
                Arguments.of(HttpMethod.GET, "/api/admin/media/" + RANDOM_ID),
                Arguments.of(HttpMethod.GET, "/api/admin/audio-drafts/pending-review/count"),
                Arguments.of(HttpMethod.GET, "/api/admin/audio-questions/generation-logs"),
                Arguments.of(HttpMethod.GET, "/api/admin/production/examples/audio/pending/count"),
                // Audio fixe diagnostic : statut/HEAD R2 et génération explicite.
                Arguments.of(HttpMethod.GET,
                        "/api/admin/diagnostics/INITIAL_TCF/versions/1/instruction-audio"),
                Arguments.of(HttpMethod.POST,
                        "/api/admin/diagnostics/INITIAL_TCF/versions/1/instruction-audio"),
                // Régénération forcée (consigne corrigée) : même route, opt-in explicite.
                Arguments.of(HttpMethod.POST,
                        "/api/admin/diagnostics/INITIAL_TCF/versions/1/instruction-audio?force=true"),
                // Module competences : les 10 routes de la console, une par une.
                Arguments.of(HttpMethod.GET, "/api/admin/skills"),
                Arguments.of(HttpMethod.GET, "/api/admin/skills/stats"),
                Arguments.of(HttpMethod.GET, "/api/admin/skills/" + RANDOM_ID),
                Arguments.of(HttpMethod.POST, "/api/admin/skills"),
                Arguments.of(HttpMethod.PATCH, "/api/admin/skills/" + RANDOM_ID),
                Arguments.of(HttpMethod.DELETE, "/api/admin/skills/" + RANDOM_ID),
                Arguments.of(HttpMethod.GET, "/api/admin/skill-prompts/" + RANDOM_ID),
                Arguments.of(HttpMethod.POST, "/api/admin/skill-prompts"),
                Arguments.of(HttpMethod.PATCH, "/api/admin/skill-prompts/" + RANDOM_ID),
                Arguments.of(HttpMethod.DELETE, "/api/admin/skill-prompts/" + RANDOM_ID),
                Arguments.of(HttpMethod.PUT, "/api/admin/skill-prompts/" + RANDOM_ID + "/references"),
                // Titres editoriaux des sujets EO/EE (console de contenu).
                Arguments.of(HttpMethod.GET, "/api/admin/production-tasks?epreuve=TCF_EE"),
                Arguments.of(HttpMethod.PATCH, "/api/admin/production-tasks/" + RANDOM_ID + "/titre"),
                // quelques mutations pour couvrir POST/PUT/PATCH/DELETE sous /api/admin
                Arguments.of(HttpMethod.POST, "/api/admin/exams"),
                Arguments.of(HttpMethod.PUT, "/api/admin/themes/" + RANDOM_ID),
                Arguments.of(HttpMethod.PATCH, "/api/admin/plans/" + RANDOM_ID),
                Arguments.of(HttpMethod.PATCH, "/api/admin/subscriptions/" + RANDOM_ID + "/realtime-sessions"),
                Arguments.of(HttpMethod.DELETE, "/api/admin/questions/" + RANDOM_ID));
    }

    @ParameterizedTest(name = "anonyme {0} {1} -> 401")
    @MethodSource("adminRoutes")
    void anonymousIsUnauthorized(HttpMethod method, String path) throws Exception {
        MvcResult result = mockMvc.perform(build(method, path)).andReturn();
        assertEquals(401, result.getResponse().getStatus(),
                () -> "Attendu 401 anonyme sur " + method + " " + path);
    }

    @ParameterizedTest(name = "USER {0} {1} -> 403")
    @MethodSource("adminRoutes")
    void userIsForbidden(HttpMethod method, String path) throws Exception {
        User user = testData.user();
        MvcResult result = mockMvc.perform(build(method, path)
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andReturn();
        assertEquals(403, result.getResponse().getStatus(),
                () -> "Attendu 403 USER sur " + method + " " + path);
    }

    @ParameterizedTest(name = "ADMIN {0} {1} -> autorisé")
    @MethodSource("adminRoutes")
    void adminIsAuthorized(HttpMethod method, String path) throws Exception {
        User admin = testData.admin();
        MvcResult result = mockMvc.perform(build(method, path)
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(admin)))
                .andReturn();
        int status = result.getResponse().getStatus();
        assertTrue(status != 401 && status != 403,
                () -> "ADMIN ne doit pas recevoir 401/403 sur " + method + " " + path
                        + " (reçu " + status + ")");
    }

    private MockHttpServletRequestBuilder build(HttpMethod method, String path) {
        MockHttpServletRequestBuilder b = switch (method.name()) {
            case "GET" -> get(path);
            case "POST" -> post(path);
            case "PUT" -> put(path);
            case "PATCH" -> patch(path);
            case "DELETE" -> delete(path);
            default -> throw new IllegalArgumentException("Méthode non gérée : " + method);
        };
        if (method != HttpMethod.GET) {
            b.contentType(MediaType.APPLICATION_JSON).content("{}");
        }
        return b;
    }
}
