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

    public record ThemeStatsResponse(
            UUID themeId,
            String themeName,
            int answered,
            int correct,
            int total
    ) {}
}
