package com.sejourfr.app.controller;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Garde-fous anti-abus de {@code /api/auth}, exerces de bout en bout (le profil
 * {@code test} les desactive par defaut, on les rallume ici avec des seuils
 * minuscules).
 *
 * <p>Deux comportements verrouilles :</p>
 * <ul>
 *   <li>un {@code X-Forwarded-For} envoye par le client ne change PAS l'identite
 *       comptee (aucun proxy de confiance n'est configure) — sinon le
 *       rate-limit se contourne avec un en-tete ;</li>
 *   <li>une authentification REUSSIE remet les compteurs a zero — sinon
 *       quelques connexions legitimes d'affilee finissent en 429.</li>
 * </ul>
 */
@TestPropertySource(properties = {
        "sejourfr.rate-limit.enabled=true",
        "sejourfr.rate-limit.forgot-password.max=1",
        "sejourfr.rate-limit.forgot-password.window-seconds=900",
        "sejourfr.rate-limit.login.max=50",
        "sejourfr.rate-limit.login.window-seconds=900",
        "sejourfr.rate-limit.login-per-account.max=2",
        "sejourfr.rate-limit.login-per-account.window-seconds=900"
})
class AuthRateLimitIT extends AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TestData data;

    /** Fige l'IP de la socket : c'est elle, et elle seule, qui doit compter. */
    private static RequestPostProcessor socket(String ip) {
        return request -> {
            request.setRemoteAddr(ip);
            return request;
        };
    }

    private MockHttpServletRequestBuilder json(String path, String body) {
        return post(path).contentType(MediaType.APPLICATION_JSON).content(body);
    }

    private String loginBody(String email, String password) {
        return "{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}";
    }

    @Test
    void forgotPassword_forgedForwardedFor_doesNotResetTheCounter() throws Exception {
        String ip = "203.0.113.41";
        String body = "{\"email\":\"inconnu@sejourfr.fr\"}";

        mockMvc.perform(json("/api/auth/forgot-password", body).with(socket(ip)))
                .andExpect(status().isNoContent());

        // Même socket, en-tête différent à chaque coup : l'identité comptée doit
        // rester la même, donc 429 (avant le correctif, chaque en-tête ouvrait
        // un compteur neuf et la requête passait en 204).
        mockMvc.perform(json("/api/auth/forgot-password", body)
                        .with(socket(ip))
                        .header("X-Forwarded-For", "10.0.1.1"))
                .andExpect(status().isTooManyRequests());

        mockMvc.perform(json("/api/auth/forgot-password", body)
                        .with(socket(ip))
                        .header("X-Forwarded-For", "10.0.2.2"))
                .andExpect(status().isTooManyRequests());
    }

    @Test
    void login_successfulAttempts_neverHitTheAccountLimit() throws Exception {
        User user = data.user();
        String ip = "203.0.113.42";
        String body = loginBody(user.getEmail(), TestData.DEFAULT_PASSWORD);

        // Limite par compte = 2 : sans reset sur succès, le 3ᵉ login légitime
        // partait en 429.
        for (int i = 0; i < 5; i++) {
            mockMvc.perform(json("/api/auth/login", body).with(socket(ip)))
                    .andExpect(status().isOk());
        }
    }

    @Test
    void login_repeatedFailures_stillGetRateLimited() throws Exception {
        User user = data.user();
        String ip = "203.0.113.43";
        String body = loginBody(user.getEmail(), "MauvaisMotDePasse1!");

        mockMvc.perform(json("/api/auth/login", body).with(socket(ip)))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(json("/api/auth/login", body).with(socket(ip)))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(json("/api/auth/login", body).with(socket(ip)))
                .andExpect(status().isTooManyRequests());
    }

    /** Un échec puis un succès : le succès efface l'ardoise du compte. */
    @Test
    void login_successAfterFailure_clearsTheAccountCounter() throws Exception {
        User user = data.user();
        String ip = "203.0.113.44";

        mockMvc.perform(json("/api/auth/login", loginBody(user.getEmail(), "Faux1234!"))
                        .with(socket(ip)))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(json("/api/auth/login",
                        loginBody(user.getEmail(), TestData.DEFAULT_PASSWORD)).with(socket(ip)))
                .andExpect(status().isOk());

        // Deux nouveaux échecs autorisés (compteur reparti de zéro), le 3ᵉ bloque.
        mockMvc.perform(json("/api/auth/login", loginBody(user.getEmail(), "Faux1234!"))
                        .with(socket(ip)))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(json("/api/auth/login", loginBody(user.getEmail(), "Faux1234!"))
                        .with(socket(ip)))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(json("/api/auth/login", loginBody(user.getEmail(), "Faux1234!"))
                        .with(socket(ip)))
                .andExpect(status().isTooManyRequests());
    }
}
