package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ProgressDto;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.progres.ProgressService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * <b>Progrès</b> (T28, {@code 30_} §7) — « montrer le MOUVEMENT, pas un tableau
 * de bord ».
 *
 * <p>🛑 <b>Jamais 204.</b> Un candidat sans diagnostic reçoit
 * {@code disponible: false} sur chaque moitié : l'écran a besoin de savoir
 * <b>pourquoi</b> il n'a rien à montrer pour ouvrir la porte qui débloque.
 *
 * <p>🛑 <b>Ce service n'invente aucune mesure</b> : il assemble ce que d'autres
 * autorités servent déjà (profil TCF, résolveur d'évolution, moteur de maîtrise,
 * plan civique). Aucun niveau, aucun palier, aucun état n'est recalculé ici.
 *
 * <p>🛑 <b>Aucun appel LLM</b> : tout est relu.
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
