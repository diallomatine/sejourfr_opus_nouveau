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
 * Scoring d'un attempt QCM : estimation par épreuve et score pondéré,
 * consommés par la finalisation d'un attempt.
 *
 * <p>🛑 <b>Aucune règle de niveau ici.</b> Tout passe par l'autorité unique,
 * {@link TcfLevelEstimatorService} — ce service ne fait que grouper les
 * questions par épreuve et lui demander le palier.
 */
@Service
@RequiredArgsConstructor
public class AttemptScoringService {

    // Pondération du score de progression par palier (A2=1, B1=2, B2=3),
    // appliquée à la finalisation d'un examen module. Max = 10*1 + 8*2 + 7*3 = 47
    // depuis la composition 10 A2 / 8 B1 / 7 B2 (cf. AttemptCompositionService).
    // 🛑 Ce score ne dérive AUCUN palier : c'est une mesure continue de
    // progression, pas un résultat d'examen.
    private static final int WEIGHT_A2 = 1;
    private static final int WEIGHT_B1 = 2;
    private static final int WEIGHT_B2 = 3;

    private final TcfLevelEstimatorService levelEstimator;

    /**
     * Palier legacy {@code level_achieved} d'un entrainement TCF libre, ou les
     * strates ne sont pas garanties.
     *
     * <p>🛑 <b>Il n'y a plus de seconde regle ici.</b> Cette methode portait
     * son propre seuil (60 % par strate, sans monotonie), donc un second
     * verdict de palier a cote de l'estimateur. Elle DELEGUE desormais a
     * l'autorite unique ({@link TcfLevelEstimatorService#niveauParStrates}) et
     * se contente de projeter le resultat sur {@link TargetLevel} — A1 et
     * « A1 non atteint » n'ont pas de projection, donc {@code null}.
     */
    public TargetLevel computeLevelAchieved(List<AttemptQuestion> aqs) {
        return toTargetLevel(estimatePerEpreuveFloor(aqs));
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
     * palier des questions correctes (si {@code onlyCorrect}) ou de toutes
     * les questions (= max atteignable). Poids : A2=1, B1=2, B2=3.
     * Les questions sans palier (rare) sont ignorées.
     *
     * <p>C'est la matière du <b>score de progression</b> 100-499
     * ({@code TcfLevelEstimatorService.calibratedScore}). 🛑 Aucun niveau
     * CECRL n'en dérive — le palier se lit strate par strate.
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
