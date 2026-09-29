package com.sejourfr.app.controller;

import com.jayway.jsonpath.JsonPath;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.social.GoogleTokenVerifier;
import com.sejourfr.app.service.social.SocialIdentity;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.empty;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Le fait « profil incomplet », servi par {@code /api/auth/me} et par chaque
 * réponse d'authentification, de bout en bout (vraies migrations, vraie base).
 *
 * <p>Le bug d'origine : un compte créé à la première connexion Google/Apple
 * naissait sans démarche, et le web l'ouvrait directement sur l'application.
 * Ce qui est verrouillé ici :
 * <ul>
 *   <li>compte social neuf : la réponse de connexion ET {@code /me} disent
 *       {@code profileIncomplete} avec la démarche à demander ;</li>
 *   <li>compte local sans démarche (mobile, ancien compte) : même fait ;</li>
 *   <li>complétion par les routes de profil existantes ({@code PUT
 *       /api/me/target-path}, {@code PATCH /api/me/profile}) : le fait retombe
 *       à {@code false}, sans rien deviner ;</li>
 *   <li>un admin n'est jamais invité à compléter.</li>
 * </ul>
 */
class ProfileCompletionIT extends AbstractIntegrationTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private TestData testData;
    @Autowired private AuthTestSupport auth;
    @Autowired private UserManager userManager;
    @Autowired private EntityManager entityManager;
    @MockitoBean private GoogleTokenVerifier googleVerifier;

    private String me(String bearer) throws Exception {
        return mockMvc.perform(get("/api/auth/me").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
    }

    @Test
    void premiereConnexionGoogle_creeUnCompteIncomplet_puisLaCompletionLeFerme() throws Exception {
        SocialIdentity id = testData.socialIdentity();
        when(googleVerifier.isConfigured()).thenReturn(true);
        when(googleVerifier.verify("tok")).thenReturn(id);

        String body = mockMvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"tok\"}"))
                .andExpect(status().isOk())
                // La réponse d'auth le dit déjà : le front n'a pas à deviner.
                .andExpect(jsonPath("$.user.profileIncomplete").value(true))
                .andExpect(jsonPath("$.user.missingProfileFields", contains("TARGET_PROCEDURE")))
                .andExpect(jsonPath("$.user.targetProcedure").doesNotExist())
                .andReturn().getResponse().getContentAsString();
        String bearer = "Bearer " + JsonPath.read(body, "$.accessToken");

        assertThat((Boolean) JsonPath.read(me(bearer), "$.profileIncomplete")).isTrue();

        mockMvc.perform(put("/api/me/target-path")
                        .header(HttpHeaders.AUTHORIZATION, bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"targetProcedure\":\"NAT\"}"))
                .andExpect(status().isNoContent());
        entityManager.flush();
        entityManager.clear();

        mockMvc.perform(get("/api/auth/me").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.profileIncomplete").value(false))
                .andExpect(jsonPath("$.missingProfileFields", empty()))
                .andExpect(jsonPath("$.targetProcedure").value("NAT"))
                .andExpect(jsonPath("$.targetLevel").value("B2"));

        // Une reconnexion Google ne redemande rien.
        mockMvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"tok\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.profileIncomplete").value(false));
    }

    /** Apple sans nom (refusé au consentement) : les MÊMES questions que l'inscription. */
    @Test
    void compteSocialSansNom_leNomEstDemande_puisComplete() throws Exception {
        User u = testData.user();
        u.setAuthProvider(AuthProvider.APPLE);
        u.setPasswordHash(null);
        userManager.save(u);
        String bearer = auth.bearer(u);

        mockMvc.perform(get("/api/auth/me").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(jsonPath("$.profileIncomplete").value(true))
                .andExpect(jsonPath("$.missingProfileFields",
                        contains("FIRST_NAME", "LAST_NAME", "TARGET_PROCEDURE")));

        mockMvc.perform(patch("/api/me/profile")
                        .header(HttpHeaders.AUTHORIZATION, bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"firstName\":\"Awa\",\"lastName\":\"Diallo\"}"))
                .andExpect(status().isNoContent());
        entityManager.flush();
        entityManager.clear();

        mockMvc.perform(get("/api/auth/me").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(jsonPath("$.profileIncomplete").value(true))
                .andExpect(jsonPath("$.missingProfileFields", contains("TARGET_PROCEDURE")));

        mockMvc.perform(put("/api/me/target-path")
                        .header(HttpHeaders.AUTHORIZATION, bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"targetProcedure\":\"CSP\"}"))
                .andExpect(status().isNoContent());
        entityManager.flush();
        entityManager.clear();

        mockMvc.perform(get("/api/auth/me").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(jsonPath("$.profileIncomplete").value(false))
                .andExpect(jsonPath("$.missingProfileFields", empty()));
    }

    /** Inscription locale sans démarche (mobile) : le compte existe, la question reste due. */
    @Test
    void inscriptionLocaleSansDemarche_estServieIncomplete() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"sans.demarche.me@test.sejourfr\",\"password\":\"MotDePasse1!\","
                                + "\"firstName\":\"Awa\",\"lastName\":\"Diallo\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.profileIncomplete").value(true))
                .andExpect(jsonPath("$.user.missingProfileFields", contains("TARGET_PROCEDURE")));
    }

    @Test
    void inscriptionLocaleAvecDemarche_estServieComplete() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"avec.demarche.me@test.sejourfr\",\"password\":\"MotDePasse1!\","
                                + "\"firstName\":\"Awa\",\"lastName\":\"Diallo\",\"targetProcedure\":\"CR\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.profileIncomplete").value(false))
                .andExpect(jsonPath("$.user.missingProfileFields", empty()));
    }

    @Test
    void admin_nEstJamaisInviteACompleter() throws Exception {
        User admin = testData.admin();
        mockMvc.perform(get("/api/auth/me").header(HttpHeaders.AUTHORIZATION, auth.bearer(admin)))
                .andExpect(jsonPath("$.profileIncomplete").value(false))
                .andExpect(jsonPath("$.missingProfileFields", empty()));
    }
}
