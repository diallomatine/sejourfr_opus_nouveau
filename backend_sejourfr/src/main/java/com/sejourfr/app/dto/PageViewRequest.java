package com.sejourfr.app.dto;

import com.sejourfr.app.enums.PageViewEvent;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Payload de POST /api/public/page-views, émis par le navigateur au chargement
 * d'une landing et au clic de son CTA.
 *
 * <p>Volontairement pauvre : le chemin suivi, la provenance et la nature de
 * l'événement. Pas d'identifiant de visiteur, pas d'horodatage client (le
 * serveur pose le jour), rien qui permette de recomposer un parcours
 * individuel. Le serveur n'accepte que des valeurs connues (cf.
 * {@code PageViewService}) — le client ne peut pas créer de nouvelles
 * dimensions.
 */
public record PageViewRequest(
        @NotBlank @Size(max = 160) String path,
        @Size(max = 40) String source,
        @NotNull PageViewEvent event
) {}
