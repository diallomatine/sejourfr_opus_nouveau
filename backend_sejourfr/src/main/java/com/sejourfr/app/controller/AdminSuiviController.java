package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AdminSuiviResponse;
import com.sejourfr.app.service.analytics.SuiviService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Le dashboard « Suivi » de la console : un seul endpoint de lecture, une seule
 * periode et un seul jeu de filtres pour tous les blocs. Contrat :
 * {@link AdminSuiviResponse} ; filtre invalide = 400 nomme.
 */
@RestController
@RequestMapping("/api/admin/analytics")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminSuiviController {

    private final SuiviService suiviService;

    @GetMapping("/suivi")
    public AdminSuiviResponse suivi(
            @RequestParam(required = false) String preset,
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String platform,
            @RequestParam(required = false) String source,
            @RequestParam(defaultValue = "false") boolean includeInternal
    ) {
        return suiviService.suivi(preset, from, to, type, platform, source, includeInternal);
    }
}
