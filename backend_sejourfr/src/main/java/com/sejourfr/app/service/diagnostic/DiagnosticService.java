package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.dto.DiagnosticExerciseDto;
import com.sejourfr.app.dto.DiagnosticProductionResultDto;
import com.sejourfr.app.dto.DiagnosticResponse;
import com.sejourfr.app.dto.DiagnosticExempleCibleDto;
import com.sejourfr.app.dto.DiagnosticResultDto;
import com.sejourfr.app.dto.DiagnosticSkillObservationDto;
import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.entity.DiagnosticProductionAnalysis;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.DiagnosticJourneyStatus;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.DiagnosticStep;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.service.ProductionEvaluationService;
import com.sejourfr.app.service.RecommendedExerciseSelector;
import com.sejourfr.app.service.diagnostic.exemplecible.DiagnosticExempleCibleFields;
import com.sejourfr.app.ratelimit.RateLimitGuard;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/** Démarrage idempotent, reprise cross-device et restitution agrégée. */
@Service
@RequiredArgsConstructor
public class DiagnosticService {

    private final DiagnosticProperties properties;
    private final DiagnosticContentResolver content;
    private final DiagnosticSessionManager sessionManager;
    private final DiagnosticSessionCreator sessionCreator;
    private final ProductionSubmissionManager submissionManager;
    private final DiagnosticProductionAnalysisManager analysisManager;
    private final SkillManager skillManager;
    private final RecommendedExerciseSelector exerciseSelector;
    private final ProductionEvaluationService evaluationService;
    private final DiagnosticSessionCoordinator coordinator;
    private final RateLimitGuard rateLimitGuard;

    public DiagnosticResponse current(UUID userId) {
        String code = content.activeCode();
        int version = content.activeVersion(code);
        return sessionManager.findByUserAndVersionWithContent(userId, code, version)
                .map(session -> toResponse(userId, session))
                .orElseGet(() -> notStarted(code, version));
    }

    public DiagnosticResponse startOrResume(UUID userId, ClientPlatform platform) {
        String code = content.activeCode();
        int version = content.activeVersion(code);
        DiagnosticSession existing = sessionManager
                .findByUserAndVersionWithContent(userId, code, version).orElse(null);
        if (existing != null) return toResponse(userId, existing);
        try {
            sessionCreator.create(userId, code, version, platform);
        } catch (DataIntegrityViolationException concurrentStart) {
            // La transaction concurrente gagnante porte l'unique session ; la
            // transaction de ce caller a rollbacké ses deux attempts.
        }
        DiagnosticSession created = sessionManager
                .findByUserAndVersionWithContent(userId, code, version)
                .orElseThrow(() -> new IllegalStateException(
                        "La session diagnostic n'a pas pu être créée ni retrouvée"));
        return toResponse(userId, created);
    }

    public DiagnosticResponse detail(UUID userId, UUID sessionId) {
        DiagnosticSession session = sessionManager.findOwnedWithContent(sessionId, userId)
                .orElseThrow(() -> new NotFoundException("Diagnostic introuvable : " + sessionId));
        return toResponse(userId, session);
    }

    public DiagnosticResponse retryAnalysis(UUID userId, UUID sessionId) {
        rateLimitGuard.checkProductionSubmission(userId);
        int max = properties.getAnalysis().getMaxSessionRetries();
        // Le bean transactionnel séparé prend un verrou pessimiste et committe
        // ANALYZING avant tout déclenchement @Async. Deux POST concurrents ne
        // peuvent ainsi jamais lancer deux pipelines/LLM.
        DiagnosticSessionCoordinator.RetryPlan retry =
                coordinator.beginRetry(sessionId, userId, max);
        for (UUID submissionId : retry.failedSubmissionIds()) {
            evaluationService.retryDiagnostic(submissionId, userId, max);
        }
        if (retry.failedSubmissionIds().isEmpty()) {
            // Les deux analyses peuvent être valides et seul l'assemblage avoir
            // été interrompu. Celui-ci est déterministe et ne coûte aucun appel.
            coordinator.onAnalysisCompleted(retry.assemblyTriggerSubmissionId());
        }
        return detail(userId, sessionId);
    }

    @Transactional(readOnly = true)
    protected DiagnosticResponse toResponse(UUID userId, DiagnosticSession session) {
        ProductionSubmission writtenSubmission = submission(session.getWrittenAttempt().getId());
        ProductionSubmission oralSubmission = submission(session.getOralAttempt().getId());
        DiagnosticResultDto result = session.getStatus() == DiagnosticSessionStatus.COMPLETED
                ? result(userId, session, writtenSubmission, oralSubmission) : null;
        return new DiagnosticResponse(
                session.getId(), session.getDiagnosticCode(), session.getDiagnosticVersion(),
                DiagnosticJourneyStatus.valueOf(session.getStatus().name()),
                step(session, writtenSubmission, oralSubmission),
                exercise(session.getWrittenTask(), session.getWrittenAttempt().getId(), writtenSubmission),
                exercise(session.getOralTask(), session.getOralAttempt().getId(), oralSubmission),
                result, session.getStartedAt(), session.getCompletedAt(), session.getErrorMessage(),
                session.getStatus() == DiagnosticSessionStatus.FAILED
                        && session.getRetryCount() < properties.getAnalysis().getMaxSessionRetries());
    }

