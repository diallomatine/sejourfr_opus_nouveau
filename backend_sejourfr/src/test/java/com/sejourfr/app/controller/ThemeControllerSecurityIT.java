package com.sejourfr.app.controller;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * GABARIT « controller + droits » : exerce la VRAIE chaîne de sécurité (filtre
 * JWT + règles {@code SecurityConfig}) avec un access token signé sur un user
 * réellement seedé en base. Matrice anonyme / USER / ADMIN par endpoint.
 *
 * <p>Règles testées :</p>
 * <ul>
 *   <li>{@code /api/themes} → {@code anyRequest().authenticated()} : 401 anonyme, 200 USER.</li>
 *   <li>{@code /api/admin/**} → {@code hasRole("ADMIN")} : 401 anonyme, 403 USER, 200 ADMIN.</li>
 * </ul>
 */
class ThemeControllerSecurityIT extends AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private TestData testData;
    @Autowired
    private AuthTestSupport auth;

    // ---- Route utilisateur : /api/themes -----------------------------------

    @Test
    void userRouteRejectsAnonymous() throws Exception {
        mockMvc.perform(get("/api/themes"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void userRouteAllowsAuthenticatedUser() throws Exception {
        User user = testData.user();
        mockMvc.perform(get("/api/themes").header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andExpect(status().isOk());
    }

    // ---- Route admin : /api/admin/themes -----------------------------------

    @Test
    void adminRouteRejectsAnonymousWith401() throws Exception {
        mockMvc.perform(get("/api/admin/themes"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void adminRouteRejectsUserWith403() throws Exception {
        User user = testData.user();
        mockMvc.perform(get("/api/admin/themes").header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminRouteAllowsAdminWith200() throws Exception {
        User admin = testData.admin();
        mockMvc.perform(get("/api/admin/themes").header(HttpHeaders.AUTHORIZATION, auth.bearer(admin)))
                .andExpect(status().isOk());
    }

    @Test
    void adminCanCreateTheme() throws Exception {
        User admin = testData.admin();
        String body = """
                {"module":"CIVIQUE","code":"SEC-IT","name":"Sécurité","description":"d","displayOrder":1}
                """;
        mockMvc.perform(post("/api/admin/themes")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(admin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated());
    }

    @Test
    void adminCreateWithInvalidBodyReturns400() throws Exception {
        User admin = testData.admin();
        String body = """
                {"module":"CIVIQUE","code":"","name":"","displayOrder":1}
                """;
        mockMvc.perform(post("/api/admin/themes")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(admin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest());
    }

    @Test
    void userCannotCreateThemeWith403() throws Exception {
        User user = testData.user();
        String body = """
                {"module":"CIVIQUE","code":"X","name":"X","displayOrder":1}
                """;
        mockMvc.perform(post("/api/admin/themes")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isForbidden());
    }
}
