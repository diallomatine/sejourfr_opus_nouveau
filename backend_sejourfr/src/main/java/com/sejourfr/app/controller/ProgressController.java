package com.sejourfr.app.controller;

import com.sejourfr.app.dto.EpreuveHistoriqueDto;
import com.sejourfr.app.dto.ProgressDto;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.progres.EpreuveHistoriqueService;
import com.sejourfr.app.service.progres.ProgressService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
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
    private final EpreuveHistoriqueService historiqueService;
    private final CurrentUser currentUser;

    @GetMapping
    public ProgressDto progres() {
        return service.progres(currentUser.getId());
    }

    /**
     * <b>« D'où sort mon niveau ? »</b> — les dernières évaluations
     * <b>qualifiantes</b> d'une épreuve TCF, celles-là mêmes qui alimentent le
     * {@code niveau} servi plus haut.
     *
     * <p>🛑 <b>Un endpoint à part, et pas un champ de {@link ProgressDto}</b> :
     * ce DTO refuse une liste d'historique parce qu'elle y créerait une seconde
     * vérité servie à tous les écrans. Ici la liste est le <b>détail d'une
     * ligne</b>, demandé quand le candidat ouvre une carte — l'Accueil garde
     * son appel unique.
     *
     * <p>🛑 <b>Jamais 404 pour une épreuve jamais mesurée</b> : la liste est
     * vide. Une absence de mesure n'est pas une erreur.
     */
    @GetMapping("/tcf/{epreuve}/historique")
    public EpreuveHistoriqueDto historique(@PathVariable EpreuveType epreuve) {
        return historiqueService.historique(currentUser.getId(), epreuve);
    }
}
