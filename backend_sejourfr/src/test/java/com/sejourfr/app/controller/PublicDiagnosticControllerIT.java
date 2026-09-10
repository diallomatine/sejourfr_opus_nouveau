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
 * Le visiteur sans compte reçoit le vrai sujet seedé, et rien d'autre : ni
 * session, ni attempt, ni submission — ni dans le corps, ni en base.
 *
 * <p>🛑 Depuis L3, le diagnostic servi est {@code QUICK_TCF} : <b>une</b>
 * production écrite transversale, et {@code oral} est nul. Ce test verrouille
 * cette forme de bout en bout — c'est la première chose qu'un front voit, et
 * un {@code oral} traité comme obligatoire bloquerait tout le parcours.
 */
class PublicDiagnosticControllerIT extends AbstractIntegrationTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private JdbcTemplate jdbc;

    @Test
    void sertLeSujetSeedeSansAuthentification() throws Exception {
        mockMvc.perform(get("/api/public/diagnostics/current"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.diagnosticCode", is("QUICK_TCF")))
                .andExpect(jsonPath("$.diagnosticVersion", is(1)))
                .andExpect(jsonPath("$.written.productionTaskId", notNullValue()))
                .andExpect(jsonPath("$.written.epreuve", is("TCF_EE")))
                .andExpect(jsonPath("$.written.title", notNullValue()))
                .andExpect(jsonPath("$.written.instruction", notNullValue()))
                .andExpect(jsonPath("$.written.helperText", notNullValue()))
                // 🛑 Bornes de RECEVABILITÉ, pas la demande : la consigne réclame
                // 150-220 mots, le serveur accepte à partir de 100 (`10_` §3.3).
                .andExpect(jsonPath("$.written.wordsMin", is(100)))
                .andExpect(jsonPath("$.written.wordsMax", is(300)))
                // 🛑 Pas d'étape orale, et ce n'est pas une panne.
                .andExpect(jsonPath("$.oral").doesNotExist());
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
