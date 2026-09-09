package com.sejourfr.app.controller;

import com.sejourfr.app.dto.TcfDiagnosticDto;
import com.sejourfr.app.dto.TcfDiagnosticResultDto;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticSectionStarter;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticService;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticViewService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Le diagnostic TCF 4 epreuves.
 *
 * <p>🛑 <b>Distinct de {@code /api/diagnostics}</b>, qui porte le diagnostic
 * initial (une production ecrite + une orale) : ce sont deux objets produit
 * differents, et 10_ §4.1 interdit de les confondre.
 *
 * <p>La <b>passation</b> ne passe pas par ici : les sections QCM repondent sur
 * {@code /api/attempts/{id}/answers} et les productions sur
 * {@code /api/production-submissions}, exactement comme l'examen complet.
 * Aucun pipeline n'est duplique.
 */
@RestController
@RequestMapping("/api/tcf-diagnostics")
@RequiredArgsConstructor
public class TcfDiagnosticController {

    private final TcfDiagnosticService service;
    private final TcfDiagnosticViewService viewService;
    private final TcfDiagnosticSectionStarter sectionStarter;
    private final CurrentUser currentUser;

    /**
     * Ouvre un diagnostic, ou rend celui deja en cours. <b>Idempotent</b> :
     * deux appuis sur « Commencer » ne creent pas deux diagnostics.
     */
    @PostMapping
    public TcfDiagnosticDto ouvrir() {
        return viewService.vue(service.ouvrir(currentUser.getId()));
    }

    /**
     * Le diagnostic courant. <b>204 quand il n'y en a aucun</b> : ne jamais en
     * ouvrir un par effet de bord d'une lecture — l'ouverture est un geste du
     * candidat, et elle consomme son unique diagnostic gratuit.
     */
    @GetMapping("/current")
    public ResponseEntity<TcfDiagnosticDto> courant() {
        return service.courant(currentUser.getId())
                .map(viewService::vue)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    @GetMapping("/{id}")
    public TcfDiagnosticDto detail(@PathVariable UUID id) {
        return viewService.vue(service.lire(currentUser.getId(), id));
    }

    /**
     * Lance le chrono d'une section. C'est l'ancre du decompte : quitter ne
     * suspend rien, le temps court pendant l'absence. Idempotent — rappele, il
     * rend le temps reellement restant.
     */
    @PostMapping("/{id}/sections/{epreuve}/start")
    public TcfDiagnosticDto lancerSection(
            @PathVariable UUID id, @PathVariable EpreuveType epreuve) {
        TcfDiagnosticSession session = service.lire(currentUser.getId(), id);
        sectionStarter.lancerSection(session, epreuve);
        return viewService.vue(session);
    }

    /**
     * Le resultat. Cloture le diagnostic au passage.
     *
     * <p>Il n'exige pas les 4 sections : 10_ §4.2 impose de « calculer sur les
     * sections realisees », les autres restant non evaluees.
     *
     * <p>🛑 <b>Aucun contenu n'est verrouille ici</b> : le paywall porte sur le
     * plan, jamais sur le constat.
     */
    @PostMapping("/{id}/result")
    public TcfDiagnosticResultDto resultat(@PathVariable UUID id) {
        TcfDiagnosticSession session = service.cloturer(currentUser.getId(), id);
        NiveauCecrl cible = service.cible(session.getUser()).orElse(null);
        return viewService.resultat(session, cible);
    }

    /** Relire un resultat deja calcule, sans rien recloturer. */
    @GetMapping("/{id}/result")
    public TcfDiagnosticResultDto relireResultat(@PathVariable UUID id) {
        TcfDiagnosticSession session = service.lire(currentUser.getId(), id);
        NiveauCecrl cible = service.cible(session.getUser()).orElse(null);
        return viewService.resultat(session, cible);
    }
}
