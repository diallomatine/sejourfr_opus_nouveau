package com.sejourfr.app.service.realtime;

import com.sejourfr.app.dto.AppendTranscriptRequest;
import com.sejourfr.app.dto.FinishRealtimeSessionRequest;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.RealtimeFallbackReason;
import com.sejourfr.app.enums.RealtimeSessionStatus;
import com.sejourfr.app.manager.RealtimeMesureManager;
import com.sejourfr.app.manager.RealtimeSessionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Mesure de l'examinateur temps réel (V090, lot M) contre la vraie base : une
 * session de bout en bout — sans fournisseur, la connexion étant simulée par
 * les fragments relayés — laisse des segments horodatés, sa cause de fin et ses
 * événements ; un client ancien (sans horodatage) reste accepté ; et les
 * requêtes de {@code docs/examinateur-ia/indicateurs.sql} s'exécutent sur le
 * schéma réel et retrouvent la session.
 */
class RealtimeMesureIT extends AbstractIntegrationTest {

    private static final Path INDICATEURS = Path.of("..", "docs", "examinateur-ia", "indicateurs.sql");

    @Autowired private TestData data;
    @Autowired private RealtimeSessionService sessions;
    @Autowired private RealtimeSessionManager sessionManager;
    @Autowired private RealtimeMesureManager mesureManager;
    @Autowired private JdbcTemplate jdbc;
    @PersistenceContext private EntityManager em;

    private RealtimeSession sessionOuverte(User u, ProductionTask task) {
        RealtimeSession s = new RealtimeSession();
        s.setUser(u);
        s.setProductionTask(task);
        s.setEpreuve(EpreuveType.TCF_EO);
        s.setTacheNumero((short) 1);
        s.setProvider("gemini");
        s.setModel("test-model");
        s.setStatus(RealtimeSessionStatus.PENDING);
        s.setPersonaVersion("v-test");
        s.setVadSilenceMs(1500);
        return sessionManager.save(s);
    }

    @Test
    void une_session_de_bout_en_bout_laisse_des_tours_horodates_sa_cause_et_ses_evenements() {
        User u = data.user();
        RealtimeSession s = sessionOuverte(u, data.productionTacheNumero(EpreuveType.TCF_EO, (short) 1));

        sessions.appendTranscript(u, s.getId(), new AppendTranscriptRequest(
                "EXAMINER", "Bonjour. Pouvez-vous vous présenter ?", 0, null, 300, 3300));
        sessions.appendTranscript(u, s.getId(), new AppendTranscriptRequest(
                "CANDIDATE", "Je m'appelle Karim et je travaille à Lille", 1, null, 4000, 9000));
        // Rejeu réseau du même tour : rien de plus.
        sessions.appendTranscript(u, s.getId(), new AppendTranscriptRequest(
                "CANDIDATE", "Je m'appelle Karim et je travaille à Lille", 1, null, 4000, 9000));
        sessions.appendTranscript(u, s.getId(), new AppendTranscriptRequest(
                "EXAMINER", "D'accord. Depuis quand ?", 2, null, 10500, 12000));
        sessions.finish(u, s.getId(), new FinishRealtimeSessionRequest("TIME_UP", List.of(
                new FinishRealtimeSessionRequest.ConductEvent("SILENCE_RELANCE", 20000, null),
                new FinishRealtimeSessionRequest.ConductEvent("TIMEUP_GRACE", 180000, 2500))));
        em.flush();

        List<Map<String, Object>> tours = jdbc.queryForList(
                "SELECT seq, turn_index, speaker, word_count, started_at_ms, ended_at_ms "
                        + "FROM realtime_session_turns WHERE session_id = ? ORDER BY seq", s.getId());
        assertThat(tours).hasSize(3);
        assertThat(tours.get(0)).containsEntry("speaker", "EXAMINER").containsEntry("started_at_ms", 300)
                .containsEntry("ended_at_ms", 3300).containsEntry("word_count", 5);
        assertThat(tours.get(1)).containsEntry("seq", 1).containsEntry("turn_index", 1)
                .containsEntry("speaker", "CANDIDATE").containsEntry("ended_at_ms", 9000);
        assertThat(tours.get(2)).containsEntry("seq", 2).containsEntry("started_at_ms", 10500);

        Map<String, Object> ligne = jdbc.queryForMap(
                "SELECT status, end_cause, transcript FROM realtime_sessions WHERE id = ?", s.getId());
        assertThat(ligne).containsEntry("status", "COMPLETED").containsEntry("end_cause", "TIME_UP");
        // Le texte noté ne change pas de forme.
        assertThat((String) ligne.get("transcript")).isEqualTo(
                "Examinateur : Bonjour. Pouvez-vous vous présenter ?\n"
                        + "Candidat : Je m'appelle Karim et je travaille à Lille\n"
                        + "Examinateur : D'accord. Depuis quand ?");

        assertThat(jdbc.queryForList(
                "SELECT type || ':' || coalesce(at_ms::text, '-') || ':' || coalesce(value_ms::text, '-') "
                        + "FROM realtime_session_events WHERE session_id = ? ORDER BY type", String.class, s.getId()))
                .containsExactly("SILENCE_RELANCE:20000:-", "TIMEUP_GRACE:180000:2500");
    }

