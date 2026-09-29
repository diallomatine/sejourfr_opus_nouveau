package com.sejourfr.app.controller;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.manager.UserFunnelEventManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.util.ClientContextResolver;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * L'idempotence de la route est ce qui remplace un rate-limit : marteler
 * l'endpoint n'écrit rien après le premier appel, et ne renvoie jamais
 * d'erreur.
 */
class FunnelEventControllerIT extends AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private TestData testData;
    @Autowired
    private AuthTestSupport auth;
    @Autowired
    private UserFunnelEventManager funnelEventManager;

    @Test
    void unRejeuRepond204SansRienCreerDePlus() throws Exception {
        User user = testData.user();

        for (int i = 0; i < 4; i++) {
            mockMvc.perform(post("/api/me/funnel-events")
                            .header(HttpHeaders.AUTHORIZATION, auth.bearer(user))
                            .header(ClientContextResolver.HEADER_CLIENT, "web")
                            .header(ClientContextResolver.HEADER_SOURCE, "tiktok")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"event\":\"PAYWALL_VIEWED\"}"))
                    .andExpect(status().isNoContent());
        }

        assertThat(funnelEventManager.countForUser(user.getId())).isEqualTo(1);
    }

    @Test
    void lesDeuxEtapesDeclarablesSontAcceptees() throws Exception {
        User user = testData.user();

        for (String event : new String[]{"PAYWALL_VIEWED", "SUBSCRIBE_CLICKED"}) {
            mockMvc.perform(post("/api/me/funnel-events")
                            .header(HttpHeaders.AUTHORIZATION, auth.bearer(user))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"event\":\"" + event + "\"}"))
                    .andExpect(status().isNoContent());
        }

        assertThat(funnelEventManager.countForUser(user.getId())).isEqualTo(2);
    }

    /**
     * CHECKOUT_STARTED dit « une session de paiement a réellement été créée » :
     * seul le serveur le constate. Un client qui le déclare ferait de la
     * dernière marche du funnel une intention.
     */
    @Test
    void unClientNePeutPasDeclarerLeDepartDePaiement() throws Exception {
        User user = testData.user();

        mockMvc.perform(post("/api/me/funnel-events")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"event\":\"CHECKOUT_STARTED\"}"))
                .andExpect(status().isUnprocessableEntity());

        assertThat(funnelEventManager.countForUser(user.getId())).isZero();
    }

    /** Le contrat est fermé : une étape inventée ne crée aucune dimension. */
    @Test
    void uneEtapeInventeeEstRefusee() throws Exception {
        User user = testData.user();

        mockMvc.perform(post("/api/me/funnel-events")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"event\":\"ETAPE_INVENTEE\"}"))
                .andExpect(status().is4xxClientError());

        assertThat(funnelEventManager.countForUser(user.getId())).isZero();
    }

    @Test
    void sansEnTeteDeContexteLaRouteRepondQuandMeme() throws Exception {
        User user = testData.user();

        mockMvc.perform(post("/api/me/funnel-events")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"event\":\"PAYWALL_VIEWED\"}"))
                .andExpect(status().isNoContent());

        assertThat(funnelEventManager.countForUser(user.getId())).isEqualTo(1);
    }
}
