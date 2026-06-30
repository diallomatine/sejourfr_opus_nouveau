package com.sejourfr.app.service;

import com.sejourfr.app.dto.ProductionBilanResponse;
import com.sejourfr.app.dto.ProductionSubmissionDto;
import com.sejourfr.app.dto.SubmitProductionTextRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.mapper.ProductionSubmissionMapper;
import com.sejourfr.app.mapper.ProductionTaskMapper;
import com.sejourfr.app.ratelimit.RateLimitGuard;
import com.sejourfr.app.security.CurrentUser;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.springframework.security.access.AccessDeniedException;

/**
 * Regles freemium EE/EO + gardes d'appartenance de
 * {@link ProductionSubmissionService}. Unitaire pur : on pilote
 * {@code subscriptionService.hasTcf} et l'etat des attempts pour verifier le
 * verrou de {@code enforceQuota} (exerce via {@code submitText}).
 */
class ProductionSubmissionServiceTest {

    private ProductionEvaluationService evaluationService;
    private ProductionSubmissionManager submissionManager;
    private AttemptManager attemptManager;
    private ProductionTaskManager taskManager;
    private ProductionSubmissionMapper mapper;
    private ProductionTaskMapper taskMapper;
    private CurrentUser currentUser;
    private SubscriptionService subscriptionService;
    private ProductionBilanService bilanService;
    private ProductionExamCompositionService compositionService;
    private RateLimitGuard rateLimitGuard;
    private ProductionSubmissionService service;

    private final UUID userId = UUID.randomUUID();
    private final UUID taskId = UUID.randomUUID();
    private final UUID attemptId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        evaluationService = mock(ProductionEvaluationService.class);
        submissionManager = mock(ProductionSubmissionManager.class);
        attemptManager = mock(AttemptManager.class);
        taskManager = mock(ProductionTaskManager.class);
        mapper = mock(ProductionSubmissionMapper.class);
        taskMapper = mock(ProductionTaskMapper.class);
        currentUser = mock(CurrentUser.class);
        subscriptionService = mock(SubscriptionService.class);
        bilanService = mock(ProductionBilanService.class);
        compositionService = mock(ProductionExamCompositionService.class);
        rateLimitGuard = mock(RateLimitGuard.class);
        service = new ProductionSubmissionService(
                evaluationService, submissionManager, attemptManager, taskManager,
                mapper, taskMapper, currentUser, subscriptionService, bilanService,
                compositionService, rateLimitGuard);

