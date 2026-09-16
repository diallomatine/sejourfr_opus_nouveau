package com.sejourfr.app.controller;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Le contrat servi par {@code GET /api/me/plan/journey}.
 *
 * <p>Ce qui est verrouille ici, ce sont les <b>faits</b> que les deux fronts
 * lisent — et l'absence de tout {@code targetLevel} en parametre : le serveur
 * connait le niveau vise du candidat, et l'accepter d'un client laisserait
 * demander un parcours qui n'est pas le sien.
 */
class JourneyControllerIT extends AbstractIntegrationTest {

    @Autowired private MockMvc mvc;
    @Autowired private AuthTestSupport auth;
    @Autowired private TestData data;

    @Test
    @DisplayName("Sans demarche declaree : NEEDS_OBJECTIVE, aucune etape (D-3)")
    void sansDemarcheDeclaree() throws Exception {
        User user = data.user();
        user.setTargetProcedure(null);
        user.setTargetLevel(null);
        data.saveUser(user);

        mvc.perform(get("/api/me/plan/journey").header("Authorization", auth.bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.state").value("NEEDS_OBJECTIVE"))
                .andExpect(jsonPath("$.targetLevel").doesNotExist())
                .andExpect(jsonPath("$.current").doesNotExist())
                .andExpect(jsonPath("$.steps").isEmpty())
                // Une suggestion n'est pas une etape : absente est le cas normal.
                .andExpect(jsonPath("$.suggestion").doesNotExist());
    }

    @Test
    @DisplayName("Sans evaluation : le parcours propose le diagnostic, et sert son niveau cible")
    void sansEvaluationLeParcoursProposeLeDiagnostic() throws Exception {
        User user = data.user();
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        data.saveUser(user);

        mvc.perform(get("/api/me/plan/journey").header("Authorization", auth.bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.state").value("IN_PROGRESS"))
                .andExpect(jsonPath("$.targetLevel").value("B2"))
                .andExpect(jsonPath("$.current.type").value("DIAGNOSTIC"))
                .andExpect(jsonPath("$.current.status").value("CURRENT"))
                .andExpect(jsonPath("$.current.locked").value(false))
                // 🛑 Le serveur sert des FAITS : aucune phrase, aucun libelle.
                // « Faire votre diagnostic rapide » appartient aux fronts.
                .andExpect(jsonPath("$.current.skillTitle").doesNotExist())
                .andExpect(jsonPath("$.hiddenUpcomingCount").value(0));
    }
}
