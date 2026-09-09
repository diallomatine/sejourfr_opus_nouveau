package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanChangeDto;
import com.sejourfr.app.dto.ProductionBilanResponse;
import com.sejourfr.app.dto.ProductionSubmissionDto;
import com.sejourfr.app.dto.ProductionTaskDto;
import com.sejourfr.app.dto.SubmitProductionTextRequest;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.mapper.ProductionSubmissionMapper;
import com.sejourfr.app.mapper.ProductionTaskMapper;
import com.sejourfr.app.ratelimit.RateLimitGuard;
import com.sejourfr.app.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;
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

    private static final int MIN_LIMIT = 1;
    private static final int MAX_LIMIT = 100;

    private final ProductionEvaluationService evaluationService;
    private final ProductionSubmissionManager submissionManager;
    private final AttemptManager attemptManager;
    private final ProductionTaskManager taskManager;
    private final ProductionSubmissionMapper mapper;
    private final ProductionTaskMapper taskMapper;
    private final CurrentUser currentUser;
    private final ProductionBilanService bilanService;
    private final ProductionExamCompositionService compositionService;
    private final ProductionAccessService accessService;
    private final RateLimitGuard rateLimitGuard;
    private final LearningPlanService learningPlanService;

    public ProductionSubmissionDto submitAudio(UUID productionTaskId, UUID attemptId,
                                               MultipartFile audio, UUID clientSubmissionId) {
        UUID userId = currentUser.getId();

        // REJEU D'ABORD, AVANT TOUT LE RESTE. Une soumission deja rendue sous
        // cette cle ne doit ni etre rate-limitee, ni reverifier un quota deja
        // consomme, ni surtout repayer Whisper puis le correcteur. C'est tout
        // l'objet de la cle : la seconde requete est la MEME requete.
        ProductionSubmissionDto rejeu = rejeu(userId, clientSubmissionId);
        if (rejeu != null) {
            return rejeu;
        }

        // Garde-fou cout LLM (Whisper + Claude/OpenAI) : borne le volume absolu
        // par utilisateur, tous tiers. Le quota freemium reste gere par
        // enforceQuota ; ceci ne fait que couper l'abus (boucle, compte premium
        // qui martele l'endpoint de notation).
        rateLimitGuard.checkProductionSubmission(userId);
        ProductionTask task = loadSubmittableTask(productionTaskId);
        assertEpreuve(task, EpreuveType.TCF_EO);
        enforceQuota(userId, task, attemptId);

        ProductionSubmission saved = evaluationService.submitAndEvaluate(
                userId, productionTaskId, attemptId, audio, null, clientSubmissionId);
        return mapper.toDto(saved);
    }

    public ProductionSubmissionDto submitText(SubmitProductionTextRequest req) {
        UUID userId = currentUser.getId();

        ProductionSubmissionDto rejeu = rejeu(userId, req.clientSubmissionId());
        if (rejeu != null) {
            return rejeu;
        }

        rateLimitGuard.checkProductionSubmission(userId);
        ProductionTask task = loadSubmittableTask(req.productionTaskId());
        assertEpreuve(task, EpreuveType.TCF_EE);
        enforceQuota(userId, task, req.attemptId());

        ProductionSubmission saved = evaluationService.submitAndEvaluate(
                userId, req.productionTaskId(), req.attemptId(), null, req.texte(),
                req.clientSubmissionId());
        return mapper.toDto(saved);
    }

    /**
     * La soumission deja rendue sous cette cle d'idempotence, ou {@code null}
     * si c'est la premiere fois (cle absente comprise : un client qui n'en
     * envoie pas garde l'ancien comportement).
     *
     * <p>On rend la ligne <b>telle qu'elle est</b>, quel que soit son statut :
     * une correction encore en cours rend un {@code SUBMITTED}, exactement ce
     * qu'aurait rendu le premier appel. Le client la suit ensuite par son
     * polling habituel.
     */
    private ProductionSubmissionDto rejeu(UUID userId, UUID clientSubmissionId) {
        return submissionManager.findByClientKey(userId, clientSubmissionId)
                .map(mapper::toDto)
                .orElse(null);
    }

    public ProductionSubmissionDto retry(UUID submissionId) {
        UUID userId = currentUser.getId();
        ProductionSubmission saved = evaluationService.retry(submissionId, userId);
        return mapper.toDto(saved);
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
        return mapper.toDto(sub).withPlanChange(planChange(userId, sub));
    }

    /**
     * Ce que cette production a change dans le Plan, resolu <b>a la lecture</b>.
     *
     * <p>Rien avant l'evaluation (il n'y a alors aucune observation), rien sur un
     * sujet de diagnostic (qui a son propre ecran de resultat agrege). Un bloc
     * absent reste un cas <b>normal</b> : les observations sont ecrites apres la
     * correction, en best-effort — le front qui poll ce detail le recevra des
     * qu'elles seront la, sans erreur ni rejeu entre-temps.
     */
    private PlanChangeDto planChange(UUID userId, ProductionSubmission sub) {
        if (sub.getStatut() != SubmissionStatut.EVALUATED) return null;
        ProductionTask task = sub.getProductionTask();
        if (task == null || task.isDiagnostic()) return null;
        return learningPlanService.changeAfterProduction(userId, sub.getId()).orElse(null);
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
        return list.stream().map(mapper::toDto).toList();
    }

    /**
     * Bilan serveur d'une session production. Le niveau CECRL d'épreuve n'est
     * calculé que pour une session d'examen blanc ({@code slotNumber} posé ou
     * sous-attempt d'un examen TCF complet) dont les 3 tâches sont évaluées —
     * jamais pour un entraînement libre.
     */
    @Transactional(readOnly = true)
    public ProductionBilanResponse bilan(UUID attemptId) {
        Attempt attempt = loadOwnProductionAttempt(attemptId);
        EpreuveType epreuve = attempt.getEpreuve();
        boolean exam = ProductionAccessService.isExamSession(attempt);
        boolean finished = attempt.getFinishedAt() != null;

        List<ProductionSubmission> submissions = submissionManager.findByAttemptId(attemptId);
        boolean inFlight = false;
        boolean anyFailed = false;
        for (ProductionSubmission s : submissions) {
            if (s.getStatut() == SubmissionStatut.FAILED) {
                anyFailed = true;
            } else if (s.getStatut() != SubmissionStatut.EVALUATED) {
                inFlight = true;
            }
        }
        Map<Integer, AiEvaluation> evalsByTache = bilanService.latestEvalsByTache(submissions);
        int evaluatedCount = evalsByTache.size();

        // Niveau d'épreuve : examen complet → moyenne pondérée des 3 tâches ;
        // examen terminé incomplet (chrono écoulé, abandon) sans pipeline IA
        // en cours ni FAILED à retenter → tâches manquantes comptées 0.
        NiveauCecrl niveauGlobal = null;
        // Épreuve écourtée : les tâches jamais rendues comptent 0 — dans le
        // niveau ET dans la note, sinon le bilan afficherait une note calculée
        // sur deux tâches à côté d'un niveau calculé sur trois.
        boolean manquantesAZero = false;
        if (exam && evaluatedCount >= ProductionBilanService.EXPECTED_TASKS_PER_EPREUVE) {
            niveauGlobal = bilanService.bilanEpreuve(evalsByTache);
        } else if (exam && finished && !inFlight && !anyFailed) {
            niveauGlobal = bilanService.bilanEpreuveTerminee(evalsByTache);
            manquantesAZero = true;
        }
        return new ProductionBilanResponse(
                attemptId,
                epreuve,
                exam,
                attempt.getSlotNumber(),
                finished,
                evaluatedCount,
                ProductionBilanService.EXPECTED_TASKS_PER_EPREUVE,
                bilanService.noteEpreuve(evalsByTache, manquantesAZero),
                niveauGlobal,
                bilanService.correspondanceTcf(niveauGlobal));
    }

    /**
     * Les 3 sujets (T1, T2, T3) composés pour une session d'examen blanc
     * production — composition déterministe backend (cf.
     * {@link ProductionExamCompositionService}). 400 sur un attempt
     * d'entraînement libre (le candidat y choisit son sujet).
     */
    @Transactional(readOnly = true)
    public List<ProductionTaskDto> examTasks(UUID attemptId) {
        Attempt attempt = loadOwnProductionAttempt(attemptId);
        return compositionService.composeFor(attempt).stream()
                .map(taskMapper::toDto)
                .toList();
    }

    private Attempt loadOwnProductionAttempt(UUID attemptId) {
        UUID userId = currentUser.getId();
        Attempt attempt = attemptManager.findById(attemptId)
                .orElseThrow(() -> new NotFoundException("Attempt introuvable : " + attemptId));
        if (attempt.getUser() == null || !attempt.getUser().getId().equals(userId)) {
            // 404 plutot que 403 : ne pas reveler l'existence des attempts d'autrui.
            throw new NotFoundException("Attempt introuvable : " + attemptId);
        }
        EpreuveType epreuve = attempt.getEpreuve();
        if (epreuve != EpreuveType.TCF_EE && epreuve != EpreuveType.TCF_EO) {
            throw new BusinessException("Cet endpoint attend un attempt TCF_EE ou TCF_EO.");
        }
        return attempt;
    }

    private ProductionTask loadActiveTask(UUID taskId) {
        return taskManager.findActiveById(taskId)
                .orElseThrow(() -> new NotFoundException("Tache introuvable : " + taskId));
    }

    private ProductionTask loadSubmittableTask(UUID taskId) {
        return taskManager.findById(taskId)
                .filter(ProductionTask::isActive)
                .orElseThrow(() -> new NotFoundException("Tache introuvable : " + taskId));
    }

    private void assertEpreuve(ProductionTask task, EpreuveType expected) {
        if (task.getEpreuve() != expected) {
            throw new BusinessException("Cette route attend une tache " + expected + " ; recu " + task.getEpreuve());
        }
    }

    /**
     * Budget freemium EE/EO — délégué à {@link ProductionAccessService} pour
     * que la voie temps réel applique exactement la même règle.
     */
    private void enforceQuota(UUID userId, EpreuveType epreuve, UUID attemptId) {
        accessService.enforceQuota(userId, epreuve, attemptId);
    }

    private void enforceQuota(UUID userId, ProductionTask task, UUID attemptId) {
        accessService.enforceQuota(userId, task, attemptId);
    }

    private int clampLimit(int limit) {
        return Math.max(MIN_LIMIT, Math.min(limit, MAX_LIMIT));
    }
}