    private DiagnosticResponse notStarted(String code, int version) {
        return new DiagnosticResponse(
                null, code, version, DiagnosticJourneyStatus.NOT_STARTED,
                DiagnosticStep.PRESENTATION, null, null, null,
                null, null, null, false);
    }

    private DiagnosticExerciseDto exercise(
            ProductionTask task, UUID attemptId, ProductionSubmission submission) {
        return new DiagnosticExerciseDto(
                task.getId(), attemptId, task.getEpreuve(), task.getTitre(), task.getConsigne(),
                DiagnosticContentResolver.helperText(task.getEpreuve()),
                task.getMotsMin(), task.getMotsMax(), task.getDureeMinSec(), task.getDureeMaxSec(),
                task.getInstructionAudioUrl(), submission == null ? null : submission.getId(),
                submission == null ? null : submission.getStatut());
    }

    private DiagnosticStep step(
            DiagnosticSession session,
            ProductionSubmission written,
            ProductionSubmission oral) {
        if (session.getStatus() == DiagnosticSessionStatus.COMPLETED) return DiagnosticStep.RESULT;
        if (written == null) return DiagnosticStep.WRITTEN;
        if (oral == null) return DiagnosticStep.ORAL;
        return DiagnosticStep.ANALYSIS;
    }

    private DiagnosticResultDto result(
            UUID userId,
            DiagnosticSession session,
            ProductionSubmission writtenSubmission,
            ProductionSubmission oralSubmission) {
        DiagnosticProductionAnalysis writtenAnalysis = analysis(writtenSubmission);
        DiagnosticProductionResultDto written = productionResult(writtenAnalysis);
        DiagnosticProductionResultDto oral = productionResult(analysis(oralSubmission));
        Map<String, DiagnosticSkillObservationDto> observations = new LinkedHashMap<>();
        if (written != null) written.skills().forEach(item -> observations.put(item.skillCode(), item));
        if (oral != null) oral.skills().forEach(item -> observations.put(item.skillCode(), item));

        Map<String, Object> summary = session.getSummaryJson() == null
                ? Map.of() : session.getSummaryJson();
        List<DiagnosticSkillObservationDto> priorities = strings(summary.get("priority_skill_codes"))
                .stream().map(observations::get).filter(Objects::nonNull).limit(3).toList();
        PlanRecommendedExerciseDto next = recommendedAction(userId, observations, priorities);
        return new DiagnosticResultDto(
                written, oral, strings(summary.get("strengths")), priorities,
                nullableText(summary.get("main_priority_explanation")), next,
                exempleCible(writtenAnalysis));
    }

    /**
     * AVANT / APRÈS de la production ÉCRITE, lu tel quel dans le JSON déjà
     * persisté de son analyse — {@code null} quand le second appel best-effort
     * n'a rien produit, ce qui est un cas <b>normal</b> (coupe-circuit, objectif
     * déjà atteint, fournisseur muet, ou analyse antérieure à la mise en
     * service). Aucune migration : le bloc vit dans le {@code jsonb} existant.
     *
     * <p>Le serveur ne recalcule rien ici : {@code original} est déjà la
     * sous-chaîne exacte de la production, résolue depuis le numéro de segment au
     * moment de l'écriture, et chaque {@code extrait} est déjà une sous-chaîne
     * exacte de {@code texte}.
     */
    static DiagnosticExempleCibleDto exempleCible(DiagnosticProductionAnalysis analysis) {
        if (analysis == null || analysis.getAnalysisJson() == null) return null;
        if (!(analysis.getAnalysisJson().get(DiagnosticExempleCibleFields.BLOC)
                instanceof Map<?, ?> bloc)) {
            return null;
        }
        String original = nullableText(bloc.get(DiagnosticExempleCibleFields.ORIGINAL));
        String texte = nullableText(bloc.get(DiagnosticExempleCibleFields.TEXTE));
        if (original == null || texte == null) return null;

        List<DiagnosticExempleCibleDto.Segment> segments = new ArrayList<>();
        if (bloc.get(DiagnosticExempleCibleFields.SEGMENTS) instanceof List<?> items) {
            for (Object raw : items) {
                if (!(raw instanceof Map<?, ?> item)) continue;
                String extrait = nullableText(item.get(DiagnosticExempleCibleFields.EXTRAIT));
                String apport = nullableText(item.get(DiagnosticExempleCibleFields.APPORT));
                if (extrait == null || apport == null) continue;
                segments.add(new DiagnosticExempleCibleDto.Segment(extrait, apport));
            }
        }
        return new DiagnosticExempleCibleDto(original, texte, List.copyOf(segments),
                niveau(bloc.get(DiagnosticExempleCibleFields.NIVEAU_VISE)));
    }

