package com.sejourfr.app.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * Corps OPTIONNEL de {@code POST /api/realtime/eo/sessions/{id}/finish} (V090,
 * mesure seulement). Un client qui n'envoie rien clôt la session comme avant.
 *
 * @param endCause {@code TIME_UP} | {@code USER_FINISH} | {@code CONNECTION_LOST}
 *                 | {@code ERROR}. Une valeur inconnue est ignorée. {@code ERROR}
 *                 clôt la session en {@code FAILED} SANS notation : le candidat
 *                 repasse sur l'enregistrement classique.
 * @param events   événements de conduite accumulés par le client pendant la
 *                 session ; seuls {@code SILENCE_RELANCE} et {@code TIMEUP_GRACE}
 *                 sont acceptés (les reprises sont tracées par le serveur).
 */
public record FinishRealtimeSessionRequest(
        String endCause,
        @Valid @Size(max = 200) List<ConductEvent> events
) {

    /**
     * @param type    type d'événement
     * @param atMs    ms depuis l'établissement de la connexion côté client
     * @param valueMs durée associée (grâce de fin de temps utilisée)
     */
    public record ConductEvent(
            String type,
            @PositiveOrZero Integer atMs,
            @PositiveOrZero Integer valueMs
    ) {}
}
