package com.sejourfr.app.service.examencivique;

import com.sejourfr.app.dto.CivicThemeExamSlotsDto;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.service.AttemptService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * La grille servie des examens blancs d'un thème civique : un {@code locked}
 * par créneau, lu chez l'autorité du verrou
 * ({@link AttemptService#isExamenDeThemeVerrouille}) — jamais recalculé.
 */
@Service
@RequiredArgsConstructor
public class CivicThemeExamSlotsService {

    private final ThemeManager themeManager;
    private final AttemptService attemptService;

    /** @param userId {@code null} pour un visiteur sans compte */
    @Transactional(readOnly = true)
    public CivicThemeExamSlotsDto slots(UUID userId, UUID themeId) {
        Theme theme = themeManager.findById(themeId)
                .filter(t -> t.getModule() == Module.CIVIQUE)
                .orElseThrow(() -> new NotFoundException("Thème civique introuvable : " + themeId));
        List<CivicThemeExamSlotsDto.Slot> slots = new ArrayList<>(AttemptService.MOCK_EXAM_SLOTS);
        for (int slot = 1; slot <= AttemptService.MOCK_EXAM_SLOTS; slot++) {
            slots.add(new CivicThemeExamSlotsDto.Slot(
                    slot, attemptService.isExamenDeThemeVerrouille(userId, slot)));
        }
        return new CivicThemeExamSlotsDto(theme.getId(), slots);
    }
}
