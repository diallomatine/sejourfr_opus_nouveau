package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SuiviPeriodPreset;

import java.time.LocalDate;

/**
 * Encart de {@code GET /api/admin/productions/stats} (DI-35) : la vue d'ensemble
 * d'une période, comptes internes inclus ou non, indépendante des autres filtres
 * de la liste.
 *
 * @param preset    preset appliqué, {@code null} pour une plage ou sans borne
 * @param from      premier jour couvert (Paris), {@code null} = sans borne
 * @param to        dernier jour couvert (Paris), {@code null} = sans borne
 * @param candidats comptes distincts ayant soumis au moins une production
 */
public record AdminProductionStatsDto(
        SuiviPeriodPreset preset,
        LocalDate from,
        LocalDate to,
        boolean includeInternal,
        long candidats,
        AdminProductionCompteursDto compteurs
) {}
