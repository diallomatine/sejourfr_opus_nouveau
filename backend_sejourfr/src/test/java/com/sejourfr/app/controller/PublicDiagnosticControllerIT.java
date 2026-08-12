package com.sejourfr.app.controller;

import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.notNullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Le visiteur sans compte reçoit les deux vrais sujets seedés (V755), et rien
 * d'autre : ni session, ni attempt, ni submission — ni dans le corps, ni en
 * base.
 */
class PublicDiagnosticControllerIT extends AbstractIntegrationTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private JdbcTemplate jdbc;

    @Test
    void sertLesDeuxSujetsSeedesSansAuthentification() throws Exception {
        mockMvc.perform(get("/api/public/diagnostics/current"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.diagnosticCode", is("INITIAL_TCF")))
                .andExpect(jsonPath("$.diagnosticVersion", is(1)))
                .andExpect(jsonPath("$.written.productionTaskId", notNullValue()))
                .andExpect(jsonPath("$.written.epreuve", is("TCF_EE")))
                .andExpect(jsonPath("$.written.title", notNullValue()))
                .andExpect(jsonPath("$.written.instruction", notNullValue()))
                .andExpect(jsonPath("$.written.helperText", notNullValue()))
                .andExpect(jsonPath("$.written.wordsMin", is(100)))
                .andExpect(jsonPath("$.written.wordsMax", is(130)))
                .andExpect(jsonPath("$.oral.epreuve", is("TCF_EO")))
                .andExpect(jsonPath("$.oral.durationMinSeconds", is(120)))
                .andExpect(jsonPath("$.oral.durationMaxSeconds", is(180)));
    }

    @Test
    void neFuitAucunChampReserveALaSessionAuthentifiee() throws Exception {
        String body = mockMvc.perform(get("/api/public/diagnostics/current"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        assertThat(body)
                .doesNotContain("attemptId")
                .doesNotContain("submissionId")
                .doesNotContain("submissionStatus")
                .doesNotContain("sessionId");
    }

    @Test
    void neCreeAucuneSessionNiAttemptPourUnVisiteur() throws Exception {
        int sessionsAvant = count("diagnostic_sessions");
        int attemptsAvant = count("attempts");

        mockMvc.perform(get("/api/public/diagnostics/current")).andExpect(status().isOk());
        mockMvc.perform(get("/api/public/diagnostics/current")).andExpect(status().isOk());

        assertThat(count("diagnostic_sessions")).isEqualTo(sessionsAvant);
        assertThat(count("attempts")).isEqualTo(attemptsAvant);
    }

    private int count(String table) {
        return jdbc.queryForObject("SELECT count(*) FROM " + table, Integer.class);
    }
}
