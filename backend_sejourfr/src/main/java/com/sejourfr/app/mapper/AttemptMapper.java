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
        //
        // 🛑 Le niveau est DÉRIVÉ DES RÉPONSES déjà chargées, jamais relu sur
        // `attempts.cecrl_level` — la colonne n'est plus ni écrite ni lue.
        // Aucune requête supplémentaire : `aqs` est l'argument de la méthode.
        boolean noteQcm = attempt.getFinishedAt() != null && isStratifiedTcfExam(attempt);
        List<AttemptEpreuveResult> epreuveResults =
                noteQcm ? epreuveResultsOf(aqs) : List.of();
        NiveauCecrl globalLevel = noteQcm
                ? levelEstimator.floor(
                        epreuveResults.stream().map(AttemptEpreuveResult::cecrlLevel).toList())
                : null;

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
                revealCorrect ? epreuveResults : List.of(),
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

    /**
     * Ligne d'historique d'une tentative.
     *
     * <p>🛑 <b>Le niveau arrive en argument</b>, il ne se lit pas ici : depuis
     * le 2026-09-20 il se dérive des réponses, et un mapper ne fait aucune
     * lookup. L'appelant ({@code AttemptInteractionService.listMine}) le
     * calcule pour <b>toute la page en une requête</b>
     * ({@code TcfLevelEstimatorService.niveauxQcm}) — le chercher ligne par
     * ligne serait un N+1.
     *
     * @param niveauQcm niveau dérivé des réponses, {@code null} si inconnu
     */
    public AttemptSummaryResponse toSummary(Attempt a, NiveauCecrl niveauQcm) {
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
                isStratifiedTcfExam(a) ? niveauQcm : null,
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
     * <b>Score de progression</b> 100-499 d'un examen TCF (dérivé du score
     * pondéré). Null ailleurs (le score brut reste pertinent).
     *
     * <p>🛑 Ce n'est pas un résultat d'examen et aucun palier n'en dérive :
     * le vrai relevé TCF a une échelle officielle que nous n'avons pas.
     *
     * <p><b>Public</b> depuis le 2026-09-13 : les cartes du diagnostic TCF
     * affichent le score de leur section de compréhension comme un examen
     * blanc affiche le sien. Le recalculer là-bas aurait fait exister un second
     * « /499 » dans le dépôt.
     */
    public Integer calibratedScoreOf(Attempt a) {
        if (!isStratifiedTcfExam(a)
                || a.getWeightedScore() == null
                || a.getMaxWeightedScore() == null) {
            return null;
        }
        return levelEstimator.calibratedScore(a.getWeightedScore(), a.getMaxWeightedScore());
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
