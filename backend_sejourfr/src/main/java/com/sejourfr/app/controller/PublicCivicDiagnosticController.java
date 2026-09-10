package com.sejourfr.app.controller;

import com.sejourfr.app.dto.CivicDiagnosticDto;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.ratelimit.RateLimitGuard;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticService;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticViewService;
import com.sejourfr.app.util.ClientIpResolver;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Le diagnostic civique <b>avant le compte</b> (V053).
 *
 * <p>🛑 <b>Arbitrage du proprietaire, 2026-09-10</b> : « que ce soit le
 * diagnostic examen civique ou TCF, l'utilisateur doit pouvoir passer le
 * diagnostic avant de creer son compte ; il repond au QCM et seulement apres on
 * lui demande de creer son compte pour voir le resultat. »
 *
 * <p><b>Ce que ce controleur expose, et ce qu'il n'expose pas.</b> Il ouvre le
 * tirage et rend l'etat d'avancement. La <b>passation</b> passe par
 * {@code /api/public/attempts/{id}} — le meme runner que la demo, aucun ecran
 * de passation n'est duplique. 🛑 <b>Il n'y a deliberement AUCUNE route de
 * resultat ici</b> : le resultat est ce qu'on echange contre le compte.
 *
 * <p>🛑 <b>Pourquoi le civique persiste la ou le TCF garde tout sur
 * l'appareil</b> ({@link PublicDiagnosticController}) : le TCF invite produit
 * du texte et de l'audio, qu'aucun serveur n'a besoin de voir avant l'analyse ;
 * le civique est du QCM, et le corriger cote client obligerait a servir les
 * bonnes reponses a un visiteur. On reutilise donc l'attempt invite de la demo,
 * et l'inscription <i>adopte</i> la session
 * ({@code POST /api/civic-diagnostics/{id}/adopt}).
 */
@RestController
@RequestMapping("/api/public/civic-diagnostics")
@RequiredArgsConstructor
public class PublicCivicDiagnosticController {

    private final CivicDiagnosticService service;
    private final CivicDiagnosticViewService viewService;
    private final RateLimitGuard rateLimitGuard;
    private final ClientIpResolver clientIpResolver;

    /**
     * Tire les questions et ouvre la session du visiteur.
     *
     * <p>🛑 <b>Pas idempotent, et c'est borne par l'IP.</b> Contrairement a
     * {@code POST /api/civic-diagnostics}, il n'y a pas de compte sur lequel
     * retrouver « celui deja en cours » : le front garde l'identifiant rendu et
     * ne rappelle cette route que pour un NOUVEAU diagnostic. Le seul frein est
     * donc le rate-limit par IP, le meme que la demo invitee.
     *
     * @param procedure la demarche declaree par le visiteur. Absente ⇒
     *                  {@code CSP}, le perimetre le plus etroit — mesurer un
     *                  candidat sur des questions qu'il n'a pas a connaitre
     *                  produirait un diagnostic faussement severe.
     */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CivicDiagnosticDto ouvrir(
            @RequestParam(required = false) TargetProcedure procedure,
            HttpServletRequest httpRequest) {
        String ip = clientIpResolver.resolve(httpRequest);
        rateLimitGuard.checkDemo(ip);
        return viewService.vue(service.ouvrirInvite(procedure, ip));
    }

    /**
     * L'etat d'avancement de la session du visiteur.
     *
     * <p><b>404 des qu'un compte l'a adoptee</b> : elle n'est plus lisible que
     * par son porteur, meme depuis la meme IP.
     */
    @GetMapping("/{id}")
    public CivicDiagnosticDto detail(@PathVariable UUID id, HttpServletRequest httpRequest) {
        return viewService.vue(
                service.lireInvite(id, clientIpResolver.resolve(httpRequest)));
    }
}
