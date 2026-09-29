package com.sejourfr.app.service.diagnosticrun;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.DiagnosticRunType;
import com.sejourfr.app.manager.DiagnosticRunManager;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.service.diagnostic.DiagnosticService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Handoff du TCF rapide (lot 2a) : la run creee en invite est liee a la
 * session du compte a {@code POST /api/diagnostics?diagnosticRunId=}, seulement
 * si elle appartient deja a ce compte. Hors transaction de test : la creation
 * de session tourne en {@code REQUIRES_NEW} (meme contrainte que
 * {@code DiagnosticServiceIT}), donc tout est nettoye a la main.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class DiagnosticRunQuickTcfHandoffIT extends AbstractIntegrationTest {

    @Autowired private DiagnosticService diagnosticService;
    @Autowired private DiagnosticRunManager runManager;
    @Autowired private AccountDeletionService accountDeletionService;
    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;

    private UUID run(UUID userId) {
        UUID id = UUID.randomUUID();
        runManager.insertIfAbsent(new DiagnosticRunManager.NewRun(id, DiagnosticRunType.QUICK_TCF,
                ClientPlatform.WEB, null, UUID.randomUUID(), userId, UUID.randomUUID(), null, null,
                null, null, null), Instant.now());
        return id;
    }

    private Object sessionDe(UUID runId) {
        return jdbc.queryForObject("SELECT diagnostic_session_id FROM diagnostic_run WHERE id = ?",
                Object.class, runId);
    }

    @Test
    @DisplayName("La run du compte est liée, et fonde le parcours ; celle d'un tiers ou sans porteur ne l'est jamais")
    void handoffLieSeulementLaRunDuCompte() {
        User user = data.user();
        User tiers = data.user();
        UUID duCompte = run(user.getId());
        UUID duTiers = run(tiers.getId());
        UUID sansPorteur = run(null);
        try {
            UUID sessionId = diagnosticService.startOrResume(user.getId(), ClientPlatform.WEB, null, duTiers)
                    .sessionId();
            diagnosticService.startOrResume(user.getId(), ClientPlatform.WEB, null, sansPorteur);
            assertThat(sessionDe(duTiers)).isNull();
            assertThat(sessionDe(sansPorteur)).isNull();

            // Reprise idempotente de la meme session, cette fois avec la bonne run.
            assertThat(diagnosticService.startOrResume(user.getId(), ClientPlatform.WEB, null, duCompte)
                    .sessionId()).isEqualTo(sessionId);
            assertThat(sessionDe(duCompte)).isEqualTo(sessionId);

            // Un id inconnu est ignore, jamais une erreur.
            diagnosticService.startOrResume(user.getId(), ClientPlatform.WEB, null, UUID.randomUUID());

            // Plan ↔ run (Q8) sur le diagnostic RAPIDE : le journal porte l'id
            // de la session, la run liee au handoff en est la fondatrice.
            UUID journeyId = DiagnosticRunFoundingIT.journey(jdbc, user.getId(), false);
            DiagnosticRunFoundingIT.evenement(jdbc, journeyId, sessionId, "QUICK_DIAGNOSTIC", null, Instant.now());
            assertThat(runManager.findFoundingRun(journeyId, user.getId()))
                    .map(com.sejourfr.app.entity.DiagnosticRun::getId).contains(duCompte);
            assertThat(runManager.findFoundingRun(journeyId, tiers.getId())).isEmpty();
        } finally {
            jdbc.update("DELETE FROM journey WHERE user_id IN (?, ?)", user.getId(), tiers.getId());
            jdbc.update("DELETE FROM diagnostic_run WHERE id IN (?, ?, ?)", duCompte, duTiers, sansPorteur);
            accountDeletionService.deleteAccount(user.getId());
            accountDeletionService.deleteAccount(tiers.getId());
        }
    }
}
