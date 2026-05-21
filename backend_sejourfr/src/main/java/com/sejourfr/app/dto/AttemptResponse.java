package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
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
        // Non-null quand l'attempt est un examen module TCF (CO ou CE) — sert
        // au mobile pour appliquer les conditions strictes (audio auto-play
        // 2s, pas de pause, lecture unique, soumission auto à la fin du temps).
        QuestionType moduleExamQuestionType,
        List<AttemptQuestionResponse> questions
) {}
