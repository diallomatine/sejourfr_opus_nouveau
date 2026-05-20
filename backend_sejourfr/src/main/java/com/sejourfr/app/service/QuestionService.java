package com.sejourfr.app.service;

import com.sejourfr.app.dto.ChoiceWriteRequest;
import com.sejourfr.app.dto.QuestionDto;
import com.sejourfr.app.dto.QuestionWriteRequest;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Media;
import com.sejourfr.app.entity.Passage;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.MediaManager;
import com.sejourfr.app.manager.PassageManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.mapper.QuestionMapper;
import com.sejourfr.app.specification.QuestionSpecifications;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * CRUD admin des questions. La validation metier (au moins 1 choix correct)
 * vit ici ; le mapping est delegue au {@link QuestionMapper} (vue admin).
 */
@Service
@Transactional
@RequiredArgsConstructor
public class QuestionService {

    private final QuestionManager questionManager;
    private final ThemeManager themeManager;
    private final PassageManager passageManager;
    private final MediaManager mediaManager;
    private final QuestionMapper mapper;

    @Transactional(readOnly = true)
    public Page<QuestionDto> search(
            Module module, UUID themeId, Difficulty difficulty, QuestionType type,
            Boolean active, String search, Pageable pageable) {
        Specification<Question> spec = Specification.allOf(
                QuestionSpecifications.hasModule(module),
                QuestionSpecifications.hasTheme(themeId),
                QuestionSpecifications.hasDifficulty(difficulty),
                QuestionSpecifications.hasType(type),
                QuestionSpecifications.hasActive(active),
                QuestionSpecifications.statementContains(search)
        );
        return questionManager.search(spec, pageable).map(mapper::toDto);
    }

    @Transactional(readOnly = true)
    public QuestionDto getById(UUID id) {
        return mapper.toDto(loadOrThrow(id));
    }

    public QuestionDto create(QuestionWriteRequest req) {
        validateChoices(req);
        Theme theme = loadTheme(req.themeId());

        Question q = new Question();
        applyCommon(q, req, theme);
        replaceChoices(q, req);

        return mapper.toDto(questionManager.save(q));
    }

    public QuestionDto update(UUID id, QuestionWriteRequest req) {
        validateChoices(req);
        Question q = loadOrThrow(id);
        Theme theme = loadTheme(req.themeId());

        applyCommon(q, req, theme);
        // Remplacement complet des choix (simple et fiable pour le MVP).
        q.clearChoices();
        replaceChoices(q, req);
        return mapper.toDto(q);
    }

    public QuestionDto setActive(UUID id, boolean active) {
        Question q = loadOrThrow(id);
        q.setActive(active);
        return mapper.toDto(q);
    }

    public void delete(UUID id) {
        if (!questionManager.existsById(id)) {
            throw NotFoundException.of("Question", id);
        }
        questionManager.deleteById(id);
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    private Question loadOrThrow(UUID id) {
        return questionManager.findById(id)
                .orElseThrow(() -> NotFoundException.of("Question", id));
    }

    private Theme loadTheme(UUID id) {
        return themeManager.findById(id)
                .orElseThrow(() -> NotFoundException.of("Theme", id));
    }

    private void applyCommon(Question q, QuestionWriteRequest req, Theme theme) {
        q.setModule(req.module());
        q.setTheme(theme);
        q.setDifficulty(req.difficulty());
        q.setQuestionType(req.questionType());
        q.setStatement(req.statement());
        q.setExplanation(req.explanation());
        if (req.active() != null) q.setActive(req.active());

        q.setPassage(req.passageId() == null ? null : loadPassage(req.passageId()));
        q.setMedia(req.mediaId() == null ? null : loadMedia(req.mediaId()));
    }

    private Passage loadPassage(UUID id) {
        return passageManager.findById(id)
                .orElseThrow(() -> NotFoundException.of("Passage", id));
    }

    private Media loadMedia(UUID id) {
        return mediaManager.findById(id)
                .orElseThrow(() -> NotFoundException.of("Media", id));
    }

    private void replaceChoices(Question q, QuestionWriteRequest req) {
        for (ChoiceWriteRequest cr : req.choices()) {
            Choice c = new Choice();
            c.setLabel(cr.label());
            c.setCorrect(cr.correct());
            c.setDisplayOrder(cr.displayOrder());
            q.addChoice(c);
        }
    }

    private void validateChoices(QuestionWriteRequest req) {
        long correct = req.choices().stream().filter(ChoiceWriteRequest::correct).count();
        if (correct < 1) {
            throw new BusinessException("Une question doit avoir au moins un choix correct");
        }
    }
}
