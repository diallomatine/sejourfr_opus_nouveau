package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;

import java.util.List;
import java.util.UUID;

/**
 * Représentation publique d'une question pour le runner.
 * <p>
 * Ne contient PAS le champ 'correct' des choix : on ne veut pas que le client
 * puisse tricher en lisant la réponse depuis la réponse JSON.
 * <p>
 * L'explication est renvoyée à la fin (review/finish) ou au moment de la
 * correction immédiate en TRAINING via {@link AnswerResultResponse}.
 */
public record QuestionPublicResponse(
        UUID id,
        Module module,
        UUID themeId,
        String themeName,
        Difficulty difficulty,
        QuestionType questionType,
        String statement,
        String explanation,
        String passageText,
        MediaResponse media,
        // Second média audio, renseigné uniquement pour les questions CO_IMAGE
        // (media = image support, audioMedia = audio des 4 propositions lues).
        MediaResponse audioMedia,
        List<ChoicePublicResponse> choices
) {
}
