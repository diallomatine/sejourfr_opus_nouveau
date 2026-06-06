package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
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
        // Thème civique scopé (lotThemeId) — non-null pour les séries et
        // examens thématiques civiques. Sert au web à retrouver l'écran
        // d'origine (retour de session vers /entrainement/civique/{themeId}).
        UUID themeId,
        // Score calibré 100-499 (examens module TCF) + niveau CECRL estimé.
        // Affichage façon relevé TCF (X/499 + niveau) à la place du X/50 interne.
        // Null hors examen module TCF.
        Integer calibratedScore,
        NiveauCecrl cecrlLevel,
        // Détail par épreuve d'un examen TCF stratifié fini (CO/CE…) — le
        // cecrlLevel global ci-dessus est le plancher de ces niveaux, comme
        // au TCF IRN. Vide hors examen TCF ou tant que l'attempt court.
        List<AttemptEpreuveResult> epreuveResults,
        List<AttemptQuestionResponse> questions
) {}
