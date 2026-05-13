package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Module;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record AttemptResponse(
        UUID id,
        AttemptType type,
        Module module,
        Integer totalQuestions,
        Integer timeLimitSeconds,
        Integer passThreshold,
        Instant startedAt,
        Instant finishedAt,
        Integer score,
        List<AttemptQuestionResponse> questions
) {}
