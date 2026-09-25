package com.sejourfr.app.service.diagnosticrun;

import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.DiagnosticRun;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.DiagnosticRunType;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.DiagnosticRunManager;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticService;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Plan ↔ run (Q8) : {@code DiagnosticRunManager.findFoundingRun} resout
 * {@code journey.id} → run fondatrice par le journal des evaluations et les FK
 * de session, sans jamais lire un identifiant de run venu d'un client. Le
 * diagnostic RAPIDE est couvert par {@link DiagnosticRunQuickTcfHandoffIT}
 * (sa session se cree hors transaction de test).
 */
class DiagnosticRunFoundingIT extends AbstractIntegrationTest {

    @Autowired private DiagnosticRunManager runManager;
    @Autowired private CivicDiagnosticService civicService;
    @Autowired private TcfDiagnosticService tcfService;
    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager em;

    static UUID journey(JdbcTemplate jdbc, UUID userId, boolean civique) {
        UUID id = UUID.randomUUID();
        if (civique) {
            jdbc.update("INSERT INTO journey (id, user_id, target_procedure, module) VALUES (?, ?, 'CSP', 'CIVIQUE')",
                    id, userId);
        } else {
            jdbc.update("INSERT INTO journey (id, user_id, target_level, module) VALUES (?, ?, 'B1', 'TCF')",
                    id, userId);
        }
        return id;
    }

    static void evenement(JdbcTemplate jdbc, UUID journeyId, UUID source, String kind, String examType,
                          Instant completedAt) {
        jdbc.update("INSERT INTO journey_assessment_event (id, journey_id, source_assessment_id, assessment_kind, "
                        + "exam_type, completed_at) VALUES (?, ?, ?, ?, ?, ?)",
                UUID.randomUUID(), journeyId, source, kind, examType, Timestamp.from(completedAt));
    }

    static UUID run(DiagnosticRunManager runManager, DiagnosticRunType type, UUID userId, UUID quick, UUID tcf,
                    UUID civic) {
        UUID id = UUID.randomUUID();
        runManager.insertIfAbsent(new DiagnosticRunManager.NewRun(id, type, ClientPlatform.WEB, null,
                UUID.randomUUID(), userId, UUID.randomUUID(), null, null, quick, tcf, civic), Instant.now());
        return id;
    }

    @Test
    @DisplayName("Civique : la run du diagnostic le plus ancien du parcours ; rien pour un autre compte")
    void civique() {
        User user = data.user();
        User autre = data.user();
        CivicDiagnosticSession premiere = civicService.ouvrir(user.getId());
        CivicDiagnosticSession seconde = civicService.ouvrirInvite(TargetProcedure.CSP, "198.51.100.9");
        em.flush();
        UUID runPremiere = run(runManager, DiagnosticRunType.CIVIQUE, user.getId(), null, null, premiere.getId());
        run(runManager, DiagnosticRunType.CIVIQUE, user.getId(), null, null, seconde.getId());
        UUID journeyId = journey(jdbc, user.getId(), true);
        Instant maintenant = Instant.now();
        evenement(jdbc, journeyId, seconde.getId(), "CIVIC_DIAGNOSTIC", null, maintenant.minus(Duration.ofDays(1)));
        evenement(jdbc, journeyId, premiere.getId(), "CIVIC_DIAGNOSTIC", null, maintenant.minus(Duration.ofDays(2)));

        assertThat(runManager.findFoundingRun(journeyId, user.getId())).map(DiagnosticRun::getId)
                .contains(runPremiere);
        // Le parcours d'un autre ne se resout jamais, meme avec son id.
        assertThat(runManager.findFoundingRun(journeyId, autre.getId())).isEmpty();
    }

    @Test
    @DisplayName("Complet : la section journalisée remonte à sa session, puis à la run")
    void complet() {
        User user = data.user();
        TcfDiagnosticSession session = tcfService.ouvrir(user.getId());
        em.flush();
        UUID section = jdbc.queryForObject("SELECT id FROM attempts WHERE tcf_diagnostic_id = ? "
                + "AND parent_attempt_id IS NOT NULL LIMIT 1", UUID.class, session.getId());
        UUID runId = run(runManager, DiagnosticRunType.FULL_TCF, user.getId(), null, session.getId(), null);
        UUID journeyId = journey(jdbc, user.getId(), false);
        evenement(jdbc, journeyId, section, "FULL_DIAGNOSTIC", "TCF_CO", Instant.now());

        assertThat(runManager.findFoundingRun(journeyId, user.getId())).map(DiagnosticRun::getId).contains(runId);
    }

    @Test
    @DisplayName("Diagnostic sans run liée (client ancien) : inconnu, jamais une run devinée")
    void sansRunLiee() {
        User user = data.user();
        CivicDiagnosticSession session = civicService.ouvrir(user.getId());
        em.flush();
        // Une run du meme compte, du meme type, mais liee a rien : pas une preuve.
        run(runManager, DiagnosticRunType.CIVIQUE, user.getId(), null, null, null);
        UUID journeyId = journey(jdbc, user.getId(), true);
        evenement(jdbc, journeyId, session.getId(), "CIVIC_DIAGNOSTIC", null, Instant.now());

        assertThat(runManager.findFoundingRun(journeyId, user.getId())).isEmpty();
        assertThat(runManager.findFoundingRun(UUID.randomUUID(), user.getId())).isEmpty();
    }
}
