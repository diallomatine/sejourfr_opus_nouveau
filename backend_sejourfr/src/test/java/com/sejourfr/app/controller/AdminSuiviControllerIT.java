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

import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * {@code GET /api/admin/analytics/suivi} : droits, resolution de la periode,
 * filtres refuses en 400 nomme, et — avec la <b>vraie</b> configuration —
 * des indicateurs {@code null} tant que leur date de debut de mesure n'est pas
 * posee (Q16, D43), jamais 0. Les chiffres eux-memes sont verrouilles par
 * {@code SuiviScenariosIT}.
 */
class AdminSuiviControllerIT extends AbstractIntegrationTest {

    private static final String URL = "/api/admin/analytics/suivi";

    @Autowired private MockMvc mvc;
    @Autowired private AuthTestSupport auth;
    @Autowired private TestData data;
    @Autowired private MutableClock clock;

    @AfterEach
    void resetClock() {
        clock.reset();
    }

    @Test
    @DisplayName("Anonyme 401, USER 403, ADMIN 200")
    void droits() throws Exception {
        mvc.perform(get(URL)).andExpect(status().isUnauthorized());
        mvc.perform(get(URL).header("Authorization", auth.bearer(data.user()))).andExpect(status().isForbidden());
        mvc.perform(get(URL).header("Authorization", auth.bearer(data.admin()))).andExpect(status().isOk());
    }

