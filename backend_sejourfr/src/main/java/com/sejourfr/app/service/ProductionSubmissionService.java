package com.sejourfr.app.service;

import com.sejourfr.app.dto.ProductionSubmissionDto;
import com.sejourfr.app.dto.SubmitProductionTextRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
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
 *
 * <p>Regles freemium (validees 2026-06-06) — Premium TCF : illimite. Gratuit :
 * <ul>
 *   <li>1 essai d'entrainement par epreuve (EE et EO) a vie ;</li>
 *   <li>les soumissions d'une session d'examen blanc production
 *       ({@code attempt.slotNumber} non null, autorisee au start cote
 *       {@code AttemptService}) ou d'un examen TCF complet ne comptent pas
 *       dans ce quota ;</li>
 *   <li>refaire l'examen blanc (2e session) consomme les essais
 *       d'entrainement restants : des 2 sessions d'examen, plus aucun
 *       entrainement gratuit.</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
public class ProductionSubmissionService {

    /**
     * Essais d'entrainement par epreuve pour les comptes non-Premium (a vie).
     */
    private static final int FREE_TRAINING_PER_EPREUVE = 1;

    private static final int MIN_LIMIT = 1;
    private static final int MAX_LIMIT = 100;

    private final ProductionEvaluationService evaluationService;
    private final ProductionSubmissionManager submissionManager;
    private final AttemptManager attemptManager;
    private final ProductionTaskManager taskManager;
    private final ProductionSubmissionMapper mapper;
    private final CurrentUser currentUser;
    private final SubscriptionService subscriptionService;

    public ProductionSubmissionDto submitAudio(UUID productionTaskId, UUID attemptId, MultipartFile audio) {
        UUID userId = currentUser.getId();
        ProductionTask task = loadActiveTask(productionTaskId);
        assertEpreuve(task, EpreuveType.TCF_EO);
        enforceQuota(userId, task.getEpreuve(), attemptId);

        ProductionSubmission saved = evaluationService.submitAndEvaluate(
                userId, productionTaskId, attemptId, audio, null);
        return mapper.toDtoWithSignedAudio(saved);
    }

    public ProductionSubmissionDto submitText(SubmitProductionTextRequest req) {
        UUID userId = currentUser.getId();
        ProductionTask task = loadActiveTask(req.productionTaskId());
        assertEpreuve(task, EpreuveType.TCF_EE);
        enforceQuota(userId, task.getEpreuve(), req.attemptId());

        ProductionSubmission saved = evaluationService.submitAndEvaluate(
                userId, req.productionTaskId(), req.attemptId(), null, req.texte());
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

    private void assertEpreuve(ProductionTask task, EpreuveType expected) {
        if (task.getEpreuve() != expected) {
            throw new BusinessException("Cette route attend une tache " + expected + " ; recu " + task.getEpreuve());
        }
    }

    private void enforceQuota(UUID userId, EpreuveType epreuve, UUID attemptId) {
        if (subscriptionService.hasTcf(userId)) return;

        // Session d'examen (slotNumber) ou examen TCF complet (parent) : la
        // session a ete autorisee au start (AttemptService), ses soumissions
        // ne consomment pas le quota d'entrainement.
        if (attemptId != null) {
            Attempt attempt = attemptManager.findById(attemptId).orElse(null);
            if (attempt != null) {
                // Epreuve deja terminee : aucune soumission. Couvre les EE/EO
                // verrouillees d'un examen complet gratuit (pre-terminees au
                // start) — empeche un client de contourner le verrou.
                if (attempt.getFinishedAt() != null) {
                    throw new AccessDeniedException(
                            "Cette epreuve est terminee. L'expression ecrite et orale ne sont "
                                    + "offertes qu'une fois ; passez Premium pour continuer.");
                }
                if (attempt.getSlotNumber() != null || attempt.getParentAttempt() != null) {
                    return;
                }
            }
        }

        // Refaire l'examen blanc (2e session) consomme les essais restants.
        if (attemptManager.countProductionExamSessions(userId) >= 2) {
            throw new AccessDeniedException(
                    "Vos essais gratuits EE/EO ont ete utilises en refaisant l'examen blanc. "
                            + "Passez Premium pour continuer.");
        }

        long used = submissionManager.countTrainingByUserAndEpreuve(userId, epreuve);
        if (used >= FREE_TRAINING_PER_EPREUVE) {
            throw new AccessDeniedException(
                    "Quota gratuit atteint pour " + epreuve + " (" + FREE_TRAINING_PER_EPREUVE
                            + " essai a vie). Passez Premium pour continuer."
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
