package com.sejourfr.app.controller;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Une requete mal formee est une erreur CLIENT : 400 (ou 404 sur un chemin
 * inexistant, 405 sur une mauvaise methode), jamais 500.
 *
 * <p>Avant ces handlers, TOUT tombait dans {@code @ExceptionHandler(Exception)}
 * : enum inconnu, parametre requis absent, UUID malformé, JSON tronque, chemin
 * inexistant → 500 « Erreur interne du serveur » + une stack trace en ERROR a
 * chaque erreur de saisie d'un front.
 *
 * <p>On verifie aussi que le message reste UTILE (il nomme le parametre) sans
 * rien divulguer d'interne (pas de type Java, pas de message Jackson, pas de
 * nom de classe).
 */
class MalformedRequestHandlingIT extends AbstractIntegrationTest {

    private static final String RANDOM_ID = "11111111-1111-1111-1111-111111111111";

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private TestData testData;
    @Autowired
    private AuthTestSupport auth;

    private String bearer() {
        User user = testData.user();
        return auth.bearer(user);
    }

    // -------------------------------------------------- parametres de requete

    @Test
    void unknownEnumValue_is400_andListsAcceptedValues() throws Exception {
        mockMvc.perform(get("/api/public/lots").param("module", "XX"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("module")))
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("CIVIQUE")));
    }

    @Test
    void missingRequiredParam_is400_andNamesIt() throws Exception {
        mockMvc.perform(get("/api/public/lots"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("module")));
    }

    @Test
    void malformedUuidParam_is400() throws Exception {
        mockMvc.perform(get("/api/public/lots")
                        .param("module", "CIVIQUE")
                        .param("themeId", "pasunuuid"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("themeId")));
    }

    /**
     * Le paramètre cité par le CLAUDE.md comme ayant déjà figé le chrono web :
     * un front qui l'oublie doit recevoir un 400 qui le nomme, pas un 500 opaque.
     */
    @Test
    void beginWithoutEpreuve_is400_andNamesTheParam() throws Exception {
        mockMvc.perform(post("/api/full-tcf-exams/" + RANDOM_ID + "/begin")
                        .header(HttpHeaders.AUTHORIZATION, bearer()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("epreuve")));
    }

    // -------------------------------------------------------- corps de requete

    @Test
    void malformedJsonBody_is400_withoutLeakingInternals() throws Exception {
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message")
                        .value(org.hamcrest.Matchers.not(
                                org.hamcrest.Matchers.containsString("com.sejourfr"))))
                .andExpect(jsonPath("$.message")
                        .value(org.hamcrest.Matchers.not(
                                org.hamcrest.Matchers.containsString("Jackson"))));
    }

    @Test
    void missingJsonBody_is400() throws Exception {
        mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest());
    }

    // ------------------------------------------------------------- routage

    @Test
    void unknownPath_is404_notServerError() throws Exception {
        mockMvc.perform(get("/api/attempts/mine")
                        .header(HttpHeaders.AUTHORIZATION, bearer()))
                .andExpect(status().isNotFound());
    }

    @Test
    void wrongHttpMethodOnKnownRoute_is405() throws Exception {
        mockMvc.perform(get("/api/auth/login"))
                .andExpect(status().isMethodNotAllowed());
    }
}
