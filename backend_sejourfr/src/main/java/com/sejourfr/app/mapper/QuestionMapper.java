package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ChoiceDto;
import com.sejourfr.app.dto.QuestionDto;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Question;
import org.springframework.stereotype.Component;
import java.util.List;

@Component
public class QuestionMapper {

    public ChoiceDto toDto(Choice c) {
        return new ChoiceDto(c.getId(), c.getLabel(), c.isCorrect(), c.getDisplayOrder());
    }

    public QuestionDto toDto(Question q) {
        List<ChoiceDto> choices = q.getChoices().stream()
                .map(this::toDto)
                .toList();

        return new QuestionDto(
                q.getId(),
                q.getModule(),
                q.getTheme() != null ? q.getTheme().getId() : null,
                q.getTheme() != null ? q.getTheme().getName() : null,
                q.getPassage() != null ? q.getPassage().getId() : null,
                q.getMedia() != null ? q.getMedia().getId() : null,
                q.getMedia() != null ? q.getMedia().getUrl() : null,
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
}
