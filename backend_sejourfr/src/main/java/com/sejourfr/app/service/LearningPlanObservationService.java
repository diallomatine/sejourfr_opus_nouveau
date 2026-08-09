package com.sejourfr.app.service;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.service.competence.CompetenceAnalysisFields;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Écrit les signaux sourcés qui alimentent le Plan, sans heuristique textuelle. */
@Service
@RequiredArgsConstructor
public class LearningPlanObservationService {

    private final LearningPlanObservationManager observationManager;
    private final DiagnosticSessionManager diagnosticSessionManager;
    private final UserSkillAttemptManager skillAttemptManager;

    public boolean hasActivePlan(UUID userId) {
        return diagnosticSessionManager.findLatestCompleted(userId).isPresent();
    }

    public void recordProduction(
            ProductionSubmission submission,
            List<Skill> allowedSkills,
            Map<String, Object> analysis,
            boolean baseline) {
        Map<String, Skill> skillsByCode = new LinkedHashMap<>();
        allowedSkills.forEach(skill -> skillsByCode.put(skill.getCode(), skill));
        LearningPlanSourceType sourceType = sourceType(submission, baseline);
        Object raw = analysis.get("skills");
        if (!(raw instanceof List<?> observations)) return;
        for (Object item : observations) {
            if (!(item instanceof Map<?, ?> value)) continue;
            Skill skill = skillsByCode.get(text(value.get("skill_code")));
            if (skill == null) continue;
            if (observationManager.findBySource(
                    submission.getUser().getId(), skill.getId(), sourceType, submission.getId()).isPresent()) {
                continue;
            }
            LearningPlanSkillStatus status = LearningPlanSkillStatus.valueOf(text(value.get("status")));
            boolean observed = Boolean.TRUE.equals(value.get("observed"));
            LearningPlanObservation observation = new LearningPlanObservation();
            observation.setUser(submission.getUser());
            observation.setSkill(skill);
            observation.setSourceType(sourceType);
            observation.setSourceId(submission.getId());
            observation.setObserved(observed);
            observation.setStatus(status);
            observation.setEvidence(observed ? nullableText(value.get("evidence")) : null);
            observation.setExplanation(nullableText(value.get("explanation")));
            observation.setConfidence(ObservationConfidence.valueOf(text(value.get("confidence"))));
            observation.setBaseline(baseline);
            observation.setObservedAt(Instant.now());
            saveIdempotently(observation);
        }
    }

    /**
     * Un micro-exercice ciblé affine la priorité, mais une réussite unique ne
     * déclare jamais la compétence SOLID. La confirmation doit venir ensuite
     * d'une production complète indépendante.
     */
    public void recordSkillAttempt(UUID attemptId) {
        UserSkillAttempt attempt = skillAttemptManager.findByIdWithPrompt(attemptId).orElse(null);
        if (attempt == null || attempt.getStatut() != SkillAttemptStatut.EVALUATED
                || attempt.getCriterionStatus() == null
                || !hasActivePlan(attempt.getUser().getId())) {
            return;
        }
        Skill skill = attempt.getSkillPrompt().getSkill();
        if (observationManager.findBySource(attempt.getUser().getId(), skill.getId(),
                LearningPlanSourceType.SKILL_TRAINING, attemptId).isPresent()) return;

        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setUser(attempt.getUser());
        observation.setSkill(skill);
        observation.setSourceType(LearningPlanSourceType.SKILL_TRAINING);
        observation.setSourceId(attemptId);
        observation.setObserved(true);
        observation.setStatus(attempt.getCriterionStatus() == SkillCriterionStatus.VALIDATED
                ? LearningPlanSkillStatus.TO_REINFORCE : LearningPlanSkillStatus.PRIORITY);
        String production = attempt.getWrittenProduction() != null
                ? attempt.getWrittenProduction() : attempt.getTranscript();
        observation.setEvidence(truncate(production, 500));
        Map<String, Object> result = attempt.getAnalysisJson();
        observation.setExplanation(result == null ? null
                : nullableText(result.get(CompetenceAnalysisFields.IMPROVEMENT_PRIORITY)));
        observation.setConfidence(ObservationConfidence.MEDIUM);
        observation.setBaseline(false);
        observation.setObservedAt(attempt.getUpdatedAt());
        saveIdempotently(observation);
    }

    private static LearningPlanSourceType sourceType(
            ProductionSubmission submission, boolean baseline) {
        boolean oral = submission.getProductionTask().getEpreuve() == EpreuveType.TCF_EO;
        if (baseline) return oral
                ? LearningPlanSourceType.DIAGNOSTIC_EO : LearningPlanSourceType.DIAGNOSTIC_EE;
        return oral ? LearningPlanSourceType.PRODUCTION_EO : LearningPlanSourceType.PRODUCTION_EE;
    }

    private static String text(Object value) { return value == null ? "" : value.toString().trim(); }
    private static String nullableText(Object value) {
        String text = text(value);
        return text.isEmpty() ? null : text;
    }
    private static String truncate(String value, int max) {
        if (value == null) return null;
        String clean = value.strip();
        return clean.length() <= max ? clean : clean.substring(0, max);
    }

    private void saveIdempotently(LearningPlanObservation observation) {
        try {
            observationManager.save(observation);
        } catch (DataIntegrityViolationException concurrentDuplicate) {
            // uq_learning_plan_observation_source : un retry ou deux workers
            // concurrents aboutissent au même signal, jamais à un doublon.
        }
    }
}
