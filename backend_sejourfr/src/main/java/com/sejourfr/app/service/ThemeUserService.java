package com.sejourfr.app.service;

import com.sejourfr.app.dto.ThemeUserResponse;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.repository.QuestionRepository;
import com.sejourfr.app.repository.ThemeRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;

@Service
public class ThemeUserService {

    private final ThemeRepository themeRepository;
    private final QuestionRepository questionRepository;

    public ThemeUserService(
            ThemeRepository themeRepository,
            QuestionRepository questionRepository
    ) {
        this.themeRepository = themeRepository;
        this.questionRepository = questionRepository;
    }

    @Transactional(readOnly = true)
    public List<ThemeUserResponse> list(Module module) {
        List<Theme> themes = module != null
                ? themeRepository.findByModuleOrderByDisplayOrderAsc(module)
                : themeRepository.findAll().stream()
                  .sorted(Comparator.comparingInt(Theme::getDisplayOrder))
                  .toList();

        return themes.stream()
                .map(t -> new ThemeUserResponse(
                        t.getId(),
                        t.getModule(),
                        t.getCode(),
                        t.getName(),
                        t.getDescription(),
                        t.getDisplayOrder(),
                        (int) questionRepository.countByThemeIdAndActiveTrue(t.getId())
                ))
                .toList();
    }
}
