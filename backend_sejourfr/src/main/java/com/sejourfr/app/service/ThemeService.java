package com.sejourfr.app.service;

import com.sejourfr.app.dto.ThemeDto;
import com.sejourfr.app.dto.ThemeWriteRequest;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.repository.QuestionRepository;
import com.sejourfr.app.repository.ThemeRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class ThemeService {

    private final ThemeRepository themeRepository;
    private final QuestionRepository questionRepository;

    public ThemeService(ThemeRepository themeRepository, QuestionRepository questionRepository) {
        this.themeRepository = themeRepository;
        this.questionRepository = questionRepository;
    }

    public static ThemeDto toDto(Theme t, long count) {
        return new ThemeDto(t.getId(), t.getModule(), t.getCode(), t.getName(),
                t.getDescription(), t.getDisplayOrder(), count);
    }

    @Transactional(readOnly = true)
    public List<ThemeDto> listAll() {
        return themeRepository.findAll().stream()
                .map(t -> toDto(t, questionRepository.countByThemeId(t.getId())))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ThemeDto> listByModule(Module module) {
        return themeRepository.findByModuleOrderByDisplayOrderAsc(module).stream()
                .map(t -> toDto(t, questionRepository.countByThemeId(t.getId())))
                .toList();
    }

    @Transactional(readOnly = true)
    public ThemeDto getById(UUID id) {
        Theme t = themeRepository.findById(id)
                .orElseThrow(() -> NotFoundException.of("Theme", id));
        return toDto(t, questionRepository.countByThemeId(t.getId()));
    }

    public ThemeDto create(ThemeWriteRequest req) {
        if (themeRepository.existsByCode(req.code())) {
            throw new BusinessException("Le code de thematique '" + req.code() + "' existe deja");
        }
        Theme t = new Theme();
        t.setModule(req.module());
        t.setCode(req.code());
        t.setName(req.name());
        t.setDescription(req.description());
        t.setDisplayOrder(req.displayOrder());
        return toDto(themeRepository.save(t), 0L);
    }

    public ThemeDto update(UUID id, ThemeWriteRequest req) {
        Theme t = themeRepository.findById(id)
                .orElseThrow(() -> NotFoundException.of("Theme", id));
        if (!t.getCode().equals(req.code()) && themeRepository.existsByCode(req.code())) {
            throw new BusinessException("Le code de thematique '" + req.code() + "' existe deja");
        }
        t.setModule(req.module());
        t.setCode(req.code());
        t.setName(req.name());
        t.setDescription(req.description());
        t.setDisplayOrder(req.displayOrder());
        return toDto(t, questionRepository.countByThemeId(t.getId()));
    }

    public void delete(UUID id) {
        Theme t = themeRepository.findById(id)
                .orElseThrow(() -> NotFoundException.of("Theme", id));
        long count = questionRepository.countByThemeId(t.getId());
        if (count > 0) {
            throw new BusinessException(
                    "Impossible de supprimer : " + count + " question(s) sont rattachees a cette thematique");
        }
        themeRepository.delete(t);
    }
}
