package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ProgressDto;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.progres.ProgressService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * « Où vous en êtes » de l'Accueil. Les écrans de progression, eux, lisent
 * {@code /api/me/progression/*} ({@link ProgressionController}).
 *
 * <p>⚠️ {@code GET /api/me/progress/tcf/{epreuve}/historique} (« Vos
 * résultats ») est <b>supprimé</b> le 2026-09-24 avec son service : remplacé
 * par {@code GET /api/me/progression/tcf/{epreuve}}.
 */
@RestController
@RequestMapping("/api/me/progress")
@RequiredArgsConstructor
public class ProgressController {

    private final ProgressService service;
    private final CurrentUser currentUser;

    @GetMapping
    public ProgressDto progres() {
        return service.progres(currentUser.getId());
    }
}
