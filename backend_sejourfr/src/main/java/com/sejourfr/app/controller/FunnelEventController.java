package com.sejourfr.app.controller;

import com.sejourfr.app.dto.FunnelEventRequest;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.FunnelEventService;
import com.sejourfr.app.util.ClientContextResolver;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Les deux etapes de funnel que le serveur ne peut pas constater lui-meme :
 * l'ecran Premium affiche et le clic sur l'abonnement.
 *
 * <p><strong>Idempotent, premiere occurrence gagnante</strong> : un rejeu
 * renvoie 204 sans rien creer. Pas de rate-limit — l'unicite
 * {@code (user, event)} borne la table a 3 lignes par compte, donc marteler la
 * route n'a aucun effet, ni sur la donnee ni sur le stockage.
 */
@RestController
@RequestMapping("/api/me/funnel-events")
@RequiredArgsConstructor
public class FunnelEventController {

    private final FunnelEventService funnelEventService;
    private final ClientContextResolver clientContextResolver;
    private final CurrentUser currentUser;

    @PostMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void record(@Valid @RequestBody FunnelEventRequest req, HttpServletRequest http) {
        funnelEventService.recordFromClient(
                currentUser.getId(), req.event(), clientContextResolver.resolve(http));
    }
}
