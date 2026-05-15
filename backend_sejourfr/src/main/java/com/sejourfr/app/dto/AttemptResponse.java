package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetLevel;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record AttemptResponse(
        UUID id,
        AttemptType type,
        Module module,
        UUID examTemplateId,
        String examTemplateSlug,
        String examTemplateName,
        Integer totalQuestions,
        Integer timeLimitSeconds,
        Integer passThreshold,
        Instant startedAt,
        Instant finishedAt,
        Integer score,
        TargetLevel levelAchieved,
        List<AttemptQuestionResponse> questions
) {}