    @Test
    @DisplayName("Presets résolus en jours de Paris ; période précédente de même durée")
    void presets() throws Exception {
        clock.set(Instant.parse("2026-09-25T22:30:00Z")); // 00:30 le 26 a Paris
        User admin = data.admin();
        mvc.perform(get(URL).header("Authorization", auth.bearer(admin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.window.preset").value("TODAY"))
                .andExpect(jsonPath("$.window.from").value("2026-09-26"))
                .andExpect(jsonPath("$.window.previousFrom").value("2026-09-25"))
                .andExpect(jsonPath("$.window.timezone").value("Europe/Paris"))
                .andExpect(jsonPath("$.window.cohortWindowDays").value(14))
                .andExpect(jsonPath("$.window.cohortOngoing").value(true));
        mvc.perform(get(URL).param("preset", "LAST_7_DAYS").header("Authorization", auth.bearer(admin)))
                .andExpect(jsonPath("$.window.from").value("2026-09-20"))
                .andExpect(jsonPath("$.window.to").value("2026-09-26"))
                .andExpect(jsonPath("$.window.previousFrom").value("2026-09-13"))
                .andExpect(jsonPath("$.window.previousTo").value("2026-09-19"));
        mvc.perform(get(URL).param("preset", "month").header("Authorization", auth.bearer(admin)))
                .andExpect(jsonPath("$.window.from").value("2026-09-01"));
        mvc.perform(get(URL).param("preset", "YESTERDAY").header("Authorization", auth.bearer(admin)))
                .andExpect(jsonPath("$.window.from").value("2026-09-25"))
                .andExpect(jsonPath("$.window.to").value("2026-09-25"));
    }

    @Test
    @DisplayName("Période personnalisée et filtres renvoyés tels qu'appliqués")
    void personnaliseEtFiltres() throws Exception {
        mvc.perform(get(URL).param("from", "2025-09-01").param("to", "2025-09-07").param("type", "civique")
                        .param("platform", "IOS").param("source", "Instagram").param("includeInternal", "true")
                        .header("Authorization", auth.bearer(data.admin())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.window.preset").value(nullValue()))
                .andExpect(jsonPath("$.window.from").value("2025-09-01"))
                .andExpect(jsonPath("$.window.previousFrom").value("2025-08-25"))
                .andExpect(jsonPath("$.filters.type").value("CIVIQUE"))
                .andExpect(jsonPath("$.filters.platform").value("IOS"))
                .andExpect(jsonPath("$.filters.source").value("instagram"))
                .andExpect(jsonPath("$.filters.includeInternal").value(true))
                .andExpect(jsonPath("$.filters.availableSources",
                        contains("instagram", "tiktok", "facebook", "direct", "autre")))
                .andExpect(jsonPath("$.funnel.scope").value("CIVIQUE"));
    }

    @Test
    @DisplayName("Filtres invalides : 400 nommé, jamais un repli muet")
    void filtresInvalides() throws Exception {
        String bearer = auth.bearer(data.admin());
        mvc.perform(get(URL).param("preset", "HIER").header("Authorization", bearer))
                .andExpect(status().isBadRequest());
        mvc.perform(get(URL).param("preset", "TODAY").param("from", "2025-09-01").param("to", "2025-09-02")
                .header("Authorization", bearer)).andExpect(status().isBadRequest());
        mvc.perform(get(URL).param("from", "2025-09-01").header("Authorization", bearer))
                .andExpect(status().isBadRequest());
        mvc.perform(get(URL).param("type", "FULL_TCF").header("Authorization", bearer))
                .andExpect(status().isBadRequest());
        mvc.perform(get(URL).param("platform", "MOBILE").header("Authorization", bearer))
                .andExpect(status().isBadRequest());
        mvc.perform(get(URL).param("source", "youtube").header("Authorization", bearer))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("D43 — avec la configuration livrée, tout indicateur sans date de mesure vaut null, jamais 0")
    void configurationLivree() throws Exception {
        mvc.perform(get(URL).header("Authorization", auth.bearer(data.admin())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.measurementStart.VISITORS").value("2026-08-21"))
                .andExpect(jsonPath("$.measurementStart.DIAGNOSTIC_SUBJECT_VIEWED").value(nullValue()))
                .andExpect(jsonPath("$.kpis.visitors.value").isNumber())
                .andExpect(jsonPath("$.kpis.submitted.value").value(nullValue()))
                .andExpect(jsonPath("$.kpis.purchases.value").value(nullValue()))
                .andExpect(jsonPath("$.kpis.netExVatCents.value").value(nullValue()))
                .andExpect(jsonPath("$.funnel.steps", hasSize(7)))
                .andExpect(jsonPath("$.funnel.steps[0].code").value("SUBJECT_VIEWED"))
                .andExpect(jsonPath("$.funnel.steps[0].count").value(nullValue()))
                .andExpect(jsonPath("$.funnel.steps[6].code").value("PURCHASED"))
                .andExpect(jsonPath("$.funnel.cohortNetExVatCents").value(nullValue()))
                .andExpect(jsonPath("$.revenue.byProvider[0].provider").value("STRIPE"))
                .andExpect(jsonPath("$.revenue.byProvider[0].purchases").value(nullValue()))
                .andExpect(jsonPath("$.revenue.refunds.count").value(nullValue()))
                .andExpect(jsonPath("$.byType[0].type").value("TCF"))
                .andExpect(jsonPath("$.byType[1].type").value("CIVIQUE"))
                .andExpect(jsonPath("$.signups.total").isNumber())
                .andExpect(jsonPath("$.signups.outsideDiagnostic").value(nullValue()))
                .andExpect(jsonPath("$.signups.byPlatform.ios").value(nullValue()))
                .andExpect(jsonPath("$.signups.typeFilterApplied").value(false))
                .andExpect(jsonPath("$.sources", hasSize(5)))
                .andExpect(jsonPath("$.sources[0].visitors").isNumber())
                .andExpect(jsonPath("$.ratios.subjectToSubmissionPct").value(nullValue()))
                .andExpect(jsonPath("$.activity.anonymousSubmittedNeverAttached").value(nullValue()));
    }

    @Test
    @DisplayName("D43 — filtre iOS avant la mesure iOS/Android : visiteurs et inscriptions null, pas 0")
    void filtreIosAvantMesure() throws Exception {
        mvc.perform(get(URL).param("platform", "IOS").header("Authorization", auth.bearer(data.admin())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.kpis.visitors.value").value(nullValue()))
                .andExpect(jsonPath("$.signups.total").value(nullValue()))
                .andExpect(jsonPath("$.sources[0].visitors").value(nullValue()));
    }
}
