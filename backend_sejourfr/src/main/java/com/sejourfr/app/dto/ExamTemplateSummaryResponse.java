package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;

import java.util.UUID;

/**
 * Payload public pour la liste GET /api/exams.
 * Pas de questions ni de règles : c'est juste la vitrine.
 */
public record ExamTemplateSummaryResponse(
        UUID id,
        String slug,
        Module module,
        TargetProcedure targetProcedure,
        TargetLevel targetLevel,
        String name,
        String subtitle,
        String description,
        int durationSeconds,
        int totalQuestions,
        int passingScore,
        boolean free,
        int position
) {}
