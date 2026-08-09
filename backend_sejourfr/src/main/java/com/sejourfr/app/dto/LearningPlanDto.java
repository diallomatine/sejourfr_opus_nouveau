package com.sejourfr.app.dto;

import com.sejourfr.app.enums.LearningPlanState;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Plan actionnable ; aucune priorité n'est recalculée dans les fronts. */
public record LearningPlanDto(
        LearningPlanState state,
        UUID diagnosticSessionId,
        Instant diagnosticCompletedAt,
        LearningPlanPriorityDto currentPriority,
        List<LearningPlanPriorityDto> nextPriorities,
        List<LearningPlanSkillDto> observedSkills,
        int observedSkillCount,
        int activitiesThisWeek,
        boolean progressionAvailable
) {}
