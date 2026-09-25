package com.sejourfr.app.service.email;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.EmailDelivery;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.enums.EmailSkipReason;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.service.diagnostic.DiagnosticSessionCoordinator;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticService;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticService;
import com.sejourfr.app.support.AbstractEmailIT;
import com.sejourfr.app.support.EmailTestSupport;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * {@code DIAGNOSTIC_PLAN_READY}, un test par point de publication (complement D) :
 * chacun prouve que l'evenement a bien une transaction a attendre, sinon il
 * serait perdu en silence ({@code fallbackExecution = false}).
 */
class DiagnosticPlanReadyEmailIT extends AbstractEmailIT {

    private static final String IP = "203.0.113.99";

    @Autowired private CivicDiagnosticService civicService;
    @Autowired private TcfDiagnosticService tcfService;
    @Autowired private AttemptManager attemptManager;
    @Autowired private DiagnosticSessionCoordinator coordinator;

    private void finirAttempt(Attempt attempt) {
        Attempt a = attemptManager.findById(attempt.getId()).orElseThrow();
        a.setFinishedAt(Instant.now());
        attemptManager.save(a);
    }

    private void awaitPlanReady(User u) {
        EmailTestSupport.await("DIAGNOSTIC_PLAN_READY envoye",
                () -> hasStatus(u, EmailType.DIAGNOSTIC_PLAN_READY, EmailDeliveryStatus.SENT));
    }

    @Test
    @DisplayName("Civique clos explicitement : le mail part une fois, cle par module")
    void civiqueClos() {
        User u = user();
        CivicDiagnosticSession s = civicService.ouvrir(u.getId());

        civicService.cloturer(u.getId(), s.getId());

        awaitPlanReady(u);
        EmailDelivery row = rowsOf(u, EmailType.DIAGNOSTIC_PLAN_READY).getFirst();
        assertThat(row.getDeduplicationKey()).isEqualTo("DIAGNOSTIC_PLAN_READY:" + u.getId() + ":CIVIQUE");
        assertThat(row.getReferenceId()).isEqualTo(s.getId());
        assertThat(mails.sentTo(u.getEmail())).singleElement().satisfies(m -> {
            assertThat(m.variables()).containsEntry("diagnosticType", "civique")
                    .containsEntry("planUrl", "http://localhost:3000/plan?module=CIVIQUE");
            assertThat(m.unsubscribeUrl()).contains("/api/public/email/unsubscribe?token=");
        });
    }

    @Test
    @DisplayName("Civique clos PARESSEUSEMENT pendant une lecture (GET) : l'evenement a sa transaction")
    void civiqueClosALaLecture() {
        User u = user();
        CivicDiagnosticSession s = civicService.ouvrir(u.getId());
        finirAttempt(s.getAttempt());

        civicService.courant(u.getId());

        awaitPlanReady(u);
    }

    @Test
    @DisplayName("Adoption d'un diagnostic invite : aucun mail, mais la cle du module est consommee")
    void adoptionConsommeLaCle() {
        CivicDiagnosticSession invite = civicService.ouvrirInvite(TargetProcedure.CSP, IP);
        finirAttempt(invite.getAttempt());
        civicService.lireInvite(invite.getId(), IP);
        User u = user();

        civicService.adopter(u.getId(), invite.getId(), IP);

        EmailTestSupport.await("cle consommee", () ->
                hasStatus(u, EmailType.DIAGNOSTIC_PLAN_READY, EmailDeliveryStatus.SKIPPED));
        assertThat(rowsOf(u, EmailType.DIAGNOSTIC_PLAN_READY)).singleElement()
                .satisfies(d -> assertThat(d.getSkipReason()).isEqualTo(EmailSkipReason.KEY_CONSUMED));
        assertThat(mails.sentTo(u.getEmail())).isEmpty();
    }

    @Test
    @DisplayName("TCF complet clos sans Plan prealable : le mail part")
    void tcfCompletSansPlanPrealable() {
        User u = user();
        TcfDiagnosticSession s = tcfService.ouvrir(u.getId());

        tcfService.cloturer(u.getId(), s.getId());

        awaitPlanReady(u);
        assertThat(rowsOf(u, EmailType.DIAGNOSTIC_PLAN_READY).getFirst().getDeduplicationKey())
                .endsWith(":TCF");
    }

    @Test
    @DisplayName("TCF complet qui AFFINE un Plan ouvert par le rapide : aucun mail")
    void tcfCompletQuiAffineNEnvoieRien() {
        User u = user();
        data.diagnosticSession(u, DiagnosticSessionStatus.COMPLETED);
        TcfDiagnosticSession s = tcfService.ouvrir(u.getId());

        tcfService.cloturer(u.getId(), s.getId());
        EmailTestSupport.settle();
        awaitEmailExecutorIdle();

        assertThat(rowsOf(u, EmailType.DIAGNOSTIC_PLAN_READY)).isEmpty();
        assertThat(mails.sentTo(u.getEmail())).isEmpty();
    }

    @Test
    @DisplayName("Rappels desactives : le mail n'est pas envoye, la cle est tracee SKIPPED / PREFERENCE")
    void rappelsDesactives() {
        User u = user();
        jdbc.update("INSERT INTO user_email_preferences (user_id, engagement_enabled) VALUES (?, FALSE)", u.getId());
        CivicDiagnosticSession s = civicService.ouvrir(u.getId());

        civicService.cloturer(u.getId(), s.getId());

        EmailTestSupport.await("refus trace", () ->
                hasStatus(u, EmailType.DIAGNOSTIC_PLAN_READY, EmailDeliveryStatus.SKIPPED));
        assertThat(rowsOf(u, EmailType.DIAGNOSTIC_PLAN_READY).getFirst().getSkipReason())
                .isEqualTo(EmailSkipReason.PREFERENCE);
        assertThat(mails.sentTo(u.getEmail())).isEmpty();
    }

    @Test
    @DisplayName("TCF rapide clos a la fin de l'analyse (chemin ASYNCHRONE du pipeline) : le mail part")
    void tcfRapideClosParLeCoordinateur() {
        User u = user();
        DiagnosticSession session = data.diagnosticSession(u, DiagnosticSessionStatus.IN_PROGRESS);
        ProductionSubmission ecrit = data.diagnosticSubmission(
                session.getWrittenAttempt(), session.getWrittenTask(), u);
        ProductionSubmission oral = data.diagnosticSubmission(
                session.getOralAttempt(), session.getOralTask(), u);
        data.diagnosticAnalysis(ecrit, NiveauCecrl.A2);
        data.diagnosticAnalysis(oral, NiveauCecrl.A2);

        coordinator.onAnalysisCompleted(oral.getId());

        awaitPlanReady(u);
        assertThat(rowsOf(u, EmailType.DIAGNOSTIC_PLAN_READY).getFirst().getReferenceId())
                .isEqualTo(session.getId());
        // 🛑 Composer le mail LIT le Plan sans jamais epingler sa premiere place :
        // un epinglage concurrent de celui du candidat faisait echouer SA requete.
        assertThat(jdbc.queryForObject("SELECT count(*) FROM plan_pinned_priorities WHERE user_id = ?",
                Long.class, u.getId())).isZero();
    }
}
