package com.sejourfr.app.service;

import com.sejourfr.app.dto.ProductionSubmissionDto;
import com.sejourfr.app.dto.SubmitProductionTextRequest;
import com.sejourfr.app.entity.ProductionSituation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.ProductionSituationManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.mapper.ProductionSubmissionMapper;
import com.sejourfr.app.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

/**
 * Orchestration des cas d'usage utilisateur final pour les epreuves productives EO/EE.
 * Premium : illimite. Gratuit : plafond de 2 submissions par epreuve a vie (spec section 11).
 */
@Service
@RequiredArgsConstructor
public class ProductionSubmissionService {

    /**
     * Plafond de submissions par epreuve pour les comptes non-Premium (a vie).
     */
    private static final int FREE_QUOTA_PER_EPREUVE = 2;

    private static final int MIN_LIMIT = 1;
    private static final int MAX_LIMIT = 100;

    private final ProductionEvaluationService evaluationService;
    private final ProductionSubmissionManager submissionManager;
    private final ProductionTaskManager taskManager;
    private final ProductionSituationManager situationManager;
    private final ProductionSubmissionMapper mapper;
    private final CurrentUser currentUser;
    private final SubscriptionService subscriptionService;

    public ProductionSubmissionDto submitAudio(UUID productionTaskId, UUID attemptId,
                                               MultipartFile audio, UUID situationId) {
        UUID userId = currentUser.getId();
        ProductionTask task = loadActiveTask(productionTaskId);
        assertEpreuve(task, EpreuveType.TCF_EO);
        validateSituation(situationId, productionTaskId);
        enforceQuota(userId, task.getEpreuve());

        ProductionSubmission saved = evaluationService.submitAndEvaluate(
                userId, productionTaskId, attemptId, audio, null, situationId);
        return mapper.toDtoWithSignedAudio(saved);
    }

    public ProductionSubmissionDto submitText(SubmitProductionTextRequest req) {
        UUID userId = currentUser.getId();
        ProductionTask task = loadActiveTask(req.productionTaskId());
        assertEpreuve(task, EpreuveType.TCF_EE);
        validateSituation(req.situationId(), req.productionTaskId());
        enforceQuota(userId, task.getEpreuve());

        ProductionSubmission saved = evaluationService.submitAndEvaluate(
                userId, req.productionTaskId(), req.attemptId(), null, req.texte(), req.situationId());
        return mapper.toDto(saved);
    }

    public ProductionSubmissionDto retry(UUID submissionId) {
        UUID userId = currentUser.getId();
        ProductionSubmission saved = evaluationService.retry(submissionId, userId);
        return mapWithSignedAudioIfPresent(saved);
    }

    @Transactional(readOnly = true)
    public ProductionSubmissionDto getOwnDetail(UUID submissionId) {
        UUID userId = currentUser.getId();
        ProductionSubmission sub = submissionManager.findById(submissionId)
                .orElseThrow(() -> new NotFoundException("Submission introuvable : " + submissionId));

        if (sub.getUser() == null || !sub.getUser().getId().equals(userId)) {
            // 404 plutot que 403 : ne pas reveler l'existence des submissions d'autrui.
            throw new NotFoundException("Submission introuvable : " + submissionId);
        }
        return mapWithSignedAudioIfPresent(sub);
    }

    @Transactional(readOnly = true)
    public List<ProductionSubmissionDto> listMine(EpreuveType epreuve, int limit) {
        UUID userId = currentUser.getId();
        int safeLimit = clampLimit(limit);

        List<ProductionSubmission> list = (epreuve == null)
                ? submissionManager.findRecentByUser(userId, safeLimit)
                : submissionManager.findRecentByUserAndEpreuve(userId, epreuve, safeLimit);
        return list.stream().map(mapper::toDto).toList();
    }

    @Transactional(readOnly = true)
    public List<ProductionSubmissionDto> lastPerTask(EpreuveType epreuve, String niveau) {
        if (epreuve != EpreuveType.TCF_EO && epreuve != EpreuveType.TCF_EE) {
            throw new BusinessException("epreuve doit etre TCF_EO ou TCF_EE.");
        }
        UUID userId = currentUser.getId();
        List<ProductionSubmission> list = submissionManager.findLatestPerTask(
                userId, epreuve, niveau.toUpperCase());
        return list.stream().map(this::mapWithSignedAudioIfPresent).toList();
    }

    private ProductionTask loadActiveTask(UUID taskId) {
        return taskManager.findActiveById(taskId)
                .orElseThrow(() -> new NotFoundException("Tache introuvable : " + taskId));
    }

    /**
     * La situation est optionnelle (entrainement libre). Si fournie, elle doit
     * exister, etre active, et appartenir a la tache soumise (anti-incoherence).
     */
    private void validateSituation(UUID situationId, UUID taskId) {
        if (situationId == null) return;
        ProductionSituation situation = situationManager.findActiveById(situationId)
                .orElseThrow(() -> new NotFoundException("Situation introuvable : " + situationId));
        if (!situation.getTaskId().equals(taskId)) {
            throw new BusinessException("La situation " + situationId + " n'appartient pas a la tache " + taskId + ".");
        }
    }

    private void assertEpreuve(ProductionTask task, EpreuveType expected) {
        if (task.getEpreuve() != expected) {
            throw new BusinessException("Cette route attend une tache " + expected + " ; recu " + task.getEpreuve());
        }
    }

    private void enforceQuota(UUID userId, EpreuveType epreuve) {
        if (subscriptionService.hasTcf(userId)) return;
        long used = submissionManager.countByUserAndEpreuve(userId, epreuve);
        if (used >= FREE_QUOTA_PER_EPREUVE) {
            throw new AccessDeniedException(
                    "Quota gratuit atteint pour " + epreuve + " (" + FREE_QUOTA_PER_EPREUVE
                            + " a vie). Passez Premium pour continuer."
            );
        }
    }

    private ProductionSubmissionDto mapWithSignedAudioIfPresent(ProductionSubmission sub) {
        return sub.getMediaUrl() != null ? mapper.toDtoWithSignedAudio(sub) : mapper.toDto(sub);
    }

    private int clampLimit(int limit) {
        return Math.max(MIN_LIMIT, Math.min(limit, MAX_LIMIT));
    }
}
