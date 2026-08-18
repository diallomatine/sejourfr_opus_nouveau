package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.DiagnosticJourneyStatus;
import com.sejourfr.app.enums.DiagnosticStep;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/** Démarrage/reprise réels sur PostgreSQL, sans lancer Whisper ni un LLM. */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class DiagnosticServiceIT extends AbstractIntegrationTest {

    @Autowired private DiagnosticService service;
    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private AccountDeletionService accountDeletionService;
    @Autowired private AttemptManager attemptManager;
    @Autowired private ProductionTaskManager taskManager;
    @Autowired private ProductionSubmissionManager submissionManager;
    @Autowired private DiagnosticSessionCoordinator coordinator;

    @Test
    void startEstIdempotentEtReprendLesMemesDeuxAttempts() {
        User user = data.user();
        try {
            var first = service.startOrResume(user.getId(), ClientPlatform.WEB);
            var second = service.startOrResume(user.getId(), ClientPlatform.WEB);
            var current = service.current(user.getId());

            assertThat(first.sessionId()).isEqualTo(second.sessionId()).isEqualTo(current.sessionId());
            assertThat(first.status()).isEqualTo(DiagnosticJourneyStatus.IN_PROGRESS);
            assertThat(first.nextStep()).isEqualTo(DiagnosticStep.WRITTEN);
            assertThat(first.written().attemptId()).isEqualTo(second.written().attemptId());
            assertThat(first.oral().attemptId()).isEqualTo(second.oral().attemptId());
            assertThat(first.written().productionTaskId())
                    .isNotEqualTo(first.oral().productionTaskId());
            assertThat(countSessions(user.getId())).isEqualTo(1);
            assertThat(countAttempts(user.getId())).isEqualTo(2);
        } finally {
            accountDeletionService.deleteAccount(user.getId());
        }
    }

    @Test
    void detailRefuseLIdorSansRevelerLaSession() {
        User owner = data.user();
        User attacker = data.user();
        try {
            UUID sessionId = service.startOrResume(owner.getId(), ClientPlatform.WEB).sessionId();

            assertThatThrownBy(() -> service.detail(attacker.getId(), sessionId))
                    .isInstanceOf(NotFoundException.class);
        } finally {
            accountDeletionService.deleteAccount(owner.getId());
            accountDeletionService.deleteAccount(attacker.getId());
        }
    }

    @Test
    void deuxStartsConcurrentsNeCreentQuUneSessionEtDeuxAttempts() throws Exception {
        User user = data.user();
        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch go = new CountDownLatch(1);
        try (var executor = Executors.newFixedThreadPool(2)) {
            var first = executor.submit(() -> {
                ready.countDown();
                go.await(5, TimeUnit.SECONDS);
                return service.startOrResume(user.getId(), ClientPlatform.WEB);
            });
            var second = executor.submit(() -> {
                ready.countDown();
                go.await(5, TimeUnit.SECONDS);
                return service.startOrResume(user.getId(), ClientPlatform.WEB);
            });
            assertThat(ready.await(5, TimeUnit.SECONDS)).isTrue();
            go.countDown();

            UUID firstId = first.get(15, TimeUnit.SECONDS).sessionId();
            UUID secondId = second.get(15, TimeUnit.SECONDS).sessionId();
            assertThat(firstId).isEqualTo(secondId);
            assertThat(countSessions(user.getId())).isEqualTo(1);
            assertThat(countAttempts(user.getId())).isEqualTo(2);
        } finally {
            accountDeletionService.deleteAccount(user.getId());
        }
    }

    @Test
    void unicitePersistanteInterditDeuxSoumissionsSurLeMemeAttemptDiagnostic() {
        User user = data.user();
        try {
            var diagnostic = service.startOrResume(user.getId(), ClientPlatform.WEB);
            var attempt = attemptManager.findById(diagnostic.written().attemptId()).orElseThrow();
            var task = taskManager.findById(
                    diagnostic.written().productionTaskId()).orElseThrow();

            ProductionSubmission first = diagnosticSubmission(user, attempt, task);
            submissionManager.save(first);

            assertThatThrownBy(() -> submissionManager.save(
                    diagnosticSubmission(user, attempt, task)))
                    .isInstanceOf(DataIntegrityViolationException.class);
            assertThat(jdbc.queryForObject(
                    "SELECT count(*) FROM production_submissions WHERE attempt_id = ?",
                    Integer.class, attempt.getId())).isEqualTo(1);
        } finally {
            accountDeletionService.deleteAccount(user.getId());
        }
    }

    @Test
    void deuxRelancesConcurrentesNeReserventQuUnSeulPipeline() throws Exception {
        User user = data.user();
        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch go = new CountDownLatch(1);
        try {
            var diagnostic = service.startOrResume(user.getId(), ClientPlatform.WEB);
            var attempt = attemptManager.findById(diagnostic.written().attemptId()).orElseThrow();
            var task = taskManager.findById(
                    diagnostic.written().productionTaskId()).orElseThrow();
            ProductionSubmission failed = diagnosticSubmission(user, attempt, task);
            failed.setStatut(SubmissionStatut.FAILED);
            submissionManager.save(failed);
            jdbc.update("""
                    UPDATE diagnostic_sessions
                    SET status = 'FAILED', error_message = 'test'
                    WHERE id = ?
                    """, diagnostic.sessionId());

            try (var executor = Executors.newFixedThreadPool(2)) {
                var first = executor.submit(() -> reserveRetry(
                        diagnostic.sessionId(), user.getId(), ready, go));
                var second = executor.submit(() -> reserveRetry(
                        diagnostic.sessionId(), user.getId(), ready, go));
                assertThat(ready.await(5, TimeUnit.SECONDS)).isTrue();
                go.countDown();

                assertThat(java.util.List.of(
                        first.get(15, TimeUnit.SECONDS), second.get(15, TimeUnit.SECONDS)))
                        .containsExactlyInAnyOrder(true, false);
            }

            assertThat(jdbc.queryForObject(
                    "SELECT status FROM diagnostic_sessions WHERE id = ?",
                    String.class, diagnostic.sessionId())).isEqualTo("ANALYZING");
            assertThat(jdbc.queryForObject(
                    "SELECT retry_count FROM diagnostic_sessions WHERE id = ?",
                    Integer.class, diagnostic.sessionId())).isEqualTo(1);
            assertThat(submissionManager.findById(failed.getId()).orElseThrow().getRetryCount())
                    .isZero();
        } finally {
            accountDeletionService.deleteAccount(user.getId());
        }
    }

    @Test
    void attemptsEtSoumissionsDiagnosticSontExclusDesStatsHistoriquesEtQuotaStandard() {
        User user = data.user();
        try {
            var diagnostic = service.startOrResume(user.getId(), ClientPlatform.WEB);
            var attempt = attemptManager.findById(diagnostic.written().attemptId()).orElseThrow();
            var task = taskManager.findById(
                    diagnostic.written().productionTaskId()).orElseThrow();
            ProductionSubmission submission = submissionManager.save(
                    diagnosticSubmission(user, attempt, task));

            assertThat(attemptManager.countByUserId(user.getId())).isZero();
            assertThat(attemptManager.countByUserIdAndModule(
                    user.getId(), com.sejourfr.app.enums.Module.TCF)).isZero();
            assertThat(attemptManager.findByUserFiltered(
                    user.getId(), null, null, null, null, 20)).isEmpty();
            assertThat(submissionManager.countByUserAndEpreuve(
                    user.getId(), EpreuveType.TCF_EE)).isZero();
            assertThat(submissionManager.countTrainingByUserAndEpreuve(
                    user.getId(), EpreuveType.TCF_EE)).isZero();
            assertThat(submissionManager.findRecentByUser(user.getId(), 20)).isEmpty();
            assertThat(submissionManager.findByStatutOrderedBySubmittedAt(
                    SubmissionStatut.SUBMITTED)).doesNotContain(submission);
        } finally {
            accountDeletionService.deleteAccount(user.getId());
        }
    }

    private static ProductionSubmission diagnosticSubmission(
            User user, com.sejourfr.app.entity.Attempt attempt,
            com.sejourfr.app.entity.ProductionTask task) {
        ProductionSubmission submission = new ProductionSubmission();
        submission.setUser(user);
        submission.setAttempt(attempt);
        submission.setProductionTask(task);
        submission.setTexteSoumis("Production diagnostic de test suffisamment explicite.");
        submission.setMotsCount(6);
        submission.setStatut(SubmissionStatut.SUBMITTED);
        submission.setDiagnostic(true);
        return submission;
    }

    private int countSessions(UUID userId) {
        return jdbc.queryForObject(
                "SELECT count(*) FROM diagnostic_sessions WHERE user_id = ?",
                Integer.class, userId);
    }

    private int countAttempts(UUID userId) {
        return jdbc.queryForObject(
                "SELECT count(*) FROM attempts WHERE user_id = ?",
                Integer.class, userId);
    }

    private boolean reserveRetry(
            UUID sessionId,
            UUID userId,
            CountDownLatch ready,
            CountDownLatch go) throws InterruptedException {
        ready.countDown();
        go.await(5, TimeUnit.SECONDS);
        try {
            coordinator.beginRetry(sessionId, userId, 3);
            return true;
        } catch (BusinessException expectedLoser) {
            return false;
        }
    }
}
