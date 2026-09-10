package com.sejourfr.app.controller;

import com.sejourfr.app.dto.CivicDiagnosticDto;
import com.sejourfr.app.dto.CivicDiagnosticResultDto;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticService;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticViewService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Le diagnostic CIVIQUE (lot L9, spec 20_ §4).
 *
 * <p>🛑 <b>Distinct de l'examen blanc civique</b>, et 20_ §4.1 les oppose ligne
 * a ligne : 24 questions contre 40, couverture equilibree contre
 * representative, il CREE le plan la ou l'examen blanc VERIFIE la preparation.
 *
 * <p>La <b>passation</b> ne passe pas par ici : les reponses vont sur
 * {@code /api/attempts/{id}/answers}, exactement comme n'importe quelle serie.
 * 🛑 Aucun runner n'est duplique.
 *
 * <p>🛑 <b>Aucune de ces routes n'appelle un LLM.</b> Le civique est du QCM
 * deterministe : sa correction ne coute rien.
 */
@RestController
@RequestMapping("/api/civic-diagnostics")
@RequiredArgsConstructor
public class CivicDiagnosticController {

    private final CivicDiagnosticService service;
    private final CivicDiagnosticViewService viewService;
    private final CurrentUser currentUser;

    /**
     * Ouvre un diagnostic, ou rend celui deja en cours. <b>Idempotent</b> :
     * deux appuis ne creent pas deux tirages, donc pas deux mesures
     * incomparables.
     */
    @PostMapping
    public CivicDiagnosticDto ouvrir() {
        return viewService.vue(service.ouvrir(currentUser.getId()));
    }

    /**
     * Le diagnostic courant. <b>204 quand il n'y en a aucun</b> : ne jamais en
     * ouvrir un par effet de bord d'une lecture — l'ouverture est un geste du
     * candidat, et elle consomme son unique diagnostic gratuit.
     */
    @GetMapping("/current")
    public ResponseEntity<CivicDiagnosticDto> courant() {
        return service.courant(currentUser.getId())
                .map(viewService::vue)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    @GetMapping("/{id}")
    public CivicDiagnosticDto detail(@PathVariable UUID id) {
        return viewService.vue(service.lire(currentUser.getId(), id));
    }

    /**
     * Le resultat. Cloture le diagnostic au passage.
     *
     * <p>🛑 <b>Aucun contenu n'est verrouille ici</b> : « le constat est
     * integralement gratuit, le paywall porte sur l'accompagnement »
     * (20_ §4.5).
     */
    @PostMapping("/{id}/result")
    public CivicDiagnosticResultDto resultat(@PathVariable UUID id) {
        CivicDiagnosticSession session = service.cloturer(currentUser.getId(), id);
        return viewService.resultat(session);
    }

    /** Relire un resultat deja calcule, sans rien recloturer. */
    @GetMapping("/{id}/result")
    public CivicDiagnosticResultDto relireResultat(@PathVariable UUID id) {
        return viewService.resultat(service.lire(currentUser.getId(), id));
    }
}
