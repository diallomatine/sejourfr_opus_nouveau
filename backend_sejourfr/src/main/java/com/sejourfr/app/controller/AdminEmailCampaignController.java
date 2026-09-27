package com.sejourfr.app.controller;

import com.sejourfr.app.dto.EmailCampaignRunResponse;
import com.sejourfr.app.service.email.campaign.EmailCampaignService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Campagnes d'information de service ({@code incident}, {@code reprise}) :
 * {@code mode=dry-run|test|send}, {@code batch} = taille de la vague ({@code send}),
 * {@code to} = adresse unique du mode {@code test}.
 *
 * <p>Sécurité : {@code /api/admin/**} → ROLE_ADMIN (cf. SecurityConfig).
 */
@RestController
@RequestMapping("/api/admin/campaigns")
@RequiredArgsConstructor
public class AdminEmailCampaignController {

    private final EmailCampaignService campaignService;

    @PostMapping("/{code}/send")
    public EmailCampaignRunResponse send(@PathVariable String code,
                                         @RequestParam String mode,
                                         @RequestParam(required = false) Integer batch,
                                         @RequestParam(required = false) String to) {
        return campaignService.run(code, mode, batch, to);
    }
}
