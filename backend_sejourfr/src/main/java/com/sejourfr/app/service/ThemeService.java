package com.sejourfr.app.service;

import com.sejourfr.app.dto.ThemeDto;
import com.sejourfr.app.dto.ThemeWriteRequest;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.mapper.ThemeMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * CRUD admin des thematiques. Suppression interdite tant qu'une question
 * y est rattachee (active ou non).
 */
@Service
@Transactional
@RequiredArgsConstructor
public class ThemeService {

    private final ThemeManager themeManager;
    private final QuestionManager questionManager;
    private final ThemeMapper mapper;

    @Transactional(readOnly = true)
    public List<ThemeDto> listAll() {
        return themeManager.findAllOrderedByDisplayOrder().stream()
                .map(this::toAdminDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ThemeDto> listByModule(Module module) {
        return themeManager.findByModuleOrderedByDisplayOrder(module).stream()
                .map(this::toAdminDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public ThemeDto getById(UUID id) {
        return toAdminDto(loadTheme(id));
    }

    public ThemeDto create(ThemeWriteRequest req) {
        if (themeManager.existsByCode(req.code())) {
            throw new BusinessException("Le code de thematique '" + req.code() + "' existe deja");
        }
        Theme t = new Theme();
        applyWrite(t, req);
        return mapper.toAdminDto(themeManager.save(t), 0L);
    }

    public ThemeDto update(UUID id, ThemeWriteRequest req) {
        Theme t = loadTheme(id);
        if (!t.getCode().equals(req.code()) && themeManager.existsByCode(req.code())) {
            throw new BusinessException("Le code de thematique '" + req.code() + "' existe deja");
        }
        applyWrite(t, req);
        return toAdminDto(t);
    }

    public void delete(UUID id) {
        Theme t = loadTheme(id);
        long count = questionManager.countByTheme(t.getId());
        if (count > 0) {
            throw new BusinessException(
                    "Impossible de supprimer : " + count + " question(s) sont rattachees a cette thematique");
        }
        themeManager.delete(t);
    }

    private Theme loadTheme(UUID id) {
        return themeManager.findById(id)
                .orElseThrow(() -> NotFoundException.of("Theme", id));
    }

    private void applyWrite(Theme t, ThemeWriteRequest req) {
        t.setModule(req.module());
        t.setCode(req.code());
        t.setName(req.name());
        t.setDescription(req.description());
        t.setDisplayOrder(req.displayOrder());
    }

    private ThemeDto toAdminDto(Theme t) {
        return mapper.toAdminDto(t, questionManager.countByTheme(t.getId()));
    }
}
