package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ThemeUserResponse;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.service.PublicThemeService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Liste publique (non authentifiee) des themes par module. Utilisee par la
 * landing pour montrer la couverture des contenus aux visiteurs avant inscription.
 */
@RestController
@RequestMapping("/api/public/themes")
@RequiredArgsConstructor
public class PublicThemeController {

    private final PublicThemeService publicThemeService;

    @GetMapping
    public List<ThemeUserResponse> list(@RequestParam(required = false) Module module) {
        return publicThemeService.list(module);
    }
}
