package com.sejourfr.app.controller;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.lessThanOrEqualTo;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Contrat HTTP de la liste des questions admin : plafond de pagination et
 * filtre média cote requete (le filtre existait deja en UI, mais ne portait que
 * sur la page affichee).
 */
class AdminQuestionControllerIT extends AbstractIntegrationTest {

    /** Doit rester aligné sur {@code spring.data.web.pageable.max-page-size}. */
    private static final int MAX_PAGE_SIZE = 100;

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private TestData testData;
    @Autowired
    private AuthTestSupport auth;

    private String adminBearer() {
        User admin = testData.admin();
        return auth.bearer(admin);
    }

    /**
     * {@code ?size=2000} renvoyait 2,65 Mo en une requête (Spring plafonne à
     * 2000 par défaut). La console pagine par 20 ; 100 couvre tous ses usages.
     */
    @Test
    void hugePageSizeIsCapped() throws Exception {
        mockMvc.perform(get("/api/admin/questions")
                        .param("size", "2000")
                        .header(HttpHeaders.AUTHORIZATION, adminBearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.size").value(lessThanOrEqualTo(MAX_PAGE_SIZE)))
                .andExpect(jsonPath("$.content.length()").value(lessThanOrEqualTo(MAX_PAGE_SIZE)));
    }

    @Test
    void reasonablePageSizeIsHonoured() throws Exception {
        mockMvc.perform(get("/api/admin/questions")
                        .param("size", "25")
                        .header(HttpHeaders.AUTHORIZATION, adminBearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.size").value(25));
    }

    /** Le filtre média est accepté côté serveur (et non plus ignoré). */
    @Test
    void mediaFilterIsAccepted() throws Exception {
        mockMvc.perform(get("/api/admin/questions")
                        .param("media", "AUDIO")
                        .header(HttpHeaders.AUTHORIZATION, adminBearer()))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/admin/questions")
                        .param("media", "NONE")
                        .header(HttpHeaders.AUTHORIZATION, adminBearer()))
                .andExpect(status().isOk());
    }

    @Test
    void unknownMediaFilterIs400_notServerError() throws Exception {
        mockMvc.perform(get("/api/admin/questions")
                        .param("media", "PODCAST")
                        .header(HttpHeaders.AUTHORIZATION, adminBearer()))
                .andExpect(status().isBadRequest());
    }
}