    @Test
    void un_client_sans_horodatage_reste_accepte() {
        User u = data.user();
        RealtimeSession s = sessionOuverte(u, data.productionTacheNumero(EpreuveType.TCF_EO, (short) 1));

        sessions.appendTranscript(u, s.getId(), new AppendTranscriptRequest("CANDIDATE", "Bonjour madame", 0, null));
        sessions.appendTranscript(u, s.getId(), new AppendTranscriptRequest("EXAMINER", "Bonjour", null, null));
        sessions.finish(u, s.getId());
        em.flush();

        List<Map<String, Object>> tours = jdbc.queryForList(
                "SELECT seq, turn_index, started_at_ms, ended_at_ms, started_at_ms_vad FROM realtime_session_turns "
                        + "WHERE session_id = ? ORDER BY seq", s.getId());
        assertThat(tours).hasSize(2);
        assertThat(tours.get(0)).containsEntry("started_at_ms", null).containsEntry("ended_at_ms", null)
                .containsEntry("started_at_ms_vad", null);
        assertThat(tours.get(1)).containsEntry("seq", 1).containsEntry("turn_index", null);
        assertThat(jdbc.queryForObject("SELECT end_cause FROM realtime_sessions WHERE id = ?", String.class, s.getId()))
                .isNull();
    }

    @Test
    void un_repli_asynchrone_est_comptable() {
        User u = data.user();
        ProductionTask task = data.productionTacheNumero(EpreuveType.TCF_EO, (short) 2);

        mesureManager.tracerRepli(u.getId(), task.getId(), null, (short) 2, RealtimeFallbackReason.QUOTA);
        em.flush();

        assertThat(jdbc.queryForObject(
                "SELECT count(*) FROM realtime_fallbacks WHERE user_id = ? AND reason = 'QUOTA' AND tache_numero = 2",
                Long.class, u.getId())).isEqualTo(1L);
    }

    @Test
    void les_requetes_d_indicateurs_s_executent_sur_le_schema_reel() throws IOException {
        User u = data.user();
        RealtimeSession s = sessionOuverte(u, data.productionTacheNumero(EpreuveType.TCF_EO, (short) 1));
        sessions.appendTranscript(u, s.getId(), new AppendTranscriptRequest(
                "EXAMINER", "Très bien. Et vos loisirs ?", 0, null, 0, 2000));
        sessions.appendTranscript(u, s.getId(), new AppendTranscriptRequest(
                "CANDIDATE", "Je fais du sport le week-end", 1, null, 3000, 9000, 2600, 8500));
        sessions.appendTranscript(u, s.getId(), new AppendTranscriptRequest(
                "EXAMINER", "D'accord. Lequel ?", 2, null, 10000, 11500));
        sessions.finish(u, s.getId(), new FinishRealtimeSessionRequest("USER_FINISH", null));
        em.flush();

        List<String> requetes = requetes();
        assertThat(requetes).hasSizeGreaterThanOrEqualTo(9);
        for (String sql : requetes) {
            jdbc.queryForList(sql);
        }

        Map<String, Object> parole = jdbc.queryForList(requetes.get(0)).stream()
                .filter(r -> "v-test".equals(r.get("persona_version"))).findFirst().orElseThrow();
        // Examinateur 2 000 + 1 500 ms, candidat 6 000 ms (référence : transcription).
        assertThat(parole.get("pct_temps_examinateur").toString()).isEqualTo("36.8");
        Map<String, Object> interdits = jdbc.queryForList(requetes.get(6)).stream()
                .filter(r -> "v-test".equals(r.get("persona_version"))).findFirst().orElseThrow();
        assertThat(((Number) interdits.get("avec_terme_interdit")).intValue()).isEqualTo(1);
        // D-07 : délai mesuré au micro (fin 8 500 → reprise 10 000) à côté de la référence.
        Map<String, Object> micro = jdbc.queryForList(requetes.get(9)).stream()
                .filter(r -> "v-test".equals(r.get("persona_version"))).findFirst().orElseThrow();
        assertThat(((Number) micro.get("avec_mesure_micro")).intValue()).isEqualTo(1);
        assertThat(micro.get("delai_median_micro_sec").toString()).isEqualTo("1.50");
    }

    /** Les requêtes du fichier, commentaires retirés, dans l'ordre. */
    private static List<String> requetes() throws IOException {
        String sansCommentaires = Arrays.stream(Files.readString(INDICATEURS, StandardCharsets.UTF_8).split("\n"))
                .filter(l -> !l.strip().startsWith("--"))
                .reduce("", (a, b) -> a + b + "\n");
        return Arrays.stream(sansCommentaires.split(";"))
                .map(String::strip)
                .filter(q -> !q.isEmpty())
                .toList();
    }
}
