package com.sejourfr.app.controller;

import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Contrôle G (option a) : la version minimale de l'app est servie sans compte,
 * et la valeur livrée ne bloque personne.
 */
class PublicAppConfigControllerIT extends AbstractIntegrationTest {

    @Autowired private MockMvc mvc;

    @Test
    @DisplayName("GET /api/public/app-config sans compte : 200, aucune version minimale livrée, cachable")
    void configLivreeNeBloquePersonne() throws Exception {
        mvc.perform(get("/api/public/app-config"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.minSupportedVersion").exists())
                .andExpect(jsonPath("$.minSupportedVersion.ios").doesNotExist())
                .andExpect(jsonPath("$.minSupportedVersion.android").doesNotExist())
                .andExpect(header().string("Cache-Control", containsString("max-age=300")));
    }
}
