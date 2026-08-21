package com.sejourfr.app.controller;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.time.ZoneId;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Contrat HTTP de la période, sur les DEUX lectures admin : les bornes sont
 * incluses, une seule borne est un 400 nommé, et {@code days} reste servi.
 */
class AdminAudienceControllerIT extends AbstractIntegrationTest {

    private static final ZoneId PARIS = ZoneId.of("Europe/Paris");

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private TestData testData;
    @Autowired
    private AuthTestSupport auth;

    private String admin;

    @BeforeEach
    void setUp() {
        User adminUser = testData.admin();
        admin = auth.bearer(adminUser);
    }

    @Test
    void leFunnelRendLesBornesReellementAppliquees() throws Exception {
        mockMvc.perform(get("/api/admin/audience/funnel")
                        .param("from", "2026-08-01").param("to", "2026-08-07")
                        .header(HttpHeaders.AUTHORIZATION, admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.cohortFrom").value("2026-08-01"))
                .andExpect(jsonPath("$.cohortTo").value("2026-08-07"))
                .andExpect(jsonPath("$.days").value(7))
                .andExpect(jsonPath("$.daily.length()").value(7))
                .andExpect(jsonPath("$.stages.length()").value(7))
                .andExpect(jsonPath("$.stages[0].stage").value("SIGNUP"))
                .andExpect(jsonPath("$.integrity").exists());
    }

    @Test
    void leFunnelSurUneSeuleJourneeRendUnPointEtUnJour() throws Exception {
        mockMvc.perform(get("/api/admin/audience/funnel")
                        .param("from", "2026-08-18").param("to", "2026-08-18")
                        .header(HttpHeaders.AUTHORIZATION, admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.days").value(1))
                .andExpect(jsonPath("$.daily.length()").value(1))
                .andExpect(jsonPath("$.daily[0].day").value("2026-08-18"));
    }

    @Test
    void leFunnelSansBornesGardeLaFenetreGlissante() throws Exception {
        LocalDate today = LocalDate.now(PARIS);

        mockMvc.perform(get("/api/admin/audience/funnel")
                        .header(HttpHeaders.AUTHORIZATION, admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.days").value(30))
                .andExpect(jsonPath("$.cohortTo").value(today.toString()));

        mockMvc.perform(get("/api/admin/audience/funnel").param("days", "7")
                        .header(HttpHeaders.AUTHORIZATION, admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.days").value(7));
    }

    @Test
    void unDemiIntervalleEstUn400Nomme() throws Exception {
        mockMvc.perform(get("/api/admin/audience/funnel").param("from", "2026-08-18")
                        .header(HttpHeaders.AUTHORIZATION, admin))
                .andExpect(status().isBadRequest());
        mockMvc.perform(get("/api/admin/audience/funnel").param("to", "2026-08-18")
                        .header(HttpHeaders.AUTHORIZATION, admin))
                .andExpect(status().isBadRequest());
    }

    @Test
    void unePeriodeInverseeInvalideOuTropLargeEstUn400() throws Exception {
        mockMvc.perform(get("/api/admin/audience/funnel")
                        .param("from", "2026-08-19").param("to", "2026-08-18")
                        .header(HttpHeaders.AUTHORIZATION, admin))
                .andExpect(status().isBadRequest());
        mockMvc.perform(get("/api/admin/audience/funnel")
                        .param("from", "18/08/2026").param("to", "2026-08-18")
                        .header(HttpHeaders.AUTHORIZATION, admin))
                .andExpect(status().isBadRequest());
        mockMvc.perform(get("/api/admin/audience/funnel")
                        .param("from", LocalDate.now(PARIS).minusDays(400).toString())
                        .param("to", LocalDate.now(PARIS).toString())
                        .header(HttpHeaders.AUTHORIZATION, admin))
                .andExpect(status().isBadRequest());
    }

    /** Cliquer un jour à venir dans un sélecteur de date n'est pas une faute. */
    @Test
    void uneBorneDeFinFutureEstAcceptéeEtRamenéeAAujourdhui() throws Exception {
        LocalDate today = LocalDate.now(PARIS);

        mockMvc.perform(get("/api/admin/audience/funnel")
                        .param("from", today.minusDays(2).toString())
                        .param("to", today.plusDays(30).toString())
                        .header(HttpHeaders.AUTHORIZATION, admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.cohortTo").value(today.toString()))
                .andExpect(jsonPath("$.days").value(3));
    }

    // ------------------------------------------------------------------------
    // Même contrat sur la mesure d'audience anonyme
    // ------------------------------------------------------------------------

    @Test
    void lAudienceAnonymeAcceptELaMemePaireDeBornes() throws Exception {
        mockMvc.perform(get("/api/admin/page-views")
                        .param("path", "/reussir")
                        .param("from", "2026-08-18").param("to", "2026-08-18")
                        .header(HttpHeaders.AUTHORIZATION, admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.from").value("2026-08-18"))
                .andExpect(jsonPath("$.to").value("2026-08-18"))
                .andExpect(jsonPath("$.days").value(1))
                .andExpect(jsonPath("$.daily.length()").value(1));
    }

    @Test
    void lAudienceAnonymeRefuseUnDemiIntervalle() throws Exception {
        mockMvc.perform(get("/api/admin/page-views")
                        .param("path", "/reussir").param("from", "2026-08-18")
                        .header(HttpHeaders.AUTHORIZATION, admin))
                .andExpect(status().isBadRequest());
    }

    @Test
    void lAudienceAnonymeSansBornesGardeSonContrat() throws Exception {
        LocalDate today = LocalDate.now(PARIS);

        mockMvc.perform(get("/api/admin/page-views").param("path", "/tarifs")
                        .header(HttpHeaders.AUTHORIZATION, admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.path").value("/tarifs"))
                .andExpect(jsonPath("$.days").value(30))
                .andExpect(jsonPath("$.to").value(today.toString()));
    }
}
