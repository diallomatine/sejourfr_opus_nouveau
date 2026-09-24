package com.sejourfr.app.controller;

import com.sejourfr.app.dto.CivicThemeExamSlotsDto;
import com.sejourfr.app.dto.ThemeUserResponse;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.ThemeUserService;
import com.sejourfr.app.service.examencivique.CivicThemeExamSlotsService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Endpoints themes pour les utilisateurs authentifies.
 */
@RestController
@RequestMapping("/api/themes")
@RequiredArgsConstructor
public class ThemeUserController {

    private final ThemeUserService themeUserService;
    private final CivicThemeExamSlotsService examSlotsService;
    private final CurrentUser currentUser;

    @GetMapping
    public List<ThemeUserResponse> list(@RequestParam(required = false) Module module) {
        return themeUserService.list(module);
    }

    /** Grille des examens blancs d'un thème civique : un {@code locked} servi par créneau. */
    @GetMapping("/{themeId}/exam-slots")
    public CivicThemeExamSlotsDto examSlots(@PathVariable UUID themeId) {
        return examSlotsService.slots(currentUser.getId(), themeId);
    }
}
