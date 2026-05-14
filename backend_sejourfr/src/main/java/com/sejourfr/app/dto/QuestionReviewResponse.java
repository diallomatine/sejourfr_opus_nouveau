package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;

import java.util.List;
import java.util.UUID;

/**
 * Version "revue" d'une question : inclut l'explication et le flag correct
 * sur chaque choix. À renvoyer uniquement quand l'utilisateur a le droit de
 * voir la correction (question déjà tentée ou favori).
 */
public record QuestionReviewResponse(
        UUID id,
        Module module,
        UUID themeId,
        String themeName,
        Difficulty difficulty,
        QuestionType questionType,
        String statement,
        String passageText,
        String explanation,
        MediaResponse media,
        List<ChoiceReviewResponse> choices
) {}
