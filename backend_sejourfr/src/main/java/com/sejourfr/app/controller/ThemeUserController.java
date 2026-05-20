package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ThemeUserResponse;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.service.ThemeUserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Endpoints themes pour les utilisateurs authentifies.
 */
@RestController
@RequestMapping("/api/themes")
@RequiredArgsConstructor
public class ThemeUserController {

    private final ThemeUserService themeUserService;

    @GetMapping
    public List<ThemeUserResponse> list(@RequestParam(required = false) Module module) {
        return themeUserService.list(module);
    }
}
