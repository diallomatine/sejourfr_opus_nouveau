package com.sejourfr.app.dto;

import java.util.List;
import java.util.UUID;

/**
 * Rapport d'une question du lot. Les champs derives ({@code themeCode} resolu,
 * {@code transcriptText}, dimensions) sont {@code null} quand la donnee source
 * est fautive. {@code draftId} et {@code imageUrl} ne sont renseignes qu'apres
 * un import reussi.
 */
public record CoImageImportQuestionReport(
        int index,
        String externalId,
        boolean ok,
        String level,
        String themeCode,
        String themeName,
        String image,
        String imageFormat,
        Integer imageWidth,
        Integer imageHeight,
        Long imageSizeBytes,
        String sceneDescription,
        List<ChoicePreview> choices,
        String correctAnswer,
        String explanation,
        String transcriptText,
        List<CoImageImportError> errors,
        UUID draftId,
        String imageUrl
) {
    /** Une proposition telle qu'elle sera lue ({@code letter} = lettre annoncee dans l'audio). */
    public record ChoicePreview(String letter, String text, boolean correct) {}
}
