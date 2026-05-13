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
import com.sejourfr.app.mapper.QuestionMapper;
import com.sejourfr.app.repository.MediaRepository;
import com.sejourfr.app.repository.PassageRepository;
import com.sejourfr.app.repository.QuestionRepository;
import com.sejourfr.app.repository.ThemeRepository;
import com.sejourfr.app.specification.QuestionSpecifications;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service
@Transactional
public class QuestionService {

    private final QuestionRepository questionRepository;
    private final ThemeRepository themeRepository;
    private final PassageRepository passageRepository;
    private final MediaRepository mediaRepository;
    private final QuestionMapper mapper;

    public QuestionService(QuestionRepository questionRepository,
                           ThemeRepository themeRepository,
                           PassageRepository passageRepository,
                           MediaRepository mediaRepository,
                           QuestionMapper mapper) {
        this.questionRepository = questionRepository;
        this.themeRepository = themeRepository;
        this.passageRepository = passageRepository;
        this.mediaRepository = mediaRepository;
        this.mapper = mapper;
    }

    @Transactional(readOnly = true)
    public Page<QuestionDto> search(Module module, UUID themeId, Difficulty difficulty,
                                    QuestionType type, Boolean active, String search,
                                    Pageable pageable) {
        Specification<Question> spec = Specification.allOf(
                QuestionSpecifications.hasModule(module),
                QuestionSpecifications.hasTheme(themeId),
                QuestionSpecifications.hasDifficulty(difficulty),
                QuestionSpecifications.hasType(type),
                QuestionSpecifications.hasActive(active),
                QuestionSpecifications.statementContains(search)
        );
        return questionRepository.findAll(spec, pageable).map(mapper::toDto);
    }

    @Transactional(readOnly = true)
    public QuestionDto getById(UUID id) {
        return mapper.toDto(loadOrThrow(id));
    }

    public QuestionDto create(QuestionWriteRequest req) {
        validateChoices(req);

        Theme theme = themeRepository.findById(req.themeId())
                .orElseThrow(() -> NotFoundException.of("Theme", req.themeId()));

        Question q = new Question();
        applyCommon(q, req, theme);

        for (ChoiceWriteRequest cr : req.choices()) {
            Choice c = new Choice();
            c.setLabel(cr.label());
            c.setCorrect(cr.correct());
            c.setDisplayOrder(cr.displayOrder());
            q.addChoice(c);
        }

        return mapper.toDto(questionRepository.save(q));
    }

    public QuestionDto update(UUID id, QuestionWriteRequest req) {
        validateChoices(req);
        Question q = loadOrThrow(id);

        Theme theme = themeRepository.findById(req.themeId())
                .orElseThrow(() -> NotFoundException.of("Theme", req.themeId()));
        applyCommon(q, req, theme);

        // Remplacement complet des choix (simple et fiable pour le MVP)
        q.clearChoices();
        for (ChoiceWriteRequest cr : req.choices()) {
            Choice c = new Choice();
            c.setLabel(cr.label());
            c.setCorrect(cr.correct());
            c.setDisplayOrder(cr.displayOrder());
            q.addChoice(c);
        }
        return mapper.toDto(q);
    }

    public QuestionDto setActive(UUID id, boolean active) {
        Question q = loadOrThrow(id);
        q.setActive(active);
        return mapper.toDto(q);
    }

    public void delete(UUID id) {
        if (!questionRepository.existsById(id)) {
            throw NotFoundException.of("Question", id);
        }
        questionRepository.deleteById(id);
    }

    private void applyCommon(Question q, QuestionWriteRequest req, Theme theme) {
        q.setModule(req.module());
        q.setTheme(theme);
        q.setDifficulty(req.difficulty());
        q.setQuestionType(req.questionType());
        q.setStatement(req.statement());
        q.setExplanation(req.explanation());
        if (req.active() != null) q.setActive(req.active());

        if (req.passageId() != null) {
            Passage p = passageRepository.findById(req.passageId())
                    .orElseThrow(() -> NotFoundException.of("Passage", req.passageId()));
            q.setPassage(p);
        } else {
            q.setPassage(null);
        }

        if (req.mediaId() != null) {
            Media m = mediaRepository.findById(req.mediaId())
                    .orElseThrow(() -> NotFoundException.of("Media", req.mediaId()));
            q.setMedia(m);
        } else {
            q.setMedia(null);
        }
    }

    private Question loadOrThrow(UUID id) {
        return questionRepository.findById(id)
                .orElseThrow(() -> NotFoundException.of("Question", id));
    }

    private void validateChoices(QuestionWriteRequest req) {
        long correct = req.choices().stream().filter(ChoiceWriteRequest::correct).count();
        if (correct < 1) {
            throw new BusinessException("Une question doit avoir au moins un choix correct");
        }
    }
}
