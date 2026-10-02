package com.sejourfr.app.dto;

import java.time.Instant;

/** Le cycle EN COURS d'un module, lu tel qu'il est persisté (aucun recalcul, aucune écriture). */
public record AdminUserCycleDto(
        String status,
        String entryLevel,
        String targetLevel,
        String targetProcedure,
        Instant startedAt,
        long stepsClosed,
        long stepsTotal
) {}
