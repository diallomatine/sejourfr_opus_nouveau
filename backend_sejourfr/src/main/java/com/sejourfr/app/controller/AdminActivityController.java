package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AdminActivityLiveResponse;
import com.sejourfr.app.dto.AdminActivityResponse;
import com.sejourfr.app.service.activity.ActivityService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * L'ecran « Activite » de la console ({@code /dashboard/activity}, D9) : une
 * lecture de periode et un direct rafraichi toutes les 30 s (D11). Contrat :
 * {@link AdminActivityResponse}, {@link AdminActivityLiveResponse} ; periode
 * invalide = 400 nomme.
 */
@RestController
@RequestMapping("/api/admin/analytics/activity")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminActivityController {

    private final ActivityService activityService;

    @GetMapping
    public AdminActivityResponse activity(
            @RequestParam(required = false) String preset,
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to,
            @RequestParam(defaultValue = "false") boolean includeInternal
    ) {
        return activityService.activity(preset, from, to, includeInternal);
    }

    @GetMapping("/live")
    public AdminActivityLiveResponse live(@RequestParam(defaultValue = "false") boolean includeInternal) {
        return activityService.live(includeInternal);
    }
}
