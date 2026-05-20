package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ProductionSubmissionDto;
import com.sejourfr.app.dto.SubmitProductionTextRequest;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.mapper.ProductionSubmissionMapper;
import com.sejourfr.app.repository.ProductionSubmissionRepository;
import com.sejourfr.app.repository.ProductionTaskRepository;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.ProductionEvaluationService;
import com.sejourfr.app.service.SubscriptionService;
import jakarta.validation.Valid;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

/**
 * Surface utilisateur des epreuves productives. Premium : illimite. Gratuit :
 * plafond de 2 submissions par epreuve (a vie) defini par la spec section 11.
 * Les endpoints admin sont dans {@code AdminCalibrationController}.
 */
@RestController
public class ProductionSubmissionController {

    /** Plafond de submissions par epreuve pour les comptes non-Premium (a vie). */
    private static final int FREE_QUOTA_PER_EPREUVE = 2;

    private final ProductionEvaluationService evaluationService;
    private final ProductionSubmissionRepository submissionRepository;
    private final ProductionTaskRepository taskRepository;
    private final ProductionSubmissionMapper mapper;
    private final CurrentUser currentUser;
    private final SubscriptionService subscriptionService;

    public ProductionSubmissionController(
            ProductionEvaluationService evaluationService,
            ProductionSubmissionRepository submissionRepository,
            ProductionTaskRepository taskRepository,
            ProductionSubmissionMapper mapper,
            CurrentUser currentUser,
            SubscriptionService subscriptionService) {
        this.evaluationService = evaluationService;
        this.submissionRepository = submissionRepository;
        this.taskRepository = taskRepository;
        this.mapper = mapper;
        this.currentUser = currentUser;
        this.subscriptionService = subscriptionService;
    }

    /** EO : upload multipart de l'audio. */
    @PostMapping(value = "/api/production-submissions", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ProductionSubmissionDto submitAudio(
            @RequestPart("audio") MultipartFile audio,
            @RequestParam("productionTaskId") UUID productionTaskId,
            @RequestParam("attemptId") UUID attemptId) {
        UUID userId = currentUser.getId();
        ProductionTask task = loadTask(productionTaskId);
        if (task.getEpreuve() != EpreuveType.TCF_EO) {
            throw new BusinessException("Cette route attend une tache TCF_EO ; reçu " + task.getEpreuve());
        }
        enforceQuota(userId, task.getEpreuve());
        ProductionSubmission saved = evaluationService.submitAndEvaluate(
            userId, productionTaskId, attemptId, audio, null
        );
        return mapper.toDtoWithSignedAudio(saved);
    }

    /** EE : texte JSON. */
    @PostMapping(value = "/api/production-submissions", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ProductionSubmissionDto submitText(@Valid @RequestBody SubmitProductionTextRequest req) {
        UUID userId = currentUser.getId();
        ProductionTask task = loadTask(req.productionTaskId());
        if (task.getEpreuve() != EpreuveType.TCF_EE) {
            throw new BusinessException("Cette route attend une tache TCF_EE ; reçu " + task.getEpreuve());
        }
        enforceQuota(userId, task.getEpreuve());
        ProductionSubmission saved = evaluationService.submitAndEvaluate(
            userId, req.productionTaskId(), req.attemptId(), null, req.texte()
        );
        return mapper.toDto(saved);
    }

    /** Relancer une submission FAILED (max 3 retries, controles dans le service). */
    @PostMapping("/api/production-submissions/{id}/retry")
    public ProductionSubmissionDto retry(@PathVariable UUID id) {
        UUID userId = currentUser.getId();
        ProductionSubmission saved = evaluationService.retry(id, userId);
        return saved.getMediaUrl() != null ? mapper.toDtoWithSignedAudio(saved) : mapper.toDto(saved);
    }

    /** Detail d'une submission : reserve au proprietaire (l'admin a sa propre route). */
    @Transactional(readOnly = true)
    @GetMapping("/api/production-submissions/{id}")
    public ProductionSubmissionDto detail(@PathVariable UUID id) {
        ProductionSubmission sub = submissionRepository.findById(id)
            .orElseThrow(() -> new NotFoundException("Submission introuvable : " + id));
        UUID userId = currentUser.getId();
        if (sub.getUser() == null || !sub.getUser().getId().equals(userId)) {
            // 404 plutot que 403 : ne pas revealer l'existence des submissions d'autrui.
            throw new NotFoundException("Submission introuvable : " + id);
        }
        return sub.getMediaUrl() != null ? mapper.toDtoWithSignedAudio(sub) : mapper.toDto(sub);
    }

    /** Historique de l'utilisateur, optionnellement filtre par epreuve. */
    @Transactional(readOnly = true)
    @GetMapping("/api/users/me/production-submissions")
    public List<ProductionSubmissionDto> mine(
            @RequestParam(required = false) EpreuveType epreuve,
            @RequestParam(defaultValue = "20") int limit) {
        UUID userId = currentUser.getId();
        int safeLimit = Math.max(1, Math.min(limit, 100));
        List<ProductionSubmission> list = (epreuve == null)
            ? submissionRepository.findByUserIdOrderBySubmittedAtDesc(userId, PageRequest.of(0, safeLimit))
            : submissionRepository.findByUserAndEpreuve(userId, epreuve, PageRequest.of(0, safeLimit));
        return list.stream().map(mapper::toDto).toList();
    }

    /**
     * Derniere submission de l'utilisateur par numero de tache pour un
     * (epreuve, niveau) donne. Renvoie 0 a 3 lignes. Sert au hub d'entrainement
     * pour afficher la derniere note sur chaque card (T1, T2, T3).
     */
    @Transactional(readOnly = true)
    @GetMapping("/api/users/me/production-submissions/last-per-task")
    public List<ProductionSubmissionDto> lastPerTask(
            @RequestParam EpreuveType epreuve,
            @RequestParam String niveau) {
        if (epreuve != EpreuveType.TCF_EO && epreuve != EpreuveType.TCF_EE) {
            throw new BusinessException("epreuve doit etre TCF_EO ou TCF_EE.");
        }
        UUID userId = currentUser.getId();
        List<ProductionSubmission> list = submissionRepository.findLatestPerTask(
            userId, epreuve.name(), niveau.toUpperCase());
        return list.stream()
            .map(s -> s.getMediaUrl() != null ? mapper.toDtoWithSignedAudio(s) : mapper.toDto(s))
            .toList();
    }

    private ProductionTask loadTask(UUID taskId) {
        ProductionTask task = taskRepository.findById(taskId)
            .orElseThrow(() -> new NotFoundException("Tache introuvable : " + taskId));
        if (!task.isActive()) {
            throw new NotFoundException("Tache introuvable : " + taskId);
        }
        return task;
    }

    private void enforceQuota(UUID userId, EpreuveType epreuve) {
        if (subscriptionService.hasTcf(userId)) return;
        long used = submissionRepository.countByUserAndEpreuve(userId, epreuve);
        if (used >= FREE_QUOTA_PER_EPREUVE) {
            throw new AccessDeniedException(
                "Quota gratuit atteint pour " + epreuve + " (" + FREE_QUOTA_PER_EPREUVE
                    + " a vie). Passez Premium pour continuer."
            );
        }
    }
}
