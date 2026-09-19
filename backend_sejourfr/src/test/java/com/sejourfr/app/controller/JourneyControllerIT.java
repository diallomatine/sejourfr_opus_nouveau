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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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
                // Aucun parcours : aucun bloc, aucun cycle.
                .andExpect(jsonPath("$.blocs").isEmpty())
                .andExpect(jsonPath("$.cycle").doesNotExist())
                // 🛑 Les deux champs de transition ont DISPARU du contrat (P6) :
                // les fronts lisent `blocs`, et « refonte = suppression
                // immediate de l'ancien ».
                .andExpect(jsonPath("$.steps").doesNotExist())
                .andExpect(jsonPath("$.hiddenUpcomingCount").doesNotExist())
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
                // ⚠️ `hiddenUpcomingCount` valait 0 ici jusqu'au 2026-09-18 : le
                // champ n'existe plus, et le fenetrage d'affichage avec lui.
                .andExpect(jsonPath("$.hiddenUpcomingCount").doesNotExist());
    }

    @Test
    @DisplayName("Le cycle borne est servi : quatre blocs dans l'ordre CO, CE, EO, EE (D-12)")
    void leCycleBorneEstServi() throws Exception {
        User user = data.user();
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        data.saveUser(user);

        mvc.perform(get("/api/me/plan/journey").header("Authorization", auth.bearer(user)))
                .andExpect(status().isOk())
                // 🛑 QUATRE blocs, toujours, dans l'ordre de
                // TcfDomainProfileDto.ORDRE (D-9, D-20) — pas celui des maquettes.
                .andExpect(jsonPath("$.blocs.length()").value(4))
                .andExpect(jsonPath("$.blocs[0].bloc.code").value("TCF_CO"))
                .andExpect(jsonPath("$.blocs[1].bloc.code").value("TCF_CE"))
                .andExpect(jsonPath("$.blocs[2].bloc.code").value("TCF_EO"))
                .andExpect(jsonPath("$.blocs[3].bloc.code").value("TCF_EE"))
                // Aucune competence, aucune epreuve mesuree : il n'y a rien a
                // travailler tant que la mesure n'a pas dit quoi.
                .andExpect(jsonPath("$.blocs[0].status").value("A_EVALUER"))
                .andExpect(jsonPath("$.blocs[0].competencesRestantes").value(0))
                .andExpect(jsonPath("$.blocs[0].exam").doesNotExist())
                // Le cycle : des NOMBRES, aucune phrase. « Cycle 1 » et
                // « 0 etape sur 1 terminee » sont composes par les fronts.
                .andExpect(jsonPath("$.cycle.numero").value(1))
                .andExpect(jsonPath("$.cycle.etapesTotal").value(1))
                .andExpect(jsonPath("$.cycle.etapesTerminees").value(0))
                .andExpect(jsonPath("$.cycle.complete").value(false))
                // Un cycle qui ne porte qu'un diagnostic n'est pas un cycle de
                // mesure : il n'a justement mesure personne.
                .andExpect(jsonPath("$.cycle.cycleDeMesure").value(false))
                // 🛑 nextStep est null tant que le cycle n'est pas termine.
                .andExpect(jsonPath("$.nextStep").doesNotExist());
    }

    @Test
    @DisplayName("POST /refresh — 409 tant que le cycle n'est pas termine")
    void actualiserEstRefuseSurUnCycleInacheve() throws Exception {
        User user = data.user();
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        data.saveUser(user);
        // La lecture cree le cycle : il porte son etape DIAGNOSTIC, ouverte.
        mvc.perform(get("/api/me/plan/journey").header("Authorization", auth.bearer(user)))
                .andExpect(status().isOk());

        // Ce geste HISTORISE le cycle en cours : le laisser passer sur un cycle
        // inacheve jetterait le plan que le candidat a sous les yeux.
        mvc.perform(post("/api/me/plan/journey/refresh")
                        .header("Authorization", auth.bearer(user)))
                .andExpect(status().isConflict());
        mvc.perform(post("/api/me/plan/journey/measurement-cycle")
                        .header("Authorization", auth.bearer(user)))
                .andExpect(status().isConflict());
    }
}
