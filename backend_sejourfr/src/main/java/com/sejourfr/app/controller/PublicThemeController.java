package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ThemeUserResponse;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.service.PublicThemeService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Liste publique (non authentifiée) des thèmes par module. Utilisée par la
 * landing pour montrer la couverture des contenus aux visiteurs avant
 * inscription.
 */
@RestController
@RequestMapping("/api/public/themes")
public class PublicThemeController {

    private final PublicThemeService service;

    public PublicThemeController(PublicThemeService service) {
        this.service = service;
    }

    @GetMapping
    public List<ThemeUserResponse> list(@RequestParam(required = false) Module module) {
        return service.list(module);
    }
}
