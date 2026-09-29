package com.sejourfr.app.service;

import com.sejourfr.app.dto.ThemeUserResponse;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.mapper.ThemeMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Catalogue des themes pour les utilisateurs authentifies. Comptage des
 * questions actives uniquement (les inactives sont reservees aux brouillons admin).
 */
@Service
@RequiredArgsConstructor
public class ThemeUserService {

    private final ThemeManager themeManager;
    private final QuestionManager questionManager;
    private final ThemeMapper mapper;

    @Transactional(readOnly = true)
    public List<ThemeUserResponse> list(Module module) {
        List<Theme> themes = module != null
                ? themeManager.findByModuleOrderedByDisplayOrder(module)
                : themeManager.findAllOrderedByDisplayOrder();

        return themes.stream()
                .map(t -> mapper.toUserResponse(t, (int) questionManager.countActiveByTheme(t.getId())))
                .toList();
    }
}
