package com.sejourfr.app.controller;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Le contrat HTTP de l'ecran Analytics.
 *
 * <p>Ce qui est verrouille ici : la <b>fenetre reutilisee telle quelle</b>
 * ({@code FenetreMesure}) — un demi-intervalle est un 400 <i>nomme</i>, jamais
 * un repli muet sur la fenetre par defaut, qui afficherait des chiffres qu'on
 * croirait filtres —, et le fait que la reponse <b>rende les bornes
 * appliquees</b> : l'ecran affiche la periode d'apres le serveur.
 */
class AdminAnalyticsControllerIT extends AbstractIntegrationTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private TestData data;
    @Autowired private AuthTestSupport auth;

    private HttpHeaders admin() {
        User admin = data.admin();
        HttpHeaders headers = new HttpHeaders();
        headers.set(HttpHeaders.AUTHORIZATION, auth.bearer(admin));
        return headers;
    }

    @Test
    @DisplayName("La réponse rend les bornes APPLIQUÉES, pas celles qu'on croit avoir demandées")
    void bornesAppliqueesRendues() throws Exception {
        mockMvc.perform(get("/api/admin/analytics")
                        .headers(admin())
                        .param("from", "2025-06-01")
                        .param("to", "2025-06-07"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.from").value("2025-06-01"))
                .andExpect(jsonPath("$.to").value("2025-06-07"))
                // Periode precedente : meme duree, collee a `from`.
                .andExpect(jsonPath("$.prevFrom").value("2025-05-25"))
                .andExpect(jsonPath("$.prevTo").value("2025-05-31"))
                .andExpect(jsonPath("$.period.days").value(7))
                .andExpect(jsonPath("$.period.grain").value("DAY"))
                .andExpect(jsonPath("$.currency").value("EUR"))
                // Serie continue : 7 jours, zeros compris.
                .andExpect(jsonPath("$.series.length()").value(7))
                .andExpect(jsonPath("$.prevSeries.length()").value(7));
    }

    /**
     * 🛑 Une seule borne est une <b>erreur nommee</b>. Rendre la fenetre par
     * defaut a qui a demande une date precise afficherait des chiffres qu'on
     * croirait filtres — le pire des cas, puisqu'il ne se voit pas.
     */
    @Test
    @DisplayName("Une seule borne est un 400 nommé, jamais un repli muet")
    void demiIntervalleRefuse() throws Exception {
        mockMvc.perform(get("/api/admin/analytics")
                        .headers(admin())
                        .param("from", "2025-06-01"))
                .andExpect(status().isBadRequest());

        mockMvc.perform(get("/api/admin/analytics")
                        .headers(admin())
                        .param("from", "2025-06-10")
                        .param("to", "2025-06-01"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Une fenêtre de plus de 365 jours est refusée")
    void fenetreTropLarge() throws Exception {
        mockMvc.perform(get("/api/admin/analytics")
                        .headers(admin())
                        .param("from", "2024-01-01")
                        .param("to", "2025-06-01"))
                .andExpect(status().isBadRequest());
    }

    /**
     * Un repere cree apparait dans la reponse principale : la courbe et ses
     * annotations viennent du meme appel, donc de la meme periode.
     */
    @Test
    @DisplayName("Un repère créé apparaît sur la courbe, puis disparaît une fois supprimé")
    void cycleDeVieDUnRepere() throws Exception {
        HttpHeaders headers = admin();
        LocalDate jour = LocalDate.of(2025, 6, 3);

        String cree = mockMvc.perform(post("/api/admin/analytics/annotations")
                        .headers(headers)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"occurredOn":"%s","title":"Trois vidéos publiées",
                                 "description":"TikTok","category":"MARKETING"}
                                """.formatted(jour)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.title").value("Trois vidéos publiées"))
                .andExpect(jsonPath("$.category").value("MARKETING"))
                .andReturn().getResponse().getContentAsString();

        String id = cree.replaceAll(".*\"id\"\\s*:\\s*\"([^\"]+)\".*", "$1");

        mockMvc.perform(get("/api/admin/analytics")
                        .headers(headers)
                        .param("from", "2025-06-01")
                        .param("to", "2025-06-07"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.annotations.length()").value(1))
                .andExpect(jsonPath("$.annotations[0].iso").value("2025-06-03"))
                .andExpect(jsonPath("$.annotations[0].kind").value("MARKETING"));

        mockMvc.perform(delete("/api/admin/analytics/annotations/" + id).headers(headers))
                .andExpect(status().isNoContent());

        mockMvc.perform(delete("/api/admin/analytics/annotations/" + id).headers(headers))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("Un repère sans titre ni catégorie est refusé, en le disant")
    void repereInvalide() throws Exception {
        mockMvc.perform(post("/api/admin/analytics/annotations")
                        .headers(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"occurredOn\":\"2025-06-03\"}"))
                .andExpect(status().isBadRequest());
    }
}
