package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AttemptQuestionResponse;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.AttemptSummaryResponse;
import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.enums.Difficulty;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class AttemptMapper {

    private final QuestionMapper questionMapper;

    public AttemptResponse toResponse(Attempt attempt, List<AttemptQuestion> aqs, boolean revealCorrect) {
        List<AttemptQuestionResponse> aqResponses = aqs.stream()
                .map(aq -> toAttemptQuestionResponse(aq, revealCorrect))
                .toList();

        ExamTemplate template = attempt.getExamTemplate();
        UUID templateId = template != null ? template.getId() : null;
        String templateSlug = template != null ? template.getSlug() : null;
        String templateName = template != null ? template.getName() : null;

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
                aqResponses
        );
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
                template != null ? template.getName() : null
        );
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
