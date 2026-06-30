package com.sejourfr.app.service.attempt;

import com.sejourfr.app.dto.QcmAnswerResult;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.service.TcfLevelEstimatorService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Scoring / niveau CECRL d'un attempt QCM. Extrait d'AttemptService —
 * concentre le calcul de niveau atteint, l'estimation par épreuve et le
 * score pondéré, consommés par la finalisation d'un attempt.
 */
@Service
@RequiredArgsConstructor
public class AttemptScoringService {

    // Seuil de reussite par strate pour le calcul du niveau CECRL en TCF.
    // L'utilisateur "atteint" un niveau si son taux de bonnes reponses sur les
    // questions de ce niveau est >= 60 %.
    private static final double TCF_LEVEL_PASS_RATIO = 0.6;

    // Pondération du score par niveau (A2=1, B1=2, B2=3) — applique à la finalisation
    // d'un examen module. Max score = 8*1 + 9*2 + 8*3 = 50.
    private static final int WEIGHT_A2 = 1;
    private static final int WEIGHT_B1 = 2;
    private static final int WEIGHT_B2 = 3;

    private final TcfLevelEstimatorService levelEstimator;

    /**
     * Niveau CECRL atteint : on retient le plus haut niveau A2/B1/B2 ou le
     * taux de bonnes reponses sur les questions de cette strate depasse le
     * seuil {@link #TCF_LEVEL_PASS_RATIO}. Si meme A2 n'est pas atteint,
     * renvoie null.
     */
    public TargetLevel computeLevelAchieved(List<AttemptQuestion> aqs) {
        TargetLevel result = null;
        for (TargetLevel level : List.of(TargetLevel.A2, TargetLevel.B1, TargetLevel.B2)) {
            Difficulty strata = toDifficulty(level);
            long total = aqs.stream()
                    .filter(aq -> aq.getQuestion().getDifficulty() == strata)
                    .count();
            if (total == 0) continue;

            long correct = aqs.stream()
                    .filter(aq -> aq.getQuestion().getDifficulty() == strata)
                    .filter(aq -> aq.getAnswer() != null && Boolean.TRUE.equals(aq.getAnswer().getCorrect()))
                    .count();

            if ((double) correct / total >= TCF_LEVEL_PASS_RATIO) {
                result = level;
            }
        }
        return result;
    }

    private Difficulty toDifficulty(TargetLevel level) {
        return switch (level) {
            case A2 -> Difficulty.A2;
            case B1 -> Difficulty.B1;
            case B2 -> Difficulty.B2;
        };
    }

    /**
     * Niveau d'un examen TCF stratifié : estimation épreuve par épreuve
     * (CO_IMAGE regroupée sous CO), puis plancher — comme au TCF IRN où le
     * niveau global est le plus faible des épreuves. Le détail par épreuve
     * exposé aux fronts est recalculé à la lecture (AttemptMapper).
     */
    public NiveauCecrl estimatePerEpreuveFloor(List<AttemptQuestion> aqs) {
        Map<QuestionType, List<AttemptQuestion>> byEpreuve = new LinkedHashMap<>();
        for (AttemptQuestion aq : aqs) {
            QuestionType t = aq.getQuestion().getQuestionType();
            if (t == null) continue;
            QuestionType key = t == QuestionType.CO_IMAGE ? QuestionType.CO : t;
            byEpreuve.computeIfAbsent(key, k -> new ArrayList<>()).add(aq);
        }
        List<NiveauCecrl> levels = byEpreuve.values().stream()
                .map(group -> levelEstimator.estimateQcm(toQcmResults(group)))
                .toList();
        return levelEstimator.floor(levels);
    }

    private static List<QcmAnswerResult> toQcmResults(List<AttemptQuestion> aqs) {
        return aqs.stream()
                .map(aq -> new QcmAnswerResult(
                        aq.getQuestion().getId(),
                        aq.getQuestion().getDifficulty(),
                        aq.getAnswer() != null && Boolean.TRUE.equals(aq.getAnswer().getCorrect())))
                .toList();
    }

    /** Niveau CECRL → palier TargetLevel exposé en legacy (A1/A1_NON_ATTEINT → null). */
    public static TargetLevel toTargetLevel(NiveauCecrl cecrl) {
        if (cecrl == null) return null;
        return switch (cecrl) {
            case A2 -> TargetLevel.A2;
            case B1 -> TargetLevel.B1;
            case B2 -> TargetLevel.B2;
            default -> null;
        };
    }

    /**
     * Calcule le score pondéré d'un examen module en sommant les poids par
     * niveau des questions correctes (si {@code onlyCorrect}) ou de toutes
     * les questions (= max score atteignable). Poids : A2=1, B1=2, B2=3.
     * Les questions sans niveau (rare) sont ignorées.
     */
    public int computeWeightedScore(List<AttemptQuestion> aqs, boolean onlyCorrect) {
        int total = 0;
        for (AttemptQuestion aq : aqs) {
            Difficulty d = aq.getQuestion().getDifficulty();
            if (d == null) continue;
            if (onlyCorrect && (aq.getAnswer() == null || !Boolean.TRUE.equals(aq.getAnswer().getCorrect()))) {
                continue;
            }
            total += switch (d) {
                case A2 -> WEIGHT_A2;
                case B1 -> WEIGHT_B1;
                case B2 -> WEIGHT_B2;
                default -> 0;
            };
        }
        return total;
    }
}