    private static NiveauCecrl niveau(Object raw) {
        String texte = nullableText(raw);
        if (texte == null) return null;
        try {
            return NiveauCecrl.valueOf(texte.toUpperCase());
        } catch (IllegalArgumentException unknown) {
            return null;
        }
    }

    private DiagnosticProductionAnalysis analysis(ProductionSubmission submission) {
        if (submission == null) return null;
        return analysisManager.findBySubmissionId(submission.getId()).orElse(null);
    }

    /**
     * Garantit une action concrète même si aucune priorité n'est assez fiable :
     * on préfère une priorité, puis une compétence à renforcer, puis toute
     * compétence réellement observée, et enfin une compétence de l'allowlist.
     *
     * <p>Le sujet renvoyé pour la compétence retenue est choisi par
     * {@link RecommendedExerciseSelector} — le même code que le Plan, pour que
     * les deux écrans proposent le même exercice, et qui fait avancer le
     * candidat au lieu de lui resservir le sujet de rang 1.
     */
    PlanRecommendedExerciseDto recommendedAction(
            UUID userId,
            Map<String, DiagnosticSkillObservationDto> observations,
            List<DiagnosticSkillObservationDto> priorities) {
        Map<String, DiagnosticSkillObservationDto> candidates = new LinkedHashMap<>();
        priorities.forEach(item -> candidates.putIfAbsent(item.skillCode(), item));
        observations.values().stream()
                .filter(DiagnosticSkillObservationDto::observed)
                .filter(item -> item.status() == LearningPlanSkillStatus.TO_REINFORCE)
                .forEach(item -> candidates.putIfAbsent(item.skillCode(), item));
        observations.values().stream()
                .filter(DiagnosticSkillObservationDto::observed)
                .forEach(item -> candidates.putIfAbsent(item.skillCode(), item));
        observations.values().forEach(
                item -> candidates.putIfAbsent(item.skillCode(), item));

        // Cascade évaluée en lot : les 8 compétences de l'allowlist se résolvent
        // en une requête de compétences + deux du sélecteur, pas 3 par candidat.
        Map<String, Skill> skills = skillManager.findByCodes(candidates.keySet());
        Map<UUID, PlanRecommendedExerciseDto> exercises =
                exerciseSelector.selectAll(userId, candidates.keySet().stream()
                        .map(skills::get).filter(Objects::nonNull).toList());
        for (String code : candidates.keySet()) {
            Skill skill = skills.get(code);
            if (skill == null) continue;
            PlanRecommendedExerciseDto exercise = exercises.get(skill.getId());
            if (exercise != null) return exercise;
        }
        throw new IllegalStateException(
                "Aucun micro-exercice actif pour les compétences du diagnostic");
    }

    private DiagnosticProductionResultDto productionResult(DiagnosticProductionAnalysis analysis) {
        if (analysis == null) return null;
        Map<String, Object> json = analysis.getAnalysisJson();
        List<DiagnosticSkillObservationDto> skills = new ArrayList<>();
        if (json.get("skills") instanceof List<?> items) {
            for (Object raw : items) {
                if (!(raw instanceof Map<?, ?> item)) continue;
                String code = String.valueOf(item.get("skill_code"));
                Skill skill = skillManager.findByCode(code).orElse(null);
                if (skill == null) continue;
                skills.add(new DiagnosticSkillObservationDto(
                        skill.getId(), skill.getCode(), skill.getTitle(), skill.getSection(),
                        Boolean.TRUE.equals(item.get("observed")),
                        LearningPlanSkillStatus.valueOf(String.valueOf(item.get("status"))),
                        nullableText(item.get("evidence")), nullableText(item.get("explanation")),
                        ObservationConfidence.valueOf(String.valueOf(item.get("confidence"))),
                        Boolean.TRUE.equals(item.get("priority"))));
            }
        }
        return new DiagnosticProductionResultDto(
                analysis.getEvaluabilite(),
                analysis.getLevelEstimate(), analysis.getTaskCompletion(),
                analysis.getCommunicationStatus(), nullableText(json.get("summary")),
                strings(json.get("strengths")), strings(json.get("weaknesses")), skills);
    }

    private ProductionSubmission submission(UUID attemptId) {
        return submissionManager.findByAttemptId(attemptId).stream().findFirst().orElse(null);
    }

    private static List<String> strings(Object raw) {
        if (!(raw instanceof List<?> list)) return List.of();
        return list.stream().filter(String.class::isInstance).map(String.class::cast).limit(3).toList();
    }

    private static String nullableText(Object raw) {
        if (raw == null) return null;
        String text = raw.toString().trim();
        return text.isEmpty() ? null : text;
    }
}
