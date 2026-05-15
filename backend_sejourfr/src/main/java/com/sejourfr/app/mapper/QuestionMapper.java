package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ChoiceDto;
import com.sejourfr.app.dto.QuestionDto;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Passage;
import com.sejourfr.app.entity.Question;
import org.springframework.stereotype.Component;
import java.util.List;

@Component
public class QuestionMapper {

    private static final int PASSAGE_PREVIEW_LENGTH = 140;

    public ChoiceDto toDto(Choice c) {
        return new ChoiceDto(c.getId(), c.getLabel(), c.isCorrect(), c.getDisplayOrder());
    }

    public QuestionDto toDto(Question q) {
        List<ChoiceDto> choices = q.getChoices().stream()
                .map(this::toDto)
                .toList();

        Passage passage = q.getPassage();

        return new QuestionDto(
                q.getId(),
                q.getModule(),
                q.getTheme() != null ? q.getTheme().getId() : null,
                q.getTheme() != null ? q.getTheme().getName() : null,
                passage != null ? passage.getId() : null,
                passage != null ? passage.getType() : null,
                passage != null ? truncate(passage.getContent()) : null,
                q.getMedia() != null ? q.getMedia().getId() : null,
                q.getMedia() != null ? q.getMedia().getUrl() : null,
                q.getMedia() != null ? q.getMedia().getType() : null,
                q.getMedia() != null ? q.getMedia().getInlineSvg() : null,
                q.getDifficulty(),
                q.getQuestionType(),
                q.getStatement(),
                q.getExplanation(),
                q.isActive(),
                q.getCreatedAt(),
                q.getUpdatedAt(),
                choices
        );
    }

    private String truncate(String s) {
        if (s == null) return null;
        String oneLine = s.replaceAll("\\s+", " ").trim();
        if (oneLine.length() <= PASSAGE_PREVIEW_LENGTH) return oneLine;
        return oneLine.substring(0, PASSAGE_PREVIEW_LENGTH).trim() + "…";
    }
}
