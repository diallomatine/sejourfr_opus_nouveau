package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AdminAccessOperationType;
import com.sejourfr.app.enums.ModuleAccess;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

/**
 * Une action admin sur l'accès d'un compte (spec §8). Dates métier en jours
 * Europe/Paris : {@code endDateInclusive} « jusqu'au 31/10/2026 inclus » ;
 * {@code startDate} (Donner / Réactiver seulement) par défaut aujourd'hui.
 * {@code fromProduct} : produit à retirer pour {@code CORRECT_PRODUCT}.
 * {@code dryRun} : aperçu calculé serveur, rien n'est écrit.
 * {@code expectedVersion} : l'{@code accessVersion} lue par la modale —
 * obligatoire pour écrire, 409 si l'état a changé.
 * {@code realtimeEoSessions} : sessions EO temps réel offertes (V084), absent = 0 ;
 * accepté (&gt; 0) seulement pour une action qui crée un GRANT INTEGRAL — Donner
 * Intégral, Réactiver Intégral, Corriger Civique → Intégral — et au plus
 * {@code sejourfr.realtime.admin-grant-max-sessions} ; 400 sinon.
 * 🛑 Le motif ne doit contenir aucune donnée personnelle inutile (G-8).
 */
public record AdminAccessOperationRequest(
        @NotNull AdminAccessOperationType operation,
        @NotNull ModuleAccess product,
        ModuleAccess fromProduct,
        LocalDate startDate,
        LocalDate endDateInclusive,
        @NotBlank @Size(min = 3, max = 500) String reason,
        boolean dryRun,
        String expectedVersion,
        @PositiveOrZero Integer realtimeEoSessions
) {}
