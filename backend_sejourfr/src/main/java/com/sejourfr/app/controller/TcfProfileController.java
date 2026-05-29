package com.sejourfr.app.controller;

import com.sejourfr.app.dto.TcfLevelProfileResponse;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.TcfProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Profil de niveau TCF par épreuve (CO/CE/EE/EO) + niveau global plancher.
 * Lecture seule, agrégation du dernier passage de chaque épreuve.
 */
@RestController
@RequiredArgsConstructor
public class TcfProfileController {

    private final TcfProfileService tcfProfileService;
    private final CurrentUser currentUser;

    @GetMapping("/api/tcf/profile/level")
    public TcfLevelProfileResponse level() {
        return tcfProfileService.levelProfile(currentUser.getId());
    }
}
