package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.entity.DiagnosticProductionAnalysis;
import com.sejourfr.app.entity.DiagnosticTaskSkill;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.DiagnosticCommunicationStatus;
import com.sejourfr.app.enums.DiagnosticTaskCompletion;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
import com.sejourfr.app.manager.DiagnosticTaskSkillManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.service.EvaluationProductionSegments;
import com.sejourfr.app.service.LearningPlanObservationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Analyse une production avec le contrat sans /20. La même voie explicite
 * observe ensuite les productions standard pour garder le Plan vivant.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DiagnosticProductionAnalysisService {

    private final ProductionSubmissionManager submissionManager;
    private final TranscriptionManager transcriptionManager;
    private final DiagnosticTaskSkillManager diagnosticTaskSkillManager;
    private final SkillManager skillManager;
    private final DiagnosticAnalysisPromptBuilder promptBuilder;
    private final DiagnosticAnalysisLlmClient client;
    private final DiagnosticAnalysisReconciler reconciler;
    private final DiagnosticAnalysisValidator validator;
    private final DiagnosticProductionAnalysisManager analysisManager;
    private final DiagnosticRubricsProvider rubrics;
    private final LearningPlanObservationService observationService;
    private final DiagnosticOralArtifactFilter oralArtifactFilter;

    public DiagnosticProductionAnalysis analyseDiagnostic(UUID submissionId) {
        DiagnosticProductionAnalysis existing = analysisManager.findBySubmissionId(submissionId).orElse(null);
        ProductionSubmission submission = load(submissionId);
        if (!submission.getProductionTask().isDiagnostic()) {
            throw new AiEvaluationException("La submission n'appartient pas au profil diagnostic");
        }
        List<Skill> allowed = diagnosticTaskSkillManager
                .findActiveByTaskId(submission.getProductionTask().getId()).stream()
                .map(DiagnosticTaskSkill::getSkill).toList();
        if (existing != null) {
            finalizeDiagnostic(submission, existing, allowed);
            return existing;
        }

        AnalysisRun run = analyse(submission, true);
        DiagnosticProductionAnalysis entity = toEntity(submission, run);
        try {
            entity = analysisManager.save(entity);
        } catch (DataIntegrityViolationException race) {
            entity = analysisManager.findBySubmissionId(submissionId).orElseThrow(() -> race);
        }
        // En cas de course, la sortie persistée gagnante est la source de vérité
        // pour le statut et les observations, pas la seconde réponse LLM locale.
        finalizeDiagnostic(submission, entity, allowed);
        return entity;
    }

    private void finalizeDiagnostic(
            ProductionSubmission submission,
            DiagnosticProductionAnalysis analysis,
            List<Skill> allowedSkills) {
        // EVALUATED signifie que toute la finalisation durable est terminée.
        // Si l'observation du Plan échoue, le runner posera FAILED et un retry
        // réutilisera l'analyse déjà persistée sans nouvel appel LLM.
        observationService.recordProduction(
                submission, allowedSkills, analysis.getAnalysisJson(), true);
        submission.setStatut(SubmissionStatut.EVALUATED);
        submission.setErreurMessage(null);
        submissionManager.save(submission);
    }

    /**
     * Appel best-effort après la correction TCF standard.
     *
     * <p><b>Plus aucune condition de diagnostic terminé</b> (levée le
     * 2026-08-12) : un candidat qui produit sans avoir passé le diagnostic
     * n'accumulait aucun historique, et tout son travail était perdu le jour où
     * il le passait. Les productions d'examen blanc passent par ici comme les
     * autres — c'est {@code LearningPlanObservationService} qui les distingue
     * ensuite par leur source.
     */
    public void observeStandardProduction(UUID submissionId) {
        ProductionSubmission submission = load(submissionId);
        if (submission.getProductionTask().isDiagnostic()) return;
        AnalysisRun run = analyse(submission, false);
        observationService.recordProduction(submission, run.allowedSkills(), run.normalized(), false);
    }

    private AnalysisRun analyse(ProductionSubmission submission, boolean initialDiagnostic) {
        ProductionTask task = submission.getProductionTask();
        String production = task.getEpreuve() == EpreuveType.TCF_EO
                ? transcriptionManager.findLatestTexteBySubmissionId(submission.getId()).orElse(null)
                : submission.getTexteSoumis();
        if (production == null || production.isBlank()) {
            throw new AiEvaluationException("Production diagnostic vide : " + submission.getId());
        }
        EvaluationProductionSegments segments = EvaluationProductionSegments.of(production, task.getEpreuve());
        if (segments.taille() == 0) {
            throw new AiEvaluationException("Aucun segment de preuve exploitable : " + submission.getId());
        }
        List<Skill> allowed = initialDiagnostic
                ? diagnosticTaskSkillManager.findActiveByTaskId(task.getId()).stream()
                        .map(DiagnosticTaskSkill::getSkill).toList()
                : standardSkills(task);
        if (allowed.isEmpty()) {
            throw new AiEvaluationException("Allowlist de compétences vide pour la tâche " + task.getId());
        }
        String target = submission.getUser().getTargetLevel() == null
                ? null : submission.getUser().getTargetLevel().name();
        String systemPrompt = promptBuilder.buildSystemPrompt();
        String userPrompt = promptBuilder.buildUserPrompt(
                task, allowed, segments, target, initialDiagnostic);

        DiagnosticAnalysisLlmClient.Outcome first = client.analyse(systemPrompt, userPrompt);
        // Réconciliation AVANT validation : le validateur ne juge jamais que la
        // sortie déjà dérivée, donc aucune réparation payée ne peut plus être
        // dépensée pour un champ que le serveur sait recalculer.
        Map<String, Object> analysis = reconciler.reconcile(first.analysis(), allowed);
        List<String> violations = validator.violations(analysis, allowed, segments);
        DiagnosticAnalysisLlmClient.Outcome accepted = first;
        if (!violations.isEmpty()) {
            log.warn("Sortie diagnostic invalide submission={} — réparation unique : {}",
                    submission.getId(), violations);
            String repair = promptBuilder.buildRepairPrompt(userPrompt, violations, analysis);
            DiagnosticAnalysisLlmClient.Outcome second = client.analyse(systemPrompt, repair);
            analysis = reconciler.reconcile(second.analysis(), allowed);
            List<String> remaining = validator.violations(analysis, allowed, segments);
            if (!remaining.isEmpty()) {
                throw new AiEvaluationException(
                        "Sortie diagnostic invalide après réparation : " + String.join(" ; ", remaining));
            }
            accepted = new DiagnosticAnalysisLlmClient.Outcome(
                    second.analysis(), sum(first.inputTokens(), second.inputTokens()),
                    sum(first.cachedInputTokens(), second.cachedInputTokens()),
                    sum(first.outputTokens(), second.outputTokens()),
                    sum(first.costEstimateMicroUsd(), second.costEstimateMicroUsd()));
        }
        Map<String, Object> normalized = validator.normalize(analysis, segments);
        // APRÈS le validateur, jamais dedans : une purge retire une phrase du
        // rapport, elle ne doit pas pouvoir rendre une session FAILED. Le filtre
        // n'agit qu'à l'ORAL et ne lève jamais (cf. DiagnosticOralArtifactFilter).
        oralArtifactFilter.purge(normalized, task.getEpreuve(), production);
        return new AnalysisRun(normalized, allowed, accepted);
    }

    private List<Skill> standardSkills(ProductionTask task) {
        SkillSection section = task.getEpreuve() == EpreuveType.TCF_EO
                ? SkillSection.EO : SkillSection.EE;
        Short number = task.getTacheNumero();
        if (number == null) return List.of();
        SkillTaskCode code = SkillTaskCode.parse(section.name() + number);
        return code == null ? List.of() : skillManager.findActiveByTaskCode(code);
    }

    private ProductionSubmission load(UUID submissionId) {
        return submissionManager.findByIdWithTaskAndUser(submissionId)
                .orElseThrow(() -> new NotFoundException("Submission introuvable : " + submissionId));
    }

    private DiagnosticProductionAnalysis toEntity(ProductionSubmission submission, AnalysisRun run) {
        Map<String, Object> output = run.normalized();
        DiagnosticProductionAnalysis entity = new DiagnosticProductionAnalysis();
        entity.setSubmission(submission);
        entity.setAnalysisJson(output);
        entity.setLevelEstimate(NiveauCecrl.valueOf(output.get("level_estimate").toString()));
        entity.setTaskCompletion(DiagnosticTaskCompletion.valueOf(
                output.get("task_completion").toString()));
        entity.setCommunicationStatus(DiagnosticCommunicationStatus.valueOf(
                output.get("communication_status").toString()));
        entity.setModelUsed(client.getModelName());
        entity.setSchemaVersion(client.getToolSchemaVersion() + "/" + rubrics.version());
        entity.setTokensInput(run.outcome().inputTokens());
        entity.setTokensInputCacheHit(run.outcome().cachedInputTokens());
        entity.setTokensOutput(run.outcome().outputTokens());
        entity.setCostMicroUsd(run.outcome().costEstimateMicroUsd());
        return entity;
    }

    private static Integer sum(Integer first, Integer second) {
        if (first == null) return second;
        if (second == null) return first;
        return first + second;
    }

    private record AnalysisRun(
            Map<String, Object> normalized,
            List<Skill> allowedSkills,
            DiagnosticAnalysisLlmClient.Outcome outcome) {}
}
