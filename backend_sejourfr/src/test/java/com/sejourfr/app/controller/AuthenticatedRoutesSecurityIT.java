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
 * Sécurité des surfaces ni admin ni publiques : règle
 * {@code anyRequest().authenticated()} + le cas spécial {@code GET /api/auth/me}.
 * Matrice par route :
 * <ul>
 *   <li>anonyme → 401</li>
 *   <li>USER → ni 401 ni 403 (le controller est atteint).</li>
 * </ul>
 * Ajouter une route = une ligne dans {@link #authenticatedRoutes()}.
 */
class AuthenticatedRoutesSecurityIT extends AbstractIntegrationTest {

    private static final String RANDOM_ID = "11111111-1111-1111-1111-111111111111";

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private TestData testData;
    @Autowired
    private AuthTestSupport auth;

    static Stream<Arguments> authenticatedRoutes() {
        return Stream.of(
                // GET /api/auth/me — sous /api/auth/** mais explicitement authentifié.
                Arguments.of(HttpMethod.GET, "/api/auth/me"),
                // AccountController
                Arguments.of(HttpMethod.DELETE, "/api/account"),
                // MeController
                Arguments.of(HttpMethod.GET, "/api/me/dashboard"),
                Arguments.of(HttpMethod.GET, "/api/me/stats"),
                Arguments.of(HttpMethod.GET, "/api/me/attempts"),
                Arguments.of(HttpMethod.GET, "/api/me/progression"),
                Arguments.of(HttpMethod.GET, "/api/me/questions/favorites"),
                // AttemptController
                Arguments.of(HttpMethod.GET, "/api/attempts/" + RANDOM_ID),
                Arguments.of(HttpMethod.POST, "/api/attempts"),
                // FullTcfExamController
                Arguments.of(HttpMethod.GET, "/api/me/full-tcf-exams"),
                Arguments.of(HttpMethod.GET, "/api/full-tcf-exams/" + RANDOM_ID),
                // ProductionSubmissionController
                Arguments.of(HttpMethod.GET, "/api/users/me/production-submissions"),
                Arguments.of(HttpMethod.GET, "/api/production-submissions/" + RANDOM_ID),
                Arguments.of(HttpMethod.GET, "/api/attempts/" + RANDOM_ID + "/production-bilan"),
                // ProductionTaskController
                Arguments.of(HttpMethod.GET, "/api/production-tasks"),
                // ProductionExampleController
                Arguments.of(HttpMethod.GET, "/api/production-examples"),
                // RealtimeEoController
                Arguments.of(HttpMethod.GET, "/api/realtime/eo/quota"),
                // ThemeUserController
                Arguments.of(HttpMethod.GET, "/api/themes"),
                // LotController (authentifié, pas dans /api/public)
                Arguments.of(HttpMethod.GET, "/api/lots"),
                // BillingController — endpoints authentifiés (hors /plans + /webhook publics)
                Arguments.of(HttpMethod.GET, "/api/billing/subscription-status"),
                Arguments.of(HttpMethod.GET, "/api/billing/payment-link"),
                // SkillController — module compétences (aucune route publique :
                // toute la progression est nominative)
                Arguments.of(HttpMethod.GET, "/api/skills/progress?section=EE"),
                Arguments.of(HttpMethod.GET, "/api/skills/analysis-quota"),
                Arguments.of(HttpMethod.GET, "/api/skills?taskCode=EE1"),
                Arguments.of(HttpMethod.GET, "/api/skills?section=EE"),
                // Sans filtre la route repond 422 a un candidat : l'anonyme doit
                // quand meme se voir opposer 401, pas la validation metier.
                Arguments.of(HttpMethod.GET, "/api/skills"),
                Arguments.of(HttpMethod.GET, "/api/skills/" + RANDOM_ID),
                Arguments.of(HttpMethod.GET, "/api/skill-prompts/" + RANDOM_ID),
                Arguments.of(HttpMethod.GET, "/api/skill-prompts/" + RANDOM_ID + "/references"),
                // SkillAttemptController
                Arguments.of(HttpMethod.POST, "/api/skill-attempts"),
                Arguments.of(HttpMethod.GET, "/api/skill-attempts/" + RANDOM_ID),
                Arguments.of(HttpMethod.POST, "/api/skill-attempts/" + RANDOM_ID + "/analyse"),
                Arguments.of(HttpMethod.POST, "/api/skill-attempts/" + RANDOM_ID + "/retry"),
                Arguments.of(HttpMethod.GET, "/api/skill-prompts/" + RANDOM_ID + "/attempts"));
    }

    @ParameterizedTest(name = "anonyme {0} {1} -> 401")
    @MethodSource("authenticatedRoutes")
    void anonymousIsUnauthorized(HttpMethod method, String path) throws Exception {
        MvcResult result = mockMvc.perform(build(method, path)).andReturn();
        assertEquals(401, result.getResponse().getStatus(),
                () -> "Attendu 401 anonyme sur " + method + " " + path);
    }

    @ParameterizedTest(name = "USER {0} {1} -> autorisé")
    @MethodSource("authenticatedRoutes")
    void userIsAuthorized(HttpMethod method, String path) throws Exception {
        User user = testData.user();
        MvcResult result = mockMvc.perform(build(method, path)
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andReturn();
        int status = result.getResponse().getStatus();
        assertTrue(status != 401 && status != 403,
                () -> "USER ne doit pas recevoir 401/403 sur " + method + " " + path
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
