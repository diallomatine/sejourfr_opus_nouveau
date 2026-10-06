package com.sejourfr.app.controller;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.MutableClock;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Contrat HTTP de l'ecran « Activite » (lot 4) : droits, presets (dont
 * {@code LAST_30_DAYS}), 400 nommes, et — avec la <b>vraie</b> configuration,
 * ou l'activite n'est pas encore datee — des indicateurs {@code null}, jamais 0.
 * Les chiffres sont verrouilles par {@code ActivityScenariosIT}.
 */
class AdminActivityControllerIT extends AbstractIntegrationTest {

    private static final String URL = "/api/admin/analytics/activity";
    private static final String LIVE = URL + "/live";

    @Autowired private MockMvc mvc;
    @Autowired private AuthTestSupport auth;
    @Autowired private TestData data;
    @Autowired private MutableClock clock;

    @AfterEach
    void resetClock() {
        clock.reset();
    }

    @Test
    @DisplayName("Anonyme 401, USER 403, ADMIN 200 — période et direct")
    void droits() throws Exception {
        for (String url : new String[]{URL, LIVE}) {
            mvc.perform(get(url)).andExpect(status().isUnauthorized());
            mvc.perform(get(url).header("Authorization", auth.bearer(data.user()))).andExpect(status().isForbidden());
            mvc.perform(get(url).header("Authorization", auth.bearer(data.admin()))).andExpect(status().isOk());
        }
    }

    @Test
    @DisplayName("Presets résolus en jours de Paris, LAST_30_DAYS compris ; période précédente de même durée")
    void presets() throws Exception {
        clock.set(Instant.parse("2026-10-02T22:30:00Z")); // 00:30 le 3 a Paris
        User admin = data.admin();
        mvc.perform(get(URL).header("Authorization", auth.bearer(admin)))
                .andExpect(jsonPath("$.window.preset").value("TODAY"))
                .andExpect(jsonPath("$.window.from").value("2026-10-03"))
                .andExpect(jsonPath("$.window.timezone").value("Europe/Paris"));
        mvc.perform(get(URL).param("preset", "LAST_30_DAYS").header("Authorization", auth.bearer(admin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.window.from").value("2026-09-04"))
                .andExpect(jsonPath("$.window.to").value("2026-10-03"))
                .andExpect(jsonPath("$.window.previousFrom").value("2026-08-05"))
                .andExpect(jsonPath("$.window.previousTo").value("2026-09-03"))
                .andExpect(jsonPath("$.activeUsers.daily", hasSize(30)));
        mvc.perform(get(URL).param("from", "2026-09-01").param("to", "2026-09-07")
                        .header("Authorization", auth.bearer(admin)))
                .andExpect(jsonPath("$.window.preset").value(nullValue()))
                .andExpect(jsonPath("$.window.to").value("2026-09-07"));
    }

    @Test
    @DisplayName("Paramètres incohérents : 400 nommé")
    void parametresInvalides() throws Exception {
        User admin = data.admin();
        mvc.perform(get(URL).param("preset", "TODAY").param("from", "2026-09-01").param("to", "2026-09-02")
                .header("Authorization", auth.bearer(admin))).andExpect(status().isBadRequest());
        mvc.perform(get(URL).param("from", "2026-09-01").header("Authorization", auth.bearer(admin)))
                .andExpect(status().isBadRequest());
        mvc.perform(get(URL).param("preset", "HIER").header("Authorization", auth.bearer(admin)))
                .andExpect(status().isBadRequest());
        mvc.perform(get(URL).param("from", "2025-01-01").param("to", "2026-09-01")
                .header("Authorization", auth.bearer(admin))).andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Configuration livrée : l'activité est datée du déploiement (2026-10-06) ⇒ mesurée, jamais null")
    void configurationLivreeDatee() throws Exception {
        User admin = data.admin();
        mvc.perform(get(URL).param("includeInternal", "true").header("Authorization", auth.bearer(admin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.includeInternal").value(true))
                .andExpect(jsonPath("$.measurementStart.ACTIVE_USERS").value("2026-10-06"))
                .andExpect(jsonPath("$.measurementStart.LOGINS").value("2026-10-06"))
                .andExpect(jsonPath("$.measurementStart.SCREEN_VIEWS_WEB").value("2026-10-06"))
                .andExpect(jsonPath("$.measurementStart.SCREEN_VIEWS_APP").value("2026-10-06"))
                .andExpect(jsonPath("$.activeUsers.total.value").value(notNullValue()))
                .andExpect(jsonPath("$.logins.byMethod[0].method").value("LOCAL"))
                .andExpect(jsonPath("$.logins.byMethod[0].label").value("E-mail"))
                .andExpect(jsonPath("$.platforms", hasSize(5)))
                .andExpect(jsonPath("$.platforms[3].label").value("App — système inconnu"))
                .andExpect(jsonPath("$.platforms[4].displayed").value(true));
        mvc.perform(get(LIVE).header("Authorization", auth.bearer(admin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.windowSeconds").value(180))
                .andExpect(jsonPath("$.measurementStart").value("2026-10-06"))
                .andExpect(jsonPath("$.total").value(notNullValue()))
                .andExpect(jsonPath("$.byPlatform", hasSize(5)))
                .andExpect(jsonPath("$.byPlatform[4].displayed").value(false));
    }
}
