package com.sejourfr.app.service;

import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.service.versionciblee.ProductionVersionCibleeService;
import com.sejourfr.app.service.diagnostic.DiagnosticProductionAnalysisService;
import com.sejourfr.app.service.diagnostic.DiagnosticSessionCoordinator;
import com.sejourfr.app.service.diagnostic.DiagnosticSessionFailureRecorder;
import com.sejourfr.app.service.diagnostic.exemplecible.DiagnosticExempleCibleService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.concurrent.CompletableFuture;
import java.util.UUID;

/**
 * Exécute le pipeline IA (Whisper + Claude) en arrière-plan après la
 * persistance d'une {@link ProductionSubmission}. Le caller
 * ({@link ProductionEvaluationService#submitAndEvaluate}) déclenche cet
 * appel via le proxy Spring, ce qui garantit que {@code @Async} prend
 * effet (impossible si on s'appelait soi-même dans la même classe).
 *
 * <p>Conséquence pour le mobile : POST /api/production-submissions
 * répond en ~500 ms (persistance + upload R2 pour EO), et l'évaluation
 * Claude tourne en parallèle pendant que l'utilisateur enchaîne sur la
 * tâche suivante. Le mobile poll ensuite {@code GET /api/full-tcf-exams/{id}}
 * pour récupérer l'état des submissions au fur et à mesure (SUBMITTED →
 * EVALUATING → EVALUATED ou FAILED).
 *
 * <p><b>Robustesse</b> : tout exception est attrapée et la submission
 * passe à {@code FAILED} avec un message tronqué — le mobile peut relancer
 * via {@code POST /api/production-submissions/{id}/retry}. Aucune
 * exception ne remonte au {@code TaskExecutor} Spring (qui les loggerait
 * mais ne pourrait rien faire).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProductionPipelineAsyncRunner {

    private final ProductionSubmissionManager submissionManager;
    private final TranscriptionManager transcriptionManager;
    private final WhisperTranscriptionService whisperService;
    private final AiEvaluationService aiEvaluationService;
    private final ProductionPipelineFailureRecorder failureRecorder;
    private final ProductionVersionCibleeService versionCibleeService;
    private final DiagnosticProductionAnalysisService diagnosticAnalysisService;
    private final DiagnosticSessionCoordinator diagnosticSessionCoordinator;
    private final DiagnosticSessionFailureRecorder diagnosticFailureRecorder;
    private final DiagnosticExempleCibleService diagnosticExempleCibleService;

    /**
     * Lance le pipeline d'évaluation IA en arrière-plan. Re-fetch la
     * submission pour éviter tout problème de session Hibernate entre
     * threads (la session du thread d'origine est fermée quand on arrive
     * ici).
     */
    @Async
    public CompletableFuture<Void> runPipelineAsync(UUID submissionId, boolean estOral) {
        // Pas de transaction englobante ici : Whisper et l'evaluation portent
        // chacune leur propre transaction. Si l'une echoue, son interceptor
        // peut marquer SA transaction rollback-only sans empoisonner le catch
        // de l'orchestrateur avec un UnexpectedRollbackException au retour.
        // JOIN FETCH initialise la task avant de detacher la submission.
        ProductionSubmission submission = submissionManager.findByIdWithTask(submissionId).orElse(null);
        if (submission == null) {
            log.warn("Submission introuvable pour pipeline async : {}", submissionId);
            return CompletableFuture.completedFuture(null);
        }
        EpreuveType epreuve = submission.getProductionTask().getEpreuve();
        try {
            if (submission.isDiagnostic() != submission.getProductionTask().isDiagnostic()) {
                throw new AiEvaluationException("Purpose diagnostic incohérent avec la tâche");
            }
            if (submission.isDiagnostic()) {
                // Synchronise IN_PROGRESS/ANALYZING dès la persistance de la
                // seconde production, avant les appels externes potentiellement longs.
                diagnosticSessionCoordinator.onAnalysisCompleted(submission.getId());
            }
            if (estOral) {
                boolean hasTranscription = transcriptionManager
                        .existsBySubmissionId(submission.getId());
                if (!hasTranscription) {
                    whisperService.transcribe(submission.getId());
                } else {
                    submission.setStatut(SubmissionStatut.EVALUATING);
                    submissionManager.save(submission);
                }
            } else {
                submission.setStatut(SubmissionStatut.EVALUATING);
                submissionManager.save(submission);
            }
            // Bifurcation sur un purpose PERSISTÉ. Un sujet diagnostic ne doit
            // jamais atteindre AiEvaluationService, ai_evaluations, la version
            // ciblée, le profil de niveau ou la calibration /20.
            if (submission.isDiagnostic()) {
                diagnosticAnalysisService.analyseDiagnostic(submission.getId());
                diagnosticSessionCoordinator.onAnalysisCompleted(submission.getId());
                log.info("Pipeline diagnostic OK pour submission {} (epreuve={})",
                        submissionId, epreuve);
                // SECOND APPEL LLM, totalement separe de l'analyse : la phrase du
                // candidat reecrite au niveau qu'il VISE (ECRIT seulement — la
                // production orale n'est jamais reecrite). Lance APRES que
                // l'analyse est persistee et la session assemblee, et hors de
                // toute transaction — comme le reste de ce runner.
                //
                // /!\ INVARIANT : il ne doit JAMAIS faire echouer un diagnostic
                // deja obtenu, ni retrograder une session COMPLETED. Le service
                // avale toutes ses exceptions ; le catch ci-dessous, qui poserait
                // FAILED, est un filet supplementaire dont on ne veut pas
                // dependre — d'ou l'appel deliberement place apres le log de
                // succes, sur une analyse deja commitee.
                diagnosticExempleCibleService.enrichir(submissionId);
                return CompletableFuture.completedFuture(null);
            }
            AiEvaluation eval = aiEvaluationService.evaluate(submission.getId());
            if (eval == null) {
                throw new AiEvaluationException(
                        "Evaluation Claude n'a pas produit de resultat.");
            }
            log.info("Pipeline async OK pour submission {} (epreuve={})",
                    submissionId, epreuve);
            // SECOND APPEL LLM, totalement separe de la correction : la reponse
            // du candidat reecrite au niveau qu'il VISE (EE seulement). Lance
            // APRES que l'evaluation est persistee et EVALUATED, et hors de
            // toute transaction — comme le reste de ce runner.
            //
            // /!\ INVARIANT : il ne doit JAMAIS faire echouer une correction
            // deja obtenue. Le service avale toutes ses exceptions ; le catch
            // ci-dessous, qui poserait FAILED, est un filet supplementaire dont
            // on ne veut pas dependre — d'ou l'appel deliberement place apres
            // le log de succes, sur une evaluation deja commitee.
            versionCibleeService.enrichir(submissionId);

            // Le Plan reste vivant grâce à une voie structurée explicite avec
            // skill IDs. Un échec de cet enrichissement ne dégrade jamais la
            // correction /20 déjà obtenue.
            try {
                diagnosticAnalysisService.observeStandardProduction(submissionId);
            } catch (Exception observationError) {
                log.warn("Observation Plan ignorée pour submission {} : {}",
                        submissionId, observationError.getMessage());
            }
        } catch (Exception e) {
            log.warn("Pipeline async FAILED pour submission {} : {}",
                    submissionId, e.getMessage(), e);
            // Toujours une transaction NEUVE : elle isole aussi FAILED d'un
            // futur changement transactionnel dans un service appele.
            failureRecorder.markFailed(submissionId, e.getMessage());
            if (submission.isDiagnostic() || submission.getProductionTask().isDiagnostic()) {
                diagnosticFailureRecorder.markFailedByAttempt(
                        submission.getAttempt().getId(), e.getMessage());
            }
        }
        return CompletableFuture.completedFuture(null);
    }
}
