package com.sejourfr.app.service.email;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

import java.sql.Timestamp;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** {@code GET/PATCH /api/me/email-preferences} (brief §8) contre la vraie chaine. */
class EmailPreferencesEndpointIT extends AbstractIntegrationTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private TestData data;
    @Autowired private AuthTestSupport auth;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private jakarta.persistence.EntityManager em;

    @Test
    @DisplayName("Sans ligne : les valeurs par defaut sont servies, et rien n'est ecrit")
    void valeursParDefaut() throws Exception {
        User u = data.user();

        mockMvc.perform(get("/api/me/email-preferences").header(HttpHeaders.AUTHORIZATION, auth.bearer(u)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.engagementEnabled", is(true)))
                .andExpect(jsonPath("$.marketingEnabled", is(false)));

        assertThat(jdbc.queryForObject("SELECT count(*) FROM user_email_preferences WHERE user_id = ?",
                Long.class, u.getId())).isZero();
    }

    @Test
    @DisplayName("PATCH engagement=false : la ligne nait, la lecture suivante le rend ; un champ absent ne bouge pas")
    void desactiverLesRappels() throws Exception {
        User u = data.user();
        String bearer = auth.bearer(u);

        mockMvc.perform(patch("/api/me/email-preferences").header(HttpHeaders.AUTHORIZATION, bearer)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"engagementEnabled\": false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.engagementEnabled", is(false)))
                .andExpect(jsonPath("$.marketingEnabled", is(false)));

        mockMvc.perform(patch("/api/me/email-preferences").header(HttpHeaders.AUTHORIZATION, bearer)
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.engagementEnabled", is(false)));

        mockMvc.perform(get("/api/me/email-preferences").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(jsonPath("$.engagementEnabled", is(false)));
    }

    @Test
    @DisplayName("Opt-in marketing : le consentement est date, et la date survit a un opt-out")
    void consentementMarketingDate() throws Exception {
        User u = data.user();
        String bearer = auth.bearer(u);

        mockMvc.perform(patch("/api/me/email-preferences").header(HttpHeaders.AUTHORIZATION, bearer)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"marketingEnabled\": true}"))
                .andExpect(jsonPath("$.marketingEnabled", is(true)))
                .andExpect(jsonPath("$.engagementEnabled", is(true)));
        em.flush();
        Timestamp consent = jdbc.queryForObject(
                "SELECT marketing_consent_at FROM user_email_preferences WHERE user_id = ?", Timestamp.class, u.getId());
        assertThat(consent).isNotNull();

        mockMvc.perform(patch("/api/me/email-preferences").header(HttpHeaders.AUTHORIZATION, bearer)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"marketingEnabled\": false}"))
                .andExpect(jsonPath("$.marketingEnabled", is(false)));
        em.flush();
        assertThat(jdbc.queryForObject("SELECT marketing_consent_at FROM user_email_preferences WHERE user_id = ?",
                Timestamp.class, u.getId())).isEqualTo(consent);
    }
}
