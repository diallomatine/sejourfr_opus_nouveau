package com.sejourfr.app.service.email;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.manager.UserEmailPreferenceManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.support.AbstractEmailIT;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Les endpoints publics de desabonnement (brief §6, complement A), contre la
 * vraie chaine de securite : GET ne modifie rien, POST et one-click desabonnent,
 * un jeton falsifie ou un compte supprime recoivent la meme page neutre.
 */
class UnsubscribeEndpointsIT extends AbstractEmailIT {

    @Autowired private MockMvc mockMvc;
    @Autowired private UnsubscribeTokenService tokens;
    @Autowired private UserEmailPreferenceManager preferences;
    @Autowired private UserManager userManager;
    @Autowired private AccountDeletionService accountDeletionService;
    @Autowired private com.sejourfr.app.config.EmailProperties properties;

    private boolean engagementEnabled(User u) {
        return preferences.find(u.getId()).map(p -> p.isEngagementEnabled()).orElse(true);
    }

    @Test
    @DisplayName("GET : page de confirmation avec un bouton, AUCUN changement d'etat")
    void getNeModifieRien() throws Exception {
        User u = user();
        String token = tokens.create(u.getId());

        mockMvc.perform(get("/api/public/email/unsubscribe").param("token", token))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
                .andExpect(content().string(containsString("Confirmer la désinscription")))
                .andExpect(content().string(containsString("method=\"post\"")));

        assertThat(preferences.find(u.getId())).isEmpty();
        assertThat(engagementEnabled(u)).isTrue();
    }

    @Test
    @DisplayName("POST avec un jeton valide : rappels desactives, message du brief")
    void postDesabonne() throws Exception {
        User u = user();

        mockMvc.perform(post("/api/public/email/unsubscribe")
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("token", tokens.create(u.getId())))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString(
                        "Vous ne recevrez plus les conseils et rappels d&#39;entraînement.")))
                .andExpect(content().string(containsString("continueront à être envoyés")));

        assertThat(engagementEnabled(u)).isFalse();
    }

    @Test
    @DisplayName("One-click (RFC 8058) : desabonne, sans page")
    void oneClick() throws Exception {
        User u = user();

        mockMvc.perform(post("/api/public/email/unsubscribe/one-click")
                        .param("token", tokens.create(u.getId()))
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .content("List-Unsubscribe=One-Click"))
                .andExpect(status().isOk());

        assertThat(engagementEnabled(u)).isFalse();
    }

    @Test
    @DisplayName("Jeton signe avec une ANCIENNE cle du trousseau : accepte")
    void ancienneCleAcceptee() throws Exception {
        User u = user();
        com.sejourfr.app.config.EmailProperties ancienne = new com.sejourfr.app.config.EmailProperties();
        ancienne.getUnsubscribe().setCurrentKeyVersion(1);
        ancienne.getUnsubscribe().setKeys(properties.getUnsubscribe().getKeys());
        String tokenV1 = new UnsubscribeTokenService(ancienne).create(u.getId());
        assertThat(tokenV1.split("\\.")[1]).isEqualTo("1");

        mockMvc.perform(post("/api/public/email/unsubscribe/one-click").param("token", tokenV1))
                .andExpect(status().isOk());

        assertThat(engagementEnabled(u)).isFalse();
    }

    @Test
    @DisplayName("Jeton falsifie : refus neutre, rien ne change")
    void jetonFalsifie() throws Exception {
        User u = user();
        String token = tokens.create(u.getId());
        String falsifie = token.substring(0, token.length() - 2) + (token.endsWith("AA") ? "BB" : "AA");

        mockMvc.perform(get("/api/public/email/unsubscribe").param("token", falsifie))
                .andExpect(status().isBadRequest())
                .andExpect(content().string(containsString("Ce lien n&#39;est pas valide.")))
                .andExpect(content().string(not(containsString(u.getEmail()))));
        mockMvc.perform(post("/api/public/email/unsubscribe").param("token", falsifie))
                .andExpect(status().isBadRequest());
        mockMvc.perform(post("/api/public/email/unsubscribe/one-click").param("token", falsifie))
                .andExpect(status().isBadRequest());

        assertThat(engagementEnabled(u)).isTrue();
    }

    @Test
    @DisplayName("Compte inconnu ou supprime : la MEME page neutre qu'un jeton invalide")
    void compteInconnuOuSupprime() throws Exception {
        String inconnu = tokens.create(UUID.randomUUID());
        String neutre = mockMvc.perform(get("/api/public/email/unsubscribe").param("token", "abc"))
                .andReturn().getResponse().getContentAsString();

        mockMvc.perform(get("/api/public/email/unsubscribe").param("token", inconnu))
                .andExpect(status().isBadRequest())
                .andExpect(content().string(neutre));

        User u = user();
        accountDeletionService.deleteAccount(u.getId());
        mockMvc.perform(get("/api/public/email/unsubscribe").param("token", tokens.create(u.getId())))
                .andExpect(status().isBadRequest())
                .andExpect(content().string(neutre));
    }

    @Test
    @DisplayName("Sans jeton : page neutre, jamais d'erreur 500")
    void sansJeton() throws Exception {
        mockMvc.perform(get("/api/public/email/unsubscribe")).andExpect(status().isBadRequest());
        mockMvc.perform(post("/api/public/email/unsubscribe")).andExpect(status().isBadRequest());
    }
}
