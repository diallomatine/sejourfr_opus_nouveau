package com.sejourfr.app.service.diagnostic;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.DiagnosticProductionAnalysis;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.DiagnosticCommunicationStatus;
import com.sejourfr.app.enums.DiagnosticTaskCompletion;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.service.ProductionAudioStorageService;
import com.sejourfr.app.service.ProductionPipelineAsyncRunner;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.is;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Ce que font les fronts juste après l'inscription du visiteur : créer la
 * session, puis pousser l'écrit et l'oral <b>coup sur coup</b>, les deux
 * productions ayant été faites hors ligne, sans compte.
 *
 * <p>C'est l'enchaînement que le parcours invité rend systématique. Une garde
 * trop stricte le casserait au pire moment de la conversion : session basculée
 * en {@code ANALYZING} dès la première production, plafond « une soumission par
 * attempt » porté sur la session entière, ou quota freemium appliqué à une
 * production diagnostique. Ce test échoue si l'une d'elles refuse la séquence.
 *
 * <p>Seuls les deux ports externes sont remplacés — le pipeline d'analyse
 * (Whisper + LLM payant) et R2. Toutes les gardes serveur (propriété de
 * l'attempt, correspondance d'épreuve, chrono, une soumission par tâche, quota)
 * restent réellement exercées.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class DiagnosticPostSignupSequenceIT extends AbstractIntegrationTest {

    private static final ObjectMapper JSON = new ObjectMapper();

    @Autowired private MockMvc mockMvc;
    @Autowired private TestData data;
    @Autowired private AuthTestSupport auth;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private AccountDeletionService accountDeletionService;
    @Autowired private AttemptManager attemptManager;
    @Autowired private ProductionTaskManager taskManager;
    @Autowired private ProductionSubmissionManager submissionManager;
    @Autowired private DiagnosticProductionAnalysisManager analysisManager;

    @MockitoBean private ProductionPipelineAsyncRunner pipelineRunner;
    @MockitoBean private ProductionAudioStorageService audioStorage;

    @Test
    void inscriptionPuisEcritPuisOralCoupSurCoup() throws Exception {
        User user = data.user();
        String bearer = auth.bearer(user);
        ProductionAudioStorageService.StoredAudio stored =
                new ProductionAudioStorageService.StoredAudio("productions/test.m4a", "audio/mp4");
        when(audioStorage.upload(any(), any(), any(), any())).thenReturn(stored);
        try {
            JsonNode session = startSession(bearer);
            assertThat(session.path("status").asText()).isEqualTo("IN_PROGRESS");
            assertThat(session.path("nextStep").asText()).isEqualTo("WRITTEN");

            submitWritten(bearer, session)
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.statut", is("SUBMITTED")));
            // Aucune attente entre les deux : c'est exactement ce que fait le
            // front, l'analyse de l'écrit tourne encore quand l'oral part.
            submitOral(bearer, session)
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.statut", is("SUBMITTED")));

            assertThat(submissionsOf(session, "written")).singleElement()
                    .satisfies(s -> assertThat(s.isDiagnostic()).isTrue());
            assertThat(submissionsOf(session, "oral")).singleElement()
                    .satisfies(s -> assertThat(s.isDiagnostic()).isTrue());
            verify(pipelineRunner, times(2)).runPipelineAsync(any(), anyBoolean());
        } finally {
            accountDeletionService.deleteAccount(user.getId());
        }
    }

    @Test
    void laDeuxiemeSoumissionSurLaMemeEtapeResteRefusee() throws Exception {
        User user = data.user();
        String bearer = auth.bearer(user);
        try {
            JsonNode session = startSession(bearer);
            submitWritten(bearer, session).andExpect(status().isOk());

            submitWritten(bearer, session).andExpect(status().isUnprocessableEntity());
            assertThat(submissionsOf(session, "written")).hasSize(1);
        } finally {
            accountDeletionService.deleteAccount(user.getId());
        }
    }

    /**
     * Le candidat avait déjà terminé ce diagnostic et rejoue le parcours
     * invité : {@code POST /api/diagnostics} rend sa session existante en
     * {@code COMPLETED} (200, avec son résultat), sans en créer une seconde, et
     * les productions qui suivraient sont refusées en 422 — jamais un 500.
     */
    @Test
    void diagnosticDejaTermineRendLaSessionExistanteEtRefuseLesNouvellesProductions() throws Exception {
        User user = data.user();
        String bearer = auth.bearer(user);
        try {
            JsonNode session = startSession(bearer);
            UUID sessionId = UUID.fromString(session.path("sessionId").asText());
            completeSession(session, sessionId);

            JsonNode replay = startSession(bearer);

            assertThat(replay.path("sessionId").asText()).isEqualTo(sessionId.toString());
            assertThat(replay.path("status").asText()).isEqualTo("COMPLETED");
            assertThat(replay.path("nextStep").asText()).isEqualTo("RESULT");
            assertThat(replay.path("result").isMissingNode()).isFalse();
            assertThat(replay.path("result").path("nextAction").isMissingNode()).isFalse();
            assertThat(countSessions(user.getId())).isEqualTo(1);

            submitWritten(bearer, session).andExpect(status().isUnprocessableEntity());
        } finally {
            accountDeletionService.deleteAccount(user.getId());
        }
    }

    /** Pose les deux productions rendues et leurs analyses, sans appeler de LLM. */
    private void completeSession(JsonNode session, UUID sessionId) {
        analyse(persistedSubmission(session, "written"), "EE1-C1");
        analyse(persistedSubmission(session, "oral"), "EO1-C1");
        // `chk_diagnostic_session_completed` impose completed_at ET summary_json
        // sur une session COMPLETED : on pose la synthèse déterministe telle que
        // l'aurait écrite le coordinateur.
        jdbc.update("""
                UPDATE diagnostic_sessions
                SET status = 'COMPLETED', completed_at = now(), summary_json = ?::jsonb
                WHERE id = ?
                """, """
                {"strengths": ["Le destinataire est pris en compte."],
                 "priority_skill_codes": ["EE1-C1", "EO1-C1"],
                 "main_priority_explanation": "Le récit reste très court."}
                """, sessionId);
    }

    private ProductionSubmission persistedSubmission(JsonNode session, String step) {
        Attempt attempt = attemptManager.findById(attemptId(session, step)).orElseThrow();
        ProductionSubmission submission = new ProductionSubmission();
        submission.setUser(attempt.getUser());
        submission.setAttempt(attempt);
        submission.setProductionTask(taskManager.findById(taskId(session, step)).orElseThrow());
        submission.setTexteSoumis("Production diagnostic déjà rendue et analysée.");
        submission.setMotsCount(7);
        submission.setStatut(SubmissionStatut.EVALUATED);
        submission.setDiagnostic(true);
        return submissionManager.save(submission);
    }

    private void analyse(ProductionSubmission submission, String skillCode) {
        DiagnosticProductionAnalysis analysis = new DiagnosticProductionAnalysis();
        analysis.setSubmission(submission);
        analysis.setAnalysisJson(Map.of(
                "summary", "Message compréhensible.",
                "strengths", List.of("Le destinataire est pris en compte."),
                "weaknesses", List.of("Les temps du passé sont instables."),
                "skills", List.of(Map.of(
                        "skill_code", skillCode,
                        "observed", true,
                        "status", "TO_REINFORCE",
                        "evidence", "Je suis allé au cours hier.",
                        "explanation", "Le récit reste très court.",
                        "confidence", "HIGH",
                        "priority", true))));
        analysis.setLevelEstimate(NiveauCecrl.A2);
        analysis.setTaskCompletion(DiagnosticTaskCompletion.PARTIAL);
        analysis.setCommunicationStatus(DiagnosticCommunicationStatus.PARTIAL);
        analysis.setModelUsed("test");
        analysis.setSchemaVersion("v1");
        analysisManager.save(analysis);
    }

    private JsonNode startSession(String bearer) throws Exception {
        String body = mockMvc.perform(post("/api/diagnostics")
                        .header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return JSON.readTree(body);
    }

    private ResultActions submitWritten(String bearer, JsonNode session) throws Exception {
        Map<String, Object> payload = Map.of(
                "productionTaskId", taskId(session, "written").toString(),
                "attemptId", attemptId(session, "written").toString(),
                "texte", copieDe(110));
        return mockMvc.perform(post("/api/production-submissions")
                .header(HttpHeaders.AUTHORIZATION, bearer)
                .contentType(MediaType.APPLICATION_JSON)
                .content(JSON.writeValueAsString(payload)));
    }

    private ResultActions submitOral(String bearer, JsonNode session) throws Exception {
        MockMultipartFile audio = new MockMultipartFile(
                "audio", "reponse.m4a", "audio/mp4", "fake-audio-bytes".getBytes());
        return mockMvc.perform(multipart("/api/production-submissions")
                .file(audio)
                .header(HttpHeaders.AUTHORIZATION, bearer)
                .param("productionTaskId", taskId(session, "oral").toString())
                .param("attemptId", attemptId(session, "oral").toString()));
    }

    private List<ProductionSubmission> submissionsOf(JsonNode session, String step) {
        return submissionManager.findByAttemptId(attemptId(session, step));
    }

    private static UUID attemptId(JsonNode session, String step) {
        return UUID.fromString(session.path(step).path("attemptId").asText());
    }

    private static UUID taskId(JsonNode session, String step) {
        return UUID.fromString(session.path(step).path("productionTaskId").asText());
    }

    /** Copie EE dans les bornes du sujet diagnostic (100–130 mots). */
    private static String copieDe(int mots) {
        StringBuilder texte = new StringBuilder("Bonjour");
        for (int i = 1; i < mots; i++) {
            texte.append(" mot").append(i);
        }
        return texte.append(".").toString();
    }

    private int countSessions(UUID userId) {
        return jdbc.queryForObject(
                "SELECT count(*) FROM diagnostic_sessions WHERE user_id = ?", Integer.class, userId);
    }
}
