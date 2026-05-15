package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/**
 * Payload pour POST /api/attempts.
 *
 * Deux modes de démarrage :
 *   1. examTemplateId fourni → MOCK_EXAM piloté par un ExamTemplate.
 *      Les autres filtres (themeId, difficulty, questionType, size) sont
 *      ignorés au profit des ExamTemplateRule du template.
 *   2. examTemplateId null → comportement historique :
 *      - TRAINING / REVIEW : tirage filtré (themeId/difficulty/questionType/size)
 *      - MOCK_EXAM         : tirage aléatoire dans le module avec config par
 *                            défaut (40 questions CIVIQUE, 60 questions TCF).
 */
public record StartAttemptRequest(
        @NotNull AttemptType type,
        @NotNull Module module,
        UUID examTemplateId,
        UUID themeId,
        Difficulty difficulty,
        QuestionType questionType,
        Integer size
) {}
