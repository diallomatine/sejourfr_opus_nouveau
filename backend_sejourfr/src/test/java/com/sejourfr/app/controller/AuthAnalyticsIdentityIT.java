package com.sejourfr.app.controller;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.manager.AnalyticsIdentityManager;
import com.sejourfr.app.repository.UserRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.util.ClientContextResolver;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Liaison anonyme -> compte a l'inscription et a la connexion (brief §3.2,
 * lot 1b) : l'identifiant de mesure arrive par le corps (champ historique
 * {@code anonymousId}) ou par l'en-tete {@code X-Sejourfr-Anonymous-Id} ; le
 * corps prime. Clients anciens : rien d'envoye, rien d'ecrit, aucune erreur.
 */
class AuthAnalyticsIdentityIT extends AbstractIntegrationTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private TestData testData;
    @Autowired private AnalyticsIdentityManager identityManager;
    @Autowired private UserRepository userRepository;
    @Autowired private EntityManager em;

    private UUID visiteur() {
        return testData.analyticsVisitor("tiktok", "FR", AnalyticsDeviceType.IOS, ClientPlatform.IOS,
                Instant.now());
    }

    private static String inscription(String email, String anonymousId) {
        return "{\"email\":\"" + email + "\",\"password\":\"MotDePasse1!\",\"firstName\":\"Awa\","
                + "\"lastName\":\"Diallo\"" + (anonymousId == null ? "" : ",\"anonymousId\":\"" + anonymousId + "\"")
                + "}";
    }

    private User relire(String email) {
        em.flush();
        em.clear();
        return userRepository.findByEmail(email).orElseThrow();
    }

    @Test
    @DisplayName("Inscription iOS avec l'identifiant en en-tête : plateforme, identifiant et lien posés")
    void inscriptionParEnTete() throws Exception {
        UUID anon = visiteur();
        String email = "ios.inscription@test.sejourfr";

        mockMvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .header(ClientContextResolver.HEADER_CLIENT, "ios")
                        .header(ClientContextResolver.HEADER_ANONYMOUS_ID, anon.toString())
                        .content(inscription(email, null)))
                .andExpect(status().isOk());

        User user = relire(email);
        assertThat(user.getSignupPlatform()).isEqualTo(ClientPlatform.IOS);
        assertThat(user.getSignupAnonymousId()).isEqualTo(anon);
        assertThat(user.isInternal()).isFalse();
        assertThat(identityManager.countForUser(user.getId())).isEqualTo(1);
    }

    @Test
    @DisplayName("Le champ historique du corps prime sur l'en-tête")
    void corpsPrime() throws Exception {
        UUID corps = visiteur();
        UUID enTete = visiteur();
        String email = "corps.prime@test.sejourfr";

        mockMvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .header(ClientContextResolver.HEADER_ANONYMOUS_ID, enTete.toString())
                        .content(inscription(email, corps.toString())))
                .andExpect(status().isOk());

        assertThat(relire(email).getSignupAnonymousId()).isEqualTo(corps);
    }

    @Test
    @DisplayName("Connexion : le lien est posé depuis l'en-tête, idempotent, et ne touche pas l'inscription")
    void connexionPoseLeLien() throws Exception {
        User user = testData.user();
        em.flush();
        UUID anon = visiteur();
        String body = "{\"email\":\"" + user.getEmail() + "\",\"password\":\"" + TestData.DEFAULT_PASSWORD + "\"}";

        for (int i = 0; i < 2; i++) {
            mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                            .header(ClientContextResolver.HEADER_ANONYMOUS_ID, anon.toString())
                            .content(body))
                    .andExpect(status().isOk());
        }

        assertThat(identityManager.countForUser(user.getId())).isEqualTo(1);
        // Une connexion n'est pas une inscription : la provenance du premier jour ne bouge pas.
        assertThat(relire(user.getEmail()).getSignupAnonymousId()).isNull();
    }

    @Test
    @DisplayName("Client ancien, identifiant inconnu ou illisible : la connexion réussit, rien n'est lié")
    void sansIdentifiantRienNEstLie() throws Exception {
        User user = testData.user();
        em.flush();
        String body = "{\"email\":\"" + user.getEmail() + "\",\"password\":\"" + TestData.DEFAULT_PASSWORD + "\","
                + "\"anonymousId\":\"" + UUID.randomUUID() + "\"}";

        mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .header(ClientContextResolver.HEADER_ANONYMOUS_ID, "pas-un-uuid")
                        .content(body))
                .andExpect(status().isOk());

        assertThat(identityManager.countForUser(user.getId())).isZero();
    }

    @Test
    @DisplayName("L'anonymisation efface l'identifiant de mesure du compte")
    void anonymisationEfface() {
        User user = testData.user();
        user.setSignupAnonymousId(UUID.randomUUID());
        user.anonymize();
        assertThat(user.getSignupAnonymousId()).isNull();
    }
}
