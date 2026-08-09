package com.sejourfr.app.service.realtime;

import com.sejourfr.app.config.RealtimeProperties;
import com.sejourfr.app.dto.AppendTranscriptRequest;
import com.sejourfr.app.dto.RealtimeSessionDescriptor;
import com.sejourfr.app.dto.RealtimeSessionStateResponse;
import com.sejourfr.app.dto.StartRealtimeSessionRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.RealtimeSessionStatus;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.RealtimeSessionManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.ProductionAccessService;
import com.sejourfr.app.service.ProductionEvaluationService;
import com.sejourfr.app.service.SubscriptionService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Orchestration des sessions EO temps reel : demarrage (quota -> mint Gemini ou
 * bascule async), accumulation de transcript (debit du quota a la 1re connexion)
 * et cloture (statut + declenchement de notation). Tous les clients externes
 * (broker Gemini, evaluation) sont mockes.
 */
@ExtendWith(MockitoExtension.class)
class RealtimeSessionServiceTest {

    @Mock private RealtimeSessionManager sessionManager;
    @Mock private RealtimeQuotaService quotaService;
    @Mock private RealtimePersonaBuilder personaBuilder;
    @Mock private RealtimeTokenBroker tokenBroker;
    @Mock private ProductionTaskManager productionTaskManager;
    @Mock private AttemptManager attemptManager;
    @Mock private ProductionEvaluationService productionEvaluationService;
    @Mock private SubscriptionService subscriptionService;
    @Mock private com.sejourfr.app.manager.ProductionSubmissionManager productionSubmissionManager;
    @Mock private UserSubscriptionManager userSubscriptionManager;

    private final RealtimeProperties props = new RealtimeProperties();

    private RealtimeSessionService service;

