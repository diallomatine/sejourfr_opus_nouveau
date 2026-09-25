package com.sejourfr.app.migration;

import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La vue {@code v_derniere_activite_entrainement} (V073, arbitrage n°1) : le max
 * des QUATRE actes du candidat, et rien d'autre.
 */
class DerniereActiviteEntrainementViewIT extends AbstractIntegrationTest {

    private static final Instant T1 = Instant.parse("2026-09-01T10:00:00Z");
    private static final Instant T2 = Instant.parse("2026-09-05T10:00:00Z");
    private static final Instant T3 = Instant.parse("2026-09-08T10:00:00Z");
    private static final Instant T4 = Instant.parse("2026-09-10T10:00:00Z");
    private static final Instant PLUS_TARD = Instant.parse("2026-09-20T10:00:00Z");

    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager em;

    private Instant derniere(User u) {
        List<Timestamp> t = jdbc.queryForList(
                "SELECT derniere_activite_at FROM v_derniere_activite_entrainement WHERE user_id = ?",
                Timestamp.class, u.getId());
        return t.isEmpty() ? null : t.getFirst().toInstant();
    }

    private void set(String table, String column, Object id, Instant at) {
        em.flush();
        jdbc.update("UPDATE " + table + " SET " + column + " = ? WHERE id = ?", Timestamp.from(at), id);
    }

    @Test
    @DisplayName("Chacun des quatre actes compte, et la vue rend le plus recent")
    void lesQuatreActes() {
        User u = data.user();
        Answer answer = data.answer(data.attemptQuestion(data.attempt(u), data.question()));
        set("answers", "answered_at", answer.getId(), T1);
        assertThat(derniere(u)).isEqualTo(T1);

        ProductionSubmission prod = data.productionSubmission(data.attempt(u), data.productionTask(), u);
        set("production_submissions", "submitted_at", prod.getId(), T2);
        assertThat(derniere(u)).isEqualTo(T2);

        UserSkillAttempt petitSujet = data.userSkillAttempt(u, data.skillPrompt());
        set("user_skill_attempts", "created_at", petitSujet.getId(), T3);
        assertThat(derniere(u)).isEqualTo(T3);

        RealtimeSession oral = data.realtimeSession(u);
        set("realtime_sessions", "connected_at", oral.getId(), T4);
        assertThat(derniere(u)).isEqualTo(T4);
    }

    @Test
    @DisplayName("🛑 Ouvrir une session n'est pas s'entrainer : attempts.started_at/finished_at sont ignores")
    void lesAttemptsNeComptentPas() {
        User u = data.user();
        Attempt ouvert = data.attempt(u);
        set("attempts", "started_at", ouvert.getId(), PLUS_TARD);
        set("attempts", "finished_at", ouvert.getId(), PLUS_TARD);

        assertThat(derniere(u)).isNull();

        Answer answer = data.answer(data.attemptQuestion(ouvert, data.question()));
        set("answers", "answered_at", answer.getId(), T1);
        assertThat(derniere(u)).isEqualTo(T1);
    }

    @Test
    @DisplayName("Une simulation orale jamais jointe (connected_at nul) ne compte pas")
    void oralJamaisJointNeComptePas() {
        User u = data.user();
        RealtimeSession jamaisJointe = data.realtimeSession(u);
        set("realtime_sessions", "started_at", jamaisJointe.getId(), PLUS_TARD);

        assertThat(derniere(u)).isNull();
    }
}
