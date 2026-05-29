package com.sejourfr.app.dto;

import java.util.List;
import java.util.UUID;

public record UserStatsResponse(
        int attemptsTotal,
        int questionsAnswered,
        int questionsCorrect,
        double successRate,
        List<ThemeStatsResponse> byTheme
) {

    /**
     * Stats par thème pour un utilisateur.
     * - {@code answered} : nombre de questions DISTINCTES du thème déjà tentées
     * - {@code correct}  : nombre de questions DISTINCTES du thème réussies au moins une fois
     * - {@code total}    : nombre total de questions actives dans le thème
     * Le front calcule le score de maîtrise (= correct / total) pour la barre de progression.
     */
    public record ThemeStatsResponse(
            UUID themeId,
            /**
             * Code stable du thème (ex: {@code CIV_PRINCIPES}, {@code TCF_CO},
             * {@code TCF_STRUCTURE}). Utilisé par le front pour router vers
             * l'écran détail correspondant — plus fiable que matcher sur le
             * {@code themeName} libellé.
             */
            String themeCode,
            String themeName,
            int answered,
            int correct,
            int total
    ) {}
}
