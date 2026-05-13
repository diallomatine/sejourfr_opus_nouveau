package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ThemeUserResponse;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.service.ThemeUserService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Endpoints publics (authentifiés) pour les thématiques.
 */
@RestController
@RequestMapping("/api/themes")
public class ThemeUserController {

    private final ThemeUserService service;

    public ThemeUserController(ThemeUserService service) {
        this.service = service;
    }

    @GetMapping
    public List<ThemeUserResponse> list(@RequestParam(required = false) Module module) {
        return service.list(module);
    }
}
