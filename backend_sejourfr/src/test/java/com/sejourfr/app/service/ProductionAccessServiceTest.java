package com.sejourfr.app.service;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.AccessDeniedException;

import java.time.Instant;
import java.util.UUID;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyShort;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Gardes de session partagées par les deux voies de notation EE/EO
 * (asynchrone et temps réel) : propriété, épreuve terminée, chrono,
 * correspondance épreuve tâche ⇄ attempt, et plafond « une soumission par
 * tâche » en session d'examen.
 */
class ProductionAccessServiceTest {

    private SubscriptionService subscriptionService;
    private AttemptManager attemptManager;
    private ProductionSubmissionManager submissionManager;
    private DiagnosticSessionManager diagnosticSessionManager;
    private ProductionAccessService service;

    private final UUID userId = UUID.randomUUID();
    private final UUID attemptId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        subscriptionService = mock(SubscriptionService.class);
        attemptManager = mock(AttemptManager.class);
        submissionManager = mock(ProductionSubmissionManager.class);
        diagnosticSessionManager = mock(DiagnosticSessionManager.class);
        service = new ProductionAccessService(
                subscriptionService, attemptManager, submissionManager,
                diagnosticSessionManager);
    }

    private User user(UUID id) {
        User u = new User();
        u.setId(id);
        return u;
    }

    private Attempt attempt(EpreuveType epreuve) {
        Attempt a = new Attempt();
        a.setId(attemptId);
        a.setUser(user(userId));
        a.setEpreuve(epreuve);
        a.setStartedAt(Instant.now());
        return a;
    }

    private ProductionTask task(EpreuveType epreuve, short tache) {
        ProductionTask t = new ProductionTask();
        t.setId(UUID.randomUUID());
        t.setEpreuve(epreuve);
        t.setTacheNumero(tache);
        t.setActive(true);
        return t;
    }

    // ------------------------------------------------------------------------
    // Propriété / état de session
    // ------------------------------------------------------------------------

    @Test
    void attempt_d_autrui_refuse() {
        Attempt foreign = attempt(EpreuveType.TCF_EE);
        foreign.setUser(user(UUID.randomUUID()));

        assertThatThrownBy(() -> service.assertCanSubmit(userId, foreign, task(EpreuveType.TCF_EE, (short) 1)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void epreuve_terminee_refuse() {
        Attempt finished = attempt(EpreuveType.TCF_EE);
        finished.setFinishedAt(Instant.now());

        assertThatThrownBy(() -> service.assertCanSubmit(userId, finished, task(EpreuveType.TCF_EE, (short) 1)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void chrono_ecoule_refuse_mais_la_grace_de_60s_passe() {
        Attempt expired = attempt(EpreuveType.TCF_EO);
        expired.setTimeLimitSeconds(900);
        expired.setStartedAt(Instant.now().minusSeconds(900 + 120));
        assertThatThrownBy(() -> service.assertCanSubmit(userId, expired, task(EpreuveType.TCF_EO, (short) 1)))
                .isInstanceOf(BusinessException.class);

        Attempt inGrace = attempt(EpreuveType.TCF_EO);
        inGrace.setTimeLimitSeconds(900);
        inGrace.setStartedAt(Instant.now().minusSeconds(900 + 10));
        assertThatCode(() -> service.assertCanSubmit(userId, inGrace, task(EpreuveType.TCF_EO, (short) 1)))
                .doesNotThrowAnyException();
    }

    // ------------------------------------------------------------------------
    // Correspondance épreuve tâche ⇄ session (défaut : oral noté dans une écrite)
    // ------------------------------------------------------------------------

    @Test
    void tache_orale_dans_une_session_ecrite_refuse() {
        Attempt ecrite = attempt(EpreuveType.TCF_EE);

        assertThatThrownBy(() -> service.assertCanSubmit(userId, ecrite, task(EpreuveType.TCF_EO, (short) 1)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("TCF_EO")
                .hasMessageContaining("TCF_EE");
    }

    @Test
    void tache_ecrite_dans_une_session_orale_refuse() {
        Attempt orale = attempt(EpreuveType.TCF_EO);

        assertThatThrownBy(() -> service.assertCanSubmit(userId, orale, task(EpreuveType.TCF_EE, (short) 2)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void tache_dans_une_session_qcm_refuse() {
        Attempt qcm = attempt(EpreuveType.TCF_CO);

        assertThatThrownBy(() -> service.assertCanSubmit(userId, qcm, task(EpreuveType.TCF_EO, (short) 1)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void epreuve_concordante_passe() {
        assertThatCode(() -> service.assertCanSubmit(
                userId, attempt(EpreuveType.TCF_EE), task(EpreuveType.TCF_EE, (short) 1)))
                .doesNotThrowAnyException();
    }

    // ------------------------------------------------------------------------
    // Plafond « une soumission par tâche » en session d'examen
    // ------------------------------------------------------------------------

    @Test
    void examen_refuse_une_seconde_soumission_sur_la_meme_tache() {
        Attempt exam = attempt(EpreuveType.TCF_EO);
        exam.setSlotNumber(1);
        when(submissionManager.countByAttemptAndTache(attemptId, (short) 2)).thenReturn(1L);

        assertThatThrownBy(() -> service.assertCanSubmit(userId, exam, task(EpreuveType.TCF_EO, (short) 2)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("déjà été rendue");
    }

    @Test
    void examen_accepte_les_autres_taches() {
        Attempt exam = attempt(EpreuveType.TCF_EO);
        exam.setSlotNumber(1);
        when(submissionManager.countByAttemptAndTache(attemptId, (short) 3)).thenReturn(0L);

        assertThatCode(() -> service.assertCanSubmit(userId, exam, task(EpreuveType.TCF_EO, (short) 3)))
                .doesNotThrowAnyException();
    }

    @Test
    void sous_epreuve_d_examen_complet_est_aussi_plafonnee() {
        Attempt parent = new Attempt();
        parent.setId(UUID.randomUUID());
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        Attempt sub = attempt(EpreuveType.TCF_EE);
        sub.setParentAttempt(parent);
        when(submissionManager.countByAttemptAndTache(attemptId, (short) 1)).thenReturn(1L);

        assertThatThrownBy(() -> service.assertCanSubmit(userId, sub, task(EpreuveType.TCF_EE, (short) 1)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void entrainement_libre_n_est_pas_plafonne_par_tache() {
        Attempt training = attempt(EpreuveType.TCF_EE); // slot null + parent null

        assertThatCode(() -> service.assertCanSubmit(userId, training, task(EpreuveType.TCF_EE, (short) 1)))
                .doesNotThrowAnyException();
        verify(submissionManager, never()).countByAttemptAndTache(any(), anyShort());
    }

    // ------------------------------------------------------------------------
    // Quota freemium (partagé avec la voie temps réel)
    // ------------------------------------------------------------------------

    @Test
    void quota_premium_passe_sans_lecture_de_compteur() {
        when(subscriptionService.hasTcf(userId)).thenReturn(true);

        service.enforceQuota(userId, EpreuveType.TCF_EO, attemptId);

        verify(submissionManager, never()).countTrainingByUserAndEpreuve(any(), any());
    }

    @Test
    void quota_gratuit_epuise_refuse() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.findById(attemptId)).thenReturn(java.util.Optional.of(attempt(EpreuveType.TCF_EO)));
        when(attemptManager.countProductionExamSessions(userId)).thenReturn(0L);
        when(submissionManager.countTrainingByUserAndEpreuve(userId, EpreuveType.TCF_EO)).thenReturn(1L);

        assertThatThrownBy(() -> service.enforceQuota(userId, EpreuveType.TCF_EO, attemptId))
                .isInstanceOf(AccessDeniedException.class);
    }

    // ------------------------------------------------------------------------
    // Diagnostic : bypass quota uniquement pour la paire task/attempt/session.
    // ------------------------------------------------------------------------

    @Test
    void diagnosticCorrectementAppariePasseSansConsommerLeQuotaEntrainement() {
        Attempt written = attempt(EpreuveType.TCF_EE);
        Attempt oral = attempt(EpreuveType.TCF_EO);
        oral.setId(UUID.randomUUID());
        ProductionTask writtenTask = task(EpreuveType.TCF_EE, (short) 3);
        writtenTask.setDiagnosticCode("INITIAL_TCF");
        writtenTask.setDiagnosticVersion(1);
        ProductionTask oralTask = task(EpreuveType.TCF_EO, (short) 3);
        oralTask.setDiagnosticCode("INITIAL_TCF");
        oralTask.setDiagnosticVersion(1);
        DiagnosticSession session = diagnosticSession(written, oral, writtenTask, oralTask);
        when(diagnosticSessionManager.findByAttemptIdWithContent(written.getId()))
                .thenReturn(Optional.of(session));
        when(attemptManager.findById(written.getId())).thenReturn(Optional.of(written));

        assertThatCode(() -> service.assertCanSubmit(userId, written, writtenTask))
                .doesNotThrowAnyException();
        assertThatCode(() -> service.enforceQuota(userId, writtenTask, written.getId()))
                .doesNotThrowAnyException();

        verify(subscriptionService, never()).hasTcf(any());
        verify(submissionManager, never()).countTrainingByUserAndEpreuve(any(), any());
    }

    @Test
    void uneTacheDiagnosticSeuleNeSuffitJamaisAContournerLeQuota() {
        Attempt written = attempt(EpreuveType.TCF_EE);
        ProductionTask diagnostic = task(EpreuveType.TCF_EE, (short) 3);
        diagnostic.setDiagnosticCode("INITIAL_TCF");
        diagnostic.setDiagnosticVersion(1);
        when(diagnosticSessionManager.findByAttemptIdWithContent(written.getId()))
                .thenReturn(Optional.empty());
        when(attemptManager.findById(written.getId())).thenReturn(Optional.of(written));

        assertThatThrownBy(() -> service.enforceQuota(userId, diagnostic, written.getId()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("hors de votre session");
    }

    @Test
    void uneTacheStandardEstRefuseeDansUnAttemptDiagnostic() {
        Attempt written = attempt(EpreuveType.TCF_EE);
        Attempt oral = attempt(EpreuveType.TCF_EO);
        ProductionTask diagnosticWritten = task(EpreuveType.TCF_EE, (short) 3);
        diagnosticWritten.setDiagnosticCode("INITIAL_TCF");
        diagnosticWritten.setDiagnosticVersion(1);
        ProductionTask diagnosticOral = task(EpreuveType.TCF_EO, (short) 3);
        diagnosticOral.setDiagnosticCode("INITIAL_TCF");
        diagnosticOral.setDiagnosticVersion(1);
        DiagnosticSession session = diagnosticSession(
                written, oral, diagnosticWritten, diagnosticOral);
        when(diagnosticSessionManager.findByAttemptIdWithContent(written.getId()))
                .thenReturn(Optional.of(session));

        assertThatThrownBy(() -> service.assertCanSubmit(
                userId, written, task(EpreuveType.TCF_EE, (short) 1)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("réservé au diagnostic");
    }

    // ------------------------------------------------------------------------
    // Le MEME budget, lu sans rien consommer (cadenas du Plan)
    // ------------------------------------------------------------------------

    @Test
    void unAbonneTcfNaJamaisDeCadenasSurUneVerification() {
        when(subscriptionService.hasTcf(userId)).thenReturn(true);

        assertThat(service.isTrainingLocked(userId, EpreuveType.TCF_EE)).isFalse();
        assertThat(service.isTrainingLocked(userId, EpreuveType.TCF_EO)).isFalse();
    }

    @Test
    void tantQueLessaiGratuitResteLaVerificationEstOuverte() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.countProductionExamSessions(userId)).thenReturn(0L);
        when(submissionManager.countTrainingByUserAndEpreuve(userId, EpreuveType.TCF_EE))
                .thenReturn(0L);

        assertThat(service.isTrainingLocked(userId, EpreuveType.TCF_EE)).isFalse();
    }

    /** La lecture dit exactement ce que l'ecriture refuserait : une seule regle. */
    @Test
    void lessaiGratuitConsommeVerrouilleLaVerification() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.countProductionExamSessions(userId)).thenReturn(0L);
        when(submissionManager.countTrainingByUserAndEpreuve(userId, EpreuveType.TCF_EE))
                .thenReturn(1L);

        assertThat(service.isTrainingLocked(userId, EpreuveType.TCF_EE)).isTrue();
        assertThatThrownBy(() -> service.enforceQuota(userId, EpreuveType.TCF_EE, null))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void deuxSessionsDexamenConsommentAussiLaVerification() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.countProductionExamSessions(userId)).thenReturn(2L);

        assertThat(service.isTrainingLocked(userId, EpreuveType.TCF_EO)).isTrue();
    }

    private DiagnosticSession diagnosticSession(
            Attempt written, Attempt oral, ProductionTask writtenTask, ProductionTask oralTask) {
        DiagnosticSession session = new DiagnosticSession();
        session.setId(UUID.randomUUID());
        session.setUser(user(userId));
        session.setWrittenAttempt(written);
        session.setOralAttempt(oral);
        session.setWrittenTask(writtenTask);
        session.setOralTask(oralTask);
        return session;
    }
}
