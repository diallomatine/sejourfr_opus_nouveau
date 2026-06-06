package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AttemptEpreuveResult;
import com.sejourfr.app.dto.AttemptQuestionResponse;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.AttemptSummaryResponse;
import com.sejourfr.app.dto.QcmAnswerResult;
import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.service.TcfLevelEstimatorService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class AttemptMapper {

    private final QuestionMapper questionMapper;
    private final TcfLevelEstimatorService levelEstimator;

    public AttemptResponse toResponse(Attempt attempt, List<AttemptQuestion> aqs, boolean revealCorrect) {
        List<AttemptQuestionResponse> aqResponses = aqs.stream()
                .map(aq -> toAttemptQuestionResponse(aq, revealCorrect))
                .toList();

        ExamTemplate template = attempt.getExamTemplate();
        UUID templateId = template != null ? template.getId() : null;
        String templateSlug = template != null ? template.getSlug() : null;
        String templateName = template != null ? template.getName() : null;

        // Détail par épreuve d'un examen TCF stratifié fini ; le niveau
        // global est alors le plancher des épreuves (règle TCF IRN : il faut
        // le niveau partout — un seul A1 tire l'ensemble à A1).
        List<AttemptEpreuveResult> epreuveResults =
                revealCorrect && attempt.getFinishedAt() != null && isStratifiedTcfExam(attempt)
                        ? epreuveResultsOf(aqs)
                        : List.of();
        NiveauCecrl globalLevel = epreuveResults.isEmpty()
                ? cecrlLevelOf(attempt)
                : levelEstimator.floor(
                        epreuveResults.stream().map(AttemptEpreuveResult::cecrlLevel).toList());

        return new AttemptResponse(
                attempt.getId(),
                attempt.getType(),
                attempt.getModule(),
                templateId,
                templateSlug,
                templateName,
                attempt.getTotalQuestions(),
                attempt.getTimeLimitSeconds(),
                attempt.getPassThreshold(),
                attempt.getStartedAt(),
                attempt.getFinishedAt(),
                attempt.getScore(),
                attempt.getLevelAchieved(),
                attempt.getModuleExamQuestionType(),
                attempt.getLotThemeId(),
                calibratedScoreOf(attempt),
                globalLevel,
                epreuveResults,
                aqResponses
        );
    }

    /**
     * Groupe les questions d'un attempt par épreuve (CO_IMAGE → CO) et évalue
     * chacune : bonnes réponses, score calibré 100-499 et niveau CECRL —
     * mêmes formules que l'examen module mono-épreuve.
     */
    private List<AttemptEpreuveResult> epreuveResultsOf(List<AttemptQuestion> aqs) {
        Map<QuestionType, List<QcmAnswerResult>> byEpreuve = new LinkedHashMap<>();
        for (AttemptQuestion aq : aqs) {
            QuestionType t = aq.getQuestion().getQuestionType();
            if (t == null) continue;
            QuestionType key = t == QuestionType.CO_IMAGE ? QuestionType.CO : t;
            byEpreuve.computeIfAbsent(key, k -> new ArrayList<>()).add(new QcmAnswerResult(
                    aq.getQuestion().getId(),
                    aq.getQuestion().getDifficulty(),
                    aq.getAnswer() != null && Boolean.TRUE.equals(aq.getAnswer().getCorrect())));
        }
        List<AttemptEpreuveResult> results = new ArrayList<>(byEpreuve.size());
        for (Map.Entry<QuestionType, List<QcmAnswerResult>> entry : byEpreuve.entrySet()) {
            List<QcmAnswerResult> answers = entry.getValue();
            int correct = (int) answers.stream().filter(QcmAnswerResult::correct).count();
            results.add(new AttemptEpreuveResult(
                    entry.getKey(),
                    correct,
                    answers.size(),
                    levelEstimator.calibratedScore(answers),
                    levelEstimator.estimateQcm(answers)));
        }
        return results;
    }

    public AttemptSummaryResponse toSummary(Attempt a) {
        // Difficulte representative d'un attempt : on prend celle de la premiere
        // question piochee. A terme on pourrait stocker une difficulte au niveau
        // de l'Attempt directement.
        Difficulty diff = null;
        if (!a.getQuestions().isEmpty()) {
            diff = a.getQuestions().getFirst().getQuestion().getDifficulty();
        }

        ExamTemplate template = a.getExamTemplate();
        return new AttemptSummaryResponse(
                a.getId(),
                a.getType(),
                a.getModule(),
                a.getEpreuve(),
                diff,
                a.getTotalQuestions(),
                a.getPassThreshold(),
                a.getStartedAt(),
                a.getFinishedAt(),
                a.getScore(),
                template != null ? template.getId() : null,
                template != null ? template.getSlug() : null,
                template != null ? template.getName() : null,
                a.getModuleExamQuestionType(),
                a.getWeightedScore(),
                a.getMaxWeightedScore(),
                calibratedScoreOf(a),
                cecrlLevelOf(a),
                a.getLotThemeId(),
                a.getSlotNumber()
        );
    }

    /**
     * Examen TCF à strates garanties : examen module (CO/CE/STRUCTURE) ou
     * examen template (diagnostic sectionné CO→CE). Seuls ces attempts portent
     * une notation calibrée 100-499 + niveau CECRL.
     */
    private boolean isStratifiedTcfExam(Attempt a) {
        return a.getModule() == Module.TCF
                && (a.getModuleExamQuestionType() != null || a.getExamTemplate() != null);
    }

    /**
     * Score calibré 100-499 d'un examen TCF (dérivé du score pondéré).
     * Null ailleurs (le score brut reste pertinent).
     */
    private Integer calibratedScoreOf(Attempt a) {
        if (!isStratifiedTcfExam(a)
                || a.getWeightedScore() == null
                || a.getMaxWeightedScore() == null) {
            return null;
        }
        return levelEstimator.calibratedScore(a.getWeightedScore(), a.getMaxWeightedScore());
    }

    /**
     * Niveau CECRL d'un examen TCF : cecrl_level stocké au finish (plancher
     * des épreuves depuis la règle « min partout » ; V112 a invalidé les
     * niveaux de l'ancienne règle), fallback dérivé du score pondéré — bande
     * du score calibré, donc couple cohérent. Null hors examens TCF stratifiés.
     */
    private NiveauCecrl cecrlLevelOf(Attempt a) {
        if (!isStratifiedTcfExam(a)) return null;
        if (a.getCecrlLevel() != null) return a.getCecrlLevel();
        return levelEstimator.levelFromWeighted(a.getWeightedScore(), a.getMaxWeightedScore());
    }

    private AttemptQuestionResponse toAttemptQuestionResponse(AttemptQuestion aq, boolean revealCorrect) {
        Answer answer = aq.getAnswer();
        List<UUID> selectedIds = answer != null ? new ArrayList<>(answer.getSelectedChoiceIds()) : List.of();
        Boolean correct = answer != null && revealCorrect ? answer.getCorrect() : null;

        // Seed = AttemptQuestion.id : ordre stable d'une lecture a l'autre
        // (reprise, refresh) mais different a chaque nouvelle session.
        return new AttemptQuestionResponse(
                aq.getId(),
                aq.getPosition(),
                questionMapper.toPublic(aq.getQuestion(), revealCorrect, aq.getId()),
                answer != null,
                selectedIds,
                correct
        );
    }
}
