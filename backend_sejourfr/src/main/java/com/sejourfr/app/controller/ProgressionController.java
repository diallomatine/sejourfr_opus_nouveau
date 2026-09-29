package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ProgressionCiviqueDto;
import com.sejourfr.app.dto.ProgressionEpreuveDto;
import com.sejourfr.app.dto.ProgressionTcfDto;
import com.sejourfr.app.dto.ProgressionThemeDto;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.progres.ProgressionExamensService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Les quatre écrans de progression (maquettes
 * {@code docs/progression/maquettes-progression/}), lus sur les examens blancs.
 * Contrat : {@code docs/regles/progression.md} § « Écrans de progression ».
 *
 * <p>{@code ?tous=true} sur les deux écrans globaux : la liste entière des
 * examens (au plus 50) au lieu des 3 derniers — le lien « Tous mes examens
 * blancs ».
 */
@RestController
@RequestMapping("/api/me/progression")
@RequiredArgsConstructor
public class ProgressionController {

    private final ProgressionExamensService service;
    private final CurrentUser currentUser;

    @GetMapping("/tcf")
    public ProgressionTcfDto tcf(@RequestParam(defaultValue = "false") boolean tous) {
        return service.tcf(currentUser.getId(), tous);
    }

    @GetMapping("/tcf/{epreuve}")
    public ProgressionEpreuveDto epreuve(@PathVariable EpreuveType epreuve) {
        return service.epreuve(currentUser.getId(), epreuve);
    }

    @GetMapping("/civique")
    public ProgressionCiviqueDto civique(@RequestParam(defaultValue = "false") boolean tous) {
        return service.civique(currentUser.getId(), tous);
    }

    @GetMapping("/civique/themes/{themeId}")
    public ProgressionThemeDto theme(@PathVariable UUID themeId) {
        return service.theme(currentUser.getId(), themeId);
    }
}