        when(currentUser.getId()).thenReturn(userId);
    }

    private ProductionTask eeTask() {
        ProductionTask t = new ProductionTask();
        t.setId(taskId);
        t.setEpreuve(EpreuveType.TCF_EE);
        t.setActive(true);
        return t;
    }

    private SubmitProductionTextRequest req() {
        return new SubmitProductionTextRequest(taskId, attemptId, "Mon texte de production.");
    }

    private void stubEvaluatedSubmission() {
        when(evaluationService.submitAndEvaluate(eq(userId), eq(taskId), eq(attemptId), isNull(), any()))
                .thenReturn(new ProductionSubmission());
        when(mapper.toDto(any())).thenReturn(mock(ProductionSubmissionDto.class));
    }

    private Attempt attempt() {
        Attempt a = new Attempt();
        a.setId(attemptId);
        return a;
    }

    // ------------------------------------------------------------------------
    // submitText : garde de tache + quota
    // ------------------------------------------------------------------------

    @Test
    void submitText_tache_introuvable_renvoie_404() {
        when(taskManager.findActiveById(taskId)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.submitText(req())).isInstanceOf(NotFoundException.class);
    }

    @Test
    void submitText_tache_oral_refuse_sur_la_route_ecrite() {
        ProductionTask oral = eeTask();
        oral.setEpreuve(EpreuveType.TCF_EO);
        when(taskManager.findActiveById(taskId)).thenReturn(Optional.of(oral));
        assertThatThrownBy(() -> service.submitText(req())).isInstanceOf(BusinessException.class);
    }

    @Test
    void submitText_premium_passe_sans_verifier_le_quota() {
        when(taskManager.findActiveById(taskId)).thenReturn(Optional.of(eeTask()));
        when(subscriptionService.hasTcf(userId)).thenReturn(true);
        stubEvaluatedSubmission();

        service.submitText(req());

        verify(rateLimitGuard).checkProductionSubmission(userId);
        verify(evaluationService).submitAndEvaluate(eq(userId), eq(taskId), eq(attemptId), isNull(), any());
        // Premium : on ne consulte pas le compteur d'entrainement.
        verify(submissionManager, never()).countTrainingByUserAndEpreuve(any(), any());
    }

    @Test
    void submitText_gratuit_premier_essai_entrainement_autorise() {
        when(taskManager.findActiveById(taskId)).thenReturn(Optional.of(eeTask()));
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.findById(attemptId)).thenReturn(Optional.of(attempt()));
        when(attemptManager.countProductionExamSessions(userId)).thenReturn(0L);
        when(submissionManager.countTrainingByUserAndEpreuve(userId, EpreuveType.TCF_EE)).thenReturn(0L);
        stubEvaluatedSubmission();

        service.submitText(req());

        verify(evaluationService).submitAndEvaluate(eq(userId), eq(taskId), eq(attemptId), isNull(), any());
    }

    @Test
    void submitText_gratuit_quota_entrainement_epuise_refuse() {
        when(taskManager.findActiveById(taskId)).thenReturn(Optional.of(eeTask()));
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.findById(attemptId)).thenReturn(Optional.of(attempt()));
        when(attemptManager.countProductionExamSessions(userId)).thenReturn(0L);
        when(submissionManager.countTrainingByUserAndEpreuve(userId, EpreuveType.TCF_EE)).thenReturn(1L);

        assertThatThrownBy(() -> service.submitText(req())).isInstanceOf(AccessDeniedException.class);
        verify(evaluationService, never()).submitAndEvaluate(any(), any(), any(), any(), any());
    }

    @Test
    void submitText_gratuit_session_examen_slotNumber_bypass_le_quota() {
        Attempt examSlot = attempt();
        examSlot.setSlotNumber(1);
        when(taskManager.findActiveById(taskId)).thenReturn(Optional.of(eeTask()));
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.findById(attemptId)).thenReturn(Optional.of(examSlot));
        stubEvaluatedSubmission();

        service.submitText(req());

        verify(evaluationService).submitAndEvaluate(eq(userId), eq(taskId), eq(attemptId), isNull(), any());
        // Bypass : pas de lecture du compteur d'entrainement.
        verify(submissionManager, never()).countTrainingByUserAndEpreuve(any(), any());
    }

    @Test
    void submitText_gratuit_epreuve_terminee_refuse() {
        Attempt finished = attempt();
        finished.setFinishedAt(Instant.now());
        when(taskManager.findActiveById(taskId)).thenReturn(Optional.of(eeTask()));
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.findById(attemptId)).thenReturn(Optional.of(finished));

        assertThatThrownBy(() -> service.submitText(req())).isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void submitText_gratuit_deux_sessions_examen_consomment_les_essais() {
        when(taskManager.findActiveById(taskId)).thenReturn(Optional.of(eeTask()));
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.findById(attemptId)).thenReturn(Optional.of(attempt()));
        when(attemptManager.countProductionExamSessions(userId)).thenReturn(2L);

        assertThatThrownBy(() -> service.submitText(req())).isInstanceOf(AccessDeniedException.class);
        verify(submissionManager, never()).countTrainingByUserAndEpreuve(any(), any());
    }

    // ------------------------------------------------------------------------
    // lectures
    // ------------------------------------------------------------------------

    @Test
    void lastPerTask_epreuve_qcm_refusee() {
        assertThatThrownBy(() -> service.lastPerTask(EpreuveType.TCF_CO, "b1"))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void getOwnDetail_submission_d_autrui_renvoie_404() {
        ProductionSubmission other = new ProductionSubmission();
        User otherUser = new User();
        otherUser.setId(UUID.randomUUID());
        other.setUser(otherUser);
        UUID subId = UUID.randomUUID();
        when(submissionManager.findById(subId)).thenReturn(Optional.of(other));

        assertThatThrownBy(() -> service.getOwnDetail(subId)).isInstanceOf(NotFoundException.class);
    }

    @Test
    void listMine_sans_epreuve_lit_tout_le_recent_avec_limite_bornee() {
        when(submissionManager.findRecentByUser(eq(userId), eq(100))).thenReturn(List.of());
        service.listMine(null, 9999); // clamp a 100
        verify(submissionManager).findRecentByUser(userId, 100);
        verify(submissionManager, never()).findRecentByUserAndEpreuve(any(), any(), org.mockito.ArgumentMatchers.anyInt());
    }

    // ------------------------------------------------------------------------
    // bilan : gardes + entrainement (pas de niveau)
    // ------------------------------------------------------------------------

    @Test
    void bilan_attempt_non_production_refuse() {
        Attempt civique = attempt();
        User u = new User();
        u.setId(userId);
        civique.setUser(u);
        civique.setEpreuve(EpreuveType.CIVIQUE);
        when(attemptManager.findById(attemptId)).thenReturn(Optional.of(civique));

        assertThatThrownBy(() -> service.bilan(attemptId)).isInstanceOf(BusinessException.class);
    }

    @Test
    void bilan_entrainement_libre_ne_calcule_pas_de_niveau() {
        Attempt training = attempt();
        User u = new User();
        u.setId(userId);
        training.setUser(u);
        training.setEpreuve(EpreuveType.TCF_EE); // slotNumber null + parent null → exam=false
        when(attemptManager.findById(attemptId)).thenReturn(Optional.of(training));
        when(submissionManager.findByAttemptId(attemptId)).thenReturn(List.of());
        when(bilanService.latestEvalsByTache(any())).thenReturn(Map.of());
        when(bilanService.moyenneNotes(any())).thenReturn(null);

        ProductionBilanResponse resp = service.bilan(attemptId);

        assertThat(resp.exam()).isFalse();
        assertThat(resp.niveauGlobal()).isNull();
        assertThat(resp.evaluatedCount()).isZero();
        assertThat(resp.expectedCount()).isEqualTo(ProductionBilanService.EXPECTED_TASKS_PER_EPREUVE);
    }
}
