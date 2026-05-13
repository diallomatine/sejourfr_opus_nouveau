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
 * - type : TRAINING (entraînement libre) ou MOCK_EXAM (examen blanc) ou REVIEW (révision).
 * - module : CIVIQUE ou TCF.
 * - themeId / difficulty / questionType : filtres optionnels pour TRAINING.
 *   Pour MOCK_EXAM, on prend tout le module et on tire 40 questions au hasard.
 * - size : nombre de questions souhaité pour TRAINING (5/10/20). Ignoré en MOCK_EXAM.
 */
public record StartAttemptRequest(
        @NotNull AttemptType type,
        @NotNull Module module,
        UUID themeId,
        Difficulty difficulty,
        QuestionType questionType,
        Integer size
) {}
