package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Module;

import java.time.Instant;

/**
 * Progression d'un module (G-10) : diagnostic clos et sa date, cycle en cours
 * (niveau d'entrée, étapes closes / total), nombre de cycles historisés. Lu en
 * tables, sans effet de bord — jamais par {@code JourneyService.lire()}.
 * {@code currentCycle} absent : aucun cycle n'a encore été créé.
 */
public record AdminUserProgressionDto(
        Module module,
        String moduleLabel,
        boolean diagnosticDone,
        Instant diagnosticCompletedAt,
        AdminUserCycleDto currentCycle,
        long historisedCycles
) {}