    private User user;
    private final UUID taskId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        // Gardes de session : collaborateur REEL (pur) pour exercer les regles
        // reellement appliquees a l'ouverture d'une session temps reel.
        ProductionAccessService accessService = new ProductionAccessService(
                subscriptionService, attemptManager, productionSubmissionManager,
                org.mockito.Mockito.mock(com.sejourfr.app.manager.DiagnosticSessionManager.class));
        service = new RealtimeSessionService(sessionManager, quotaService, personaBuilder,
                tokenBroker, productionTaskManager, attemptManager, productionEvaluationService,
                accessService, userSubscriptionManager, props);
        user = new User();
        user.setId(UUID.randomUUID());
    }

    private ProductionTask eoTask(short tache) {
        ProductionTask task = new ProductionTask();
        task.setId(taskId);
        task.setEpreuve(EpreuveType.TCF_EO);
        task.setTacheNumero(tache);
        task.setDureeMaxSec(180);
        return task;
    }

    private RealtimeQuotaService.Quota quota(boolean canStart, int remaining) {
        UserSubscription sub = canStart ? new UserSubscription() : null;
        return new RealtimeQuotaService.Quota(sub, remaining, remaining);
    }

    // ----- start -----

    @Test
    void start_consigne_introuvable_404() {
        when(productionTaskManager.findActiveById(taskId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.start(user, new StartRealtimeSessionRequest(taskId, null)))
            .isInstanceOf(NotFoundException.class);
    }

    @Test
    void start_refuse_une_epreuve_non_eo() {
        ProductionTask task = eoTask((short) 1);
        task.setEpreuve(EpreuveType.TCF_EE);
        when(productionTaskManager.findActiveById(taskId)).thenReturn(Optional.of(task));

        assertThatThrownBy(() -> service.start(user, new StartRealtimeSessionRequest(taskId, null)))
            .isInstanceOf(BusinessException.class);
    }

    @Test
    void start_refuse_une_tache_hors_1_2() {
        when(productionTaskManager.findActiveById(taskId)).thenReturn(Optional.of(eoTask((short) 3)));

        assertThatThrownBy(() -> service.start(user, new StartRealtimeSessionRequest(taskId, null)))
            .isInstanceOf(BusinessException.class);
    }

    @Test
    void start_bascule_async_si_broker_non_configure() {
        when(productionTaskManager.findActiveById(taskId)).thenReturn(Optional.of(eoTask((short) 1)));
        when(quotaService.evaluate(user.getId())).thenReturn(quota(true, 3));
        when(tokenBroker.isConfigured()).thenReturn(false);

        RealtimeSessionDescriptor d = service.start(user, new StartRealtimeSessionRequest(taskId, null));

        assertThat(d.mode()).isEqualTo(RealtimeSessionDescriptor.MODE_ASYNC_FALLBACK);
        assertThat(d.sessionId()).isNull();
        assertThat(d.sessionsRemaining()).isEqualTo(3);
        verify(sessionManager, never()).save(any());
    }

    @Test
    void start_bascule_async_si_quota_epuise() {
        when(productionTaskManager.findActiveById(taskId)).thenReturn(Optional.of(eoTask((short) 1)));
        when(quotaService.evaluate(user.getId())).thenReturn(quota(false, 0));
        when(tokenBroker.isConfigured()).thenReturn(true);

        RealtimeSessionDescriptor d = service.start(user, new StartRealtimeSessionRequest(taskId, null));

        assertThat(d.mode()).isEqualTo(RealtimeSessionDescriptor.MODE_ASYNC_FALLBACK);
        verify(sessionManager, never()).save(any());
    }

    @Test
    void start_bascule_async_si_mint_echoue() {
        when(productionTaskManager.findActiveById(taskId)).thenReturn(Optional.of(eoTask((short) 1)));
        when(quotaService.evaluate(user.getId())).thenReturn(quota(true, 2));
        when(tokenBroker.isConfigured()).thenReturn(true);
        when(personaBuilder.build(any())).thenReturn("persona");
        when(tokenBroker.mint("persona")).thenThrow(new RuntimeException("mint KO"));

        RealtimeSessionDescriptor d = service.start(user, new StartRealtimeSessionRequest(taskId, null));

        assertThat(d.mode()).isEqualTo(RealtimeSessionDescriptor.MODE_ASYNC_FALLBACK);
        assertThat(d.sessionsRemaining()).isEqualTo(2);
        verify(sessionManager, never()).save(any());
    }

    @Test
    void start_realtime_emet_le_descripteur_et_reserve_un_slot() {
        when(productionTaskManager.findActiveById(taskId)).thenReturn(Optional.of(eoTask((short) 1)));
        when(quotaService.evaluate(user.getId())).thenReturn(quota(true, 3));
        when(tokenBroker.isConfigured()).thenReturn(true);
        when(tokenBroker.provider()).thenReturn("gemini");
        when(personaBuilder.build(any())).thenReturn("persona");
        when(tokenBroker.mint("persona"))
            .thenReturn(new RealtimeTokenBroker.MintedSession("tok", "wss://g", "model-x"));
        UUID sessionId = UUID.randomUUID();
        when(sessionManager.save(any())).thenAnswer(inv -> {
            RealtimeSession s = inv.getArgument(0);
            s.setId(sessionId);
            return s;
        });

        RealtimeSessionDescriptor d = service.start(user, new StartRealtimeSessionRequest(taskId, null));

        assertThat(d.mode()).isEqualTo(RealtimeSessionDescriptor.MODE_REALTIME);
        assertThat(d.sessionId()).isEqualTo(sessionId);
        assertThat(d.ephemeralToken()).isEqualTo("tok");
        assertThat(d.model()).isEqualTo("model-x");
        assertThat(d.tacheNumero()).isEqualTo(1);
        assertThat(d.targetDurationSec()).isEqualTo(180);
        // 3 restants, cette session en reserve 1.
        assertThat(d.sessionsRemaining()).isEqualTo(2);
        verify(tokenBroker).mint("persona");
    }

    @Test
    void start_attempt_d_autrui_404() {
        when(productionTaskManager.findActiveById(taskId)).thenReturn(Optional.of(eoTask((short) 1)));
        UUID attemptId = UUID.randomUUID();
        Attempt other = new Attempt();
        User someoneElse = new User();
        someoneElse.setId(UUID.randomUUID());
        other.setUser(someoneElse);
        when(attemptManager.findById(attemptId)).thenReturn(Optional.of(other));

        assertThatThrownBy(() -> service.start(user, new StartRealtimeSessionRequest(taskId, attemptId)))
            .isInstanceOf(NotFoundException.class);
        // La session visee est validee AVANT de mobiliser le broker / le quota.
        verify(tokenBroker, never()).mint(any());
    }

    /** Attempt EO du user, non termine, chrono ouvert : le cas nominal. */
    private Attempt ownEoAttempt() {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setUser(user);
        a.setEpreuve(EpreuveType.TCF_EO);
        a.setStartedAt(Instant.now());
        return a;
    }

    @Test
    void start_refuse_une_sous_epreuve_deja_terminee() {
        // Sous-epreuve EE/EO pre-terminee par le verrou freemium d'un examen
        // complet : l'invariant « epreuve terminee => plus aucune soumission »
        // etait faux sur la voie temps reel.
        when(productionTaskManager.findActiveById(taskId)).thenReturn(Optional.of(eoTask((short) 1)));
        Attempt locked = ownEoAttempt();
        locked.setFinishedAt(Instant.now());
        when(attemptManager.findById(locked.getId())).thenReturn(Optional.of(locked));

        assertThatThrownBy(() -> service.start(user, new StartRealtimeSessionRequest(taskId, locked.getId())))
            .isInstanceOf(BusinessException.class);
        verify(sessionManager, never()).save(any());
        verify(tokenBroker, never()).mint(any());
    }

    @Test
    void start_refuse_une_session_d_une_autre_epreuve() {
        when(productionTaskManager.findActiveById(taskId)).thenReturn(Optional.of(eoTask((short) 1)));
        Attempt ecrite = ownEoAttempt();
        ecrite.setEpreuve(EpreuveType.TCF_EE);
        when(attemptManager.findById(ecrite.getId())).thenReturn(Optional.of(ecrite));

        assertThatThrownBy(() -> service.start(user, new StartRealtimeSessionRequest(taskId, ecrite.getId())))
            .isInstanceOf(BusinessException.class);
        verify(sessionManager, never()).save(any());
    }

    @Test
    void start_refuse_une_tache_deja_rendue_dans_l_examen() {
        when(productionTaskManager.findActiveById(taskId)).thenReturn(Optional.of(eoTask((short) 1)));
        Attempt exam = ownEoAttempt();
        exam.setSlotNumber(1);
        when(attemptManager.findById(exam.getId())).thenReturn(Optional.of(exam));
        when(productionSubmissionManager.countByAttemptAndTache(exam.getId(), (short) 1)).thenReturn(1L);

        assertThatThrownBy(() -> service.start(user, new StartRealtimeSessionRequest(taskId, exam.getId())))
            .isInstanceOf(BusinessException.class);
        verify(sessionManager, never()).save(any());
    }

    // ----- appendTranscript -----

    @Test
    void appendTranscript_pending_passe_active_et_debite_une_session_du_pass() {
        UserSubscription subscription = new UserSubscription();
        subscription.setId(UUID.randomUUID());
        RealtimeSession session = new RealtimeSession();
        session.setId(UUID.randomUUID());
        session.setUser(user);
        session.setSubscription(subscription);
        session.setStatus(RealtimeSessionStatus.PENDING);
        session.setTranscript("");
        when(sessionManager.findById(session.getId())).thenReturn(Optional.of(session));

        service.appendTranscript(user, session.getId(),
            new AppendTranscriptRequest("CANDIDATE", "Bonjour"));

        assertThat(session.getStatus()).isEqualTo(RealtimeSessionStatus.ACTIVE);
        assertThat(session.getConnectedAt()).isNotNull();
        assertThat(session.getTranscript()).isEqualTo("Candidat : Bonjour");
        // Débit d'UNE session sur le pass, à la 1re activité (PENDING -> ACTIVE).
        verify(userSubscriptionManager).decrementRealtimeSessions(subscription.getId());
        verify(sessionManager).save(session);
    }

    @Test
    void appendTranscript_concatene_les_locuteurs() {
        RealtimeSession session = new RealtimeSession();
        session.setId(UUID.randomUUID());
        session.setUser(user);
        session.setStatus(RealtimeSessionStatus.ACTIVE);
        session.setConnectedAt(Instant.now());
        session.setTranscript("Candidat : Bonjour");
        when(sessionManager.findById(session.getId())).thenReturn(Optional.of(session));

        service.appendTranscript(user, session.getId(),
            new AppendTranscriptRequest("EXAMINER", "Bonjour, presentez-vous"));

        assertThat(session.getTranscript())
            .isEqualTo("Candidat : Bonjour\nExaminateur : Bonjour, presentez-vous");
        // Déjà ACTIVE : pas de nouveau débit (le débit a lieu une seule fois).
        verify(userSubscriptionManager, never()).decrementRealtimeSessions(any());
    }

    @Test
    void appendTranscript_ignore_un_fragment_apres_cloture() {
        RealtimeSession session = new RealtimeSession();
        session.setId(UUID.randomUUID());
        session.setUser(user);
        session.setStatus(RealtimeSessionStatus.COMPLETED);
        when(sessionManager.findById(session.getId())).thenReturn(Optional.of(session));

        service.appendTranscript(user, session.getId(),
            new AppendTranscriptRequest("CANDIDATE", "tardif"));

        verify(sessionManager, never()).save(any());
    }

    @Test
    void appendTranscript_session_d_autrui_404() {
        RealtimeSession session = new RealtimeSession();
        session.setId(UUID.randomUUID());
        User someoneElse = new User();
        someoneElse.setId(UUID.randomUUID());
        session.setUser(someoneElse);
        when(sessionManager.findById(session.getId())).thenReturn(Optional.of(session));

        assertThatThrownBy(() -> service.appendTranscript(user, session.getId(),
            new AppendTranscriptRequest("CANDIDATE", "x")))
            .isInstanceOf(NotFoundException.class);
    }

    // ----- finish -----

    @Test
    void finish_session_reellement_jouee_passe_completed_et_declenche_la_notation() {
        Attempt attempt = new Attempt();
        attempt.setId(UUID.randomUUID());
        attempt.setUser(user);
        ProductionTask task = eoTask((short) 1);

        RealtimeSession session = new RealtimeSession();
        session.setId(UUID.randomUUID());
        session.setUser(user);
        session.setAttempt(attempt);
        session.setProductionTask(task);
        session.setStatus(RealtimeSessionStatus.ACTIVE);
        session.setConnectedAt(Instant.now().minusSeconds(60));
        session.setTranscript("Examinateur : Bonjour\nCandidat : Je m'appelle Karim");
        when(sessionManager.findById(session.getId())).thenReturn(Optional.of(session));
        when(quotaService.remaining(user.getId())).thenReturn(1);

        RealtimeSessionStateResponse resp = service.finish(user, session.getId());

        assertThat(session.getStatus()).isEqualTo(RealtimeSessionStatus.COMPLETED);
        assertThat(session.getEndedAt()).isNotNull();
        assertThat(resp.status()).isEqualTo(RealtimeSessionStatus.COMPLETED);
        assertThat(resp.sessionsRemaining()).isEqualTo(1);
        assertThat(resp.evaluated()).isTrue();
        verify(productionEvaluationService).evaluateRealtimeTranscript(
            eq(user.getId()), eq(task.getId()), eq(attempt.getId()), any(String.class), any());
    }

    @Test
    void finish_jamais_connectee_passe_failed_sans_notation() {
        RealtimeSession session = new RealtimeSession();
        session.setId(UUID.randomUUID());
        session.setUser(user);
        session.setStatus(RealtimeSessionStatus.PENDING);
        session.setConnectedAt(null);
        session.setTranscript("");
        when(sessionManager.findById(session.getId())).thenReturn(Optional.of(session));
        when(quotaService.remaining(user.getId())).thenReturn(2);

        RealtimeSessionStateResponse resp = service.finish(user, session.getId());

        assertThat(session.getStatus()).isEqualTo(RealtimeSessionStatus.FAILED);
        assertThat(resp.status()).isEqualTo(RealtimeSessionStatus.FAILED);
        assertThat(resp.evaluated()).isFalse();
        verify(productionEvaluationService, never())
            .evaluateRealtimeTranscript(any(), any(), any(), any(), any());
    }

    @Test
    void finish_completed_sans_tour_candidat_ne_note_pas() {
        Attempt attempt = new Attempt();
        attempt.setId(UUID.randomUUID());
        attempt.setUser(user);
        RealtimeSession session = new RealtimeSession();
        session.setId(UUID.randomUUID());
        session.setUser(user);
        session.setAttempt(attempt);
        session.setProductionTask(eoTask((short) 1));
        session.setStatus(RealtimeSessionStatus.ACTIVE);
        session.setConnectedAt(Instant.now().minusSeconds(30));
        session.setTranscript("Examinateur : Bonjour"); // aucun tour candidat
        when(sessionManager.findById(session.getId())).thenReturn(Optional.of(session));
        when(quotaService.remaining(user.getId())).thenReturn(0);

        RealtimeSessionStateResponse resp = service.finish(user, session.getId());

        assertThat(session.getStatus()).isEqualTo(RealtimeSessionStatus.COMPLETED);
        // Bug corrigé : sans tour candidat, aucune submission n'est créée ->
        // evaluated=false, les fronts affichent « vous n'avez pas parlé » au lieu
        // d'un écran de résultat vide (« session introuvable »).
        assertThat(resp.evaluated()).isFalse();
        verify(productionEvaluationService, never())
            .evaluateRealtimeTranscript(any(), any(), any(), any(), any());
    }

    @Test
    void finish_deja_terminee_renvoie_l_etat_sans_re_sauvegarder() {
        RealtimeSession session = new RealtimeSession();
        session.setId(UUID.randomUUID());
        session.setUser(user);
        session.setStatus(RealtimeSessionStatus.COMPLETED);
        when(sessionManager.findById(session.getId())).thenReturn(Optional.of(session));
        when(quotaService.remaining(user.getId())).thenReturn(1);

        RealtimeSessionStateResponse resp = service.finish(user, session.getId());

        assertThat(resp.status()).isEqualTo(RealtimeSessionStatus.COMPLETED);
        // Session déjà COMPLETED sans transcript/attempt : rien à réévaluer.
        assertThat(resp.evaluated()).isFalse();
        verify(sessionManager, never()).save(any());
        verify(productionEvaluationService, never())
            .evaluateRealtimeTranscript(any(), any(), any(), any(), any());
    }

    @Test
    void finish_notation_en_echec_reste_completed() {
        Attempt attempt = new Attempt();
        attempt.setId(UUID.randomUUID());
        attempt.setUser(user);
        RealtimeSession session = new RealtimeSession();
        session.setId(UUID.randomUUID());
        session.setUser(user);
        session.setAttempt(attempt);
        session.setProductionTask(eoTask((short) 1));
        session.setStatus(RealtimeSessionStatus.ACTIVE);
        session.setConnectedAt(Instant.now().minusSeconds(45));
        session.setTranscript("Candidat : Bonjour je me presente");
        when(sessionManager.findById(session.getId())).thenReturn(Optional.of(session));
        when(quotaService.remaining(user.getId())).thenReturn(0);
        when(productionEvaluationService.evaluateRealtimeTranscript(any(), any(), any(), any(), any()))
            .thenThrow(new RuntimeException("pipeline KO"));

        RealtimeSessionStateResponse resp = service.finish(user, session.getId());

        assertThat(resp.status()).isEqualTo(RealtimeSessionStatus.COMPLETED);
        // evaluateRealtimeTranscript CREE la submission puis delegue l'eval a un
        // runner async : si elle leve (garde refusee, quota epuise), rien n'a ete
        // cree. Annoncer evaluated=true enverrait le front sur un ecran de
        // resultat vide.
        assertThat(resp.evaluated()).isFalse();
    }
}
