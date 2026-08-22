package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AdminAnalyticsResponse;
import com.sejourfr.app.dto.AnalyticsAnnotationDto;
import com.sejourfr.app.dto.AnalyticsAnnotationRequest;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.analytics.AdminAnalyticsService;
import com.sejourfr.app.service.analytics.AnalyticsAnnotationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * L'ecran Analytics de la console : <b>un seul endpoint de lecture</b>, plus la
 * gestion des reperes poses sur la courbe.
 *
 * <p><b>Pourquoi un endpoint et pas cinq.</b> L'ecran recalcule toutes ses
 * sections a partir d'une meme periode et des memes filtres. Cinq endpoints,
 * c'est cinq fenetres de temps a garder coherentes cote console — et le jour ou
 * l'une decale, deux blocs de la meme page racontent deux histoires.
 *
 * <p><b>{@code from}/{@code to} l'emportent sur {@code days}</b> ; une seule
 * borne, une date illisible, {@code from > to} ou plus de 365 jours sont des
 * <b>400 nommes</b>, jamais un repli muet — autorite {@code FenetreMesure},
 * reutilisee telle quelle, jamais une seconde fenetre. La reponse rend les
 * bornes <i>appliquees</i> : l'ecran affiche la periode d'apres le serveur.
 *
 * <p>Les quatre filtres ({@code source}, {@code country}, {@code device},
 * {@code platform}) sont facultatifs et se cumulent. Une valeur inconnue ne
 * leve pas : elle ne correspond simplement a aucune ligne, et le tableau vide
 * est la reponse juste.
 */
@RestController
@RequestMapping("/api/admin/analytics")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminAnalyticsController {

    private final AdminAnalyticsService analyticsService;
    private final AnalyticsAnnotationService annotationService;
    private final UserManager userManager;

    @GetMapping
    public AdminAnalyticsResponse analytics(
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to,
            @RequestParam(defaultValue = "30") int days,
            @RequestParam(required = false) String source,
            @RequestParam(required = false) String country,
            @RequestParam(required = false) String device,
            @RequestParam(required = false) String platform
    ) {
        return analyticsService.analytics(from, to, days, source, country, device, platform);
    }

    /**
     * Les reperes d'une fenetre. Ils sont deja servis dans la reponse
     * principale ; cette route existe pour la console d'edition, qui a besoin de
     * leur identifiant et de leur description complete.
     */
    @GetMapping("/annotations")
    public List<AnalyticsAnnotationDto> annotations(
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to,
            @RequestParam(defaultValue = "30") int days
    ) {
        var fenetre = com.sejourfr.app.util.FenetreMesure.resolve(from, to, days);
        return annotationService.between(fenetre.from(), fenetre.to());
    }

    @PostMapping("/annotations")
    @ResponseStatus(HttpStatus.CREATED)
    public AnalyticsAnnotationDto create(@Valid @RequestBody AnalyticsAnnotationRequest request,
                                         Authentication authentication) {
        AnalyticsAnnotationDto cree = annotationService.create(request, auteur(authentication));
        // L'admin doit voir SON repere tout de suite : le lui faire attendre
        // 60 s lui donnerait l'impression que rien ne s'est passe, et il le
        // reposerait.
        analyticsService.invalidate();
        return cree;
    }

    @DeleteMapping("/annotations/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        annotationService.delete(id);
        analyticsService.invalidate();
    }

    /**
     * Auteur du repere, pour la tracabilite. {@code null} est tolere : le repere
     * survit au depart de son auteur, c'est une donnee produit, pas une donnee
     * personnelle.
     */
    private UUID auteur(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) return null;
        return userManager.findByEmail(authentication.getName())
                .map(com.sejourfr.app.entity.User::getId)
                .orElse(null);
    }
}
