package com.sejourfr.app.service.diagnostic;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.service.ProductionPipelineAsyncRunner;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.is;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * LE TUNNEL DU DIAGNOSTIC ÉCRIT RAPIDE (lot L3), contre la vraie base.
 *
 * <p>Le parcours arbitré en {@code 50_} §3.1 : le visiteur lit le sujet
 * <b>sans compte</b>, rédige <b>sur son appareil</b> (aucun {@code anon_id},
 * aucune ligne en base), crée son compte, puis pousse son texte. L'appel LLM ne
 * part qu'à ce moment — on ne paie pas les diagnostics abandonnés.
 *
 * <p>Ce que ce test verrouille, et pourquoi chacun compte :
 * <ul>
 *   <li>le sujet public et le sujet de la session créée sont <b>le même</b> —
 *       sinon le candidat rédige sur un énoncé et se fait corriger sur un
 *       autre ;</li>
 *   <li><b>un seul</b> attempt est créé : pas d'attempt oral orphelin ;</li>
 *   <li>sous 100 mots, <b>aucun appel au pipeline</b> — la recevabilité de
 *       {@code 10_} §3.3 doit couper AVANT la dépense, pas après.</li>
 * </ul>
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class DiagnosticRapideIT extends AbstractIntegrationTest {

    private static final ObjectMapper JSON = new ObjectMapper();

    @Autowired private MockMvc mockMvc;
    @Autowired private TestData data;
    @Autowired private AuthTestSupport auth;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private AccountDeletionService accountDeletionService;

    @MockitoBean private ProductionPipelineAsyncRunner pipelineRunner;

    @Test
    @DisplayName("Le sujet lu sans compte est celui de la session créée après inscription")
    void leSujetLuSansCompteEstCeluiDeLaSession() throws Exception {
        UUID sujetPublic = UUID.fromString(publicCurrent()
                .path("written").path("productionTaskId").asText());

        User user = data.user();
        try {
            JsonNode session = startSession(auth.bearer(user), sujetPublic);

            assertThat(UUID.fromString(
                    session.path("written").path("productionTaskId").asText()))
                    .isEqualTo(sujetPublic);
            // 🛑 Pas d'étape orale, donc l'écrit mène DIRECTEMENT à l'analyse.
            assertThat(session.path("oral").isMissingNode()
                    || session.path("oral").isNull()).isTrue();
            assertThat(session.path("nextStep").asText()).isEqualTo("WRITTEN");
            // Un seul attempt : un attempt oral orphelin coûterait une ligne à
            // chaque candidat, pour une étape qui n'existe pas.
            assertThat(countAttempts(user.getId())).isEqualTo(1);
        } finally {
            accountDeletionService.deleteAccount(user.getId());
        }
    }

    @Test
    @DisplayName("🛑 Sous 100 mots : refus AVANT toute dépense, et le message ne parle pas de « tâche »")
    void sousLeSeuilDeRecevabiliteAucunAppelLlm() throws Exception {
        User user = data.user();
        String bearer = auth.bearer(user);
        try {
            JsonNode session = startSession(bearer, null);

            mockMvc.perform(post("/api/production-submissions")
                            .header(HttpHeaders.AUTHORIZATION, bearer)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(JSON.writeValueAsString(Map.of(
                                    "productionTaskId",
                                    session.path("written").path("productionTaskId").asText(),
                                    "attemptId",
                                    session.path("written").path("attemptId").asText(),
                                    "texte", copieDe(60)))))
                    .andExpect(status().isUnprocessableEntity())
                    .andExpect(jsonPath("$.message",
                            is("Nous n'avons pas assez d'éléments pour estimer votre niveau. "
                                    + "Complétez votre texte : il faut au moins 100 mots.")));

            // 🛑 L'ASSERTION QUI COMPTE : pas un seul appel payant. La garde de
            // recevabilité doit couper avant le pipeline, jamais après.
            verify(pipelineRunner, never()).runPipelineAsync(any(), anyBoolean());
            assertThat(countSubmissions(user.getId())).isZero();
        } finally {
            accountDeletionService.deleteAccount(user.getId());
        }
    }

    @Test
    @DisplayName("Au-dessus du seuil, la production est reçue et le pipeline part une fois")
    void auDessusDuSeuilLaProductionEstRecue() throws Exception {
        User user = data.user();
        String bearer = auth.bearer(user);
        try {
            JsonNode session = startSession(bearer, null);

            mockMvc.perform(post("/api/production-submissions")
                            .header(HttpHeaders.AUTHORIZATION, bearer)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(JSON.writeValueAsString(Map.of(
                                    "productionTaskId",
                                    session.path("written").path("productionTaskId").asText(),
                                    "attemptId",
                                    session.path("written").path("attemptId").asText(),
                                    "texte", copieDe(180)))))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.statut", is("SUBMITTED")));

            assertThat(countSubmissions(user.getId())).isEqualTo(1);
        } finally {
            accountDeletionService.deleteAccount(user.getId());
        }
    }

    // ------------------------------------------------------------------------

    private JsonNode publicCurrent() throws Exception {
        return JSON.readTree(mockMvc.perform(get("/api/public/diagnostics/current"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
    }

    private JsonNode startSession(String bearer, UUID writtenTaskId) throws Exception {
        var request = post("/api/diagnostics").header(HttpHeaders.AUTHORIZATION, bearer);
        if (writtenTaskId != null) {
            request = request.param("writtenTaskId", writtenTaskId.toString());
        }
        return JSON.readTree(mockMvc.perform(request)
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
    }

    private int countAttempts(UUID userId) {
        return jdbc.queryForObject(
                "SELECT COUNT(*) FROM attempts WHERE user_id = ?", Integer.class, userId);
    }

    private int countSubmissions(UUID userId) {
        return jdbc.queryForObject(
                "SELECT COUNT(*) FROM production_submissions WHERE user_id = ?",
                Integer.class, userId);
    }

    /** Un texte de {@code mots} mots, sans autre propriété que sa longueur. */
    private static String copieDe(int mots) {
        return String.join(" ", java.util.Collections.nCopies(mots, "quotidien"));
    }
}
