package com.sejourfr.app.controller;

import com.sejourfr.app.dto.PageViewRequest;
import com.sejourfr.app.service.PageViewService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Réception des événements d'audience des landings, sans authentification.
 *
 * <p>Répond 204 : le navigateur émet cet appel en {@code sendBeacon} et ne lit
 * jamais la réponse — renvoyer un corps serait du gaspillage.
 */
@RestController
@RequestMapping("/api/public/page-views")
@RequiredArgsConstructor
public class PublicPageViewController {

    private final PageViewService pageViewService;

    @PostMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void track(@Valid @RequestBody PageViewRequest request) {
        pageViewService.track(request);
    }
}
