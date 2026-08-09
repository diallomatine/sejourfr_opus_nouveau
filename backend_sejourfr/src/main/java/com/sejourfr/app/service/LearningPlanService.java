package com.sejourfr.app.service;

import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.dto.LearningPlanDto;
import com.sejourfr.app.dto.LearningPlanPriorityDto;
import com.sejourfr.app.dto.LearningPlanSkillDto;
import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanState;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.SkillPromptManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Le Plan dit quoi faire maintenant ; les statistiques historiques restent séparées. */
@Service
@RequiredArgsConstructor
public class LearningPlanService {

    private static final ZoneId PARIS = ZoneId.of("Europe/Paris");

    private final DiagnosticProperties diagnosticProperties;
    private final ProductionTaskManager taskManager;
    private final DiagnosticSessionManager sessionManager;
    private final LearningPlanObservationManager observationManager;
    private final SkillPromptManager promptManager;

    @Transactional(readOnly = true)
    public LearningPlanDto get(UUID userId) {
        DiagnosticSession completed = sessionManager.findLatestCompleted(userId).orElse(null);
        if (completed == null) {
            DiagnosticSession inProgress = currentSession(userId);
            return new LearningPlanDto(
                    inProgress == null ? LearningPlanState.NEEDS_DIAGNOSTIC
                            : LearningPlanState.DIAGNOSTIC_IN_PROGRESS,
                    inProgress == null ? null : inProgress.getId(), null,
                    null, List.of(), List.of(), 0, 0, true);
        }

        List<LearningPlanObservation> all = observationManager.findAllByUserWithSkill(userId);
        // Requête triée DESC : le premier signal RÉELLEMENT observé de chaque
        // compétence fait foi. NOT_OBSERVED reste un événement historique
        // utile, mais signifie seulement « aucune preuve dans cette production »
        // et ne contredit donc jamais une preuve antérieure.
        Map<UUID, LearningPlanObservation> latest = new LinkedHashMap<>();
        for (LearningPlanObservation observation : all) {
            if (!observation.isObserved()) continue;
            latest.putIfAbsent(observation.getSkill().getId(), observation);
        }
        List<LearningPlanObservation> actionable = latest.values().stream()
                .filter(item -> item.getStatus() == LearningPlanSkillStatus.PRIORITY
                        || item.getStatus() == LearningPlanSkillStatus.TO_REINFORCE)
                .sorted(Comparator
                        .comparingInt((LearningPlanObservation item) ->
                                item.getStatus() == LearningPlanSkillStatus.PRIORITY ? 0 : 1)
                        .thenComparing(LearningPlanObservation::getObservedAt,
                                Comparator.reverseOrder()))
                .limit(3)
                .toList();
        List<LearningPlanPriorityDto> priorities = actionable.stream().map(this::priority).toList();

        List<LearningPlanSkillDto> observed = latest.values().stream()
                .sorted(Comparator.comparing(LearningPlanObservation::getObservedAt).reversed())
                .limit(8)
                .map(item -> new LearningPlanSkillDto(
                        item.getSkill().getId(), item.getSkill().getCode(), item.getSkill().getTitle(),
                        item.getSkill().getSection(), item.getStatus(), item.getObservedAt()))
                .toList();
        int observedCount = latest.size();
        int activities = Math.toIntExact(observationManager.countSince(userId, startOfWeek()));
        return new LearningPlanDto(
                LearningPlanState.ACTIVE, completed.getId(), completed.getCompletedAt(),
                priorities.isEmpty() ? null : priorities.getFirst(),
                priorities.size() <= 1 ? List.of() : priorities.subList(1, priorities.size()),
                observed, observedCount, activities, true);
    }

    private DiagnosticSession currentSession(UUID userId) {
        String code = diagnosticProperties.getInitialCode();
        Integer version = taskManager.findLatestActiveDiagnosticVersion(code).orElse(null);
        return version == null ? null
                : sessionManager.findByUserAndVersionWithContent(userId, code, version).orElse(null);
    }

    private LearningPlanPriorityDto priority(LearningPlanObservation observation) {
        return new LearningPlanPriorityDto(
                observation.getSkill().getId(), observation.getSkill().getCode(),
                observation.getSkill().getTitle(), observation.getSkill().getSection(),
                observation.getStatus(), observation.getExplanation(), observation.getEvidence(),
                observation.getConfidence(), observation.getObservedAt(),
                recommendedExercise(observation.getSkill()));
    }

    private PlanRecommendedExerciseDto recommendedExercise(Skill skill) {
        SkillPrompt prompt = promptManager.findActiveBySkillId(skill.getId()).stream()
                .findFirst().orElse(null);
        if (prompt == null) return null;
        return new PlanRecommendedExerciseDto(
                prompt.getId(), skill.getId(), skill.getCode(), prompt.getTitle(),
                skill.getSection(), skill.getSection() == com.sejourfr.app.enums.SkillSection.EO ? 5 : 4);
    }

    private static Instant startOfWeek() {
        ZonedDateTime now = ZonedDateTime.now(PARIS);
        return now.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
                .toLocalDate().atStartOfDay(PARIS).toInstant();
    }
}
